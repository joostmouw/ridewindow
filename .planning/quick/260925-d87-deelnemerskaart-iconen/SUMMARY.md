---
quick_id: 260925-d87-deelnemerskaart-iconen
date: 2026-09-25
status: complete
---

# #87: dubbele samenvatting weg, status als icoon, score klein op de plankaart

## Wat er gebouwd is (twee commits)

1. **`b32b191` — het ritdetail.** Op een groepsrit draait de teller nu
   alleen fietsjes; de telregel van CLUB-16 ("2 gaan mee · 1 kan niet ·
   2 nog niet") is daarmee de enige telzin. Dat was letterlijk de
   "dubbele tekst" uit de screenshot. De status per persoon is geen
   woord meer maar een icoon in de statuskleur: check, prohibit,
   hourglass -- met het woord als Semantics-label, zodat het scherm
   rustiger wordt zonder dat een screenreader de betekenis verliest.
   Drie verschillende vormen, dus het onderscheid hangt niet aan kleur
   alleen.
2. **deze commit — de plankaart op Home.** Joost stuurde onderweg bij:
   ook het tier-woord ("Toprit") op de plankaartjes at de breedte van
   het vakje op. `ScoreBadge` kreeg een `score`-variant: het getal in de
   tierkleur, kleiner dan de woordpil. Woord en getal samen vormen het
   Semantics-label ("Toprit, 88"). Het detail houdt het woord; de
   Ritten-tab laat zijn eigen "100 Toprit"-pil staan, die kaart heeft
   de breedte.

## Vondsten

1. **De dubbeling was een regressie van het stapelen, geen oude ontwerpfout.**
   De teller kwam in schets 014 (21 sept), de telregel in fase 35 /
   schets 016 (24 sept); pas op het detailscherm stonden ze boven elkaar.
   Home en de Ritten-tab waren altijd al dubbelvrij.
2. **De telregel is de rijkere zin** -- hij noemt ook "kan niet", de
   teller niet. Daarom viel de keuze op de zin van de teller weglaten en
   niet op de telregel.
3. **Bij een gewone gedeelde rit telt de organisator níét mee in de zin**
   ("Nog niemand geantwoord · 1 wacht nog"), bij een groepsrit wél ("2
   gaan mee" = jij + Jacco). Dat verschil zat al in
   `RideEntry.acceptedCount` (schets 016) en is nu in de tests
   vastgelegd; mijn eerste verwachting in de r1-test was fout en werd
   door de suite verbeterd.
4. **In één deelnemersrij staan twee Semantics-knopen**, waarvan één met
   een leeg label. Waar de tweede vandaan komt is niet achterhaald; de
   labelcontrole zoekt daarom naar de knoop mét label en eist dat dat er
   precies één is.
5. **De entries-provider laat verstreken ritten vallen.** De eerste
   plankaart-fixture van deze taak stond op een datum in juni en
   verscheen daardoor niet eens op Home; de fixture staat nu op morgen.

## Bewijs en grenzen

- Volledige suite: **983 tests groen** (was 982, +1 voor de plankaart).
- `flutter analyze`: **201 infos, nul errors, nul warnings** -- onder de
  baseline van 202; de twee extra komma-infos van onderweg zijn
  opgeruimd.
- Geen ARB-sleutels toegevoegd of weggegooid: de statuswoorden en
  tierwoorden bestaan verder voor Semantics en de andere schermen.
- Geen versiebump, geen release. **Goedkeuren op de Oppo is Joost's
  ronde**: het ritdetail van een groepsrit (fietsjes zonder zin, telregel
  eronder, iconen per persoon) en een plankaartje onder GEPLAND (getal
  in plaats van "Toprit"). Een release-bump moet die ronde afronden.
- De Ritten-tab-pil ("100 Toprit") kan hetzelfde worden als Joost dit
  op het toestel goed vindt; bewust niet meegenomen, hij vroeg om Home.
