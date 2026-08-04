# 21-12 — Samenvatting: de outbox stopt met stil falen

**Status:** code klaar en geverifieerd op de machine. Toestelverificatie staat nog open (dat is
per definitie de volgende sessie — dit plan bouwt juist het gereedschap dáárvoor).

## Wat er gebouwd is

**1. `SyncOutboxService` logt nu per mislukte rij.** De `catch` deed alleen
`markFailed(row.id, e.toString())`; die foutstring landde in Drifts `lastError`-kolom en werd
nergens gelezen. Er staat nu één regel per mislukking:

```
SyncOutbox: send failed for profile/uid1 (operation=upsert, attempt 1): Exception: network down
```

Het loggen gaat via een injecteerbare `log`-seam (`SyncOutboxService(dao, log: ...)`, standaard
`debugPrint`), zodat de test op echte uitvoer kan asserten in plaats van stdout te schrapen. De
bestaande constructor-aanroepen blijven werken.

**2. Elke drain sluit af met een samenvatting.** `SyncOutbox: drain done — 2 pending, 1 sent, 1
failed`. Ook bij een lege outbox (`0 pending, 0 sent, 0 failed`) — juist die regel maakt
onderscheid tussen "er was niets te doen" en "de drain heeft nooit gedraaid". Dat verschil is
in deze fase twee keer verkeerd gelezen.

**3. De twee stille wegwerp-paden praten nu.** In `CloudSyncReconciler.drainOutbox` keerden
`upsertFn` (onbekende entity) en `deleteFn` (niet-`planned_ride`, of `entityKey` zonder `:`)
gewoon terug — waarna de aanroeper `markSent()` doet en **de rij verwijdert**. Een onbekende rij
werd dus zonder een spoor weggegooid. Het weggooien blijft bewust staan (een rij die nooit
verzonden kan worden mag de outbox niet eeuwig blokkeren, en de teller moet nul kunnen halen),
maar er gaat nu een `debugPrint` aan vooraf.

**4. `lastError` is leesbaar op het toestel zelf.** Nieuw item in het verborgen debugmenu:
"Sync-outbox bekijken" toont elke openstaande rij met entity, key, aantal pogingen en de laatste
fout, plus een "Outbox wissen"-actie. Geen adb, geen laptop nodig. `SyncOutboxDao.clearAll()`
is daarvoor toegevoegd en wordt door geen enkel productiepad aangeroepen.

## Waarom dit precies zo is afgebakend

Geen retry-beleid, geen dead-letter-tabel, geen pogingenlimiet. Dat zijn echte beslissingen over
dataverlies en die horen in een eigen plan, nádat we weten wat de fout zegt. Dit plan haalt
alleen de blinddoek af.

## Verificatie

- `flutter analyze`: 0 errors (163 pre-existing infos, ongewijzigd t.o.v. de basislijn).
- `flutter test`: **426/426 groen**, inclusief drie nieuwe tests die falen zodra het loggen weer
  verdwijnt: één op de faalregel (entity, key, `attempt 1`, foutstring én overeenstemming met de
  opgeslagen `lastError`), één op de samenvattingsregel bij een lege outbox, één op de
  sent/failed-telling.
- `flutter build apk --release`: exit 0, 68.3 MB.
  Kanttekening: dit vereiste het tijdelijk kopiëren van `android/key.properties` naar de
  worktree — dat bestand is gitignored en staat dus alleen in de hoofd-checkout. Het is na de
  build meteen weer verwijderd en is nooit getrackt geweest. Zonder dat bestand faalt élke
  release-build in élke worktree met `null cannot be cast to non-null type kotlin.String` op
  `build.gradle.kts:29` — een worktree-artefact, geen codefout.
- ARB-sleutelpariteit: **387/387** NL/EN (was 380/380; zeven nieuwe sleutels in beide talen),
  alle zeven aanwezig in de drie gegenereerde bestanden.

## Wat de volgende toestelsessie hiermee doet

1. Open het debugmenu → "Sync-outbox bekijken". Staat er niets in terwijl de statustekst
   "Syncing..." toont, dan is het een UI-/streamprobleem, geen sendprobleem.
2. Staan er rijen in: lees `lastError`. Dat is het antwoord waar deze fase al twee rondes op
   wacht.
3. Wis daarna de outbox. Blijft de teller op 0 en syncen nieuwe wijzigingen wél, dan was de
   hypothese "oude vergiftigde rijen van vanochtend" juist. Klimt hij meteen terug, dan faalt de
   drain nog volledig — en dan staat de reden nu in `lastError`.

Stap 1 uit STATE.md (`profiles.notif_evening_before` in het Supabase-dashboard controleren) is
hiermee niet vervangen, maar wel minder kritisch: de foutmelding op het toestel zegt
waarschijnlijk al genoeg.
