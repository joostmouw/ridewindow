---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Accounts & Sociaal
status: "Fase 21: alleen Play-installatie op toestel open"
last_updated: "2026-09-02T06:10:00.000Z"
last_activity: 2026-09-01
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 25
  completed_plans: 18
  percent: 40
---

# Project State

## Deferred Items

Items acknowledged and deferred at v2.0 milestone close on 2026-07-17. The `audit-open` tool flagged these 11 quick tasks as "missing" status, but each one has a committed PLAN.md + SUMMARY.md and corresponding feature commits — this is treated as a tracking/audit-tool false positive, not unfinished work.

| Category | Item | Status |
|----------|------|--------|
| quick_task | 260617-qjd-android-home-screen-widget-toont-volgend | missing (audit false-positive, work complete) |
| quick_task | 260618-csx-week-agenda-view-met-ride-overlap-overla | missing (audit false-positive, work complete) |
| quick_task | 260714-m63-add-sun-partly-cloudy-icon-to-ride-detai | missing (audit false-positive, work complete) |
| quick_task | 260714-n0c-add-feedback-feature-backlog-33-send-fee | missing (audit false-positive, work complete) |
| quick_task | 260714-nfk-add-backlog-36-google-calendar-connectio | missing (audit false-positive, work complete) |
| quick_task | 260714-o54-bundle-backlog-34-sticky-plan-ride-butto | missing (audit false-positive, work complete) |
| quick_task | 260714-qor-ride-detail-plan-ride-knop-toont-planned | missing (audit false-positive, work complete) |
| quick_task | 260714-r8u-herstijl-screenhintoverlay-dot-indicator | missing (audit false-positive, work complete) |
| quick_task | 260714-rne-availability-grid-twee-tik-bereik-select | missing (audit false-positive, work complete) |
| quick_task | 260714-rrx-unplan-delete-geplande-rit-vanaf-ride-de | missing (audit false-positive, work complete) |
| quick_task | 260714-spo-agenda-tab-vervang-long-press-sleep-sele | missing (audit false-positive, work complete) |

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-25)

**Core value:** Accurate cyclist-specific weather scoring translated into concrete bookable time slots
**Current focus:** Phase 21 — sync-migration

## Current Position

Phase: 21 (sync-migration) — EXECUTING

## Stand na de avond van 2026-08-05 — lees dit eerst

**Build op het toestel: 1.0.21+22, SIDELOAD (niet via Play).** Halverwege de avond is de
Play-route verlaten: elke iteratie kostte 20+ minuten tegen 2 voor `adb install`, en §2 — de enige
sectie die de Play App Signing-route echt moet bewijzen — was al afgetekend. `adb uninstall` +
`adb install` van de lokale release-APK. Zolang dit een sideload is biedt Play geen updates meer
aan (andere handtekening); aan het eind van de fase één Play-installatie als afsluiting.

**Wat er die avond is gefixt (vier plannen, alle vier gevonden op het toestel):**
- 21-11 disposed `Ref` — de drain draaide niet
- 21-12 availability-payload was geen rij
- 21-13 `rideId` overleefde de `timestamptz`-rondgang niet → één rit verscheen als twee
- 21-14 push gebeurde ná pull → een verwijderde rit werd door de merge weer opgewekt

**Groen op het toestel (sessie 5, 22:53-23:00):**
- **MIG-02** — tweede toestel, leeg lokaal + gevulde cloud. Rooster identiek aan de opname van
  vóór de wipe, profiel en taal terug, geen conflictdialoog. Stond in de requirements en was nog
  nooit getest.
- **§5b** — twee ritten op een verse installatie die alles uit de cloud trok. Sterkere vorm dan de
  checklist vroeg: er was geen lokale staat die het resultaat kon maskeren.
- **§5c** — verwijderde rit blijft weg na drie cycli; de delete is zichtbaar in de drain vóór de
  pull.

**Openstaand, en waarom:**
- §5b's dashboardcontrole (`ride_id` op `Z`, `start_at` 10:00 UTC voor de 12:00-rit) — alleen Joost
  komt in Supabase.
- §2's uitlog-ronde — **geblokkeerd door mijn eigen sideload**: de OAuth-grant van Google Calendar
  hing aan de vorige installatie en is meegegaan met de de-installatie. De koppeling staat nu op
  "Not connected", dus D-12 (uitloggen mag de agendakoppeling niet meeslepen) is niet toetsbaar
  tot de agenda opnieuw gekoppeld is. Dat had ik moeten voorzien; ik woog wel de lokale database
  af, niet de OAuth-grant.
- §3 (iPhone-PWA), §4 (koude start), §5 (multi-tab), §6 (account verwijderen).

**Niet als bewezen wegschrijven:** 21-13's cloud-reparatiepad (`_repairNonCanonicalRideIds`) heeft
nooit gedraaid — de spookrijen waren al uit de cloud verdwenen vóór de sideload. Zie
MANUAL-VERIFICATION-21.md voor de redenering. Alleen unit-tests dekken dat pad.

**Backlog-items uit deze avond:** #56 (agenda-mismatchcheck toont een Google-venster bij koude
start, terwijl de code belooft nooit te prompten), #57 (elke start herschrijft profiel én
availability zonder wijziging), #58/#59 (agenda-events hardcoded Nederlands en hardcoded
`Europe/Amsterdam`), **#60 (CloudSyncReconciler injecteerbaar maken — vijf keer op rij de reden
dat een bug pas op een toestel gevonden werd; het enige item dat dit patroon doorbreekt)**.

**21-13 uitgevoerd 2026-08-05 (build 1.0.20+21).** Toestelsessie 4 legde bloot dat één tik op
"Schedule" twee identieke ritkaarten opleverde. `rideId` kwam uit `start.toIso8601String()` en die
string verschilt voor een lokale en een UTC-`DateTime`; alles wat door de `timestamptz`-kolom gaat
komt als UTC terug, dus dezelfde rit kreeg twee sleutels en de union-merge hield ze allebei.

Onderweg bleek er een **tweede** fout onder te zitten: `toRow()` schreef een offsetloze string, die
Postgres in de sessiezone (UTC) leest. Een rit van 12:00 lokaal is dus opgeslagen als 12:00 UTC —
hetzelfde klokgetal, twee uur verschoven. Bestaande cloud-rijen dragen daarom én een verkeerde
sleutel én een verkeerd tijdstip, en de lokale lijst is de enige bron waar de bedoelde tijd nog
klopt. Dat bepaalt de opruimstrategie: cloud-rij weggooien, lokale kopie opnieuw pushen.

Suite 440/1 (de ene is de bekende post-19:00-UTC notificatietest), analyze 0 errors op de baseline
van 162 infos, REG-05 groen. Toestelverificatie staat als §5b in REGRESSION-CHECKLIST-21.md, met
de nadrukkelijke instructie om op convergentie ná een foreground-cyclus te oordelen en niet op het
eerste scherm — de duplicaten zijn echte data.

