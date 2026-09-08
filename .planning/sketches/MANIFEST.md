# Sketch Manifest

Schetsen voor milestone **v4.0 "Eigen gezicht"**. Startpunt van de epic:
`.planning/EIGEN-GEZICHT.md`.

## Design Direction

RideWindow heeft zijn merkkleuren en zijn huisletter (Outfit) al binnen; wat ontbreekt is
**durven contrasteren**. De app is nu één groentint waarin achtergrond, dagstrip, periodefilter en
ritkaarten allemaal even zwaar wegen, waardoor het oog nergens naartoe wordt getrokken en de
kernwaarde van het product — de score en het beste venster — visueel gelijkstaat aan een filterchip.
De richting is daarom niet "meer Material 3 naleven" maar: geef het scherm een duidelijke eerste,
tweede en derde plek, en maak de weergegevens leesbaar in plaats van decoratief.

## Reference Points

- De eigen app-icoon: RW-monogram in één ononderbroken monoline, ronde uiteinden, geen scherpe hoek.
- De werkwijze die zich in dit project bewees: kandidaten als HTML naast elkaar renderen met de
  échte merkkleuren en de échte inhoud, screenshotten, en binnen een minuut kiezen. Zo is Outfit
  gekozen (`750189f`).

## Werkwijze

Alle schetsen zijn losse HTML zonder bouwstap. Ze linken naar `themes/default.css`, waarin de
tokens uit `lib/theme/app_colors.dart` en `lib/theme/app_typography.dart` één op één zijn
overgenomen, en ze laden `assets/fonts/Outfit.ttf` rechtstreeks uit de repo. Een schets die hier
goed oogt is daarom haalbaar in Dart met tokens die al bestaan.

```bash
python3 -m http.server 8765     # vanuit de repo-root, anders laadt het lettertype niet
```

## Sketches

| # | Naam | Design Question | Winnaar | Tags |
|---|------|-----------------|---------|------|
| 001 | [home-hierarchie](001-home-hierarchie/) | Waar komt de hiërarchie op Home vandaan — uit een dominante held, uit een neutraal papier, of uit het weer zelf? | **B — Papier en inkt** | home, hierarchie, typografie, weerbalken, fase-23 |
| 002 | [iconografie](002-iconografie/) | Waar komt het kledingadvies vandaan als het geen systeememoji meer is — twee losse kledingstukken, één tenue, of een gekleed figuur? | *afgewezen — verkeerde vraag* | iconografie, kleding, fase-24 |
| 003 | [kledingadvies-zonder-plaatje](003-kledingadvies-zonder-plaatje/) | Als het kledingadvies geen plaatje meer is — hoeveel grafiek verdient het dan wél? | **A — Gevoelsbalk** | iconografie, kleding, weerbalken, fase-24 |
| 004 | [iconenfamilie](004-iconenfamilie/) | Welke iconenfamilie deelt de hand van het RW-logo en van Outfit? | *ingehaald door 006* | iconografie, fase-24, merk, rider-types |
| 006 | [hele-set-per-familie](006-hele-set-per-familie/) | Hoe ziet de volledige icooninventaris eruit in elke kandidaat-familie? | **Phosphor** (gewicht open) | iconografie, fase-24, mapping, keuze |
| 008 | [ritten-rollen](008-ritten-rollen/) | Hoe lees je aan een rit af welke rol jij erin hebt — en hoe kom je vanaf een gedeelde rit in één tik bij het detail? | *nog te kiezen* | ritten, peloton, rollen, navigatie, lijst |

## Beslissingen die doorwerken

- **001 → B (2026-09-07).** Groen is behang en wordt accent: `lightSurface` gaat van `brandLight`
  naar `surfaceContainerLowest`, zodat de oppervlakkenladder eindelijk bereik heeft en een kaart
  kán oplichten. `brandLight` blijft als accent in gebruik. Dit raakt élk scherm, niet alleen Home
  — zie de implementatielijst onderaan `001-home-hierarchie/README.md`. Let bij het uitvoeren op de
  contrastratio's uit backlog #9: die zijn *op brandLight* gemeten.
- **Weerbalken krijgen een leesbaar bereik plus een woord.** De absolute schaal blijft eerlijk maar
  wordt ingezoomd (regen 0–3 mm i.p.v. 0–10 mm), en er komt een oordeel naast de waarde. Dat is de
  ingreep die "versiering" naar "informatie" tilt.

