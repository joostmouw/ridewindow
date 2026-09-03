---
quick_id: 260903-bey
slug: backlog-57-adoptie-van-een-cloud-rij-enq
date: 2026-09-03
status: complete
backlog_item: 57
commits:
  - 1ac8f3f
files:
  modified:
    - lib/data/repositories/profile_repository.dart
    - lib/data/repositories/availability_repository.dart
    - lib/providers/cloud_sync_reconciler_provider.dart
    - lib/services/account_sync_service.dart
    - test/providers/cloud_sync_reconciler_gateway_test.dart
    - test/data/repositories/profile_repository_test.dart
---

# Backlog #57 — opgelost, en het was een lus

**Klaar.** Suite **462/462** (was 459, +3), `flutter analyze` onveranderd op 169 issues / 0 errors.

## Het item had de oorzaak mis, en dat is het interessante deel

Het backlog-item vermoedde `enqueueCurrentState()` "op het sign-in/reconcile-pad dat ook bij een
bestaande sessie draait". Dat is niet zo: die methode hangt uitsluitend aan
`SyncDecision.pushLocalToCloud` en draait alleen bij het inloggen.

De werkelijke oorzaak voedt zichzelf:

1. Koude start → de reconcile ziet de cloud-rij meer dan de noop-band van 5 seconden nieuwer en
   neemt hem over met `save(stamp: false)`.
2. `save()` enqueuede **onvoorwaardelijk** — ook deze schrijving. Dát is het defect: de
   `stamp`-vlag dekte de tijdstempel wel en de enqueue niet.
3. `stampUpdatedAt()` zet lokaal op het *oude* cloudtijdstip.
4. De drain duwt de rij omhoog; de trigger `profiles_set_updated_at` (`before update`, migratie
   `0001_accounts_sync.sql`) zet `updated_at = now()`.
5. Volgende koude start: de cloud is nieuwer met het hele verstreken tijdsverschil → terug naar 1.

## Waarom dit meer was dan ruis

`updated_at` is de invoer waarop `resolveAccountSync()` beslist wie wint bij een divergentie. Een
kolom die bij elke app-start opschuift meet niet meer "wanneer wijzigde de gebruiker dit", en dat
raakt de conflictafhandeling zelf — niet alleen de logregels en het dataverkeer.

## De fix

`ProfileRepository.save()` en `AvailabilityRepository.save()` krijgen een eigen `enqueue`-vlag
(default `true`). De vier plekken die een cloud-rij overnemen geven `enqueue: false`: profiel en
beschikbaarheid in de reconciler, en beide `pullCloudToLocal`-takken in `AccountSyncService`. De
`pushLocalToCloud`-tak leunt niet op `save()`'s enqueue — die roept `enqueueCurrentState()` zelf
aan — dus er gaat geen push verloren.

**Bewust een eigen vlag en niet afgeleid van `stamp`.** Kort zou het zijn, maar
`ProfileNotifier.setUserNameFromSignIn()` schrijft met `stamp: false` én moet de cloud wél
bereiken. Twee vlaggen die meestal samenvallen samentrekken is precies hoe dit is ontstaan. Er
staat nu een test op die specifiek die samentrekking blokkeert, met de reden erbij.

## Dat dit nu een test is en geen toestelsessie, is de opbrengst van #60

De reconciler-test kon dit gisteren nog niet meten. Twee dingen die de test eerlijk houden:

- Hij toetst **eerst dat er werkelijk geadopteerd is** (de naam uit de cloud-rij staat lokaal).
  Zonder die controle zou een reconcile die helemaal niets doet ook "outbox leeg" opleveren en
  groen blijven om de verkeerde reden.
- Hij is **aantoonbaar load-bearing**: met `enqueue: false` weggehaald faalt hij, daarna
  teruggezet. Gemeten, niet aangenomen.

## Wat dit verklaart uit device session 10

Op de verse Play-installatie logde élke voorgrondcyclus `0 pending, 0 sent`, terwijl sessie 5 juist
`1 sent (availability)` per cyclus gaf. Dat leek tegenstrijdig en staat als open vraag in
`REGRESSION-CHECKLIST-21.md`. Het past nu precies: na de eerste-login-migratie lagen lokaal en
cloud binnen de noop-band, dus er werd niets overgenomen en dus niets ge-enqueued. De lus start pas
na één echte adoptie. Dat is ook waarom dit met een tellertje niet te vinden was.

## Buiten scope gebleven

De noop-band van 5 seconden, en de vraag of `updated_at` beter client-side gezet kan worden dan
door een `before update`-trigger. Dat laatste is de diepere ontwerpvraag hieronder — de trigger
maakt elke schrijving, ook een echo, tot "een wijziging". Voor nu is de echo weg; de vraag blijft.
