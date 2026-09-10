# Openstaande punten

Opgemaakt 2026-09-10, bij het wissen van de context. Alles wat in de sessie van 8–10 september
open is blijven staan, plus wat er al lag. Gesorteerd op wat je als eerste tegenkomt, niet op
belang.

---

## 1. Blokkerend — afgehandeld op 2026-09-10

| | Wat | Stand |
|---|---|---|
| **A** | Migratie 0007 (`darkness_weight`) | **Gedraaid** door Joost in het Supabase-dashboard. Profiel-upserts kunnen weer. |
| **B** | PWA verouderd | **Gedeployed** — https://my-project-joost.web.app draait nu het daglicht én de fietstaal. Deel de link met ⌘⇧R erbij. |
| **C** | Play-bundel verouderd | **Herbouwd** als `1.0.29+30` (die versie was klaargezet maar nooit geüpload, dus hergebruikt). Release-notities bijgewerkt en binnen de Play-limiet van 500 tekens gebracht — ze stonden er met 736 en 645 al overheen. **Uploaden wacht nog op je akkoord (punt E).** |

## 2. Beslissingen die op jou wachten

| | Wat | Stand |
|---|---|---|
| **D** | ~~Schets 010 — hoeveel fietstaal, en waar.~~ **Gekozen op 2026-09-10: stand 3**, gebouwd en gedeployed (`1bf942d`). Oorspronkelijke tekst:** Drie standen geschetst: (1) fiets in de toon, (2) ook in de oordelen (*Toprit / Fijne rit / Te doen / Binnenblijver*), (3) ook in de wegwijzers (*Peloton* terug, mét introductie). | **Afgerond.** Je ging destijds verder met Ingrids feedback. Mijn aanbeveling was **stand 3**. Het inzicht van de schets: "uit het niets" was geen verkéérd woord maar een **ontbrekende introductie** — Peloton stond op een tabblad zonder dat de app het ooit uitlegde. Zeven woorden op de lege staat repareren dat. |
| **E** | **Play-upload zelf.** | Wacht op jouw akkoord ná de PWA-ronde. |
| **F** | **Blok 4 van schets 009 — de toon.** *Nachtuil*, *Weekendstrijder*, *TOLERANTIES*, *RIJLENGTE*, "plan de route strategisch". | Je koos bewust **niets**. Ligt uitgeschreven klaar in schets 009 als je erop terug wilt komen. |

---

## 3. Niet geverifieerd — gebouwd maar niet met eigen ogen gezien

| | Wat | Wat ervoor nodig is |
|---|---|---|
| **G** | **De vier rolregels op échte data** (schets 008: wacht op jou / jij organiseert / je gaat mee / alleen jij). | Twee ingelogde accounts. In widget-tests vastgelegd, maar niemand heeft ze met echte maatjesritten gezien. Loop dan ook na: nodig iemand uit vanaf een rit die je al gepland had — dat hóórt één kaart te blijven, niet twee. |
| **H** | **Niets is op de Oppo gedraaid.** Deze hele sessie zat er geen toestel aan. | Veeggedrag op de nieuwe rittenlijst, de daglichtbalk, de vierde schuif en de afzeg-dialoog zijn alleen in Chrome gezien. Je eigen afspraak: aanraken en scrollen verifieer je via adb op de Oppo. `~/Library/Android/sdk/platform-tools/adb`. |
| **I** | **De Play Developer API is nog niet ingericht.** `tool/play_upload.dart` is geschreven en getest tot aan de authenticatie. | Twee rechtenwijzigingen op je Play-account. Daarna is uploaden één commando in plaats van een handmatige ronde. Stond al open vóór deze sessie. |
| **J** | **`joost.oppo` opnieuw inloggen en controleren of hij in je maatjeslijst verschijnt.** | Toetst het vangnet uit `ef391bf` (de mislukte `onSignIn` waarvan de oorzaak nooit is gevonden — het symptoom is gedicht, de oorzaak niet). Stond al open. |

