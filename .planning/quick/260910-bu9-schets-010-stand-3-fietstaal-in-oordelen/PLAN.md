---
quick_id: 260910-bu9
slug: schets-010-stand-3-fietstaal-in-oordelen
date: 2026-09-10
sketch: 010
---

# Schets 010, stand 3 — fiets in de oordelen én de wegwijzers

Joost koos stand 3 op 2026-09-10. Het inzicht van de schets: "Peloton kwam uit het niets"
was geen verkeerd woord maar een **ontbrekende introductie**. Dus: de fietstaal gaat verder
de app in, en Peloton komt terug mét uitleg.

## A. De vier oordelen worden namen

| key-set | van | naar |
|---|---|---|
| `tierPerfect` | Perfect / Perfect | **Toprit** / **Top ride** |
| `tierGreat` | Goed / Great | **Fijne rit** / **Good ride** |
| `tierAcceptable` | Acceptabel / Acceptable | **Te doen** / **Doable** |
| `tierPoor` | Slecht / Poor | **Binnenblijver** / **Indoor day** |

Twee afgeleide ingrepen die hierbij horen:

1. **`tier*Agenda` verdwijnt.** Die aparte set bestond alleen om korter te zijn
   (*Oké* in plaats van *Acceptabel*). Een oordeel dat per scherm anders heet is geen naam.
   `_tierLabel()` in `week_agenda_screen.dart` en `planned_rides_screen.dart` wijst
   voortaan naar `tier*`; de acht keys gaan weg.
2. **De legenda in de Agenda wordt een `Wrap`.** Vier dots + labels + "Gepland" stonden in
   een `Row`. Met 20 tekens paste dat; met 35 loopt hij over. Zie
   `week_agenda_screen.dart:265`.

Ook: `detailTierAcceptableDesc` zegt nu "Te doen, pak een extra laag" — dat wordt dubbelop
zodra het label zélf *Te doen* heet. Wordt "Pak een extra laag".

`widgetTier*` is dood (nul verwijzingen in Dart, Kotlin of XML) maar wordt gelijkgetrokken,
zodat het de nieuwe namen niet tegenspreekt als het ooit aangesloten wordt.

## B. Peloton terug, mét introductie

- `ridesTabBuddies`: Maatjes → **Peloton** (EN: Buddies → Peloton — het is ook in het
  Engels een wielerwoord).
- Kruisverwijzingen mee: `pelotonNeedFriendsFirst`, `pelotonSignInToJoin`,
  `pelotonInviteShareLink`, `pelotonGoToPeloton`.
- **De introductie** landt op `pelotonNoFriends` / `pelotonNoFriendsHint` — dát is de lege
  staat die `buddies_tab.dart:246` toont, en precies het kader uit de schets:
  - "Je peloton is nog leeg"
  - "Een peloton is de groep waarmee je rijdt. Nodig een maatje uit en jullie zien elkaars ritten."

Het wóórd *maatje* blijft bestaan voor een persoon. Alleen de wegwijzer heet Peloton.

## C. Naslepers van schets 009 in de meldingen

Schets 009 maakte *fietsmoment* het standaardwoord, maar
`lib/platform/notification_service.dart` bleef buiten schot — die teksten staan hardgecodeerd
(backlog #67). *rijmoment* → *fietsmoment*, *rijoverzicht* → *fietsmomenten*,
*Rijmeldingen* → *Fietsmeldingen*.

Eén inhoudelijke correctie erbij: de avondmelding beloofde
"perfecte omstandigheden verwacht" ongeacht de score, terwijl je die herinnering vanaf
élk ritdetail zet — ook een Binnenblijver. Die claim gaat eruit.

Het lokaliseren van deze teksten blijft #67; dit is alleen de woordkeus.

## Gate

`flutter gen-l10n` → `flutter analyze` (nul fouten) → volledige testsuite (653 groen).
