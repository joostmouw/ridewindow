---
quick_id: 260908-j2q
slug: peloton-afzeggen
date: 2026-09-08
status: complete
---

# Een geaccepteerde rit afzeggen

## Was het er al? Nee — half

Joost vroeg of je een rit die je van iemand anders hebt geaccepteerd kunt
afzeggen. Het antwoord bleek: **alles behalve de knop bestond al.**

| Laag | Stand vooraf |
|---|---|
| Database | `status` kent `declined`; `group_ride_participants_update_own` staat elke update op je eigen rij toe. **Geen migratie nodig.** |
| Model | `ParticipantStatus.declined` bestaat |
| Gateway | `respondToRide(accepted: false)` bestaat en werkt |
| UI | `_JoinedRideRow` was een kale `ListTile`. Geen weg naartoe. |

Eenmaal "ik ga mee" zat je er dus aan vast, terwijl elke laag eronder het al
toestond.

## Wat er bij kwam kijken en niet gevraagd was

Afzeggen is **een deur die maar één kant op gaat**. Een rit met status
`declined` valt uit alle drie de providers tegelijk: uit `pendingRideInvites`
(filtert op `invited`), uit `joinedGroupRides` (filtert op `accepted`) en uit
`ownedGroupRides` (hij is niet van jou). Hij is daarna nergens meer aan te
wijzen — terwijl de rij in de database gewoon bestaat en het RLS-beleid een
terugweg toestaat.

Een misklik zou dus onherstelbaar zijn zonder dat daar een technische reden
voor is. Daarom zit er een **ongedaan-maken in de snackbar**, die echt
terugzet (`accepted: true`) en dat bevestigt.

## Wat het níét oplost

Morgen alsnog van gedachten veranderen. Daarvoor moet een afgezegde rit
zichtbaar blijven, en dat is een aparte keuze over wat de Peloton-tab toont.
Let op: **dit gat bestond al** — het afwijzen van een uitnodiging (de knop
"Kan niet") is net zo definitief. Staat als voorstel in BACKLOG.md.

## Vormkeuze

Een tekstknop, geen kruisje. Een kruisje naast andermans rit leest als
"verwijder deze rit", en dat is precies wat er níét gebeurt: de rit blijft
bestaan, jij gaat alleen niet mee.

Label: NL "Toch niet", EN "Drop out". Bewust anders dan het "Kan niet" /
"Can't make it" op een uitnodiging — je komt ergens op terug in plaats van
iets af te wijzen.

## In beide talen

`pelotonWithdraw`, `pelotonWithdrawn`, `pelotonRejoined`, `pelotonUndo` staan
in `app_en.arb` én `app_nl.arb`. Geen hardgecodeerde tekst — anders dan
`app_tour_overlay.dart`, dat nog steeds Nederlands toont in de Engelse app
(zie schets 007).

## Verificatie

`test/features/peloton_withdraw_test.dart`, drie tests, groen:

- een geaccepteerde rit draagt de knop;
- afzeggen stuurt `accepted: false` en de rit verdwijnt uit de lijst;
- ongedaan maken stuurt `accepted: true` en de rit staat er weer.

Die middelste twee bewaken wat aan de UI níét te zien is: dat de knop de
juiste kant op stuurt. Verwissel `true` en `false` en je hebt een knop die
exact het tegenovergestelde doet van wat erop staat.

Volledige suite: 512 tests groen.
