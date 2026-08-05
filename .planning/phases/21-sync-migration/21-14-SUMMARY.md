# 21-14 — SUMMARY

**Status:** code klaar, toestelverificatie open (§5c van `REGRESSION-CHECKLIST-21.md`)
**Suite:** 441 geslaagd / 1 gefaald — de bekende tijdsafhankelijke `notification_service_test.dart`
(faalt na 19:00 UTC), geen regressie. `flutter analyze`: 0 errors / 0 warnings, 162 `info`s =
baseline. Build **1.0.21+22**.

## Wat kapot was

Handmatig verwijderde ritten kwamen bij elke sync terug (toestel, 2026-08-05).
`reconcileOnForeground()` las de cloud vóórdat het de outbox leegde:

```
await _reconcileProfile(...)        // pull
await _reconcileAvailability(...)   // pull
await _reconcilePlannedRides(...)   // pull + union-merge, schrijft lokaal
...
await drainOutbox();                // push -- pas hier vertrekt de delete
```

De lus: `remove()` haalt de rit lokaal weg en zet een `delete` in de outbox. De volgende voorgrond
leest de cloud, waar de rij nog staat omdat de delete nog niet verstuurd is, en de union-merge zet
de rit lokaal terug. Daarna vertrekt de delete en verdwijnt de cloud-rij — maar lokaal staat hij
alweer, dus de cyclus daarna meldt hem als `localOnly` en pusht hem opnieuw omhoog.

`mergePlannedRides` is een union en kan een verwijdering structureel niet uitdrukken; dat staat in
zijn eigen commentaar. Dat is een verdedigbaar ontwerp **mits lokale intentie eerst wordt
weggeschreven**. Dat gebeurde niet.

**Reikwijdte is breder dan deletes.** Elke lokale wijziging die in de outbox wacht, kon door een
eerder uitgevoerde pull worden overschreven. Bij deletes is het effect totaal, daarom viel het
daar op.

## Wat er gewijzigd is

`drainOutbox()` staat nu ook vóór de drie reconcile-aanroepen. De bestaande aanroep aan het eind
blijft: de merge enqueuet upserts voor ritten die alleen lokaal bestaan, en zonder die tweede drain
wachten die een hele cyclus. `drain()` heeft sinds 21-10 een re-entrancy-guard en een lege wachtrij
is een gelogde no-op, dus twee aanroepen zijn goedkoop.

Push-vóór-pull is de standaardvolgorde voor een outbox, en precies om deze reden: de wachtrij
bevat de *intentie* van de gebruiker, de cloud de laatst *overeengekomen* stand. Overeengekomen
stand lezen vóór je intentie indient, gooit die intentie weg.

## Waarom vier eerdere plannen dit niet vonden

21-10 t/m 21-13 repareerden allemaal de drain zelf: dat hij werd aangeroepen, dat hij zijn werk
bereikte, dat zijn payload een legale rij was, dat zijn sleutel Postgres overleefde. Alle vier
vroegen *"werkt de push?"*. Geen enkele vroeg *"gebeurt de push op het juiste moment ten opzichte
van de pull?"* — en dat kón ook geen enkele component-test zien, want beide componenten zijn
afzonderlijk correct. De fout zat uitsluitend in hun onderlinge volgorde.

## De zwakte van de nieuwe test, expliciet

De toegevoegde test in `outbox_drain_wiring_test.dart` is een **bronvolgorde-assertie**. Hij
bewijst dat de aanroep op de juiste plaats geschreven staat, niet dat de push tijdens runtime
vóór de pull afrondt. Geverifieerd dat hij faalt zodra de leidende `drainOutbox()` weg is, en
weer slaagt als hij terugkomt.

Dat het niet gedragsmatig kan, is zelf de bevinding. `CloudSyncReconciler` grijpt rechtstreeks
naar `Supabase.instance.client` binnen de methodebody, dus de volgorde van zijn netwerkaanroepen
is van buitenaf onwaarneembaar zonder levende backend. **Dit is nu vijf keer achter elkaar de
beperkende factor geweest.** Die afhankelijkheden injecteerbaar maken is de structurele remedie —
bewust buiten de scope van dit plan gehouden, maar het is de enige wijziging die dit patroon
doorbreekt in plaats van er nog een pleister op plakt.

## Eigen fout, onderweg gecorrigeerd

De versiebump naar 1.0.20+21 raakte `pubspec.yaml` maar niet `lib/core/app_version.dart`. De
suite ving dat meteen — `app_version_test.dart` bestaat precies daarvoor, toegevoegd in de
21-12-samenvoeging. Rechtgezet en doorgebumpt naar 1.0.21+22 zodat naam en buildnummer weer
kloppen.

## Nog open

- **Toestelverificatie §5c:** verwijder een rit, drie keer achtergrond/voorgrond, hij mag niet
  terugkomen — en moet weg zijn uit `planned_rides`.
- **De spookritten van 21-13 staan er nog.** Die hebben een intern consistente rij (sleutel klopt
  bij hun eigen `start_at`) met een verschoven tijdstip, dus 21-13's herstelroutine ziet ze niet
  als kapot. Ze zijn nu wél handmatig te verwijderen, want met 21-14 blijft een delete staan. Dat
  is de aangewezen route; een heuristiek die "14:00" van een echte rit onderscheidt bestaat niet.
