---
quick_id: 260929-verlopen-optie
date: 2026-09-29
status: planned
bron: toestelcontrole 1.0.52 (63), Richards rit
---

# Een venster dat al voorbij is, staat niet meer ter keuze

## Wat er mis is

Onder "Kies samen een venster" bij Richards rit stond op 29 september nog een
optie op zo 27 sep, met "Ik kan / Kan niet" erbij; het ritdetail toonde hem
ook. `GroupRide.hasOpenChoice`, `frontRunner`, het blok op de rittenlijst
(`_OptionsBlock`) en de stemmenlijst op het detail (`_buildOptionVoters`)
kijken allemaal naar `ride.options`, zonder op de tijd te letten. De tests
zagen het niet: elke testoptie ligt in de toekomst (`DateTime.now()` + dagen).

## Hoe goedlopende apps dit doen

- **Doodle**: een tijdstip dat voorbij is, is geen keuze meer; je stemt er
  niet op.
- **Calendly, Google Calendar "Voorstel nieuwe tijd"**: tijden in het
  verleden worden niet aangeboden.
- **WhatsApp-peilingen** zijn geen tijdsvoorstellen en blijven open; dat is
  hier niet het model, want een fietsvenster heeft een begin.

Overgenomen: een venster dat begonnen is, verdwijnt uit de keuze, zowel om
op te stemmen als om als eigenaar te kiezen. Blijft er één venster over, dan
is er niets meer te kiezen en verdwijnt het blok, volgens de regel die al
gold ("één venster is geen keuze"). Niet grijs laten staan: een stem op iets
dat voorbij is zegt niets meer, en een grijze rij kost ruimte op een kaart die
al vol is.

## Stappen

1. `GroupRide.openOptions({now})`: de opties die nog niet begonnen zijn.
   `hasOpenChoice` en `frontRunner` rekenen daarmee.
2. `_OptionsBlock` (lijst, volgorde en "jij hebt overal geantwoord") en
   `_buildOptionVoters` (detail) tonen alleen `openOptions()`.
3. Tests: model (een verlopen optie telt niet mee, een lopende evenmin; twee
   toekomstige plus een verlopen blijft een keuze), en de ritkaart met een
   verlopen optie naast een toekomstige toont geen blok.
4. Suite, analyze, commit; op de Oppo na de volgende build: Richards rit
   heeft geen blok meer.
