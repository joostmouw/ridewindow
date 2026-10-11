# Schets 017 — tablet: compacte lijst naast het detail

**Vraag (Joost, 2026-10-11):** de tabletlijst toont te weinig vensters naast het paneel. Op een
liggende tablet passen er naast het detailpaneel maar drie à vier grote kaarten van ~170 px, en
die dragen knoppen (Inplannen, uitklappen) die het paneel rechts al heeft.

**Wat er op het canvas staat:** https://claude.ai/artifact/UAag5LBicLrK83HDQ5AqQm, artboard
"A · Liggend: compacte lijst + detail". Het plan van quick 261011-l5k beschrijft alleen artboard A;
welke andere artboards er naast stonden is hier niet vastgelegd, en de link is bij het archiveren
niet geopend. Er is geen HTML gekopieerd; het canvas is de bron.

**Gekozen: A** (Joost, 2026-10-11). Rijen van ~64 px zoals de berichtenlijst van Gmail op een
tablet: links een gevuld scorebolletje van 44 px in de tierkleur, dan dag + tijd op regel één en
een weerregel ("17° · droog · 9 km/u") op regel twee, rechts de duur. Geen knoppen in de rij. De
gekozen rij is tonaal gevuld (`surfaceContainerHighest`), zonder rand en zonder accentstreep. De
filterkop (dagstrip, dagdeelfilter, Vensters/Blokken + sortering) blijft vanaf expanded bovenaan
staan tijdens het scrollen, zoals de kop boven de berichtenlijst van Outlook.

**Keuzes bij de bouw:**

- **"Beste keuze" als tekstlabel rechtsonder**, op de plek van Gmails ster, en geen pil: een pil
  van 24 px breekt de rijhoogte van 64. Weglaten kan niet, want gesorteerd op tijd staat het
  beste venster niet bovenaan.
- **Geen veeg op expanded.** Een muis of trackpad kan niet vegen, en Inplannen staat in het paneel
  ernaast. Op de telefoon blijft de veeg.
- **Tekstkleur per vulling via `onScoreFill`:** wit of zwart, wat het hoogste contrast haalt.
  Wit op het teal van "Goed" (#26A69A) haalt maar 2,9:1; met de keuze per vulling halen alle acht
  (licht + donker × vier tiers) minstens 4,5:1.
- **De blokweergave is ongewijzigd.** Die heeft al een eigen tik op expanded; compacte blokken
  vragen een eigen ontwerp.

**Status:** gebouwd in quick 261011-l5k (`lib/features/home/filled_score_badge.dart`,
`_buildCompactRow` in `lib/features/home/home_screen.dart`).
