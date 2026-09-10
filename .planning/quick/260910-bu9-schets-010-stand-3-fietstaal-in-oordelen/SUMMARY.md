---
quick_id: 260910-bu9
slug: schets-010-stand-3-fietstaal-in-oordelen
status: complete
date: 2026-09-10
commit: 1bf942d
sketch: 010
---

# Uitgevoerd — schets 010, stand 3

Joost koos stand 3 op 2026-09-10.

## Wat er nu anders is

**De vier oordelen zijn namen geworden.** Toprit / Fijne rit / Te doen /
Binnenblijver (EN: Top ride / Good ride / Doable / Indoor day). Ze staan op
elke kaart, elke dag — dat is de plek waar één woord het vaakst gezien wordt.

**Peloton is terug als tabnaam, mét de introductie** op de lege staat, zodat
het niet meer koud binnenkomt.

## Wat de sweep opleverde dat niet in de opdracht stond

Drie plekken hielden hun eigen woordenlijst bij, en één was al afgedreven:

| Plek | Wat er stond | Waarom het wegkon |
|---|---|---|
| `tier*Agenda` (8 keys) | *Oké* naast *Acceptabel* | Bestond alleen om korter te zijn. Een oordeel dat per scherm anders heet is geen naam — set opgeheven, `_tierLabel()` wijst naar `tier*`. |
| `widget_update_service.dart` | *Geweldig* waar de app *Goed* zei | Hardgecodeerd, buiten elke l10n-sweep gebleven. Dit is óók waarom `widgetTier*` in de arb dood was: de widget leest die keys niet. |
| `notification_service.dart` | *rijmoment*, *rijoverzicht*, *Rijmeldingen* | Naslepers van schets 009, die dit bestand miste omdat de teksten hardgecodeerd zijn (#67). |

Verder:

- **De legenda in de Agenda is een `Wrap`.** Vier dots plus "Gepland" pasten bij
  20 tekens op een regel; bij 35 niet meer.
- **`detailTierAcceptableDesc`** zei "Te doen, pak een extra laag" — dubbelop
  zodra het label zelf *Te doen* heet. Nu "Pak een extra laag".
- **De avondmelding beloofde te veel.** "Perfecte omstandigheden verwacht" ging
  mee ongeacht de score, terwijl je die herinnering vanaf élk ritdetail zet.
  Die claim is eruit.
- **Eén test heette niet wat hij deed.** "Score-banner toont beschrijvingstekst
  voor Perfect" toetste in werkelijkheid het tier-woord. Toetst nu
  `detailTierPerfectDesc`.

## Nagekomen: de introductie bereikte niet wie hem nodig had

Op het toestel bleek de introductie achter het inloggen te zitten. Uitgelogd
toont het Peloton-tabblad `pelotonSignedOut` / `pelotonSignedOutHint`, en die
legden uit *waarom een account nodig is* — niet *wat een peloton is*. Precies
andersom: wie nog niet is ingelogd, is juist degene die het woord voor het eerst
ziet.

De definitie staat nu vooraan in de uitgelogde tekst:

> Een peloton is de groep waarmee je rijdt. Inloggen is nodig zodat je maatjes
> je kunnen vinden — de rest van de app werkt gewoon zonder.

Dit is precies het soort gat dat je alleen ziet door de app te openen. In de
tests stond niets fout; het scherm was gewoon nooit uitgelogd bekeken.

## Nog dood, bewust niet aangeraakt

`pelotonEmptyTitle` / `pelotonEmptyHint` — nul verwijzingen. Ze spreken de
nieuwe taal niet tegen, dus opruimen kan een keer mee met een andere ronde.

## Gate

`flutter analyze`: nul fouten. `flutter test`: 570 groen.
Web-build gemaakt en lokaal bekeken op poort 8766. **Niet gedeployed** — dat
wacht nog steeds op migratie 0007.
