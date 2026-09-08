---
sketch: 006
name: hele-set-per-familie
question: "Hoe ziet de volledige icooninventaris van RideWindow eruit in elke kandidaat-familie?"
winner: "Phosphor — gewicht nog te kiezen"
tags: [iconografie, fase-24, mapping, keuze]
---

# Sketch 006: De hele set, in zeven handen

> **Gekozen: Phosphor** (Joost, 2026-09-08). Het gewicht staat nog open — regular, bold of duotone
> staan als drie aparte knoppen vooraan. Zie *De correctie op Phosphor* hieronder: de eerste telling
> van 77/83 was mijn fout, niet die van de set.

## Waarom deze schets bestaat

Schets 004 liet per familie **vier** signatuur-iconen zien. Joost koos Hugeicons, en toen de
volledige set er lag (schets 005) viel die tegen. Dat is geen wispelturigheid maar een fout in mijn
opzet: **vier iconen zeggen te weinig over een familie.** Wat je wil weten is of 83 iconen eruitzien
alsof dezelfde persoon ze tekende, en dat zie je pas als ze er alle 83 staan.

Deze schets toont daarom de **volledige inventaris van de app** — 12 emoji-plekken plus 71
Material-iconen — met één knop om van familie te wisselen. Schets 005 is hierin opgegaan.

## Dekking

Alle 83 plekken, per familie machinaal opgezocht in de officiële naamlijsten:

| Familie | Gedekt | Mist |
|---|---|---|
| **Phosphor** (3 gewichten) | **83/83** | — |
| **Tabler** | **83/83** | — |
| **Hugeicons** | **83/83** | — |
| **Lucide** | 82/83 | swipe |
| Mynaui | 78/83 | tune, hourglass, touch, swipe, kracht |
| Solar | 75/83 | fiets, berg, agenda-kruis, swipe |
| Iconoir | 73/83 | cloud-off, groups, berg, zonsopgang |

De vertaaltabel is per familie opgebouwd uit synoniemen, want elke set noemt dingen anders — "check"
heet bij Hugeicons `tick`, bij Solar `check-circle`, bij Tabler gewoon `check`. Waar niets gevonden
is staat een **rood vak**: dat begrip moet dan bijgetekend worden in dezelfde hand.

## How to View

```bash
python3 -m http.server 8765     # vanuit de repo-root
open http://localhost:8765/.planning/sketches/006-hele-set-per-familie/index.html
```

Zeven familieknoppen bovenin, plus **maat** (24 / 13 / 20 px), **lijndikte** (2 / 2,5 / 1,5) en
**donker**. De lijndikte en de uiteinden worden voor álle families gelijkgetrokken — anders vergelijk
je gewichten in plaats van handschriften.

## De correctie op Phosphor

De eerste telling gaf Phosphor 77/83 en dat was **onjuist**. De vertaaltabel werkte met algemene
synoniemen, en Phosphor gebruikt eigen taal:

| Begrip | Wat ik zocht | Hoe Phosphor het noemt |
|---|---|---|
| block | ban, block, forbid | `prohibit` |
| refresh | refresh, reload, rotate | `arrows-clockwise` |
| restart | restart | `arrow-counter-clockwise` |
| open in new | external-link | `arrow-square-out` |
| link off | unlink, link-off | `link-break` |
| error | alert-circle | `warning-circle` |

Met een mapping in zijn eigen vocabulaire dekt Phosphor **alle 83**. Dit is een les over de methode:
een dekkingsgetal zegt evenveel over de zoekwoorden als over de set. Bij de andere families kan
hetzelfde spelen — hun gaten zijn niet met dezelfde zorg nagelopen, dus lees die cijfers als
ondergrens.

## Het gewicht is nu de vraag

Phosphor heeft zes gewichten; drie staan hier als knop. Het RW-monogram is een **dikke stiftlijn**,
en Phosphor *regular* is dunner dan dat.

- **Regular** — elegant, maar op 13 px in de weerbalken kan hij wegvallen naast de tekst ernaast.
- **Bold** — dichter bij het monogram; let op of hij op 13 px niet dichtslibt.
- **Duotone** — zelfde tekening met een tweede vlak op 20% dekking. Geeft diepte zonder tweede kleur,
  maar voegt wel een nieuwe visuele laag toe aan een app die net rust heeft gekregen in fase 23.

Vergelijk ze vooral op **13 px** en **op donker** — daar wijken ze het meest af.

## What to Look For

1. **Samenhang boven schoonheid.** Springt er één icoon uit de rij qua gewicht of detailniveau? Dat
   is wat bij Hugeicons opviel zodra de hele set er lag: karaktervol per stuk, ongelijk als groep.
2. **De acht rider-types als serie** — berg, zonsopgang, zonsondergang, zon, kracht, fiets, geen
   tijd, renner. Die staan in de app onder elkaar op één scherm.
3. **13 px.** De maat in de weerbalken en de harde ondergrens. Een set die daar uit elkaar valt, valt
   af, hoe goed hij op 24 px ook oogt.
4. **De rode vakken** zijn de echte kosten van een familie.

## Wat er verder nog uit kwam

**Eén ontwerpgat geldt voor élke familie, niet voor één.** Material gebruikt gevuld-versus-omlijnd
(`home` naast `home_outlined`, `directions_bike` naast `directions_bike_outlined`) om de geselecteerde
tab in de navigatiebalk aan te wijzen. Geen van de zeven lijnfamilies heeft die tweedeling: beide
worden hetzelfde icoon. De navigatiebalk moet selectie dus anders tonen — kleur, gewicht of een
indicator. Dat is een beslissing, geen vertaling, en hij komt terug ongeacht wat er gekozen wordt.

## Ná de keuze

Met een pub-pakket houdt de aanroep dezelfde vorm — `Icon(X.iets, size: 24)` — dus het is 71 regels
vervangen. De twaalf emoji-plekken zijn meer werk: daar staat nu een `Text` met een string die een
`Icon` moet worden, en in `availability_screen.dart` verandert een record-type van `String` naar
`IconData`.

**Verifiëren in een release-build op het toestel, niet in debug.** `--tree-shake-icons` snijdt een
glyph weg die alleen in een ternaire voorkomt; dat kostte in `9bf1e38` een onzichtbare knop. Bij 83
nieuwe iconen tegelijk is dat risico navenant groter.
