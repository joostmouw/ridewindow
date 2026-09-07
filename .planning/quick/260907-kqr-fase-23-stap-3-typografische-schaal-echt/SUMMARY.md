---
task_id: 260907-kqr
slug: fase-23-stap-3-typografische-schaal-echt
date: 2026-09-07
milestone: v4.0
phase: 23
status: complete
---

# Stap 3 afgerond

Op de Oppo geverifieerd: de beste kaart draagt "Saturday" op 24 met de score op
45, de kaart eronder "Monday" op 16 met de score op 28. Het verschil is
onmiddellijk zichtbaar en dat was de hele bedoeling — de kaart wijst zichzelf
nu aan door maat, niet door schaduw of een gekleurde staaf.

498 tests groen, `flutter analyze` zonder fouten of waarschuwingen.

## Waarom `ScoreEmphasis` een enum werd en geen `bool isBest`

`ScoreDisplay` staat in `features/shared/` en weet niets van ritkaarten. Een
`isBest` zou daar een begrip uit Home naar binnen trekken; `hero`/`normal` zegt
wat de widget doet — groot of gewoon — en laat de vraag wie de beste is bij de
aanroeper. Dat is ook wat het bruikbaar houdt als er ooit een tweede plek is
waar één ding uit een lijst mag opvallen.

## Wat níét is gedaan, en waarom

Punt 1 van de schets liet nog een marge liggen: `lightTextTertiary` en
`lightTextHint` hebben op papier ruim twee punten contrast over en "mogen weer
lichter". Dat is bewust blijven liggen. De hiërarchie komt nu uit maat, en dat
werkt — tekst óók lichter maken kost leesbaarheid voor iets wat al opgelost is.
Als het later alsnog moet: eerst 11–12 punt op de Oppo bekijken, want de meting
uit backlog #9 is op Roboto gedaan en Outfit oogt lichter.

## Consistentie

Rides (`planned_rides_screen.dart`) is bewust ongewijzigd: daar staat elke
regel op `titleMedium` met een `ScoreBadge`, en dat klopt — het zijn ritten die
je al hebt ingepland, er is geen eerste plek om aan te wijzen.

## Fase 23 na deze stap

Nog open: **stap 5** — dagstrip en periodefilter rustiger (de dagchips verliezen
hun gekleurde achtergrond, de kwaliteit van een dag wordt een 3px onderstreping
in de tierkleur). En het kleine restje: Peloton-kaarten missen hun haarlijn.
