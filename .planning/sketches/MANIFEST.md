# Sketch Manifest

Schetsen voor milestone **v4.0 "Eigen gezicht"**. Startpunt van de epic:
`.planning/EIGEN-GEZICHT.md`.

## Design Direction

RideWindow heeft zijn merkkleuren en zijn huisletter (Outfit) al binnen; wat ontbreekt is
**durven contrasteren**. De app is nu één groentint waarin achtergrond, dagstrip, periodefilter en
ritkaarten allemaal even zwaar wegen, waardoor het oog nergens naartoe wordt getrokken en de
kernwaarde van het product — de score en het beste venster — visueel gelijkstaat aan een filterchip.
De richting is daarom niet "meer Material 3 naleven" maar: geef het scherm een duidelijke eerste,
tweede en derde plek, en maak de weergegevens leesbaar in plaats van decoratief.

## Reference Points

- De eigen app-icoon: RW-monogram in één ononderbroken monoline, ronde uiteinden, geen scherpe hoek.
- De werkwijze die zich in dit project bewees: kandidaten als HTML naast elkaar renderen met de
  échte merkkleuren en de échte inhoud, screenshotten, en binnen een minuut kiezen. Zo is Outfit
  gekozen (`750189f`).

## Werkwijze

Alle schetsen zijn losse HTML zonder bouwstap. Ze linken naar `themes/default.css`, waarin de
tokens uit `lib/theme/app_colors.dart` en `lib/theme/app_typography.dart` één op één zijn
overgenomen, en ze laden `assets/fonts/Outfit.ttf` rechtstreeks uit de repo. Een schets die hier
goed oogt is daarom haalbaar in Dart met tokens die al bestaan.

```bash
python3 -m http.server 8765     # vanuit de repo-root, anders laadt het lettertype niet
```

## Sketches

| # | Naam | Design Question | Winnaar | Tags |
|---|------|-----------------|---------|------|
| 001 | [home-hierarchie](001-home-hierarchie/) | Waar komt de hiërarchie op Home vandaan — uit een dominante held, uit een neutraal papier, of uit het weer zelf? | — | home, hierarchie, typografie, weerbalken, fase-23 |
