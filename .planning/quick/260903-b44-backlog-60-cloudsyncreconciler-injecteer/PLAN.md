---
quick_id: 260903-b44
slug: backlog-60-cloudsyncreconciler-injecteer
date: 2026-09-03
backlog_item: 60
---

# Backlog #60 — `CloudSyncReconciler` injecteerbaar maken

## Waarom dit item bestaat

Fase 21 had vijf gap-closure-plannen nodig (21-10 t/m 21-14) en élk defect werd op een toestel
gevonden, niet door de suite. De reden is steeds dezelfde: `CloudSyncReconciler` grijpt in zijn
eigen methodebody naar `Supabase.instance.client`, dus van buitenaf is niet waarneembaar wát hij
doet. `test/providers/startup_reconcile_wiring_test.dart` zegt dat zelf in zijn header — het kan
alleen bewijzen *dat* de methode gedraaid heeft (via de drain), niet wat de cloudkant deed. Dit
item is de ingreep die dat patroon doorbreekt, en het staat op HOOG omdat epic #62 (Peloton) zwaar
op dezelfde reconciler gaat leunen.

## Vorm — het bestaande patroon, niet een nieuw

Dit project heeft dit probleem al twee keer opgelost en beide keren op dezelfde manier:
`AccountSyncService` krijgt zijn cloudkant als closures (`readCloudProfile`, `migrateFn`, …) en
`RideDetailScreen` krijgt een optionele `calendarServiceFactory` / `notificationServiceFactory` met
een productie-default. Hier dus geen mock van `SupabaseClient` — die heeft een fluent query builder
en is precies daarom niet fake-baar — maar een smalle poort met exact de zes aanroepen die de
reconciler werkelijk doet.

## Taken

### Taak 1 — `CloudSyncGateway` introduceren

Nieuw bestand `lib/services/cloud_sync_gateway.dart`:

- `abstract class CloudSyncGateway` met zes leden, elk precies één bestaande aanroep:
  `currentSessionUserId()`, `readProfileRow`, `readAvailabilityRow`, `readPlannedRideRows`,
  `upsertRow(table, payload)`, `deletePlannedRide(userId, rideId)`.
- `class SupabaseCloudSyncGateway implements CloudSyncGateway` — de huidige aanroepen, ongewijzigd.

**Harde eis, uit plan 21-11:** de `Supabase.instance.client`-lookup moet *binnen* elke methode
blijven, niet in de constructor of een veld. `Supabase.instance` gooit als Supabase niet
geïnitialiseerd is — de normale toestand in deze suite — en een lookup bij constructie zou die
throw naar voren halen tot vóór de code die we juist willen observeren. Dat is letterlijk de bug
die 21-11 een dag heeft gekost.

### Taak 2 — de reconciler laten injecteren

`CloudSyncReconciler(this._ref, {CloudSyncGateway? gateway})` met
`_gateway = gateway ?? const SupabaseCloudSyncGateway()`. De vijf `Supabase.instance.client`-plekken
in `cloud_sync_reconciler_provider.dart` gaan door de poort. `_signedInUser()` behoudt zijn
volgorde: eerst `authStateProvider`, dan de poort als terugval. De `accountSyncService`-provider in
hetzelfde bestand blijft ongemoeid — die heeft zijn eigen closure-seam al.

### Taak 3 — de test die het gedrag vastlegt dat alleen een toestel zag

Nieuw `test/providers/cloud_sync_reconciler_gateway_test.dart` met één opnemende fake die álle
gebeurtenissen in één lijst schrijft, drain incluis, zodat volgorde toetsbaar is:

1. **Push vóór pull (21-14).** `reconcileOnForeground()` moet `drain` loggen vóór de eerste
   cloudlezing. Dit is de bug waardoor een verwijderde rit bij elke sync terugkwam.
2. **Twee drains per cyclus (21-14).** Eén vóór de reconcile, één erna voor wat de merge enqueuet.
3. **Opstart-reconcile (#61).** `reconcileOnStartup()` leest werkelijk uit de cloud, en doet dat
   één keer per uid per app-start.
4. **Uitgelogd doet niets.**
5. **De reparatie van niet-canonieke `ride_id`'s (21-13).** Dit pad is op een echt toestel niet
   meer uit te lokken — de rijen bestaan niet meer, wat in REGRESSION-CHECKLIST-21.md §5b als
   permanent open vinkje staat. Via de poort kan het nu wél: geef een rij met een verschoven
   sleutel terug en toets dat er een delete op volgt.

### Taak 4 — de caveat in de bestaande test intrekken

De header van `startup_reconcile_wiring_test.dart` beschrijft de beperking en wijst vooruit naar
dit item. Die alinea moet vervangen worden door wat er nu wél getest wordt, met een verwijzing naar
het nieuwe bestand — anders blijft een onwaar geworden waarschuwing achter, en dat is precies het
soort commentaar dat toekomstige lezers misleidt.

## Acceptatie

- `flutter test` groen (baseline 451/451).
- `flutter analyze` geen nieuwe errors of warnings (baseline 162 pre-existing infos).
- Geen enkele `Supabase.instance.client` meer in `CloudSyncReconciler`; de resterende in dit bestand
  zit in `accountSyncService`, die zijn eigen seam heeft.
- De nieuwe test faalt aantoonbaar als de push/pull-volgorde omgedraaid wordt.

## Buiten scope

Gedragswijzigingen. Dit is een testbaarheidsingreep: de productiepaden moeten aantoonbaar hetzelfde
blijven doen. #57 (elke cyclus schrijft zonder wijziging) wordt hierdoor pas *toetsbaar*, maar niet
in dit item opgelost.
