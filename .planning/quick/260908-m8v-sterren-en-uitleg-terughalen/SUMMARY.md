---
quick_id: 260908-m8v
slug: sterren-en-uitleg-terughalen
date: 2026-09-08
status: complete
---

# Sterren, een doel onder de vouw, en uitleg die terugkomt

Drie punten van Joost op 2026-09-08, na 1.0.26 op zijn toestel.

## 1. De sterren gingen niet aan

```dart
icon: Icon(selected ? AppIcons.star : AppIcons.star)
```

Beide takken hetzelfde icoon. Bij de Phosphor-migratie (fase 24) zijn
`Icons.star` en `Icons.star_border` allebei op `AppIcons.star` uitgekomen,
waardoor het enige verschil tussen aan en uit nog de kleur was.

`Phosphor-Fill.ttf` draagt dezelfde codepunten als `Phosphor.ttf` — dat is met
de hand uit de cmap-tabel van beide fonts gelezen, niet aangenomen. Er is dus
alleen een `AppIconsFill.star` bij gekomen.

De test hierop vergelijkt `fontFamily`, want dát is het enige verschil tussen
gevuld en omlijnd. Geen screenshot-vergelijking op kleur zou dit opmerken.

## 2. De uitleg over de rijvensters wees naar iets onder de vouw

De hint op Home wees naar een ritkaart die half buiten beeld hing: de uitsnede
viel weg en de tekstkaart kwam er bovenop. Je las uitleg over iets wat je niet
zag.

De tekst verplaatsen lost dat niet op — het **doel** moet in beeld. De overlay
roept nu `Scrollable.ensureVisible` met `alignment: 0.25` vóór de spotlight
valt, en meet daarna opnieuw. Dat is wat driver.js ook doet, en het helpt elke
hint, niet alleen deze.

**Grens, en die staat in de code.** Dit werkt alleen als het doel al gebouwd
is. In een lui opgebouwde lijst bestaat een doel ver naar beneden nog niet, en
dan gebeurt er niets in plaats van iets verkeerds. Voor de zes hints die de app
vandaag heeft is dat geen beperking. De eerste testopzet gebruikte een
`ListView` en viel precies in dat gat — de test is aangepast naar
`SingleChildScrollView`, wat de situatie op Home is, en de grens is
opgeschreven in plaats van weggepoetst.

## 3. Uitleg terughalen: op het scherm, plus één plek in Over

Joost verwachtte op elke pagina een `i`'tje. Terecht: **drie** schermen hebben
uitleg — Home, Agenda en Mijn ritten — maar alleen Agenda had de knop. Op de
andere twee zag je hem één keer en daarna nooit meer.

Zijn tweede idee was Profiel → Over. Dat is voor de schermgebonden uitleg de
verkeerde plek: die *wijst* naar dingen. "Tik op een dag bovenaan" betekent
alleen iets terwijl je naar die dagstrip kijkt met een spotlight erop. In Over
wordt het proza of screenshots — een tweede artefact dat je apart onderhoudt en
dat vanzelf uit de pas gaat lopen.

Maar Over vult wél een gat: de **rondleiding van vier schermen** bij eerste
start gaat niet over één scherm maar over waar alles zit, en die had nergens
een terugweg. Die staat er nu, als eerste regel onder Over.

De scheiding is dus: schermgebonden uitleg op het scherm, app-brede rondleiding
in Over. Niet hetzelfde ding op twee plekken.

Meegenomen: de tooltip van het Agenda-knopje was `hintDragSelect` — de titel
van één specifieke hint, als label voor een knop die ze allemaal opent. Nu
`showTips`, in beide talen.

## Verificatie

- `test/features/feedback_dialog_test.dart` — zes tests, waaronder de nieuwe
  die de gevulde ster vasthoudt.
- `test/features/screen_hint_overlay_test.dart` — negen tests, waaronder dat
  een doel onder de vouw in beeld wordt gescrold en boven de schermhelft
  uitkomt.
- Volledige suite: 522 groen.
- De 58 analyzer-meldingen in de aangeraakte schermen stonden er al: geteld
  vóór en ná de wijziging, beide keren 58.
