# Openstaande punten

> **Stand 2026-09-21.** De secties vanaf "Openstaande punten (stand 2026-09-10)"
> verderop zijn van 10 september en gedeeltelijk achterhaald: de Play Developer
> API is inmiddels wél ingericht (punt I), de screenshots en de listing zijn
> vervangen, en de bundel staat allang in de Console. Lees eerst wat hieronder
> staat. Bij tegenspraak wint deze sectie.

---

## Hoe je dit oppakt, en met welke agent

Dit project wordt door twee agents bediend: **Claude Code** (leest `CLAUDE.md`)
en **Factory Droid** (leest `AGENTS.md`). Beide werken op dezelfde checkout.

De overdracht tussen die twee is **git, niet de prompt**. Dat betekent
praktisch:

1. Voordat je wisselt: commit alles, ook half werk. Een `wip:`-commit is beter
   dan een schone werkboom die de andere agent niet kan zien.
2. Wat je weet en niet in een bestand staat, is bij de volgende agent weg. Zet
   bevindingen in het bestand waar ze thuishoren (`.planning/debug/<slug>.md`
   voor een onderzoek, `STATE.md` voor een afgeronde taak, dit bestand voor wat
   blijft liggen), niet alleen in je antwoord.
3. Claude Code werkt via GSD-commando's (`/gsd-quick`, `/gsd-debug`,
   `/gsd-execute-phase`). Die schrijven hun eigen artefacten in `.planning/`.
   Droid heeft die commando's niet; laat Droid de artefacten wél lezen en
   bijwerken, anders lopen de twee uit elkaar.
4. Er staat een `ai`-switcher klaar die openstaand werk eerst vastlegt. Gebruik
   die in plaats van zomaar van terminal wisselen.

Elk punt hieronder is zo opgeschreven dat een agent die deze sessie niet heeft
meegemaakt er koud mee verder kan: wat er aan de hand is, wat al onderzocht is,
en wat de volgende stap is.

---

## 1. Het ongevraagde Google-inlogvenster bij het openen van Profiel

**Status: code opgelost, toestelcontrole nog open.** De oorzaak en fix zijn
vastgelegd in `.planning/debug/google-calendar-profile-prompt.md`.

### Oorzaak

De keten liep via `ProfileScreen.initState()` naar
`currentGoogleEmail()`, dat `attemptLightweightAuthentication()` aanriep.
`google_sign_in_android` 7.2.15 voert bij die methode na een mislukte
auto-select een tweede Credential Manager-flow uit. Die flow mag een
accountkiezer tonen. De oude code veronderstelde ten onrechte dat deze methode
altijd stil was.

### Fix

- Profiel gebruikt geen lightweight Google-authenticatie meer.
- De primaire Calendar-id wordt alleen na een expliciete Calendar-actie lokaal
  gecachet.
- De passieve mismatchcontrole leest die cache.
- Een succesvolle Calendar-disconnect wist de cache.
- Regressietests bewaken de cache en blokkeren de oude auth-route.

### Verificatie

- Volledige suite: **710 tests groen**.
- Gerichte tests en structuurtest: groen.
- `flutter build apk --release`: groen.
- `flutter analyze`: geen errors; 7 bestaande `info`-meldingen in
  `profile_screen.dart`.

De release-APK is bewust niet over de Play-installatie gezet, omdat sideloaden
de lokale database en Calendar-grant kan raken. Resterend: op de Oppo via de
normale Play-update bevestigen dat Profiel openen geen Google-venster meer toont.

---

## 2. Het patroon achter de bugs van 21 september: stille takken

**Dit is geen taak maar een staande zoekopdracht.** Neem hem mee bij elke
wijziging.

Op 2026-09-21 zijn drie bugs gevonden die allemaal dezelfde vorm hadden: een
tak die stil niets doet.

- `profile_screen.dart`: `if (await canLaunchUrl(uri))` zonder `else`. Gaf
  false, dus de privacy-link deed niets, zonder melding.