**Uit toestelsessie 4 ook vastgelegd:** §2's versie-assertie, startup, AUTH-04 en het agenda-event
zijn afgetekend; alleen de uitlog-ronde resteert van §2. Het "Signing you in."-venster dat bij een
koude start opkomt is Google Play Services' `AssistedSignInActivity`, niet onze app — AUTH-04 is
dus groen, maar `calendar_service.dart` belooft in zijn commentaar nooit te prompten en dat klopt
niet (backlog #56). Verder: elke koude start herschrijft profiel én beschikbaarheid zonder
wijziging (#57), en agenda-events zijn hardcoded Nederlands (#58) met een hardcoded
`Europe/Amsterdam` (#59).

**Gepusht en gedeployd** (was eerder "nog niet gepusht"): de PWA serveert 1.0.21+22, dezelfde code
als het toestel. §3 en §5 vergelijken dus appels met appels.

**Post-merge gate op `631ef14` (2026-08-04 19:45) — groen.** De samenvoeging van de twee
parallelle 21-12-takken is geverifieerd op main: suite **434/434**, `flutter analyze` 0 errors /
0 warnings (162 pre-existing `info`s), REG-05-structuurtest groen. Release-artefacten opnieuw
gebouwd op **1.0.19+20** — de vorige lagen op 19:06 en dateerden van vóór de merge (nog +18);
`versionName 1.0.19` geverifieerd in de AAB-manifest. De PWA staat op dezelfde code
(`version.json` = 1.0.19/20, `main.dart.js` 17:44:53 GMT), dus beide kanten van §3 draaien
identiek. §0 van de checklist wees nog naar +18 en is rechtgetrokken.

**§5a afgetekend.** SYNC-05 is op toestel bewezen met twee metingen in tegengestelde richting;
de vinkjes in REGRESSION-CHECKLIST-21.md stonden nog open terwijl het bewijs al in
MANUAL-VERIFICATION-21.md stond. Eén vinkje blijft bewust open: de statustekst
"Gesynchroniseerd" is nooit waargenomen, alleen afgeleid uit `0 failed`.

**Openstaande beslissing voor Joost (uit 21-12-RECONCILIATION.md, geen actie van mij):** main's
`kMaxSendAttempts = 5` gooit een rij na vijf mislukte pogingen wég. Nu de payloadbug gefixt is
klein risico, maar het betekent dat een beschikbaarheidswijziging stilzwijgend kan sneuvelen.
Waard om er bewust ja tegen te zeggen in plaats van het te laten meeliften.

Plan: 12 of 14 met SUMMARY (21-01 t/m 21-07 + 21-10 t/m 21-14); resteren 21-08 en 21-09, beide
`autonomous: false` -- hun code/docs zijn gecommit (139a4f8, aaae7b6) maar er is nog GEEN
SUMMARY.md, omdat beide nog wachten op hun toestel-checkpoint (taak 2, `gate="blocking"`).
Status: Toestelsessie 2026-08-04 uitgevoerd. MIG-05/06 bewezen. SYNC-05 was NIET geleverd;
plan 21-10 heeft dat op 2026-08-04 gedicht (in code -- toestelverificatie staat nog open).

**Auto-helften geauditeerd 2026-08-04 -- allebei groen.** Beide plannen waren taak 1 gecommit
zonder ooit tegen hun acceptatiecriteria afgetekend te zijn; dat is nu alsnog gedaan:
- 21-08 taak 1: `kDeleteOwnAccountRpc` aanwezig; RPC staat strikt vóór `signOut()` binnen
  dezelfde `try`, dus een mislukte RPC logt de gebruiker nooit uit (D-02); geen enkele
  `resetToDefaults`/`clearAll` binnen `_confirmAndDeleteAccount()` -- die matches horen bij de
  losstaande account-switch-tak (D-03 gerespecteerd); alle zes ARB-sleutels in EN+NL en in de
  drie gegenereerde bestanden; EN/NL sleutelpariteit 380/380; de "kan niet ongedaan"-tekst
  staat er letterlijk in beide talen.
- 21-09 taak 1: suite 420/420, REG-05-test groen, `flutter build apk --release` exit 0,
  REGRESSION-CHECKLIST-21.md bevat alle vier vereiste secties én de verplichte `BLOCKER`-regel
  over de nooit-gemeten fase-19-basislijn.
- Kanttekening: `verify.key-links` meldt 0/1 voor 21-08. Dat is een planningsartefact -- het
  `from`-veld is proza ("the delete-account confirm dialog's Delete action") in plaats van een
  bestandspad, dus de tool vindt geen bronbestand. Inhoudelijk handmatig geverifieerd, zie
  hierboven. Geen codefout.

**PWA-blokkade opgelost 2026-08-04 14:58 — de hele checklist is weer één sessie.** De deploy
faalde sinds 2026-07-26 omdat `deploy-web.yml` verwees naar een secret
`FIREBASE_SERVICE_ACCOUNT` dat nooit is aangemaakt; de PWA stond daardoor nog op 1.0.12+13 van
26 juli, wat §3/§4/§5 onuitvoerbaar maakte. `firebase init hosting:github` maakte service
account `github-action-1257243656` en zette de key als `FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST`;
de workflow wijst nu daarnaartoe (commit `4e3957e`, run #3 groen in 3m 8s). Live geverifieerd:
`version.json` = 1.0.15+16, `main.dart.js` Last-Modified 2026-08-04 12:57 UTC.

Let op: het oude commentaar in `deploy-web.yml` adviseerde het secret te hernoemen naar een
nettere naam. Dat kan niet -- GitHub Actions-secrets kennen geen rename en hun waarde is
write-only, dus hernoemen kost een compleet nieuwe service-account-key. Advies gecorrigeerd in
het bestand zelf.

Ook nodig geweest: het token `ridewindow-cli` had alleen scope `repo`, waardoor de push met de
workflow-wijziging werd geweigerd. Scope `workflow` toegevoegd (geen regenerate, dus de keychain
bleef geldig).

**Sessievolgorde nu:** §0 → §1 → §2 → §5a → §3 → §4 → §5 → §6, in één sessie. §6 blijft laatste
omdat het het testaccount vernietigt dat §3/§4/§5 levend nodig hebben -- niet meer wegens een
blokkade. Build: **1.0.16+17** (bevat de 21-11-fix; +16 faalde aantoonbaar op §5a). De PWA moet
opnieuw deployen zodra +17 op main staat, zodat §3's beide kanten weer dezelfde code draaien.

**Wat de sessie afsluit:** §6 sluit plan 21-08, §4+§3+§5 sluiten plan 21-09. Draai je alles, dan
kan fase 21 naar 10/10 en door naar verificatie. Niets in `lib/` staat nog open.

**21-12 (2026-08-04, gevonden zonder toestel): de availability-payload was nooit een rij.**
`AvailabilityRepository` enqueuede `jsonEncode(toRecurringRow(hours))`, dus
`client.from('availability').upsert(payload)` bood `"1-9"` en `"6-14"` aan als KOLOMNAMEN van
`public.availability` (kolommen: user_id, recurring, version, updated_at). Structureel
onmogelijk, geen netwerkkwestie. `profiles` en `planned_rides` waren wel correct -- vandaar dat
een profielwijziging leek te syncen terwijl de teller nooit nul haalde. Gevonden door het
SQL-schema naast de Dart-payloads te leggen.

Meegenomen: `_drainInternal` logt nu elke mislukte send (entity, key, poging, fout) in plaats van
hem in de `lastError`-kolom te laten verdwijnen, en `kMaxSendAttempts = 5` met `dropRow()` zorgt
dat een onverzendbare rij een toestel niet eeuwig op "Syncing..." vastzet -- Joost's telefoon had
er zo een. Suite 431/431.

**De les, nu drie keer:** 21-10 controleerde of de aanroep bestond, 21-11 of die zijn werk
bereikte, 21-12 of de payload een legale rij was. Elke keer stopte de test één laag te vroeg. De
nieuwe `outbox_payload_shape_test.dart` bewaakt die laatste laag tabelgedreven.

**Historie, opgelost (toestelsessie 2, 2026-08-04 16:20).** Op 1.0.16+17 is de
`disposed`-fout aantoonbaar wég -- `adb logcat | grep -i disposed` blijft leeg na een
foreground-cyclus, waar diezelfde grep op +16 twee regels gaf. 21-11 heeft dus gedaan wat het
moest doen. **Maar de statustekst staat nog steeds op "Syncing..."**, dus
`watchPendingCount()` > 0 en er komen nog altijd rijen niet weg.

Waarom we niks zien in logcat: `SyncOutboxService._drainInternal` vangt per rij en doet
`_dao.markFailed(row.id, e.toString())` -- **zonder enige log**. De fout landt in de kolom
`lastError` in Drift en wordt nergens getoond. Dat is de eerste zaak om te dichten; nu is elke
mislukte send onzichtbaar, en dat is precies het patroon dat deze fase al twee keer heeft
gebeten.

Wat we wél weten:
- `pendingRows()` en `watchPendingCount()` selecteren allebei ALLE rijen, zonder filter. Teller
  boven nul betekent dus letterlijk: er staan rijen die niet verzonden krijgen.
- `markSent()` verwijdert de rij; blijft de rij staan, dan is de send gefaald.
- Sterke hypothese, nog niet bewezen: dit zijn **oude, vergiftigde rijen van vanochtend**,
  aangemaakt toen de drain stuk was. Nieuwe wijzigingen syncen mogelijk prima terwijl de teller
  door die oude rijen boven nul blijft. Dat onderscheid is nog niet gemaakt.

Testwijziging die klaarstaat: "Evening before" is om 16:19 AAN gezet op het toestel (Joost's
eigen instelling -- terugzetten mag). Als `profiles.notif_evening_before` in het Supabase-
dashboard op true staat, dan werkt de nieuwe sync en zijn alleen de oude rijen stuk.

Volgende stappen, in deze volgorde:
1. Dashboard openen en `profiles.notif_evening_before` voor joostmouw@gmail.com controleren.
   True = nieuwe sync werkt, alleen oude rijen vastgelopen. False = de drain faalt nog volledig.
2. Hoe dan ook: een plan 21-12 dat `_drainInternal`'s catch laat loggen (en overweeg `lastError`
   ergens zichtbaar te maken, al is het maar via het verborgen debugmenu). Zonder dat blijven we
   blind diagnosticeren.
3. Pas daarna verder met §5a.

**21-10 was NIET genoeg -- 21-11 dicht de echte bug (2026-08-04, toestelsessie 2).** Op
1.0.15+16 bleef de statustekst op "Syncing..." staan. Logcat na een foreground-cyclus:
`CloudSyncReconciler.drainOutbox failed: Cannot use the Ref of cloudSyncReconcilerProvider
after it has been disposed` -- en dezelfde regel voor `reconcileOnForeground`, dus SYNC-04 was
sinds 21-04 al stuk op exact dat pad. Oorzaak: bare `@riverpod` is auto-dispose in Riverpod 3,
beide callsites gebruiken `ref.read` (terecht), en `CloudSyncReconciler` bewaart de `Ref` over
await-grenzen. Plan 21-11 zet beide providers op `@Riverpod(keepAlive: true)` en haalt de
`Supabase.instance.client`-lookup uit `drainOutbox()` naar de send-closures, zodat de methode
zonder Supabase testbaar is. Suite 423/423, de acht Supabase-ruisregels zijn weg.

**De les, nu twee keer geleerd:** 21-10's test was een structurele broncode-scan die bewees dat
de aanroep bestond. Deze bug leefde in of die aanroep zijn werk bereikte. 21-11 voegt een
gedragstest toe die `drainOutbox()` via een kale `container.read` draait -- exact zoals productie
-- en faalde aantoonbaar op de oude code met de letterlijke disposed-Ref-melding.

**Opgelost door 21-10 (2026-08-04):** `syncOutboxServiceProvider` bouwt nu
`SyncOutboxService` met echte Supabase-send-closures, en `drain()` heeft twee echte
aanroepplekken: `CloudSyncReconciler.reconcileOnForeground()` en
`AccountSection._runAccountSync()` (na sign-in, zodra conflictdialogen zijn afgehandeld).
`drain()` kreeg een re-entrancy-guard. `test/providers/outbox_drain_wiring_test.dart`
faalt zodra de wiring weer verdwijnt. Suite: 420/420 groen, `flutter analyze` schoon.
Nog te doen op toestel: item §5a in REGRESSION-CHECKLIST-21.md -- wijzig een
profielinstelling terwijl je ingelogd bent en controleer dat de `profiles`-rij in Supabase
verandert ZONDER uit- en weer in te loggen.

**Het defect zoals het gevonden werd (2026-08-04, nu gedicht):** `SyncOutboxService` werd nergens in
`lib/` aangemaakt en `drain()` wordt nooit aangeroepen. De outbox is write-only in productie:
repositories zetten er rijen in, niets haalt ze eruit. Eerste-login-migratie werkt wel (die
roept de RPC rechtstreeks aan, buiten de outbox om), maar elke wijziging daarna bereikt de
cloud nooit. Oorzaak is een planning-gat, geen uitvoeringsfout: 21-03 wees het werk toe aan
21-04/21-05, 21-04 wees het door naar 21-06/21-07, en die noemen `drain` nul keer. Suite is
groen omdat `drain()` zelf goed getest is -- alleen roept niemand hem aan. Plan 21-10
(gap_closure, wave 9) dicht dit en voegt een test toe die faalt zodra de wiring weer verdwijnt.

**Wel bewezen op het toestel:** MIG-05/06 -- eerste login schreef profiel (echte waarden),
availability (120 uurblokken) en 2 geplande ritten in EEN atomaire RPC, alle drie met tijdstempel
2026-08-04 09:14:46. Daarmee is het grootste risico van deze fase (de 14-argumentsignatuur van
`migrate_account_data`) definitief afgedekt. Geen fouten in logcat.

**Procesles, opgenomen als item 0 van de checklist:** de eerste testronde leek volledig te
falen; er ging ~40 minuten in serverdiagnose voordat bleek dat het toestel versionCode 13 draaide
(de build van 26 juli, zonder fase 20/21-code). Play serveerde die omdat het account in de
bestaande closed test zat en niet in interne tests. Controleer ALTIJD eerst de geinstalleerde
versionCode voordat je gedrag interpreteert.

**Ook gecorrigeerd:** REGRESSION-CHECKLIST-21.md zei dat de statustekst "Gesynchroniseerd" bewijs
was voor een geslaagde migratie. Dat klopt niet -- die tekst telt outbox-rijen en de migratie
gaat niet via de outbox, dus hij staat sowieso op "Gesynchroniseerd". Alleen rijen in het
dashboard zijn bewijs.

**Los, inmiddels OPGELOST (2026-08-04 14:58):** `.github/workflows/deploy-web.yml` faalde sinds
2026-07-26 op een ontbrekende repository-secret. Zie het blok "PWA-blokkade opgelost" hierboven
voor wat er precies gebeurd is. Sectie 3 (iPhone) is niet langer geblokkeerd.

**Wat af is (waves 1-6, alles gemerged op main):**
- 21-01 `resolveAccountSync()` — pure beslisfunctie, 11 tests
- 21-02 Postgres-schema live toegepast. **Belangrijk:** tijdens de checkpoint bleek dat RLS-
  policies alléén niet volstaan — Postgres controleert tabelrechten vóór RLS, en Supabase's
  defaults gaven de `authenticated`-rol geen DML. Zonder de toegevoegde `grant`-regels kon een
  ingelogde gebruiker zelfs zijn eigen rijen niet lezen. Gefixt in `0001_accounts_sync.sql`
  (commit 581cd73) en live toegepast. SYNC-08 bewezen: B select/update/delete van A's rij = 0/0/0,
  A select eigen rij = 1. Zie MANUAL-VERIFICATION-21.md.
- 21-03 offline outbox (Drift schemaVersion 1→2, additief)
- 21-04 profile + availability via outbox naar cloud
- 21-05 planned rides (per-rit outbox-sleutel, niet per gebruiker)
- 21-06 first-login migratie via één `rpc('migrate_account_data', …)`
- 21-07 sign-in UI + conflictdialogen, EN/NL beide 374 sleutels

Volle suite: 414 geslaagd / 1 gefaald. Die ene is `notification_service_test.dart`
"scheduleEveningBefore tijdberekening" — faalt **elke run na 19:00 UTC** (tijdsafhankelijke
bug in de test zelf, niet de maandgrens die hier eerder stond; die is een tweede, aparte bug in
dezelfde test). Geen regressie.

**Open risico dat alleen op het toestel te bewijzen is:** `migrate_account_data` is gegrant met
een exacte 14-argumentsignatuur. De Dart-aanroep in `lib/domain/services/migration_payload.dart`
is statisch geverifieerd — alle 14 namen en types komen overeen — maar of Postgres de overload
werkelijk resolvet blijkt pas bij een echte aanroep. Mismatch faalt at runtime en ziet eruit als
een auth-fout, niet als een signatuurfout.

Builds klaar (1.0.12+13, gebouwd 2026-08-04, bevat waves 1-6):
`build/app/outputs/flutter-apk/app-release.apk` en `build/app/outputs/bundle/release/app-release.aab`.
Let op: het versienummer +13 is hetzelfde als de fase-19-build van 2026-07-26 maar de inhoud is
totaal anders — bump naar +14 vóór upload als +13 al gebruikt is.

Nog open van fase 19: 19-07 blijft handwerk — de AAB uploaden naar de Play Console internal
testing track, daarna
installeren via de Store-link (nadrukkelijk niet een lokale APK — D-16/AUTH-10, alleen de Play
App Signing SHA-1 bewijst het juiste OAuth-client) en
`.planning/phases/19-auth/REGRESSION-CHECKLIST.md` aflopen: Android in-/uitloggen + agenda-event

+ herstartpersistentie, iPhone-PWA installeren/standalone/navigeren/inloggen/agenda-event, plus

de koudestartmeting mét toestel, verbindingstype en methode (die methode wordt in fase 21
letterlijk herhaald voor REG-03).
Last activity: 2026-08-04
en volle testsuite zelf geverifieerd op main.

## Performance Metrics

**Velocity:**

- Total plans completed: 18 (Phases 1, 1.5, 2)
- Average duration: ~15min voor mechanische taken (geautomatiseerd executor-modus)
- Total execution time: ~3h (Phase 1) + ~45min (Phase 1.5) + ~40min (Phase 2)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | ~3h | ~1h |
| 1.5 | 4 | ~45min | ~11min |
| 2 | 3 | ~40min | ~13min |
| 9 | 2 | - | - |
| 15 | 2 | - | - |
| 18 | 4 | - | - |

**Recent Trend:**

- Last plan: 02-03 — groen, single-attempt, WeatherRepository cache policy
- Trend: Geautomatiseerde executor verwerkt mechanische infra-taken goed

| Phase 03-riverpod-providers-state-graph P01 | 25 | 2 tasks | 8 files |
| Phase 03-riverpod-providers-state-graph P02 | 20 | 1 task | 5 files |
| Phase 03-riverpod-providers-state-graph P03 | 35 | 2 tasks | 6 files |
| Phase 03-riverpod-providers-state-graph P04 | 15 | 2 tasks | 2 files |
| Phase 06 P02 | 3min | 2 tasks | 1 files |
| Phase 06 P04 | 8 | 2 tasks | 2 files |
| Phase 08-background-refresh-notifications P03 | 8 | 1 tasks | 1 files |
| Phase 08-background-refresh-notifications P04 | 5min | 2 tasks | 2 files |
| Phase 09-google-calendar-integration P01 | 20min | 2 tasks | 4 files |
| Phase 09-google-calendar-integration P02 | 10min | 2 tasks | 4 files |
| Phase 16 P01 | ~2h | 2 tasks | 13 files |
| Phase 16 P02 | 25min | 2 tasks | 12 files |
| Phase 16 P03 | ~10min | 2 tasks | 6 files |
| Phase 21 P02 | 23min | 3 tasks | 4 files |

## Accumulated Context

### Decisions

Beslissingen zijn gelogd in PROJECT.md Key Decisions tabel.
Recente beslissingen die het huidige werk beinvloeden:

- Roadmap geherstructureerd 2026-06-02: originele Phase 1 (skeleton + scoring) gesplitst in Phase 1 (skeleton only) + Phase 1.5 (scoring domain).
- Flutter test vereist (niet dart test) voor tests die AppDatabase importeren — drift_flutter trekt dart:ui mee; NativeDatabase.memory() direct doorgeven als QueryExecutor (DatabaseConnection wrapper niet nodig in Drift 2.x).
- Plan 02-03: mockito ^5.6.4 (niet ^5.7.0 — analyzer-versieconflict met drift_dev 2.33.0).
- Phase 3 planning (2026-06-02): riverpod_generator ^2.6.5 + riverpod_annotation ^4.0.2 + flutter_riverpod ^3.3.1 toegevoegd; shared_preferences ^2.5.5 voor ProfileNotifier en AvailabilityNotifier.
- Riverpod 3.0 patroon: gebruik @riverpod annotatie (code-gen), AutoDisposeNotifier is nu gewoon Notifier (auto-dispose is default), StateProvider/StateNotifierProvider zijn legacy — niet gebruiken.
- SlotsEmptyReason sealed enum gekozen voor SLOT-05 expliciete empty state (badWeather | allBlocked).
- AvailabilityNotifier: SharedPreferences-aanpak als fallback als Drift-tabel ontbreekt (te controleren in 03-03).
- 03-01 (2026-06-02): riverpod_generator ^4.0.4-dev.1 vereist (plan: ^2.6.5) — 2.x reeks incompatibel met riverpod_annotation 4.0.2.
- 03-01 (2026-06-02): Riverpod 3.x gegenereerde provider-naam voor WeatherNotifier is weatherProvider (Notifier-suffix gestript door code-gen).
- 03-01 (2026-06-02): Riverpod 3.x error-staat is AsyncLoading(hasError: true) door auto-retry — test checkt state.hasError ipv isA<AsyncError>().
- 03-01 (2026-06-02): Ref-parameter in Riverpod 3.x provider-functies is plain Ref (niet typed XxxRef).
- 03-02 (2026-06-03): UserProfile als plain Dart class met _sentinel-pattern voor nullable copyWith — geen Freezed benodigd voor scalar settings dataklasse.
- 03-02 (2026-06-03): profileProvider is de gegenereerde naam voor ProfileNotifier (Notifier-suffix gestript door Riverpod 3.x code-gen).
- 03-03 (2026-06-03): AvailabilityNotifier gebruikt SharedPreferences — AvailabilityGridEntries tabel slaat dayOfWeek+hour weekpatroon op, niet DateTime-instanties.
- 03-03 (2026-06-03): availabilityProvider en slotsProvider zijn de gegenereerde namen (Notifier-suffix gestript door code-gen).
- 03-03 (2026-06-03): Fake notifiers in ProviderContainer-tests moeten concrete klassen extenden (WeatherNotifier), niet de _$-abstracte klassen.
- 03-03 (2026-06-03): SlotsNotifier als synchrone Notifier<SlotsState> — build() gebruikt ref.watch() synchroon; geen AsyncNotifier nodig.
- 03-04 (2026-06-03): FakeNotifier-subclasses (extends WeatherNotifier) gekozen boven mockito voor integratietests — simpeler, state direct injecteerbaar via .state = AsyncData(...).
- 03-04 (2026-06-03): ProviderScope op buitenste runApp-niveau — gereed voor ConsumerWidget gebruik in Phase 4.
- 04-01 (2026-06-03): BlockType enum in availability_notifier.dart (niet apart bestand) — eenvoudiger voor Phase 4; refactor in Phase 6 indien nodig.
- 04-01 (2026-06-03): domain→providers import richting in availability_filter.dart geaccepteerd per PATTERNS.md notitie (tijdelijk, Phase 6 refactor).
- 04-01 (2026-06-03): try-catch around SharedPreferences deserialization voor T-04-01: corrupt entries worden overgeslagen (log + skip).
- 04-02 (2026-06-03): go_router resolved to 17.3.0 (plan specified ^17.2.3 — semver compatible, accepted).
- 04-02 (2026-06-03): buildPreset assert enforces weekStart.weekday == DateTime.monday; test date fixed from DateTime(2026,6,9) [Tuesday] to DateTime(2026,6,8) [Monday].
- 04-02 (2026-06-03): Stub screen classes (_WelcomeScreenStub etc.) in router.dart allow file to compile before Wave 3 creates real screens; replace in 04-03.
- 04-03 (2026-06-03): _PresetOption plain Dart class chosen over Dart 3 records — simpler, named fields, avoids positional access syntax.
- 04-03 (2026-06-03): Dashed border for custom preset via _DashedBorderPainter CustomPainter — Flutter Border API does not support BorderStyle.dashed.
- 04-03 (2026-06-03): _HomeScreenPlaceholder retained in router.dart; Wave 4 (04-04) replaces with real HomeScreen import.
- 04-04 (2026-06-03): Weather chip values are placeholder "?°C / ?mm / ?km/u" — HourlyForecast data not directly accessible from RideSlot; Phase 5 will wire real data.
- 04-04 (2026-06-03): HomeScreen uses SingleTickerProviderStateMixin for skeleton pulse AnimationController — no shimmer package needed.
- 04-04 (2026-06-03): Day selection uses year+month+day triple comparison to avoid cross-month false matches.
- 04-05 (2026-06-03): tester.pump(Duration) used instead of pumpAndSettle in HomeScreen tests — AnimationController.repeat() causes pumpAndSettle to timeout.
- 04-05 (2026-06-03): FakeStaticSlotsNotifier omits ref.watch calls to bypass upstream provider initialization in widget tests.
- 04-05 (2026-06-03): HomeScreen._buildHeader Container color+decoration bug fixed — Container cannot have both color and decoration properties simultaneously.
- 05-01 (2026-06-03): HourlyRow is plain Dart class (no Freezed) — Phase-5-only view model merging HourlyScore + HourlyForecast by time.
- 05-01 (2026-06-03): DetailArgs uses const constructor — immutable DTO safe for go_router extra.
- 05-01 (2026-06-03): T-05-01 mitigated: router uses 'is! DetailArgs' guard before cast, returns error Scaffold for invalid navigation.
- 05-01 (2026-06-03): Weather chips show avg temp (1 decimal), total precip (1 decimal), avg wind (0 decimal); '—' when no data.
- 05-01 (2026-06-03): Forecast filtering uses !f.time.isBefore(slot.start) && f.time.isBefore(slot.end) per SLOT-02 [start, end) convention.
- 05-02 (2026-06-03): ScoreBadge widget embedded in score-banner alongside tier emoji + description text (key_links requirement in plan).
- 05-02 (2026-06-03): Inline tier switch expressions for banner colors/emoji/description — no separate helper class needed.
- 05-02 (2026-06-03): Empty-slot guard returns '—' for all avg fields when forecasts list is empty (T-05-02-02 mitigated).
- 05-03 (2026-06-03): SingleChildScrollView wraps InsightsSheet Column to prevent RenderFlex overflow in constrained viewports (bottom sheet height varies by device/test).
- 05-03 (2026-06-03): _avg() returns 50.0 for empty hours list — divide-by-zero prevented per T-05-03-01.
- 05-03 (2026-06-03): LinearProgressIndicator value uses .clamp(0.0, 1.0) as defense-in-depth per T-05-03-02.
- 05-04 (2026-06-03): Existing test files from Waves 2+3 already covered plan requirements; only the SC-4 ScoringEngine fixture pin was missing — added 1 targeted test to insights_sheet_test.dart.
- 05-04 (2026-06-03): ScoringEngine fixture pin uses closeTo(1.0, 0.0001) for double comparison safety; calls ScoringEngine().score() directly (no mocks) to prove domain-widget wiring.
- 06-01 (2026-06-03): AsyncValue.value (not .valueOrNull) is the correct nullable getter in Riverpod 3.x — valueOrNull does not exist in the 3.x API.
- 06-01 (2026-06-03): ProfileScreen Wave 1 skeleton uses // ignore: unused_field on late double slider fields — Wave 2 will fill them; suppress avoids analyzer warnings.
- 06-01 (2026-06-03): darkTheme uses same seedColor 0xFF2E7D32 with brightness: Brightness.dark; MaterialApp.router now has darkTheme + themeMode: ref.watch(themeModeProvider).
- 06-02 (2026-06-03): Explicit FilterChip widgets (3 separate) over for-loop — grep -c verification requires 3 text occurrences of FilterChip in source.
- 06-02 (2026-06-03): WeatherTolerances import not needed in ProfileScreen — copyWith() accessible via profile.tolerances instance (generated by Freezed on the class).
- 06-02 (2026-06-03): Trailing comma required after updateTolerances(tolerances.copyWith(...),) by require_trailing_commas lint rule.
- 06-03 (2026-06-03): GestureDetector count is 169 (not 168) — BackButton and horizontal SingleChildScrollView each add a GestureDetector; test uses findsAtLeastNWidgets(168).
- 06-03 (2026-06-03): SharedPreferences mock resolves synchronously in Flutter tests — AvailabilityNotifier never stays AsyncLoading; loading-state CircularProgressIndicator test is unreliable.
- [Phase ?]: 06-04: skipOffstage: false required for cell-color container search in scrollable availability grid
- [Phase ?]: 06-04: Tap-guard test uses hour 0 cell (visible in viewport) instead of hour 9 (off-screen) for reliable tester.tap() interaction
- 07-01 (2026-06-03): geolocator 14.0.2 + permission_handler 12.0.3 added; compileSdk = 35 override in build.gradle.kts (D-07-11)
- 07-01 (2026-06-03): kNlCities const list with 12 NL cities in lib/core/nl_cities.dart (D-07-05)
- 07-01 (2026-06-03): Used // comment (not ///) for nl_cities.dart header to avoid dangling_library_doc_comments lint info
- 07-02 (2026-06-03): GpsPermissionNotifier as AsyncNotifier<LocationPermission> with gpsPermissionProvider generated name (D-07-03)
- 07-02 (2026-06-03): LocationNotifier replaces stub — three-step priority: profile override > GPS > Amsterdam default (LOC-02, LOC-04, LOC-05)
- 07-02 (2026-06-03): HomeScreen updated to handle AsyncValue<LocationData> via .value?.city — locationProvider changed from sync to async (Rule 3 fix)
- 07-03 (2026-06-03): .value (niet .valueOrNull) is correcte nullable getter in Riverpod 3.x; bevestigt STATE.md 06-01 beslissing
- 07-03 (2026-06-03): skipOffstage: false vereist in ProfileScreen widget tests — LOCATIE sectie zorgt dat RIJLENGTE/THEMA buiten test-viewport rolt in scrollbare ListView
- 07-03 (2026-06-03): FakeLocationNotifier extends LocationNotifier toegevoegd aan weather_notifier_test — WeatherNotifier watchet locationProvider; ProviderContainer tests vereisen override
- 07-03 (2026-06-03): anyNamed() matcher in mockito voor named parameters na getForecast({lat, lon}) signature uitbreiding
- 07-04 (2026-06-03): HomeScreen dynamische locatienaam reeds geimplementeerd in Wave 2 als Rule 3 auto-fix — locationAsync.value?.city ?? kDefaultCity
- 07-04 (2026-06-03): kDefaultCity ('Amsterdam') als fallback tijdens AsyncLoading — consistenter dan literal '...' uit plan specificatie
- 07-05 (2026-06-03): FakeWeatherNotifier lokaal gedefinieerd in profile_screen_location_test — ProfileScreen vereist weatherProvider override om te bouwen
- 07-05 (2026-06-03): HomeScreen Test 2 verifieert 'Amsterdam' (kDefaultCity) i.p.v. '...' — conform implementatie beslissing 07-04
- 07-05 (2026-06-03): Completer<void>().future voor permanente AsyncLoading simulatie — betrouwbaarder dan Future.delayed
- 08-01 (2026-06-03): workmanager ^0.9.0+3 + flutter_local_notifications ^21.0.0 + timezone ^0.11.0 + flutter_timezone ^5.1.0 toegevoegd aan pubspec.yaml; flutter pub get geslaagd
- 08-01 (2026-06-03): AndroidManifest.xml: RECEIVE_BOOT_COMPLETED + SCHEDULE_EXACT_ALARM + POST_NOTIFICATIONS + FOREGROUND_SERVICE + WAKE_LOCK permissies; WorkManager SystemForegroundService + RescheduleOnBootReceiver; ride_alerts notificatiekanaal meta-data
- 08-01 (2026-06-03): SCHEDULE_EXACT_ALARM gedeclareerd — Android 12+ vereist expliciete gebruikerstoestemming via systeeminstellingen (T-08-01-02)
- 08-02 (2026-06-03): FlutterTimezone 5.1.0 retourneert TimezoneInfo object (niet String) — gebruik .identifier property voor tz.getLocation()
- 08-02 (2026-06-03): isInDebugMode parameter deprecated in workmanager 0.9.x — verwijderd; Workmanager().initialize(callbackDispatcher) volstaat
- 08-02 (2026-06-03): AppDatabase in WorkManager isolate geinitialiseerd met driftDatabase(name: 'ridewindow') — zelfde naam als foreground DB; Drift WAL-modus handelt gelijktijdige toegang af (T-08-02-02)
- 08-02 (2026-06-03): NetworkType.connected constraint in registerPeriodicTask — voorkomt zinloze network-retries (T-08-02-01 mitigatie)
- [Phase ?]: UI toggle placement
- [Phase ?]: Lifecycle observer teardown
- 10-01 (2026-06-05): applicationId = ridewindow.joost.amsterdam (PERMANENT — cannot change after first Play Console upload; user confirmed via Task 2 checkpoint)
- 10-01 (2026-06-05): Upload keystore at ~/upload-keystore.jks (outside project dir — never at risk of git commit); backed up to password manager
- 10-01 (2026-06-05): key.properties gitignored via android/.gitignore (pre-existing Android gitignore) — real passwords set, no PLACEHOLDER values
- 10-01 (2026-06-05): versionCode uses flutter.versionCode (derived from pubspec.yaml +1 build number) — pubspec.yaml is single source of truth for versioning
- 10-02 (2026-06-05): compileSdk bumped 35→36 — required by url_launcher_android, shared_preferences_android, flutter_local_notifications, geolocator_android, google_sign_in_android, package_info_plus; backward compatible with targetSdk/minSdk
- 10-02 (2026-06-05): isCoreLibraryDesugaringEnabled = true + desugar_jdk_libs:2.1.5 added — flutter_local_notifications v21+ requires core library desugaring
- 10-02 (2026-06-05): Android cmdline-tools/latest installed to ~/Library/Android/sdk — required for Flutter 3.44.1 post-build symbol stripping; not bundled with Android Studio on this machine
- [Phase 16-01]: Recomputed the logo crop bbox via pixel scan instead of the plan's literal coordinates (not tight/symmetric, baked a white halo into maskable/splash composites); added flood-fill alpha for clean colored-canvas compositing; nudged crop origin (+36,+36)px so the 32x32 favicon's center pixel lands on solid black rather than the monogram crossbar stroke
- [Phase 16-02]: isStandaloneDisplayMode/isIosBrowserMode gate on isWebPlatform BEFORE their own debug overrides (isWebPlatform && (override ?? impl())) so a false web override always wins
- [Phase 16-02]: AddToHomeScreenOverlay uses colorScheme.inverseSurface/onInverseSurface MD3 tonal pair, top-positioned, no dismiss/persistence per D-04
- [Phase 16-03]: SafeBackButton uses plain Navigator.of(context).canPop() (never go_router's context.canPop() extension) so it builds identically with or without a GoRouter ancestor -- required by existing MaterialApp(home: child)-only widget test harnesses
- [Phase 16-03]: Non-poppable tooltip uses a null-safe Localizations.of<S>(context, S) lookup (not S.of(context)!) falling back to a plain 'Home' literal -- avoids throwing in localization-delegate-less test harnesses
- [Phase 16-03]: Confirmed via git-stash before/after comparison that test/features/availability_screen_test.dart (11 failures) and test/features/detail/ride_detail_screen_calendar_test.dart (4 failures) are pre-existing, unrelated to this plan (BACKLOG.md #11 test-suite health issue) -- identical failure counts before/after
- 17-01 (2026-07-17): Corrected full automated-test baseline established (supersedes the partial 16-03 note): `flutter test` on current HEAD consistently reports 215 passing / 69 failing across 13 files -- `ride_detail_screen_test.dart` (13), `insights_sheet_test.dart` (13), `availability_screen_test.dart` (11-12), `profile_screen_test.dart` (5), `profile_screen_notif_test.dart` (5), `weather_repository_test.dart` (3-5), `home_screen_test.dart` (4), `detail/ride_detail_screen_calendar_test.dart` (4), `onboarding_screen_test.dart` (3), `welcome_screen_test.dart` (2), `home_screen_location_test.dart` (2), `providers/integration_test.dart` (1), plus one of `core/pwa_display_mode_test.dart`/`providers/slots_notifier_test.dart` (1) -- the 215/69 totals are stable across repeated runs on this machine but the exact per-file split shifts slightly run-to-run (test-binding/localization state leakage between files, tracked in BACKLOG.md #11). No Phase 17 source changes were made, so this variance is confirmed pre-existing, not a regression.
- 17-01 (2026-07-17): Phase 17 production deploy completed -- `flutter build web --release` + `firebase deploy --only hosting` succeeded; live at https://my-project-joost.web.app. All 4 curl checks passed on the first attempt (/, /profile, /detail/test123 all HTTP 200; /sqlite3.wasm HTTP 200 with `content-type: application/wasm`) -- firebase.json required no changes. `flutter build apk --release` also exits 0 on this same HEAD.
- Roadmap 2026-07-25: v3.0 (Accounts & Sociaal) scoped to phases 1–2 of `.planning/milestones/v3.0-ACCOUNTS.md` only. Phases 18–22 created: 18 Preconditions, 19 Auth, 20 Repository refactor (local-only), 21 Sync + migration, 22 Account-backed feedback. AUTH-09 (account deletion removing server data) deliberately mapped to Phase 21, not Phase 19, since no Firestore data exists to delete until Phase 21 wires cloud writes. REG-01/02/04 mapped to Phase 19 (firebase_core/firebase_auth added there); REG-03 mapped to Phase 21 (full Firebase payload, pairs with SYNC-07's 2s budget); REG-05 mapped to Phase 20 (the phase that touches background_task.dart).
- [Phase 21]: 21-02: Supabase default privileges for 'authenticated' on newly created tables exclude DML (only REFERENCES/TRIGGER/TRUNCATE) — RLS policies alone are insufficient; explicit GRANT statements are required and are now part of 0001_accounts_sync.sql. — Found live: signed-in client rejected with 42501 permission denied before any RLS policy ran. Fixed via grant select/insert/update/delete to authenticated on profiles/availability/planned_rides, insert-only on feedback.
- [Phase 21]: 21-02: rls_deny_test.sql rewritten to return a visible result table instead of relying on raise notice — the Supabase SQL Editor does not display NOTICE output, so a passing and a silently-skipped run were indistinguishable. — Also added the positive case (owner can select own row), which a missing-grants defect would have passed silently while the deny-case-only assertions still held.

### Pending Todos

- **Trim GSD config voor Phase 1.5 planning** — zet research, plan_check, verifier, etc. uit in .planning/config.json. Besproken met gebruiker; uitgesteld.
- **GitHub remote setup** — push project naar private GitHub-repo voor tweede computer. Uitgesteld.

### Blockers/Concerns

- Phase 9 (Google Calendar): Vereist Google Cloud project setup, OAuth consent screen, en SHA-1 fingerprint registratie. Flag dit bij afsluiting Phase 8.
- Phase 8 (Notifications): Must test on Samsung/Xiaomi physical devices for WorkManager OEM reliability.
- Phase 10 (Release): Plans 01-03 complete. Smoke test passed. Plan 10-04 BLOCKED — Google Play developer account identity verification pending (submitted 2026-06-05, may take a few days). Once verified: complete store listing, Data Safety form, content rating, upload AAB, publish Internal testing track.
- Phase 3 notitie (opgelost 03-03): AvailabilityNotifier gebruikt SharedPreferences — de Drift AvailabilityGridEntries tabel slaat een weekpatroon op (dayOfWeek+hour), niet DateTime-instanties. SharedPreferences met ISO-8601 serialisatie is de juiste aanpak.
- Phase 18 (Preconditions) — the privacy policy rewrite is legal work with real lead time; per research it should start immediately and run in parallel with Phase 19–21 code, not block them, but it must be live before the accounts release ships.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Tooling | Android Studio + Android SDK + accepted licenses | Resolved — Phase 10 Plan 01 | 2026-06-05 |
| Verification | Package legitimacy audit (manual pub.dev check) | Skipped (covered by CLAUDE.md) | 2026-06-02 (Plan 01-01 Task 2) |
| Infra | GitHub remote + private repo | Pending | 2026-06-02 |

## Quick Tasks Completed

| ID | Slug | Description | Date | Commit |
|----|------|-------------|------|--------|
| 260605-wv8 | ux-ui-polish-8-super-app-inspired-improv | UX/UI polish: 8 super-app inspired improvements (Plan het fix, pull-to-refresh, Hero animation, haptic feedback, beste keuze highlight, animated weather icons, swipe-to-calendar, share function) | 2026-06-05 | ca6f0f8 |
| 260617-qjd | android-home-screen-widget-toont-volgend | Android home screen widget — toont volgende ride slot op een oogopslag | 2026-06-17 | 2691d59 |
| 260618-csx | week-agenda-view-met-ride-overlap-overla | Week-agenda view met ride-overlap overlay en 10 dagen vooruit scrollen | 2026-06-18 | af16b02 |
| 260714-m63 | add-sun-partly-cloudy-icon-to-ride-detai | Sun/partly-cloudy/rain-cloud icon cue on Ride Detail Hourly precip label | 2026-07-14 | c5967b9 |
| 260714-n0c | add-feedback-feature-backlog-33-send-fee | Backlog #33: "Send feedback" dialog (1-5 star rating + comment) on Profile screen, submitted via mailto: URI using existing url_launcher dependency | 2026-07-14 | 5f00127 |
| 260714-nfk | add-backlog-36-google-calendar-connectio | Backlog #36: Google Calendar connection visibility — CalendarService.isCalendarConnected()/disconnectCalendar(), Profile screen status row (Connected/Not connected + Disconnect), EN/NL l10n, TDD widget test | 2026-07-14 | 98f1f3b |
| 260714-o54 | bundle-backlog-34-sticky-plan-ride-butto | Backlog #34: sticky "Plan ride" button via Scaffold.bottomNavigationBar on Ride Detail. Backlog #35: live "N losse tijdvakken geselecteerd" drag-run indicator on Availability, backed by pure countSelectionRuns() helper, 7 unit tests, EN/NL l10n | 2026-07-14 | 1703d60 |
| 260714-qor | ride-detail-plan-ride-knop-toont-planned | Backlog #34 vervolg: Ride Detail's "Plan ride" button reactively shows "Planned" + checkmark (muted OutlinedButton) when the effective slot is already in plannedRidesProvider | 2026-07-14 | a109aa2 |
| 260714-r8u | herstijl-screenhintoverlay-dot-indicator | Restyle ScreenHintOverlay: dot-indicator row + filled pill CTA replaced with compact MD3 "N/M" counter + TextButton, inspired by a shared React/shadcn layout reference (Flutter-native, no React introduced) | 2026-07-14 | 862c80a |
| 260714-rrx | unplan-delete-geplande-rit-vanaf-ride-de | Unplan/delete a planned ride from Ride Detail's "Planned" button and a new delete icon on Home's planned-rides row, both gated behind a shared confirm dialog; reverses qor's earlier display-only scope choice per explicit user request | 2026-07-14 | 5ce3e6e |
| 260714-rne | availability-grid-twee-tik-bereik-select | Availability grid: two-tap range-select model (open/fill/close/cancel/cross-day) alongside existing drag gesture, long-press cell-info bottom sheet, day-scoped live counter extension — TDD, 8 unit/widget tests, went through 2 plan-check revision rounds | 2026-07-14 | e5a3683 |
| 260714-spo | agenda-tab-vervang-long-press-sleep-sele | Agenda tab: replaced long-press-drag range-select with two-tap fixed-anchor model (grow/shrink/cancel/cross-day-restart), long-press repurposed to always show weather-detail sheet — full gesture parity with Availability screen. New baseline test suite (7 tests), went through 2 plan-check revision rounds | 2026-07-15 | 52495b9 |
| 260717-no1 | backlog-31-google-oauth-consent-screen-p | Backlog #31: fast-publish route chosen for the OAuth consent screen (Google Calendar scope is Sensitive, not Restricted — no formal verification required). Produced OAUTH-PUBLISH-CHECKLIST.md for Joost to follow manually in Cloud Console; BACKLOG.md #31 marked "Ready for user action" (not Done — the Cloud Console click itself requires Joost's own authenticated session) | 2026-07-17 | 2595362 |
| 260726-ka2 | web-shell-gelijktrekken-met-de-merkkleur | PWA-shell op de merkkleuren gezet vóór de deploy: `web/index.html` + `web/manifest.json` van `#2E7D32` naar `#C5D4B6` (background) / `#234934` (theme), en de 5 iOS-splash-PNG's opnieuw gegenereerd op het nieuwe merk. Grondoorzaak was niet de kleur maar dat `tools/make_icons.py` alleen iconen genereerde — de splash was op 17 juli handwerk en liep daarna stilzwijgend achter toen `792eb44` de iconen verving; splash-generatie zit nu in hetzelfde script (`SPLASH_SIZES` + `centred_rect()`). `pwa_install_meta_test.dart` asserteerde letterlijk op `#2E7D32` en is herschreven naar de echte invariant: index.html en manifest.json moeten het onderling eens zijn. Sweep-bevindingen: `ic_launcher_background.xml` stond al goed, score-kleuren in `app_colors.dart` bewust ongemoeid, `docs/feature-graphic.html` nog open (vergt her-upload naar de Store) | 2026-07-26 | e31a1e1 |
| 260718-f1m | backlog-9-accessibility-audit-screenread | Backlog #9: accessibility audit — added Semantics/tooltips to 9 icon-only controls + the Availability and Agenda grid cells (previously 0 Semantics widgets in the app), raised touch targets to 48dp (Availability cells/headers, Agenda rows converted to scrollable fixed-height layout, Profile info button, Onboarding back button), fixed WCAG AA contrast on acceptableFg and textHint (light+dark) in app_colors.dart. Research/plan/execute run autonomously; plan had to be manually completed after the planner agent's connection dropped mid-write, and the execution worktree was accidentally forked from a stale base — required manual merge-conflict resolution in availability_screen_test.dart. flutter test confirmed 282/2 post-merge (matches #11's baseline, no regression) | 2026-07-19 | 277f763 |
| 260725-knl | availability-key-mismatch | Beschikbaarheids-pipeline gerepareerd — canonieke uur-sleutel + migratie, weekpatroon-model, seedPreset merget, dedup symmetrisch, now-cutoff, stabiele sortering (audit A1/A2/A4/B2/B3/B4/B5/C1/C2/C3). Tests 282/2 → 306/0 (suite voor het eerst volledig groen) | 2026-07-25 | 82c9438 |
| 260804-vb1 | bump-version-1-0-13-14 | Versie gebumpt naar 1.0.13+14 en release-AAB herbouwd (+13 was al gebruikt door de fase-19-build van 2026-07-26) | 2026-08-04 | 169b1d6 |
| 260804-gi3 | gitignore-assistant-memory-en-videos | `.claude/projects/` (Claude-geheugen) en `photos/*.mp4` (~15 MB bronvideo) gegitignored — publieke repo, blijven anders permanent in de historie; `.claude/skills/material-3/` en de logo-PNG wel gecommit | 2026-08-04 | bd2cf78 |
| 260807-gpz | fase-21-doc-afronding | Fase-21-docs bijgewerkt na drie antwoorden van Joost: SYNC-11 (multi-tab) en SYNC-04 (webkant) afgetekend als PASS op echte waarnemingen, mijn eerdere bugvermoeden uit de web-diagnose expliciet ingetrokken (de telefoon had nooit een voorgrond-overgang gemaakt — meetopstelling, niet code), en §3 herschreven naar Android-WebAPK met de iOS-PWA uitgesteld naar v2 op grond van de Android-only-constraint. MORGEN.md terug van zeven naar zes toestelstappen | 2026-08-07 | ca91cb8 |
| 260901-nz7 | fix-backlog-61-startup-reconcile-voor-ee | Backlog #61: er was geen pad dat bij het opstarten uit de cloud las — `reconcileOnForeground()` had één aanroeper (`didChangeAppLifecycleState` op `resumed`) en die vuurt niet bij het starten, dus een verse installatie met een geldige sessie toonde een lege PLANNED-lijst tot de app eenmaal was weggezet. Nieuw `reconcileOnStartup()`, fire-and-forget vanuit `HomeScreen.initState`, one-shot per account per app-start. De sweep vond een tweede gat langs dezelfde vorm: `onSignIn()` dekt alleen profile+availability, dus een verse ínlog haalde zijn ritten evenmin op — `_runAccountSync()` sluit nu af met `reconcileOnForeground()` in plaats van een kale `drainOutbox()`. Onderweg gemeten en het bepaalde het ontwerp: een StreamProvider zonder listener abonneert zich nooit, dus `authStateProvider.value` is null bij `initState`; opgelost met een terugval op de herstelde sessie. Suite 451/451, analyze op baseline 162 (0 errors). **Niet op toestel geverifieerd** — zie SUMMARY | 2026-09-01 | 36f4fca, abcf557 |
| 260901-q01 | documenteer-stap-1b-tegenproef-backlog-6 | Stap 1b uitgevoerd en vastgelegd: backlog #61 tegengeproefd op het toestel, **PASS aan beide kanten**. De fix bleek twee helften te hebben en die zijn apart geproefd — de inlogflow (`account_section.dart:328`) via site-data wissen + verse inlog, en de koude start (`reconcileOnStartup`) via een rit die alleen in de cloud stond. Negatieve controle die de proef pas betekenis geeft: de native app 1.0.21+22 (vóór de fix) staat op hetzelfde toestel, ingelogd met dezelfde sessie en dezelfde cloud, en toonde bij koude start géén PLANNED — pas na één achtergrond→voorgrond-cyclus verscheen de rit. Twee correcties op MORGEN.md: de wisinstructie was fout voor een WebAPK (opslag zit in Chrome's profiel voor het origin, niet in het launcher-pakket), en de precondition ontbrak (nul geplande ritten). Nevenwaarneming, niet gefixt: een rit plannen enqueuet wel maar duwt niet — de outbox loopt alleen leeg bij app-start, voorgrond-overgang of inloggen. Geen codewijziging | 2026-09-01 | 4172bc4 |
| 260901-r92 | app-version-constante-liep-achter-op-pub | `ee1a081` bumpte `pubspec.yaml` naar 1.0.23+24 maar liet `lib/core/app_version.dart` op 1.0.22 (23) staan. De AAB en de live PWA dragen daardoor een manifest dat 1.0.23 zegt en een profielscherm dat 1.0.22 toont. Het echte punt zit in hoe het gevonden is: `test/core/app_version_test.dart` bewaakt precies deze invariant en stond dus rood, maar MORGEN.md en STATE.md noteerden de suite als "441/1 -- die ene is de bekende notificatietest". Dat was hij niet; de notificatietest slaagde. Eén bekende flaky test maakt elke nieuwe rode onzichtbaar zodra je "1 gefaald" leest in plaats van *welke*. Constante bijgewerkt, AAB opnieuw gebouwd (de oude droeg de foute waarde), en geverifieerd op twee niveaus: `versionName=1.0.23` in het packaged manifest én de string `1.0.23 (24)` letterlijk in de gecompileerde Dart. Suite nu **451/451**, analyze op baseline 162. Openstaand: de live PWA draait nog de oude constante tot deze commit gepusht wordt | 2026-09-01 | 926667c |
| 260807-nm1 | app-naam-gelijktrekken | De app heette op drie plekken anders: `android:label` en `web/index.html` stonden op `ridewindow`, `web/manifest.json` op `RideWindow` — zichtbaar geworden doordat de §3-PWA naast de native app op het beginscherm kwam te staan. Alle gebruikerszichtbare bronnen op `RideWindow` gezet (`pubspec.yaml`'s package-naam bewust ongemoeid). `test/web/app_display_name_test.dart` legt de invariant vast als "de bronnen zijn het onderling eens" in plaats van een letterlijke waarde — de les van quick-260726-ka2 — en is negatief geverifieerd. AAB opnieuw gebouwd; die van 12:26 droeg de oude naam. Suite 445/445, analyze op baseline 162 | 2026-08-07 | (zie commit) |

## Session Continuity

Last session: 2026-09-02T06:10:00.000Z
Last activity: 2026-09-02 - Fase 21 vrijwel dicht. Stap 1b: backlog #61 tegengeproefd op het toestel, **PASS aan beide helften** (inlogflow én koude start), met een negatieve controle op de pre-fix build 1.0.21+22 die de bug live reproduceerde. §6 (AUTH-09) uitgevoerd op de PWA: app-kant PASS inclusief D-03 op drie schermen, en de Supabase-kant geverifieerd via twee leesqueries (nul weesrijen, account weg uit `auth.users`). De `feedback`-controle is **vervallen, niet gehaald** — die tabel is leeg, dus `on delete set null` is alleen door het schema gedekt. Onderweg gevonden en gefixt: `lib/core/app_version.dart` liep achter op `pubspec.yaml` (quick 260901-r92) — de rode test die dat aanwees was maandenlang afgedaan als "de bekende flaky notificatietest". Suite nu **451/451**. Alles staat op **1.0.23+24**: main gepusht, PWA live geverifieerd in de bundel, toestel bijgewerkt via `adb install -r` (data behouden), en Play internal testing uitgerold op 2026-09-02 08:00. `21-08-SUMMARY.md` geschreven (compleet), `21-09-SUMMARY.md` geschreven (**incomplete**).

**Enige openstaande stap voor fase 21:** de app één keer via Play installeren op het toestel. Vereist eerst deïnstalleren (sideload vs. Play-signing) en wist daarmee lokale data + de Calendar-OAuth-grant. Let daarna specifiek op inloggen en Google Calendar — zie `.planning/phases/21-sync-migration/MORGEN.md` stap 3. Blijft daarnaast staan: fase 19's ontbrekende koude-start-basislijn (plan 19-07), waardoor REG-03 geen vóór/ná-vergelijking heeft.
Vorige sessie: 2026-08-07 - Fase 21 webkant afgerond: SYNC-11 en SYNC-04 afgetekend op echte waarnemingen, §3 herschreven naar Android-WebAPK (iOS naar v2), MORGEN.md opgeschoond. Fase 21 wacht nu enkel nog op vijf toestelstappen — zie `.planning/phases/21-sync-migration/MORGEN.md`. Daarna 21-08/21-09-SUMMARY en de fase-verificatie.

## Operator Next Steps

- Review the v3.0 roadmap draft (`.planning/ROADMAP.md`, Phases 18–22) and confirm scope/phase split before planning begins.
- Once approved: `/gsd:plan-phase 18`