- **002 → afgewezen (2026-09-07).** Eigen kledingpictogrammen zijn de verkeerde oplossing voor het
  goede probleem. Dat de emoji op elk platform anders wordt getekend klopt, maar het antwoord is niet
  "teken ze zelf" — het advies gaat over hoe koud het aanvoelt, en dat is informatie, geen
  illustratie. Dezelfde afweging als bij de weerbalken in fase 23: een plaatje dat niets toevoegt is
  versiering. Voor de zestien niet-kleding-emoji blijft de vraag wél open, en daar is het antwoord
  waarschijnlijk Material Symbols — die zitten al in Flutter en zijn op elk platform identiek.
- **De gevoelstemperatuur hoort in beeld.** `recommendClothing()` rekent al met
  `temp − (wind + 15) × 0,05` maar toonde dat getal nergens, waardoor de app bij 15 °C "lange mouw"
  adviseerde zonder reden te geven. Dat is geen stijlkeuze maar een ontbrekend stuk informatie, en
  het geldt ongeacht welke variant uit 003 wint.
- **003 → A (2026-09-07), en meteen gebouwd.** Het kledingadvies is een balk in
  de familie van de weerbalken geworden. Eén ding kwam pas boven water toen het
  in de app stond: RideWindow had al een "feels like" — die van Open-Meteo, in
  de weerlijst — en die staat vier centimeter van de balk vandaan een ander
  getal te tonen. Twee berekeningen onder dezelfde woorden. Voorlopig gescheiden
  met een eigen label, maar de echte vraag is of het kledingadvies niet gewoon
  van de gevoelstemperatuur moet uitgaan. Dat verandert wat de app adviseert en
  is daarom een beslissing, geen opruimwerk.
- **004 → Hugeicons, en daarna teruggedraaid (2026-09-08).** Op vier signatuur-iconen viel de keuze
  op Hugeicons; zodra de volledige set van 83 er lag, viel hij tegen. De les zit in de opzet, niet in
  de familie: **een iconenfamilie beoordeel je op de hele set, niet op een handvol.** Karaktervol per
  stuk kan ongelijk als groep zijn, en dat zie je alleen bij elkaar. Schets 006 doet het daarom
  opnieuw met alle 83 en een familieknop. Wat blijft staan uit 004: De maatstaf was niet "welke set is mooi" maar welke set de hand
  van het app-icoon deelt: ronde uiteinden, gulle bochten, gelijke lijndikte, cirkelvormige
  geometrie. Hugeicons komt daar het dichtst bij en dekt als enige alle begrippen. Twee routes zijn
  onderweg afgevallen en staan vastgelegd in die README: een kant-en-klaar handgetekend pakket
  bestaat niet voor dit domein, en een schone familie door een schetsfilter halen levert het
  verkeerde soort handgemaakt op — het logo is zelfverzekerd handschrift, geen krassige schets.
- **De overstap raakt 83 plekken, niet 16.** Naast de emoji tekent de app 71 Material-iconen. Die
  half laten staan levert twee handen op één scherm. Volledige mapping in schets 005; alle 63
  benodigde vormen bestaan. Eén echt ontwerpgat: Material gebruikt gevuld-versus-omlijnd om de
  geselecteerde tab aan te wijzen, en die tweedeling heeft Hugeicons niet — de navigatiebalk moet
  selectie dus anders tonen.
- **006 → Phosphor (2026-09-08).** Gekozen op de volledige set van 83, niet op een handvol. Het
  gewicht — regular, bold of duotone — staat nog open. Twee dingen om te onthouden: een familie
  beoordeel je op alles wat de app tekent, en **een dekkingsgetal zegt evenveel over je zoekwoorden
  als over de set** — Phosphor leek 77/83 tot ik zijn eigen taal gebruikte (`prohibit`,
  `arrows-clockwise`, `link-break`), en toen was het 83/83.

## 007 — Uitleg in stappen

`007-uitleg-stappen/` — De twee uitleg-overlays (`screen_hint_overlay.dart`,
`app_tour_overlay.dart`) kunnen alleen vooruit en staan op glas in plaats van papier. Vier
varianten voor een voet met teller en `‹ ›`, live klikbaar op een nagebouwd Home-scherm.
Aanleiding: Joost, 2026-09-08, met driver.js als referentie. **Nog te kiezen.**

## 008 — Ritten en rollen

`008-ritten-rollen/` — Vier ritsoorten (wacht op jou / jij organiseert / je gaat mee / alleen jij)
staan verdeeld over twee tabbladen, dragen hetzelfde icoon, missen hun datum en zijn niet aan te
tikken. Drie manieren om de rol áán de rit te hangen — filterrij, secties, of een rolstrook — plus
één keer waar de tik op uitkomt. Aanleiding: Joost, 2026-09-08. **Nog te kiezen.**