- `analytics_consent_sheet.dart`: `Navigator.pop()` stond achter een `await`
  die kon gooien. De kaart sloot nooit.
- `onboarding_screen.dart`: `context.go('/home')` stond achter awaits die
  konden gooien. Een nieuwe gebruiker kon vastlopen op het eerste scherm.

Geen van de drie geeft een fout, een log of een melding. Ze laten de gebruiker
achter met een scherm dat niet reageert, en ze zijn onzichtbaar in code review
en in de testsuite.

**Wat je zoekt:** elke navigatie- of sluitactie die achter een `await` staat, en
elke `if` rond een platform-aanroep zonder `else`. Vraag bij elk: wat ziet de
gebruiker als dit misgaat. Is het antwoord "niets", dan is het fout.

**Eerste uitvoering: 2026-09-21.** Tien plekken gedicht, zes daarvan in de
Peloton-flow. Zie `.planning/quick/260921-stille-takken-sweep/SUMMARY.md` en de
aanvulling onderaan `consent-card-en-privacy-link.md`.

Volledige uitwerking in `.planning/debug/consent-card-en-privacy-link.md`.

---

## 3. Feedbackadres in Play Console loopt niet gelijk met het privacybeleid

**Prioriteit: middel, maar nu urgent geworden.** Er zitten twintig testers in de
groep die straks iets willen melden.

- Play Console, Closed testing > Alpha > Testers, veld "Feedback URL or email
  address": `joostmouw@gmail.com`.
- `docs/privacy-policy.html` publiceert op vier plekken (account-verwijdering en
  Contact, in beide talen): `joost@fanalists.com`.

Fase 26 plan 03 adviseerde deze twee gelijk te trekken, met als argument dat één
adres voor de hele app minder fragmenteert dan drie. Dat advies is nooit
uitgevoerd.

**Beslissing die bij Joost ligt:** welk adres wint. Daarna aanpassen op de plek
die verliest. Het is een veld in de Console plus eventueel een tekstwijziging in
het privacybeleid.

---

## 4. De vastgeprikte "20 testers"-post op r/AndroidClosedTesting

**Prioriteit: laag, kost één blik.**

De vastgeprikte community-post van die subreddit heet "App testing requirements
for new personal developer accounts, a minimum of 20 testers". De hele
milestone-rekensom gaat uit van **twaalf**, wat is wat Play Console voor dit
project toont.

Vermoedelijk is de vastgeprikte post verouderd (Google verlaagde het aantal
medio 2025), maar dat is een aanname. Play Console is leidend. Eén controle
daar sluit het af. Als het tóch twintig is, verandert de rekensom in
`.planning/phases/27-wervingsonderzoek/27-KANALEN.md` en het doel van fase 30.

---

## 5. De toestand van de Oppo na 21 september

Twee dingen zijn veranderd door de screenshot-ronde en niet teruggezet, omdat
ze inloggen vereisen en dat bij Joost blijft:

- **Google Agenda staat op "Not connected".** Gevolg: de fietsmomenten zakten
  van 30 naar 15, want de agenda-blokken zijn weg. Herverbinden in Profiel.
- **De app staat op Engels.** Omzetten in Profiel, onderaan bij de taalkeuze.

Relevant voor wie hier verder test: de app staat op **1.0.36 (47)**, binnengekomen
als Play-update via de internal track. Dat pad behoudt de lokale database en de
grants; sideloaden over een Play-installatie heen doet dat niet.

---

## 6. Werving loopt, en wat er nu bewaakt moet worden

Stand 2026-09-21, 08:30.

- **De Google Groep `ridewindow-testers` telt 20 leden plus Joost.** Negen
  daarvan zijn de eigen kring (direct toegevoegd op 20 september), elf zijn
  vreemden die zich vanaf 15:55 op 20 september zelf hebben aangemeld, vrijwel
  zeker via r/AndroidClosedTesting.
