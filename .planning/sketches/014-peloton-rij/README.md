---
sketch: 014
name: peloton-rij
question: "Waar staat de rij fietsers die laat zien hoe groot een gedeelde rit is — en wat vervangt het vlaggetje bij 'Jij organiseert'?"
winner: "Gekozen — zie gekozen.html"
tags: [peloton, iconografie, ritten, home, rollen, detail]
---

# Schets 014: Peloton in een rij

## Design Question
Een gedeelde rit draagt vandaag een **vlag** (`AppIcons.flag`) bij "Jij organiseert" en **drie koppen**
(`usersThree`) bij "Je gaat mee met …". Geen van beide gaat over fietsen, en hoe groot de groep is
staat alleen als tekst — en alleen bij de rit die je zelf organiseert. De vraag: **waar komt de rij
fietsers te staan**, en **hoe ver gaat dat** — neemt hij de plek van het rol-icoon in, krijgt hij een
eigen telregel, of staat hij in de kop van de kaart? De megafoon (`megaphone-simple`, de roeicoach-toeter)
vervangt in alle drie de varianten het vlaggetje.

## How to View
```bash
python3 -m http.server 8765   # vanuit de repo-root, anders laadt Phosphor niet
open http://localhost:8765/.planning/sketches/014-peloton-rij/index.html
```

## Variants
- **A: Peloton ís het icoon** — de rij fietsers neemt de plek van het rol-icoon in; megafoon ervóór als jij organiseert. Compactst: geen extra regel, en solo (één fietser) en peloton (vijf) worden hetzelfde gebaar.
- **B: Megafoon voorop, peloton op de telregel** — rolregel houdt één icoon, de rij staat vóór "3 gaan mee · 1 wacht nog". Duidelijkst uit te leggen, kost op Home een derde regel per kaart.
- **C: Peloton in de kop** — de rij naast de dagnaam. Hardst zichtbaar, maar de fietsers staan twee keer op dezelfde kaart en bij lange dagnamen wordt het krap.

## Ronde 2 — hetzelfde op alle drie de schermen
Joost: *"het gaat ook om het homescherm bij planned rides — verzin hier iets gezamenlijks voor."*
Op Home staat het rol-icoon vandaag **twee keer**: groot links op de kaart (`rideRoleStyle().icon`,
20px, in `plannedRide`-blauw) én klein in de `RideRoleLine` eronder. Daar valt de vlag het meest op.
De gedeelde grammatica van ronde 2: **links staat wat jij bent, in de regel staat wie er meerijdt.**

- **D: Rol links, peloton in de regel** *(aanbevolen)* — één merkteken links (megafoon / fietser /
  zandloper), het peloton in de rolregel. Geen extra regel, en het dubbele icoon op Home verdwijnt.
- **E: Peloton links, rol in de regel** — de groep neemt de icoonplek over, óók in de rittenlijst,
  die daarvoor een linkerkolom krijgt die hij nu niet heeft.
- **F: Peloton op de startlijst-regel** — het merkteken links zoals D, de fietsers onderaan mét de
  telzin, op alle drie de schermen. Duidelijkst, en op Home een regel duurder per kaart.

Elke variant toont Home, de rittenlijst én de peloton-kaart op het detailscherm naast elkaar.

## Het peloton-teken (`icoon.html`)
Joost: *"kan je niet één icoon maken zoals person-simple-bike, maar meer zoals users-three?"* —
en na de eerste ronde: *"3, drie fietsers in een lint, vond ik het beste."* De knop **"Eén peloton-teken"**
in `index.html` wisselt overal tussen de rij losse fietsers en dat ene teken.

Gemaakt door de échte Phosphor-fietser (0xe734, uit `assets/fonts/Phosphor.ttf`) drie keer over elkaar
te leggen met dezelfde uitsparing die Phosphor zelf gebruikt, en het resultaat samen te voegen tot
**één pad** — dus bouwbaar als glyph in een eigen icoonfont, zonder plaatje en zonder extra pakket.
Afstelling: schaal 0,82 · afstand 420 · tussenruimte 86 · **halve** dikte-correctie (krimpen maakt de
lijn dunner dan de buuriconen; volledig herstellen maakt hem te vet en loopt de wielen dicht).

## Gekozen (2026-09-21) — `gekozen.html`
Joost koos het lint én legde het systeem vast. Drie regels, de hele app door:

1. **Links, in het blauw van een geplande rit, staat wat voor rit het is.** Het peloton-lint bij een
   groepsrit, `person-simple-bike` als je alleen gaat. Op Home (20px) én in de rittenlijst (22px) —
   die krijgt daarvoor een linkerkolom die hij vandaag niet heeft.
2. **De megafoon staat in de rolregel en alleen daar**, en betekent: jíj organiseert. Ga je mee, dan
   is de zin genoeg — "Je gaat mee met Bram" krijgt géén icoon meer (nu nog `usersThree`).
3. **De teller laat zien wie al ja zei:** één fietsje per persoon, wachtenden op 32% dekking (45% in
   donker), met "3 gaan mee · 1 wacht nog" ernaast. Ook bij andermans rit — vandaag krijg je die zin
   alleen te zien als je zelf organiseert.

Twee open vragen staan als knop in de pagina: **teller als fietsjes of als stippen** (naast het lint
staan er anders veel fietsjes op één kaart), en **rittenlijst met of zonder die linkerkolom**.

Bij het bouwen nog te beslissen: telt "3 gaan mee" jou mee, en hoeveel fietsjes tekenen we maximaal
voordat het `+3` wordt.

## What to Look For
- **Tel je de groep in één blik?** Gevuld = gaat mee, doorzichtig = wacht nog op antwoord.
- **Blijft de rolregel op één regel** bij vijf fietsers + megafoon + "Jij organiseert" (372px breed)?
- **Home versus de rittenlijst:** dezelfde regel, één maat kleiner. Wat op Home een regel extra kost, telt dubbel.
- **Welke megafoon** — `megaphone` (0xe324, met greep) of `megaphone-simple` (0xe642, kale toeter).
- **Licht én donker** met de knop rechtsboven; de wachtende fietser staat op .38 dekking (licht) / .5 (donker).

## Bevindingen tijdens het tekenen
- **Overlap werkt niet.** Fietsers met -2/-3px overlap smeren bij 16px tot één veeg; ze werden pas
  telbaar met **1px lucht** ertussen. Dat is in het bestand zo gezet.
- **Vijf is de bovengrens** op de rolregel van een 372px-kaart; daarboven hoort het `+3` te worden.
- Op donker verdwijnt .38 dekking bijna; daar staat de wachtende fietser op .5.
- **Het icoon telt niet meer.** Eén peloton-teken zegt "met meer mensen", niet "met z'n vieren" —
  het aantal blijft dus in de tekstregel staan ("3 gaan mee · 1 wacht nog"). De rij losse fietsers
  kon dat wel; dat is de afruil tussen de twee knoppen.
- **Nog te meten op de telefoon:** of het teken bij 14 en 16 px nog verschilt van één fietser.
