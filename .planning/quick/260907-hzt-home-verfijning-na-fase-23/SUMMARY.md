---
task_id: 260907-hzt
slug: home-verfijning-na-fase-23
date: 2026-09-07
milestone: v4.0
phase: 23
status: complete
---

# Home-verfijning na fase 23 — zes rondes op aanwijzing van Joost

Fase 23 was afgerond; dit is wat daarná kwam, allemaal terwijl Joost meekeek op
het toestel. Zes wijzigingen, elk klein, maar drie ervan legden iets bloot dat
een volgende sessie uren kan kosten als het niet op schrift staat.

Commits: `026699f`, `7a3ed6d`, `3971201`, `7d32c3d`, `9bf1e38`, `b3ee1c1`.

## Wat er is gebouwd

1. **De dagstrip toont vier niveaus in plaats van drie** en de dag néémt de
   kleur van zijn beste rit over — dagnummer én een balk over de volle
   dagbreedte. Perfect en Great zaten samen in "goed", dus groen dekte 70–100
   en in een redelijke week was élke dag groen. Een dag met 99 zag er uit als
   een dag met 71, terwijl de kaarten eronder dat verschil wél maken.
2. **Lijsten hebben een plafond.** RIDE TIMES rendeerde `slots.length` zonder
   grens — bij Joost 64 kaarten, ruim 11.000 pixels scrollen. Nu vijf plus
   "Toon alle 64 vensters" dat ter plekke uitklapt; PLANNED drie plus "nog N →"
   naar het tabblad Rides, dat die volledige lijst al ís.
3. **Elk tijdvak kan open én dicht**, ook de favoriet, met een kruisvervaging
   ertussen.
4. **De ingeklapte kaart is een kwart korter** (~250 → ~187 logische px) met
   exact dezelfde informatie.
5. **Het infovenster legt uit waarom deze score deze score is** — deelscore,
   binnen/buiten je bereik, en de schaal met twee voorbeelden uit de motor.

## De drie vondsten die je niet wilt herontdekken

**1. Een icoon dat alleen in een ternaire staat, wordt uit het lettertype
gesneden.** `Icons.expand_less` stond uitsluitend in
`expanded ? Icons.expand_less : Icons.expand_more` en dus nergens als constante
instantie. `--tree-shake-icons` houdt alleen glyphs die het als constante vindt,
dus die verdween uit de gesubsette `MaterialIcons-Regular.otf`. De knop werkte,
de ruimte werd gereserveerd, er tekende níéts — en de kaart was daarmee niet
meer dicht te klikken. `Icons.expand_more` stond elders wél in een `const Icon`
en werkte gewoon, vandaar dat openen lukte en sluiten niet.

**Zichtbaar in een release-build op een toestel, nergens anders.** In debug is
het lettertype compleet. Oplossing: één glyph die 180° draait.

Ik heb hier twee keer een verkeerde diagnose gesteld. Eerst verdacht ik de
plaatsing in `AnimatedCrossFade` (onschuldig — dat kostte een build). Daarna
"bewees" ik met een zelfgeschreven cmap-parser dat beide glyphs aanwezig waren;
die controle deugde niet, want een format-4 segment kan codepoints bevatten die
naar glyph 0 wijzen, dus mijn hele bereik kwam als aanwezig terug.

**2. `gen-l10n` sorteert placeholders alfabetisch, niet op volgorde in de zin.**
Bij `"... {ex1} ... {score1}, en {ex2} ... {score2}"` is de gegenereerde
handtekening `(Object ex1, Object ex2, Object score1, Object score2)`. Geef je
ze in leesvolgorde door, dan compileert alles en staat er onzin op het scherm:
*"32° zou 40° scoren, en 70 zou 30 scoren"*. De analyzer merkt niets, want alle
parameters zijn `Object`. **Je vindt dit alleen door de zin te lezen.**

**3. Het toestel serveerde meermaals een verouderde bundel** ondanks de
`no-cache`-headers uit `d99b3bd`. `PELOTON.md` zegt dat dat sinds die fix niet
meer hoort te gebeuren en dat het dán het signaal is — dat klopte. Gebruik bij
elke deploy waarvan je het resultaat gaat beoordelen de cache-bust-truc uit
`PELOTON.md`, anders beoordeel je oude code. Ik heb daar twee rondes op
verloren voordat ik het doorhad.

## Een architectuurkeuze die blijft staan

De scorecurves zijn uit `ScoringEngine` gelicht naar een publieke
`MetricScores`; de engine roept precies die functies aan. Dat is geen netheid:
het infovenster noemt nu concrete voorbeelden ("32° zou 70 scoren") en die
moeten uit dezelfde formule komen als de score ernaast. Een tweede kopie in de
presentatielaag gaat afwijken zodra iemand een grens verschuift, en dan liegt de
app over zijn kernwaarde.

## Werkafspraak die Joost deze sessie stelde

**Denk verder dan de letterlijke vraag en stel de symmetrische versie zelf
voor.** Aanleiding: hij vroeg of de kleine kaarten uitklapbaar konden; ik bouwde
precies dat en liet de beste kaart permanent openstaan. Eén kaart die als enige
niet gehoorzaamt aan een interactie die alle andere wél hebben, is geen keuze
maar een half afgemaakte feature.