- **De groep is sinds 21 september gekoppeld** aan de test-track in Play
  Console. Daarvoor stond de track op de e-maillijst, waardoor die elf
  zelf-joiners geen toegang hadden. Dat is opgelost.
- **Zeven persoonlijke mails** zijn op 20 september verstuurd naar de eigen
  kring, en **elf Engelse mails** op 21 september naar de nieuwe leden.
- **`e.j.heineke@gmail.com` staat op "bouncing"** in Google Groups. Die
  persoon is per mail niet te bereiken; via een ander kanaal benaderen.

**Wat bewaakt moet worden:** de Console-teller, niet het ledenaantal van de
groep. Lid zijn van de groep is niet hetzelfde als opt-in. Het verschil daartussen
is precies waar de eigen kring op vastliep (D-10). De veertien dagen beginnen pas
te tellen bij twaalf aangemelde testers, en wie tussentijds uitstapt breekt de
reeks.

**Let op bij de eigen kring:** de tien adressen in de Play-lijst zijn zeven
mensen. Twee mensen staan er met twee accounts in en één adres is Joost zelf.
Zie `.planning/phases/27-wervingsonderzoek/27-KANALEN.md` voor de gecorrigeerde
rekensom.

---

## 7. Fase 26 staat nog als open in de ROADMAP-checklist

De checklistregel voor fase 26 is niet afgevinkt, terwijl alle vier de plannen
een SUMMARY hebben en de meeste openstaande Console-punten op 20 en 21
september zijn afgerond:

- Landen/regio's staan op 177 van 177. **Gedaan.**
- Feedbackadres is ingevuld. **Gedaan**, zie punt 3 voor de vraag welk adres.
- Google Groep bestaat en is gekoppeld. **Gedaan op 21 september.**
- Release-route via internal. **Gedaan**, `tool/play_upload.dart` werkt.

Wat nog nagekeken moet worden voordat je de regel afvinkt: de **nl-NL
winkelpagina** (die ontbrak nog op 10 september) en de **changelog vanaf build
41**. Controleer die twee in de Console, vink dan af.

---

## 8. Promotiemateriaal: twee losse eindjes

`docs/promo/` bevat nu schermafdrukken in beide talen, plus logo,
feature-graphic en de intro-video. Zie `docs/promo/README.md`.

- **De afdrukken verouderen.** Home toont de week van 21 tot en met 27
  september en een geplande rit op maandag. Voor echte promotie wil je een week
  met louter groene dagen; maak dan nieuwe.
- **Er zijn drie varianten van de login-animatie** in `photos/`: gewoon, zonder
  watermerk, en "special edition". In `docs/promo/` staat de versie zonder
  watermerk. Joost heeft niet bevestigd dat dat de juiste is.

---

## 9. Oude debugsessie die nooit is afgerond

`.planning/debug/test-binding-state-leakage.md` staat sinds 2026-07-17 op
`awaiting_human_verify`. Het ging om 69 falende tests over 13 bestanden wanneer
de volledige suite in één proces draait.

**Dat symptoom bestaat niet meer:** op 2026-09-21 draait `flutter test` volledig
groen met 707 tests. Of dat komt doordat de oorzaak onderweg is weggewerkt of
doordat de tests zijn aangepast, is niet vastgesteld. Iemand moet die sessie
lezen, vaststellen wat er van de oorspronkelijke hypothese klopt, en hem sluiten
of heropenen. Een debugsessie die twee maanden op "wacht op verificatie" staat
is ruis in elke volgende zoektocht.

---

## 10. Waar de milestone staat

**v4.1 "Zo snel mogelijk live in de store"**, fases 26 tot en met 32.

| Fase | Stand |
|---|---|
| 26 Console op orde | Feitelijk af, checklistregel nog open, zie punt 7 |
| 27 Wervingsonderzoek | **Af** op 2026-09-20, beide plannen, `27-KANALEN.md` en `27-TEKSTEN.md` |
| 28 Feedbackstroom | Nog niet gepland. Volgende fase. |
| 29 Eerste minuut | Nog niet gepland |
| 30 Werving | Deels al uitgevoerd buiten de fase om: de eigen kring en de elf van Reddit zijn gemaild |
| 31 De veertien dagen | Loopt zodra de teller twaalf haalt |
| 32 Aanvraag en productie | Sluitstuk |

