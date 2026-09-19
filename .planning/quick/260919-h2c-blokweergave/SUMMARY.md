---
quick_id: 260919-h2c
slug: blokweergave
status: complete
date: 2026-09-19
backlog: [69, 70]
commits: [18507d7, 8cf67d9, ...]
---

# Blokweergave — #69 en #70

## De keuze die Joost maakte

De schets legde drie standen voor. Joost koos géén van de twee modellen, maar **allebei, met
een knop ertussen**: de vensterlijst blijft de standaard, met een schakelaar naar de
blokweergave. Plus een tweede keuze: sorteren op score of op tijd. Dat is een betere keuze dan
kiezen — er is meer dan één juiste manier om naar een week te kijken.

## Wat er staat

| | |
|---|---|
| **Vensters / Blok** | De losse vensters, of één kaart per dag met de rijdag als balk |
| **Beste eerst / Op tijd** | Alleen in vensterweergave; in blokweergave is er per dag één kaart |
| Onthouden | Onder `home.*`, buiten de profielsynchronisatie — een kijkvoorkeur van dit toestel |

`buildRideBlocks` / `buildRideDays` zijn puur en opgebouwd **uit de vensters**, niet uit de
uurscores. Die vensters zijn al door toleranties, beschikbaarheid, toegestane duur en de
6–22-grens heen; opnieuw beginnen zou al die regels een tweede keer nabouwen en twee
antwoorden geven op dezelfde vraag.

## Vijf rondes, en wat elke ronde leerde

Joost keek er telkens naar en wees iets aan. Elke correctie was raak, en drie ervan legden
fouten bloot die er al langer zaten.

**1. "15 hours straight" klopt niet.** De regel toonde de lengte van het goede dagdeel. Op een
mooie dag werd dat vijftien uur, en dat leest als "je kunt vijftien uur fietsen". Het antwoord
op *hoe lang kan ik weg* is de langste rit die in het blok past — begrensd door de toegestane
ritduren, niet door hoe lang het mooi blijft. → `longestRideHours`.

**2. "Het geeft niet aan hoe de rest van de dag eruit ziet."** Ik was afgedwaald van mijn eigen
schets: daar liep de balk over de hele dag, bij het bouwen schaalde ik hem op het blok.
Daardoor zag "goed van 06:00 tot 21:00" er precies zo uit als "goed van 09:00 tot 11:00" — een
volle balk. → Eén kaart per dág, schaal 06:00–22:00, het grijs eromheen is de helft van de
informatie.

**3. "06:00–22:00, doe dit ook in de agenda."** Legde bloot dat die twee getallen op **drie**
plekken los van elkaar stonden. En dat de Agenda er aantoonbaar uit liep: die toonde uur 22 als
rij, oftewel 22:00–23:00, wat `maxHour` (exclusief) nooit aanbiedt. Je kon er een rit inplannen
die de app zelf nooit zou voorstellen. → `kRideDayStartHour` / `kRideDayEndHour` in
`core/config.dart`.

**4. "Om welk tijdvak gaat de rating?"** De score stond naast de dagnaam, het tijdvak drie
regels lager. Je las "Sunday: 98" terwijl die 98 over 17:00–19:00 gaat. → Tijdvak boven het
cijfer; de rechterkolom leest als één zin.

**5. "Wat zeggen de kleuren?"** Het eerlijke antwoord was: niets. Ik had de kaartkleuren
hergebruikt, en die komen uit drie families — `greatBg` is teal, `acceptableBg` is oranje. Op
een kaart werkt dat (het woord staat ernaast); op een balk van 24px werd het een lappendeken.
Erger: het gat gebruikte `surfaceDim` = `#DAE2CC`, een grόénige beige, en was dus zelf al half
groen. → Eén kleur in drie sterktes, neutraal gat.

**De les die eronder zit:** een ordinale schaal hoort als schaal getekend te worden, niet als
palet. Kaartkleuren en balkkleuren zijn niet hetzelfde probleem.

## Twee fouten die hierdoor gevonden zijn, los van #69

- **"Beste eerst" sorteerde niet op score.** Op tier, en binnen een tier chronologisch. Alles
  boven 85 is "Toprit", dus een 85 van zes uur stond boven een 93 van acht uur. Onzichtbaar
  zolang er geen knop boven stond die iets anders beloofde.
- **De Agenda bood een uur aan dat de motor nooit voorstelt** (zie ronde 3).

## Verificatie

- `flutter analyze`: 0 fouten
- `flutter test`: 661 groen (22 nieuwe), waarvan 13 op Ingrids exacte zaterdag
- Vijf keer door Joost op de webbuild bekeken en goedgekeurd

## Niet met eigen ogen gezien

Niets op de Oppo. Aanraakgedrag op de keuzerij, en of de balk op een echt scherm leesbaar is
in beide helderheden, staan nog open.
