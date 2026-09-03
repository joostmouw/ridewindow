---
quick_id: 260903-b44
slug: backlog-60-cloudsyncreconciler-injecteer
date: 2026-09-03
status: complete
backlog_item: 60
commits:
  - 8c04df9
files:
  created:
    - lib/services/cloud_sync_gateway.dart
    - test/providers/cloud_sync_reconciler_gateway_test.dart
  modified:
    - lib/providers/cloud_sync_reconciler_provider.dart
    - test/providers/startup_reconcile_wiring_test.dart
---

# Backlog #60 — `CloudSyncReconciler` injecteerbaar gemaakt

**Klaar.** De cloudkant van de reconciler loopt nu door `CloudSyncGateway` en is vervangbaar.
Suite **459/459** (was 451, +8 nieuwe), `flutter analyze` **0 errors** — 169 issues tegen een
baseline van 170, dus geen nieuwe en netto één minder.

## Wat er is gebeurd

`lib/services/cloud_sync_gateway.dart` is nieuw: zes leden, elk precies één aanroep die de
reconciler al deed (`currentSessionUserId`, drie lezingen, `upsertRow`, `deletePlannedRide`), plus
`SupabaseCloudSyncGateway` met de bestaande calls ongewijzigd. `CloudSyncReconciler` krijgt een
optionele `gateway`-parameter met productie-default — hetzelfde patroon als
`RideDetailScreen.calendarServiceFactory`.

Geen mock van `SupabaseClient`: die klasse biedt een fluent query builder, en een fake daarvan
bouwen betekent dat je de builder namaakt in plaats van je eigen gedrag te toetsen.

## Wat er nu vastligt en eerder alleen op een toestel te zien was

`test/providers/cloud_sync_reconciler_gateway_test.dart`, 8 tests, met één gedeeld logboek voor
gateway én outbox zodat de *volgorde* tussen die twee toetsbaar is — twee losse tellers zouden elk
apart kloppen terwijl de bug juist in hun onderlinge volgorde zit.

| Wat | Waarom het ertoe doet |
|---|---|
| Duwen vóór trekken (21-14) | Anders wekt de union-merge een zojuist verwijderde rit weer op |
| Twee drains per cyclus (21-14) | De merge enqueuet zelf; zonder de tweede wacht dat een hele cyclus |
| Opstart-reconcile leest werkelijk (#61) | De oude test kon alleen zien *dát* er gedraind werd |
| Uitgelogd leest niet, draint wél | De drain staat bewust vóór de uitgelogd-check |
| 21-13's reparatie van niet-canonieke `ride_id`'s | **Op een toestel niet meer uit te lokken** |

Die laatste is de opbrengst die niet in de acceptatiecriteria stond: `_repairNonCanonicalRideIds`
staat in `REGRESSION-CHECKLIST-21.md` §5b als permanent open vinkje, omdat de rijen die het pad
uitlokken nergens meer bestaan. Via de poort kan het wél, inclusief de tegenproef dat een
canonieke rij met rust gelaten wordt — want een reparatie die te breed aanslaat verwijdert
geplande ritten uit de cloud.

## De volgordetest is aantoonbaar load-bearing

Niet aangenomen maar gemeten: de eerste `drainOutbox()` is tijdelijk onder de cloudlezing
geschoven, de pre-21-14-volgorde. De volgordetest faalde daarop (en twee andere mee), waarna de
sabotage is teruggedraaid. Een test die niet faalt als je de bug terugzet, bewaakt niets.

## Wat 21-11's les hier doet

De `Supabase.instance`-lookup is in de gateway een **getter per aanroep**, geen veld en geen
constructor-argument. `Supabase.instance` gooit als Supabase niet geïnitialiseerd is — de normale
toestand in deze suite — en bij constructie zou die throw gebeuren vóór de code die je juist wilt
observeren. Precies zo bleef de disposed-`Ref`-bug van 21-11 een dag onzichtbaar: de lookup stond
bovenaan `drainOutbox()` en gooide vóór de regel die werkelijk stuk was. Dat staat als
waarschuwing in het bestand zelf, niet alleen hier.

## Afwijking van het plan

Eén, bewust: `startup_reconcile_wiring_test.dart` is **niet** vervangen maar bijgesteld. Zijn
header wees vooruit naar dit item en die alinea was onwaar geworden. Hij blijft bestaan naast de
nieuwe test omdat hij iets anders bewaakt — de *bedrading* (bestaat het opstartpad, komt de aanroep
uit `initState`) via de echte provider zonder enige injectie, waar de nieuwe test het *gedrag*
bewaakt. Dat staat er nu expliciet bij, met de instructie hem niet weg te halen omdat de nieuwe
"meer" doet.

## Wat dit niet is

Geen gedragswijziging — de productiepaden doen aantoonbaar hetzelfde. Backlog **#57** (elke cyclus
schrijft profiel en beschikbaarheid opnieuw zonder wijziging) wordt hierdoor voor het eerst
*toetsbaar*, maar is niet opgelost. Dat is nu een kleine test in plaats van een toestelsessie.
