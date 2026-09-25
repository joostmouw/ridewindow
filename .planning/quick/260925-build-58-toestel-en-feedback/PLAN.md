---
quick_id: 260925-build-58-toestel-en-feedback
date: 2026-09-25
status: complete
---

# Build 58 op toestel, web en testerfeedback

## Doel

De bestaande #84-fix op de Oppo via Play verifiëren zonder een bestaande rit
te verwijderen, de PWA pas daarna gelijkzetten met internal, en de nieuwe
testerfeedback uit twee screenshots als afzonderlijke vervolgpunten bewaren.
De meldingen-werkboom moet de twee commits van #84 en de versiebump meekrijgen
voordat hij samengevoegd wordt.

## Stappen

1. Controleer de Play-versie en maak een rit van zaterdag 26 september
   08:00–10:00 in de groep met één lid. Zeg alleen die nieuwe rit via Home af;
   controleer dat de eigen planning weg is, de oude ritten blijven en de
   Play-installatie intact blijft.
2. Leg #84's toestelbewijs vast en maak drie backlogpunten: een groepsrit met
   iemand buiten de groep delen, eenmalig met een groep meerijden, en de
   dubbele/tekstzware deelnemersweergave. Noteer voor de eerste twee de
   rechten- en privacyvraag, niet alvast een onbewezen oplossing.
3. Deploy dezelfde 1.0.47+58-commit naar de PWA met de bestaande deployscript-
   hashcontrole; werk de release-stand bij.
4. Breng de #84-fix gecontroleerd over naar `meldingen`, behoud die
   werkbooms eigen commits, draai de relevante tests en noteer resultaat en
   eventuele open verificatie in SUMMARY.md. De gepubliceerde buildcode 58
   niet kopiëren naar een branch met extra, nog niet gepubliceerde features.

## Grenzen

- Geen bestaande ritten van Joost of andere deelnemers afzeggen.
- Geen sideload over een Play-installatie; geen promotie naar alpha.
- De screenshots bevatten gesprekken en namen: beschrijf alleen het
  productprobleem in de backlog, voeg de afbeeldingen niet aan git toe.
