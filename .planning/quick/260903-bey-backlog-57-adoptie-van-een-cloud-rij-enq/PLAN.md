---
quick_id: 260903-bey
slug: backlog-57-adoptie-van-een-cloud-rij-enq
date: 2026-09-03
backlog_item: 57
---

# Backlog #57 — het overbodige schrijven bij elke start is een lus, geen overijverige enqueue

## Wat het item zei, en wat het werkelijk is

Het backlog-item beschrijft het symptoom: twee opeenvolgende koude starts logden allebei
`drain done — 2 pending, 2 sent (profile, availability), 0 failed` zonder dat er iets gewijzigd
was, met als vermoeden "vermoedelijk `enqueueCurrentState()` op het sign-in/reconcile-pad dat ook
bij een bestaande sessie draait".

Dat vermoeden klopt niet. `enqueueCurrentState()` hangt uitsluitend aan
`SyncDecision.pushLocalToCloud` in `AccountSyncService`, en dat pad draait alleen bij het inloggen.
De werkelijke oorzaak is een **lus die zichzelf voedt**:

1. Koude start → `reconcileOnStartup()` leest de cloud. Is de cloud-rij meer dan de noop-band van
   5 seconden nieuwer dan lokaal, dan wordt hij overgenomen.
2. Overnemen gebeurt met `profileRepo.save(cloudProfile.profile, stamp: false)`. Die `stamp: false`
   zegt terecht "dit is geen lokale bewerking, zet de tijdstempel niet op nu" — **maar `save()`
   enqueuet onvoorwaardelijk een outbox-upsert**, ook voor deze schrijving. Dat is het defect: de
   vlag dekt de tijdstempel wel en de enqueue niet.
3. `stampUpdatedAt(cloudUpdatedAt)` zet lokaal op het *oude* cloudtijdstip.
4. De drain duwt die rij terug omhoog. De trigger `profiles_set_updated_at`
   (`before update on public.profiles`, migratie `0001_accounts_sync.sql`) zet
   `updated_at = now()`.
5. Volgende koude start: de cloud is nu nieuwer dan lokaal met het hele verstreken tijdsverschil —
   terug naar stap 1.

Zelfde keten voor `availability`, met dezelfde trigger.

## Waarom dit meer is dan ruis

- **`updated_at` is onbruikbaar geworden als "wanneer wijzigde de gebruiker dit".** Die kolom is
  precies de invoer waarop `resolveAccountSync()` beslist wie er wint bij een divergentie. Een
  kolom die bij elke app-start opschuift, meet niets meer.
- Elke start kost twee netwerkschrijvingen zonder aanleiding.
- Een drain mét werk is niet meer te onderscheiden van een drain zonder, wat logdiagnose in deze
  fase al twee keer heeft vertraagd.

## Waarom het niet altijd optreedt

Op 2026-09-02 (device session 10, verse Play-installatie) logde elke voorgrondcyclus
`0 pending, 0 sent`. Dat is consistent: na de eerste-login-migratie waren lokaal en cloud binnen de
noop-band gelijk, dus er werd niets overgenomen en dus ook niets ge-enqueued. De lus start pas
zodra er één keer een echte adoptie plaatsvindt. Dat is ook precies waarom dit niet met een
tellertje te vinden was.

## Taken

### Taak 1 — `save()` een expliciete `enqueue`-parameter geven

`ProfileRepository.save()` en `AvailabilityRepository.save()` krijgen
`{bool stamp = true, bool enqueue = true}`. De vier plekken die een cloud-rij overnemen geven
`enqueue: false` mee:

- `cloud_sync_reconciler_provider.dart` — profiel en beschikbaarheid
- `account_sync_service.dart` — `_applyProfileDecision` / `_applyAvailabilityDecision`, tak
  `pullCloudToLocal`

**Bewust niet gekoppeld aan `stamp`.** Dat zou korter zijn, maar er is één `stamp: false`-aanroep
die géén cloud-adoptie is: `ProfileNotifier.setUserNameFromSignIn()` schrijft de naam uit het
Google-account zonder te stampen, en die moet de cloud wél bereiken. Twee vlaggen die toevallig
meestal samenvallen op één vlag samentrekken, is precies hoe deze bug is ontstaan.

De `pushLocalToCloud`-tak leunt niet op `save()`'s enqueue — die roept `enqueueCurrentState()`
zelf aan. Er gaat dus geen enkele push verloren.

### Taak 2 — een test die de lus vastlegt

De lus is nu meetbaar dankzij backlog #60's `CloudSyncGateway`. In
`test/providers/cloud_sync_reconciler_gateway_test.dart`: adopteer een nieuwere cloud-rij en toets
dat er daarna **geen** outbox-rij klaarstaat. Plus een repository-test dat `save()` met
`enqueue: false` de outbox met rust laat en zonder die vlag wél enqueuet — anders is het de
volgende keer weer weg te "vereenvoudigen".

## Acceptatie

- `flutter test` groen (baseline 459/459).
- `flutter analyze` geen nieuwe errors of warnings (baseline 169 issues, 0 errors).
- Een adoptie van een cloud-rij laat de outbox leeg; een gewone gebruikerswijziging enqueuet nog
  steeds.

## Buiten scope

De noop-band van 5 seconden en de vraag of `updated_at` beter client-side gezet kan worden. Dat is
een ontwerpdiscussie; dit item haalt alleen de schrijving weg die er niet hoort te zijn.
