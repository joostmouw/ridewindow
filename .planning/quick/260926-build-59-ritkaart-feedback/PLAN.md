---
quick_id: 260926-build-59-ritkaart-feedback
date: 2026-09-26
backlog: "87, 65"
status: planned
---

# Build 59-rondje: drie punten van de toestelcontrole op de Ritten-tab

## Aanleiding

Joost's toestelcontrole van 1.0.48 (59) leverde drie opmerkingen:

1. De scorepil ("99 Toprit") hing midden naast de kaart in plaats van in
   de rechterbovenhoek; de "+"-regel hoort eronder op de hoogte van de
   datum.
2. Bij het uitnodigen komt de vensterkiezer (slice 2, epic #65) ongevraagd:
   die moet een bewuste keuze worden, met een vinkje als "select multiple
   ride dates". Het feature zelf is goed.
3. "Kies samen een venster" op de kaart blijft altijd open staan, ook als
   je overal al gestemd hebt, en neemt dan veel ruimte in. Die moet in-
   en uitklapbaar zijn, met een indicatie dat jij gestemd hebt.

## Aanpak

1. `RideCard` (planned_rides_screen.dart): de buitenste rij krijgt
   `crossAxisAlignment: CrossAxisAlignment.start`. Klaar, wacht op
   tests en commit.
2. `invite_buddies_sheet.dart`: stap 1 (met wie) krijgt een vinkje
   "Meerdere rittijden voorleggen" (EN: "Select multiple ride dates"),
   standaard uit. Uit = de oude enkele uitnodiging, zonder tussenstap;
   aan = de bestaande vensterkiezer. `_pickWindows` krijgt dus een
   `multi`-vlag en levert bij uit alleen het oorspronkelijke venster.
   Nieuwe ARB-sleutels in beide talen.
3. `_OptionsBlock` wordt stateful met een inklapregel: titel, jouw status
   ("Jij hebt gestemd" / nog niet) en een chevron. Standaard dicht zodra
   jij op alle opties hebt gestemd, anders open; een tik van de gebruiker
   gaat vóór die automatiek. Nieuwe ARB-sleutels in beide talen.

## Grenzen

- Geen serverwerk, geen versiebump, geen release.
- Het detailscherm laat alles gewoon open staan: daar ben je voor het
  overzicht, het inklappen is voor de lijst.
- Geen sleutels weg; de bestaande teksten blijven staan.
