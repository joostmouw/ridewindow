---
sketch: 014
name: peloton-rij
question: "Waar staat de rij fietsers die laat zien hoe groot een gedeelde rit is — en wat vervangt het vlaggetje bij 'Jij organiseert'?"
winner: null
tags: [peloton, iconografie, ritten, home, rollen]
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