Volgende GSD-commando bij Claude: `/gsd-plan-phase 28`.

**Let op de volgorde in fase 30:** die gaat ervan uit dat de gekozen kanalen pas
na build 43 worden ingezet. Dat is inmiddels ingehaald door de werkelijkheid,
want de werving via Reddit loopt al. Fase 30 moet bij het plannen tegen die
stand aan gehouden worden in plaats van andersom.

## 11. Een Ridewindow-account zonder Gmail

**Status: gebouwd (2026-09-21), toestelcontrole open.** E-mail + wachtwoord
via Supabase' e-mail-authenticatie (elk geldig adres, geen Gmail nodig), als
tweede optie in Profiel naast "Inloggen met Google". Na succesvolle inlog
draait de app dezelfde afronding als na Google (accountwissel-check, sync,
naam-invulstap). Bevestigingsmail staat aan (dashboard-instelling): een nieuw
account moet eerst de mail aanklikken. Suite 727/727. Details en het
toestel-vervolg: `.planning/quick/260921-lokaal-account/SUMMARY.md`.

**Vervolg (later):** wachtwoord-vergeten-flow via Supabase's e-mail-trigger, en
een diep-link zodat de bevestigingsmail terug naar de app leidt in plaats van
naar de browser. Op dit project spel je die afwegingen door dezelfde checklist
als hieronder.

**Eerder onderzoek (oorspronkelijke notitie):** Naast Google-login moet een
gebruiker ooit kunnen kiezen voor een Ridewindow-account dat lokaal op de
telefoon wordt aangemaakt, zonder Google- of Gmail-account als voorwaarde.
Bij het oppakken eerst onderzoeken hoe andere apps dit oplossen, met aandacht
voor:

- account aanmaken en inloggen zonder Google;
- wachtwoordbeheer, passkeys of een andere lokale credential;
- herstel bij een verloren telefoon of vergeten credential;
- de verhouding tussen lokale brondata, Supabase-sync en accountwisselen;
- privacy, abuse-preventie en de extra supportlast.

**Beslissing 2026-09-21:** e-mail + wachtwoord via Supabase, géén
lokaal-op-toestel-account (die keuze vervalt het nut: cloudkopie, maatjes,
multi-device).

De keuze mag accounts niet verplicht maken: signed-out gebruik en de bestaande
Google-login blijven werken. Dit is eerst een product- en privacybeslissing,
geen dependency- of UI-taak.

---

## 12. De licentie van de intro-opname: opgelost op 2026-09-21

**Status: rond. De clip mag mee in een Play-upload.** De bron is
**Pixabay**, niet freesound:
<https://pixabay.com/sound-effects/bicycle-pedal-105846/>, geüpload door
`freesound_community` (oorspronkelijke opname van gerfaut83), 10 seconden,
wat klopt met de 10,4 s bronopname uit de taak. De licentie is de
**Pixabay Content License**: commercieel gebruik toegestaan, bewerken
toegestaan, naamsvermelding niet verplicht. Het enige verbod dat de
licentie kent is de opname op zichzelf doorverkopen, en dat speelt hier
niet: de clip zit bewerkt en ingebed in de intro.

Vastgelegd in `assets/sounds/WELCOME_ROLL-LICENSE.txt`, naast de asset,
zoals de fonts het ook doen. Geen credit-regel in de app nodig, geen
vervangende opname nodig.

**Hoe de bron gevonden is, want dit werkt bij elke volgende asset
waarvan de herkomst zoek is.** macOS bewaart bij een browserdownload de
bron-URL en de verwijzende pagina in een extended attribute:

```bash
xattr -p com.apple.metadata:kMDItemWhereFroms ~/Downloads/<bestand>
```

