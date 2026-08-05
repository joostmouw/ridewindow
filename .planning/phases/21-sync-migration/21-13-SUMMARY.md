# 21-13 — SUMMARY

**Status:** code klaar, toestelverificatie open (§5b van `REGRESSION-CHECKLIST-21.md`)
**Commits:** `721929b` (plan), `336d2b8` (implementatie)
**Suite:** 440 geslaagd / 1 gefaald — die ene is de gedocumenteerde tijdsafhankelijke
`notification_service_test.dart`-bug (faalt elke run na 19:00 UTC), geen regressie.
`flutter analyze`: 0 errors / 0 warnings, 162 `info`s — exact de baseline van vóór dit plan.
REG-05-structuurtest groen.

## Wat kapot was

Eén tik op "Schedule" leverde twee identieke kaarten in "My Rides" (toestelsessie 4,
2026-08-05). `rideId` werd afgeleid uit `start.toIso8601String()`, en die string verschilt voor
een lokale en een UTC-`DateTime` die hetzelfde tijdstip aanduiden. Alles wat door de
`timestamptz`-kolom `start_at` gaat komt als UTC terug, dus de cloud-kopie kreeg een andere
sleutel dan de lokale en de union-merge hield ze allebei.

De testuitvoer van taak 1 zegt het in twee regels:

```
Expected: '2026-08-08T12-00-00-000'
  Actual: '2026-08-08T10-00-00-000Z'
```

## Wat er onderweg bij bleek te zitten

Er stapelden **twee** fouten op elkaar, en alleen de eerste was gezocht.

`toRow()` schreef een **offsetloze** string. Postgres leest die in de sessiezone — bij Supabase
UTC — dus een rit van 12:00 lokaal werd opgeslagen als 12:00 **UTC**: hetzelfde klokgetal, een
tijdstip dat twee uur verschoven is. De rijen die nu in `public.planned_rides` staan dragen dus
niet alleen een verkeerde sleutel maar ook een verkeerd tijdstip.

Dat veranderde taak 3 wezenlijk. Een reparatie die de cloud-rij als bron neemt, herstelt de
verschuiving niet — die zou de rit op 14:00 lokaal zetten. De lokale lijst is de enige plek waar
de bedoelde tijd nog klopt, dus die is de bron geworden en de cloud-rij wordt weggegooid en
opnieuw gepusht.

## Wat er gewijzigd is

**Identiteit canoniek (taak 2).** `rideId` uit `start.toUtc()`. `toRow()` schrijft expliciet
UTC. `fromRow()` en `fromJson()` zetten terug naar lokaal — dat laatste is geen cosmetiek: zonder
die omzetting zijn de kopieën geen duplicaat meer maar liggen ze de lokale offset uit elkaar, wat
een subtielere fout is dan de fout die we oplosten.

**Instant-vergelijking.** `add()` en `remove()` gebruiken `isAtSameMomentAs` in plaats van `==`.
Dart's `DateTime.==` is alleen waar als óók `isUtc` gelijk is; daardoor ontsnapten beide kopieën
aan `add()`'s eigen duplicaatguard. Precies de regel die
`lib/domain/services/availability_key.dart:8` al vastlegt voor de beschikbaarheidsrooster-sleutel
en die nooit is doorgetrokken naar planned rides.

**Opruimen in twee helften (taak 3).**
- `readLocal()` klapt kopieën met dezelfde UTC-instant samen, eerste wint. Een bestaand toestel
  toont daarmee direct één kaart, zonder migratiestap en zonder netwerk.
- De foreground-reconcile verwijdert cloud-rijen waarvan de opgeslagen `ride_id` niet gelijk is
  aan de canonieke sleutel uit hun eigen `start_at`, en laat ze uit de merge weg, zodat de lokale
  kopie als `localOnly` opnieuw gepusht wordt — nu met de juiste sleutel én het juiste tijdstip.

**Convergentie:** één foreground-cyclus met netwerk. De delete gaat rechtstreeks, de her-upsert
loopt via de bestaande outbox en wordt in dezelfde cyclus gedraineerd. Een toestel zonder
verbinding klapt zijn lokale duplicaat meteen samen (dat is puur lokaal) en repareert de cloud bij
de eerstvolgende verbonden foreground.

**Fout die ik onderweg maakte en heb hersteld:** de eerste versie verwijderde de cloud-rij maar
liet hem in `cloudRows` staan. De merge zag de rit dan als "staat al in de cloud", pushte niets
terug, en de rit was weg. Nu geeft de reparatie de te gebruiken rijen terug; mislukt een delete,
dan blijft de rij in de merge zitten, want hij bestaat nog.

## Waarom de suite groen was

`test/domain/models/planned_ride_row_test.dart:37` test `fromRow(toRow(userId))` en slaagt: de
round-trip sluit **binnen Dart**, waar de string offsetloos blijft en `DateTime.parse` weer een
lokale `DateTime` oplevert. Postgres is wat hem breekt.
`test/services/cloud_reconcile_service_test.dart:84` had het spiegelbeeld: de `ride()`-helper
bouwde lokale én cloud-kant met dezelfde offsetloze string, dus de splitsing kón zich daar niet
voordoen.

Beide zijn nu aangevuld met tests die bij de **wire-vorm** beginnen: een string met `+00:00`,
zoals PostgREST hem echt teruggeeft. De nieuwe tests controleren bovendien hun eigen voorwaarde —
op een UTC-machine falen ze luid in plaats van betekenisloos te slagen.

Twee bestaande assertions legden de oude representatie vast (`rideId` als lokale ISO-string, en
`toRow`'s offsetloze velden) en zijn herzien, met een notitie erbij zodat niemand ze "herstelt".

## De les, nu vier keer

| Plan | De test controleerde | Wat er misging |
|------|----------------------|----------------|
| 21-10 | of de aanroep bestond | hij bereikte zijn werk niet |
| 21-11 | of hij zijn werk bereikte | de payload was geen legale rij |
| 21-12 | of de payload een legale rij was | de sleutel overleefde de database niet |
| 21-13 | of de sleutel de database overleeft | — |

Elke keer stopte de test één laag vóór de grens die brak. Deze keer was die grens de rand van
Dart: alles wat de code over zichzelf kon bewijzen klopte, en wat Postgres met de waarde deed viel
buiten beeld.

De diepere bevinding is niet de bug maar waar de regel stond. `availability_key.dart` legt in
proza uit dat `DateTime.==` ook `isUtc` vergelijkt. Zo'n invariant in het commentaar van één
bestand beschermt precies één bestand. Overweeg een gedeelde helper of een test die over álle
gesleutelde domeinobjecten loopt — vandaag zijn dat er twee, en ze hebben allebei dezelfde bug
gehad.

## Nog open

Toestelverificatie, §5b van `REGRESSION-CHECKLIST-21.md`. Let daar op één ding: de duplicaten zijn
echte data, lokaal én in de database. Beoordeel de fix op convergentie na een foreground-cyclus,
niet op het eerste scherm na installatie.
