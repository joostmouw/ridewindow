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

| | |
|---|---|
| **A** | Teller links, pijlen rechts. Het dichtst bij wat er nu staat, alleen met terug erbij |
| **B** | `‹ 1/3 ›` gecentreerd als één geheel. Het meest als driver.js |
| **C** | De besturing in een eigen balk op `paper-low`, met een scheidingslijn. Kost hoogte |
| **D** | Als A, maar voortgang als streepjes zoals de dagstreepjes op Home |

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

## Nog te beslissen

Welke variant. Daarna: krijgt de eerste tour (vier volle schermen) dezelfde voet, of wordt hij
helemaal vervangen door coach marks op het echte scherm? Dat laatste is wat driver.js doet en het
is eerlijker — je ziet de app in plaats van een dia over de app — maar het is een grotere ingreep.