---

## 4. Backlog — inhoudelijk open

| # | Wat | Herkomst |
|---|---|---|
| **69** | **De lijst toont losse vensters, niet het groene blok.** Ingrid kreeg op één zaterdag 09:00–11:00 (100), 06:00–09:00 (99) én 11:00–13:00 (95) achter elkaar. Geen fout — `dedup` doet zijn werk — maar een ánder model dan dat van de gebruiker: de app beantwoordt *"welk venster van N uur is het beste"*, zij vraagt *"wanneer is het vandaag goed en hoe lang kan ik weg"*. | Ingrid, 2026-09-09 |
| **70** | **Waarom dít venster en niet dat ernaast.** Haar vermoeden klopte — 09:00–11:00 scoort echt hoger dan 08:00–11:00 — maar het weggegooide alternatief en zijn score zijn onzichtbaar. `insights_sheet.dart` legt al uit waarom een score die score is; dit is de buurman-vraag. | Ingrid, 2026-09-09 |
| **63** | **iPhone-tester komt niet terug uit het beschikbaarheidsscherm.** Niet op te lossen zonder iPhone; de knop bestáát in alle drie de takken, dus het is een safe-area-kwestie op iOS-standalone. | v4.0 |
| **66** | **Afgezegde ritten blijven onbereikbaar.** De snackbar met ongedaan-maken dekt de misklik, niet "morgen toch wel". | v4.0 |
| **67** | **Notificaties zijn hardgecodeerd Nederlands.** Zes teksten in `notification_service.dart`. De weg is bekend: `AppLocalizations.delegate.load(Locale(profile.locale))` levert een `S` zonder `BuildContext`. | v4.0 |
| **65** | **Epic "Peloton v2"** — meekijken zonder account, meerdere geschoorde vensters voorleggen, gedeelde beschikbaarheid, maatjes via gebruikersnaam. | v3.0 |

---

## 5. Losse einden zonder ticket

- **De radii vormen geen systeem.** 24 op ritkaarten, 18 op detail- en sectiekaarten, 16 op PLANNED-regels, 12 en 3 elders. Material 3 kent 12, 16 en 20 — **18 en 24 zijn geen token**. Een aparte opruimronde waard.
- **`ScoreBadge` staat naast `ScoreDisplay`** in `features/shared/`, twee vormtalen naast elkaar, nooit tegen het papier-uiterlijk gehouden.
- **iOS-verificatie:** vijf vinkjes in `19-auth/REGRESSION-CHECKLIST.md`, geen iPhone in het project.
- **De flaky notificatietest** (`scheduleEveningBefore tijdberekening`) faalt na 19:00 UTC. Op 10 september 's ochtends slaagde hij. Geen regressie, wel een test die van de klok afhangt.
- **De PWA-cache.** De eerste herlaad na een deploy gaf op 8 september de **oude** bundel terug, inclusief een gebrek dat net gerepareerd was. De server had het goede bestand (byte-identiek nagemeten). Deel een link dus altijd mét `?v=N` of ⌘⇧R erbij.

---

## 6. Twee dingen die je niet opnieuw moet uitvinden

1. **Ga niet terug naar de gesloten zonsopgangsvergelijking** omdat hij korter is. Hij zat er 104 seconden naast in Amsterdam en 175 op Tromsø, en de fout groeit met de breedtegraad en rond de equinox. `daylight.dart` rekent nu de zonshoogte uit en zoekt per seconde de horizon: binnen 53 seconden.
2. **Meet leesbaarheid altijd in béide helderheden.** Dezelfde klacht kwam op 8 september twee keer; de eerste keer was het de dekking, de tweede keer wél de kleur — 1,21:1 in donkere modus tegen 9,63:1 in lichte. Een scherm dat zijn achtergrond hardcodeert moet zijn voorgrond ook vastzetten (`BrandCanvas`).
