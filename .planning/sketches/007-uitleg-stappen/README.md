# 007 — Uitleg in stappen

> `index.html` — vier varianten, live klikbaar. Serveren met
> `python3 -m http.server 8782 --directory .planning/sketches/007-uitleg-stappen`

## Waarom

Joost, 2026-09-08: *"die pop ups met uitleg vind ik niet mooi en niet helder"* — met als
gevraagde richting het patroon van [driver.js](https://driverjs.com): een teller (`1/3`) en
`‹ ›` zodat je uitleg kunt terughalen.

Er staan nu **twee** systemen naast elkaar die geen van beide dat doen:

| Bestand | Wat het is | Wat eraan mankeert |
|---|---|---|
| `screen_hint_overlay.dart` | Spotlight-coach marks per scherm | Heeft `1/3`, maar géén terug. Elke tik op het scherm springt vooruit, ook als je alleen wilde lezen. Kaart is `Colors.white.withAlpha(30)` — glas, terwijl de app papier is |
| `app_tour_overlay.dart` | Vier volle schermen bij eerste start | Alleen bolletjes, geen teller, geen terug. Teksten staan hardgecodeerd in het Nederlands, dus de Engelse app toont ze ook zo |

Dit zijn precies de twee bestanden die `EIGEN-GEZICHT.md` noemt als de laatste met hardcoded
kleuren. Ze zijn nooit meegegaan in de papier-en-inkt-ronde van fase 23.

## Wat de schets laat zien

Een nagebouwd Home-scherm met de spotlight erop, en vier manieren om de voet van de kaart in te
richten. Ze verschillen **alleen** daarin — de kaart, de uitsnede en de plaatsing zijn gelijk.

Er stonden er eerst vier (teller links, `‹ 1/3 ›` gecentreerd, een aparte balk, en streepjes).
Joost koos de streepjes, en vroeg erbij: *"of is er nog een betere Material Design-optie die
aansluit op mijn app?"* Die vraag bleek de moeite waard, dus de schets is teruggebracht tot twee:

| | |
|---|---|
| **D** | Streepjes op de papieren kaart uit fase 23. Rijmt met de dagstreepjes op Home |
| **E** | Material 3 rich tooltip met een determinate `LinearProgressIndicator` |

**Gekozen: E** (Joost, 2026-09-08, na beide live te hebben geklikt).

### Waarom E, en wat het antwoord op de vraag was

MD3 kent **geen** rondleiding-component — er staat geen coach mark in de spec, en driver.js is een
webbibliotheek, geen Material-patroon. Maar er is wél een component met precies de goede anatomie:
de **rich tooltip** (meerdere regels, titel, knoppen eronder). Dat legt andere maten op dan de
ritkaarten: `surfaceContainer` in plaats van papier, hoek 12 (`AppShapes.radiusMd`) in plaats van
20, en schaduwniveau 2.

De streepjes zijn óók geen MD3: er is geen stappenteller in de spec. De dichtstbijzijnde echte
component is de determinate `LinearProgressIndicator`, en Flutter 3.44 tekent die in de huidige
M3-vorm met een gat vóór de stopindicator. Vandaar dat E hem gebruikt.

## Wat er hoe dan ook verandert

- **Terug kunnen** — de aanleiding van de vraag.
- **Papier in plaats van glas** — `surfaceContainerLowest`, radius 20 (`AppShapes.radiusXl`, een
  bestaand token — de 18 en 24 die elders rondzwerven zijn dat niet, zie STATE.md).
- **Niet meer overal tikken om vooruit te gaan.** Alleen de knoppen doen iets. Een tik die je
  ongewild een stap verder zet is precies waarom uitleg "niet helder" voelt.
- **Eén voet voor beide systemen**, zodat de eerste tour en de coach marks hetzelfde ding zijn.

## Wat hetzelfde blijft

De spotlight-uitsnede met het lichte randje, en de keuze boven/onder het doel op basis van waar het
op het scherm staat. Dat werkte; alleen de kaart eraan was niet in stijl.

## Uitgevoerd

Zie `quick/260908-k4t-uitleg-in-stappen/SUMMARY.md`. Beide overlays delen nu
`lib/features/shared/step_controls.dart`, en de rondleiding is niet langer hardgecodeerd
Nederlands.

## Nog te beslissen

Of de eerste tour (vier schermen áchter elkaar, los van de app) op termijn helemaal verdwijnt ten
gunste van coach marks op het échte scherm. Dat is wat driver.js doet en het is eerlijker — je ziet
de app in plaats van een dia over de app — maar het is een grotere ingreep dan deze ronde.
