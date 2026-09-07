---
quick_id: 260907-wgz
slug: fase-24-kledingadvies-gevoelsbalk
date: 2026-09-07
status: in-progress
---

# Fase 24 — het kledingadvies wordt de gevoelsbalk

Uitvoering van **schets 003, variant A**, gekozen door Joost op 2026-09-07.
Zie `.planning/sketches/003-kledingadvies-zonder-plaatje/`.

## Waarom

Fase 24 stond in `EIGEN-GEZICHT.md` als "iconografie": het kledingadvies tekent
losse Unicode-emoji die elk platform anders rendert. Schets 002 probeerde daar
eigen pictogrammen voor te maken en werd afgewezen — niet de tekening maar de
aanpak. Het advies gaat niet over textiel maar over hoe koud het aanvoelt, en
dat hoort informatie te zijn, niet illustratie. Dezelfde beweging als fase 23
met de weerbalken.

Er zat bovendien een gat in het product: `recommendClothing()` rekent al met
gevoelstemperatuur — `temp − (wind + 15) × 0,05`, waarbij die 15 km/u je eigen
snelheid is — maar toonde dat getal nergens. Daardoor adviseerde de app bij een
gemeten 15 °C "lange mouw" zonder ooit de reden te geven.

## Taken

1. **`ClothingCombo` krijgt zijn bandgrenzen** (`lib/features/shared/clothing_tip.dart`).
   De drempels 20 / 14 / 5 stonden als losse getallen in `recommendClothing()`.
   De balk moet dezelfde grenzen tekenen, dus ze worden één bron: velden op de
   enum plus `ClothingCombo.forFeelsLike()`. Anders kunnen tekening en advies
   uit elkaar lopen.
2. **`ClothingTip` (de emoji-pil) verdwijnt.** Enige gebruiker is
   `ride_detail_screen.dart:455`. De rekenfuncties blijven.
3. **Nieuwe `FeelsLikeBar`** (`lib/features/shared/feels_like_bar.dart`) in de
   anatomie van `weather_indicator_bar.dart`: label, waarde, oordeelswoord,
   baan van 14 px met de vier banden als tint en een markering, schaalregel
   eronder. Plus een infovenster dat uitlegt waar het getal vandaan komt —
   zonder die uitleg is een gevoelstemperatuur die 2° van de voorspelling
   afwijkt gewoon verwarrend.
4. **`_buildClothingTip()`** wordt een kolom: kop, balk, kledinglijst.
5. **EN + NL strings.** Let op de val uit `b3ee1c1`: `gen-l10n` sorteert
   placeholders alfabetisch, niet op leesvolgorde. Daarom `from`/`to` als namen
   — dan valt alfabetisch samen met leesvolgorde.
6. **Test op de bandgrenzen**, zodat 5,0 en 4,9 vastliggen.

## Wat hier níét in zit

De zestien andere systeememoji (🌡 🌧 💨 🚴 🏔 🚩 en de acht rider-types). Die
vragen een aparte keuze — waarschijnlijk Material Symbols, want die zitten al in
Flutter en zijn op elk platform identiek.
