---
quick_id: 260926-plankaart-kleur-en-rolregel
date: 2026-09-26
backlog: "87"
status: planned
---

# Plankaartjes onder GEPLAND: één kleur per kaart, en een rolregel die zijn zin afmaakt

## Aanleiding

Screenshot 26 sept (web-PWA, build 59) bij de toestelcontrole:

1. De getallen op de plankaartjes staan in de groene tierpil terwijl het
   kaartje zelf gepland-blauw is: twee kleuren op één kaart.
2. De rolregel kapt af ("On the Roll · You're o..."): op het smalle
   kaartje past de rolzin naast de groepsnaam niet meer op één regel.

## Keuzes van Joost (via AskUser, 26 sept)

1. **Getal in blauw.** Het kaartje blijft zoals het is; het getal gaat in
   de gepland-blauw. De tierkleur verdwijnt van dit kaartje; het oordeel
   blijft in het Semantics-label ("Toprit, 97") en op het detail in
   woord én tierkleur.
2. **Eén regel als het kan, twee als het moet.** De rolregel probeert op
   één regel te blijven, maar loopt om naar twee als hij niet past.

## Aanpak

- `ScoreBadge` krijgt een optionele `color` die op de getalvariant de
  tierkleur overruled; Home geeft `rw.plannedRide` mee. De woordvariant
  (detail) blijft onaangetast.
- `RideRoleLine`: het label mag naar twee regels omslaan. De groepsnaam
  houdt zijn cap van 45 procent (schets 016), de kaart groeit alleen
  als het echt niet past.

## Grenzen

- Geen ARB-wijzigingen, geen serverwerk, geen versiebump, geen release.
- De agendacel (scorekleur + blauwe rand) blijft zoals hij is: daar is
  de scorekleur juist de taal.