Dat gaf hier de CDN-link plus `https://pixabay.com/`. De nummering in de
bestandsnaam was juist het dwaalspoor: 105846 is een **Pixabay**-id, geen
Freesound-id, en daarom vond de vorige sessie op freesound.org een
synthesizer-kick van iemand anders. Kijk dus eerst naar de metadata van
het bestand en pas daarna naar de naam.

**Randzaken die hier nog naast liggen:** de Oppo staat op een lokale
sideload met verse data (agendakoppeling vervallen; de eerstvolgende
internal-release herstelt de Play-installatie, zie `STATE.md`), en de
e-mailaccount-flow van build 52 wacht nog op Supabase' maillimiet.

---

## 13. De intro-animatie heeft geen licentiebestand

**Eén vraag aan Joost, geen onderzoek.** `assets/animations/welcome_ride.webp`
is het enige overgebleven asset zonder vastgelegde herkomst. Commit
`02328fd` zegt "Joost leverde een animatie aan (10 s, 1280x720)", en het
bestand heeft geen download-metadata (de truc uit punt 12 levert hier
niets op). In `~/Downloads` staat wel `kan_je_daar_een_video_animatie.mp4`
van dezelfde dag, wat erop wijst dat de animatie zelf of met AI gemaakt is
en dus van Joost.

**Wat nodig is:** bevestiging dat de animatie eigen werk is. Dan een
regel ernaast zoals bij het geluid, en alle assets hebben een herkomst.
Is hij ergens vandaan gedownload, dan geldt dezelfde controle als bij
punt 12.

---

## Openstaande punten (stand 2026-09-10)


Opgemaakt 2026-09-10, bij het wissen van de context. Alles wat in de sessie van 8–10 september
open is blijven staan, plus wat er al lag. Gesorteerd op wat je als eerste tegenkomt, niet op
belang.

---

## 1. Blokkerend — allemaal weg op 2026-09-10

Migratie 0007 is gedraaid, de PWA is gedeployed, en de bundel staat op `1.0.30+41`.
Er is geen blokkade meer. Wat resteert is handwerk in de Play Console:

| | Wat | Waar het ligt |
|---|---|---|
| **A** | **Bundel 41 uploaden** | `~/Desktop/ridewindow-1.0.30-41.aab` |
| **B** | **Het app-icoon in de listing vervangen** — daar staat nu een plaatsaanduiding, een kalender met een potlood. Het echte RW-logo zit al wél in de app | `~/Desktop/ridewindow-store/play-store-icon-512.png` |
| **C** | **De vijf screenshots vervangen** — die in de winkel zijn van 21 juni en tonen een app die niet meer bestaat: smileys, dichtgroene kaarten, "RIJTIJDEN" | `~/Desktop/ridewindow-store/` |
| **D** | **Beide omschrijvingen overnemen** — de oude noemden "Zaterdag 09:00–13:00 — Perfect", kenden het daglicht niet en zwegen over samen fietsen | `docs/store-listing.md` |
| **E** | **De feature graphic** is ook nog van 21 juni | `docs/feature-graphic.png` |

**Let op bij versiecodes:** Play weigerde vandaag zowel code 30 als 31, terwijl commit
`2293358` beweerde dat 30 nooit geüpload was. De git-historie is hiervoor niet te
vertrouwen; de App bundle explorer in de Console wel. Vandaar de sprong naar 41.

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
| ~~**66**~~ | ~~Afgezegde ritten blijven onbereikbaar.~~ **Opgelost 2026-09-19** (`265e282`): eigen filter "Afgezegd", weg terug op het ritdetail. | v4.0 |
| ~~**67**~~ | ✅ **Opgelost 2026-09-19** (`3a1beaf`) — ~~Notificaties zijn hardgecodeerd Nederlands.~~ Zes teksten in `notification_service.dart`. De weg is bekend: `AppLocalizations.delegate.load(Locale(profile.locale))` levert een `S` zonder `BuildContext`. | v4.0 |
| **65** | **Epic "Peloton v2"** — meekijken zonder account, meerdere geschoorde vensters voorleggen, gedeelde beschikbaarheid, maatjes via gebruikersnaam. | v3.0 |

---

## 5. Losse einden zonder ticket

- **Er is geen push.** Een uitnodiging, een stem op een venster of een verzette tijd bereikt de ander pas als die de app zelf opent. Dat raakt slice 2 direct. Push vereist FCM (nieuwe dependency, Google-sleutel, derde sub-processor) of Supabase Realtime (geen nieuwe partij, maar werkt alleen met de app open). Beslissing staat open; zie slice 4 van [[65]].
- **`calendar_service.dart` zet nog `?km/u wind` in Google Calendar-events** -- hardgecodeerd Nederlands én in km/u. Ontsnapt aan zowel de i18n-sweep als de eenhedenkeuze van 2026-09-20.
- **De regentolerantie op de Oppo staat op 1,9 mm** door een verdwaalde tik tijdens de toestelronde; hij stond op 2,3. De temperatuur (12-30) is wel hersteld.

- ~~**De radii vormen geen systeem.**~~ ✅ **Opgelost 2026-09-19** — elke maat heeft een naam in `AppShapes` die zegt bij welk soort object hij hoort (hair/cell/xs/sm/md/lg/xl/panel/card). Nul hardgecodeerde radii over. Bewust **niet** naar de Material 3-schaal toegerekend: 24 op ritkaarten was een gemaakte keuze in v4.0.
- ~~**`ScoreBadge` staat naast `ScoreDisplay`**~~ — **nagekeken 2026-09-19: dit is opzet, geen drift.** `score_display.dart` legt uit dat de badge blijft voor de compacte plekken waar een hele regel niet past; hij staat op de PLANNED-rijen en in de detail-AppBar. Niets aan gedaan.
- **iOS-verificatie:** vijf vinkjes in `19-auth/REGRESSION-CHECKLIST.md`, geen iPhone in het project.
- ~~**De flaky notificatietest**~~ ✅ **Opgelost 2026-09-19** (`637ca34`) — de slotdag ligt twee dagen vooruit in plaats van een, dus "de avond ervoor" is altijd toekomst. Het waren er inmiddels drie: de taaltests van #67 erfden dezelfde opzet. De verwachte datum wordt nu uitgerekend zoals de service het doet, wat meteen de tweede bug in die test dicht (de eerste van de maand).
- **Het privacybeleid belooft twaalf maanden bewaartermijn voor `app_events`, en niets dwingt dat af.** Er is geen opruimtaak: `service_role` heeft sinds `6475504` alleen SELECT, geen DELETE, en migratie 0008 houdt die weg bewust dicht. Zolang de eerste rij van september 2027 nog niet bestaat is er geen haast, maar de belofte staat wel al gepubliceerd.
- **De PWA-cache.** De eerste herlaad na een deploy gaf op 8 september de **oude** bundel terug, inclusief een gebrek dat net gerepareerd was. De server had het goede bestand (byte-identiek nagemeten). Deel een link dus altijd mét `?v=N` of ⌘⇧R erbij.

---

## 6. Twee dingen die je niet opnieuw moet uitvinden

1. **Ga niet terug naar de gesloten zonsopgangsvergelijking** omdat hij korter is. Hij zat er 104 seconden naast in Amsterdam en 175 op Tromsø, en de fout groeit met de breedtegraad en rond de equinox. `daylight.dart` rekent nu de zonshoogte uit en zoekt per seconde de horizon: binnen 53 seconden.
2. **Meet leesbaarheid altijd in béide helderheden.** Dezelfde klacht kwam op 8 september twee keer; de eerste keer was het de dekking, de tweede keer wél de kleur — 1,21:1 in donkere modus tegen 9,63:1 in lichte. Een scherm dat zijn achtergrond hardcodeert moet zijn voorgrond ook vastzetten (`BrandCanvas`).
