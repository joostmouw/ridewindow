---
slug: consent-card-en-privacy-link
status: resolved
trigger: "Tester Androidguju67 meldt twee bugs in 1.0.35+46. (1) De toestemmingskaart \"Help make the app better?\" sluit niet bij \"No thanks\" noch bij \"Yes, go ahead\"; na de app killen en herstarten is de vraag wel weg. (2) Privacy Policy in Profiel opent een \"free weather api\"-pagina in de in-app browser in plaats van het privacybeleid."
created: 2026-09-21
updated: 2026-09-21
reporter: Androidguju67 (externe tester, geworven via r/AndroidClosedTesting)
build: 1.0.35+46
---

# Debug: toestemmingskaart sluit niet, privacy-link opent Open-Meteo

Twee onafhankelijke bugs uit dezelfde melding. Ze delen geen oorzaak maar wel
een sessie, omdat ze samen in een van de eerste indrukken van een nieuwe tester
zitten: de eerste knop die hij indrukt doet niets, en de link die zijn privacy
moet uitleggen wijst naar een weer-API. Beide raken vertrouwen, niet alleen
functionaliteit.

## Symptomen

### Bug 1 — toestemmingskaart sluit niet

| Vraag | Antwoord |
|---|---|
| Verwacht | Tik op "No thanks" of "Yes, go ahead": de keuze wordt opgeslagen en de kaart verdwijnt meteen. |
| Werkelijk | Beide knoppen doen zichtbaar niets. De kaart blijft staan. |
| Foutmelding | Geen gemeld. Tester zag geen crash, geen snackbar. |
| Tijdlijn | Gebouwd in de analytics-quicktask van 2026-09-19. Eerste externe melding op 1.0.35+46. Nooit op een echt toestel door een ander dan Joost bediend. |
| Reproductie | App openen tot de kaart verschijnt (tweede start, zie `AnalyticsConsentStore.kAskAtOpenCount`), dan op een van beide knoppen tikken. |
| Belangrijk detail | Na de app volledig killen en opnieuw openen is de vraag **weg**. De keuze is dus wél gepersisteerd; alleen het sluiten van het venster gebeurt niet. |

### Bug 2 — Privacy Policy opent Open-Meteo

| Vraag | Antwoord |
|---|---|
| Verwacht | Profiel → Privacy Policy opent `https://joostmouw.github.io/ridewindow/privacy-policy.html`. |
| Werkelijk | Er opent een pagina over een "free weather api" in de in-app browser (Chrome Custom Tab). |
| Foutmelding | Geen. |
| Tijdlijn | De URL-constante is in juli gecorrigeerd (F-8, `docs/CONSOLE-SETUP-CHECKLIST.md`). Deze melding is nieuw. |
| Reproductie | Profiel openen, op de rij "Privacy Policy" tikken. |

## Beginhypothesen (van de orkestrator, nog niet getoetst)

### H1 — bug 1: `Navigator.pop()` wordt nooit bereikt

`lib/features/shared/analytics_consent_sheet.dart` doet in `answer()`:

```dart
await ref.read(analyticsConsentProvider.notifier).setConsent(granted);
if (sheetContext.mounted) Navigator.of(sheetContext).pop();
```

`setConsent` staat in `lib/providers/analytics_provider.dart:35-46` en doet drie
dingen ná de lokale schrijfactie: `flushPending()` (in try/catch), en daarna
`ref.invalidateSelf()`. Regel 36 is `final store = _store ?? await future;`.

Kandidaten die het `await` nooit laten terugkeren of laten gooien, terwijl de
schrijfactie op regel 37 al geslaagd is:
- `await future` blijft hangen als de provider zelf nog aan het laden is
- `ref.invalidateSelf()` gooit of laat de await hangen doordat de notifier
  zichzelf ongeldig maakt terwijl de aanroeper er nog op wacht
- `sheetContext.mounted` is false geworden door de invalidatie, waardoor de
  `pop()` bewust wordt overgeslagen

Dat laatste past het beste op de waarneming: keuze opgeslagen, venster blijft
staan, en na een herstart is de vraag weg.

**Te toetsen:** wat gebeurt er precies tussen regel 37 en de `pop()`. Een test
die `answer()` draait en controleert of de route daadwerkelijk gepopt wordt, is
het bewijs. Dit is ook de reden dat de bug nooit is opgevallen: er is geen test
die het sluiten van dit venster afdwingt.

### H2 — bug 2: `canLaunchUrl` geeft false, gebruiker ziet de buurman

`profile_screen.dart:80-85`:

```dart
final uri = Uri.parse(_kPrivacyPolicyUrl);
if (await canLaunchUrl(uri)) {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

Geen else. Geeft `canLaunchUrl` false, dan gebeurt er niets en krijgt de
gebruiker geen enkel signaal. De ListTile direct eronder (regel 1266-1270) roept
`launchUrl(Uri.parse('https://open-meteo.com/'))` aan **zonder** die guard en
**zonder** `LaunchMode.externalApplication`, dus die opent wel, en wel in een
in-app tab. open-meteo.com heet op zijn homepage letterlijk "Free Weather API".

Dat verklaart de melding zonder dat er een URL verwisseld hoeft te zijn: de
privacy-rij doet niets, de gebruiker tikt door of interpreteert de pagina die
hij vervolgens ziet als het resultaat van zijn vorige tik.

**Waarom `canLaunchUrl` false zou geven:** op Android 11+ vereist package
visibility een `<queries>`-blok in `AndroidManifest.xml` voor
`android.intent.action.VIEW` met scheme `https`. Zonder dat blok geeft
`canLaunchUrl` false, ook als er een browser op het toestel staat. Dit manifest
heeft in deze maand al een keer een ontbrekende declaratie gehad die pas op een
echt toestel zichtbaar werd (de workmanager-receiver, `7bb52c9`).

**Te toetsen:** staat er een `<queries>`-blok in `android/app/src/main/AndroidManifest.xml`.
Dat is een kwestie van kijken, geen experiment.

**Let op bij de fix:** als H2 klopt, is de guard zelf het echte probleem, niet
alleen het manifest. Een link die stil niets doet is in elke situatie fout. De
fix hoort beide te raken: het manifest aanvullen én de stille tak vervangen door
of een poging zonder guard, of een zichtbare melding als openen echt niet lukt.

## Consistentie-sweep (verplicht bij de fix)

Dit project kent de regel dat een wijziging niet af is tot de rest van de app op
hetzelfde patroon is nagelopen. Concreet voor deze twee:

1. **Elke andere `canLaunchUrl`-guard in de app** heeft dezelfde stille tak.
   Zoek ze allemaal op en behandel ze gelijk.
2. **Elk ander modaal venster dat na een async actie sluit** kan dezelfde
   volgorde-fout hebben als bug 1. `feedback_dialog.dart`,
   `invite_buddies_sheet.dart` en de onboarding zijn de eerste plekken om te
   kijken.
3. **De drie plekken waar het privacybeleid-adres staat** (app, winkelpagina,
   OAuth-toestemmingsscherm) horen gelijk te lopen; de commentaarregel bij
   `_kPrivacyPolicyUrl` zegt dat zelf.

## Current Focus

```yaml
reasoning_checkpoint:
  hypothesis: >
    Bug 1: setConsent() gooit een UnmountedRefException op ref.invalidateSelf().
    analyticsConsentProvider is auto-dispose (Riverpod 3-standaard) en wordt
    alleen via ref.read() aangesproken, dus hij heeft geen luisteraar en wordt
    weggegooid zodra de read klaar is. Na de twee awaits in setConsent is de Ref
    niet meer mounted. De uitzondering ontsnapt uit setConsent, waardoor de
    await in answer() gooit en Navigator.pop() nooit wordt uitgevoerd. De
    schrijfactie ervoor is al geslaagd, dus de keuze staat wel in prefs.
    Bug 2: canLaunchUrl geeft false. Het manifest heeft wel een <queries>-blok,
    maar alleen voor PROCESS_TEXT; url_launcher_android brengt zelf geen queries
    mee. Op targetSdk 35/36 verbergt package visibility daarmee elke browser.
    De privacy-rij doet stil niets; de Open-Meteo-rij eronder heeft geen guard
    en geen externalApplication, opent dus wel, en wel in een Custom Tab.
  confirming_evidence:
    - "Widgettest reproduceert beide knoppen: UnmountedRefException op analytics_provider.dart:45, stacktrace loopt via answer() op analytics_consent_sheet.dart:29. Kaart blijft staan, prefs bevat de keuze."
    - "Profiel roept dezelfde setConsent aan vanuit een ref.watch(analyticsConsentProvider) in dezelfde build. Daar is de provider wel mounted en werkt het. Dat verklaart waarom dit nooit is opgevallen."
    - "url_launcher_android-6.3.32/android/src/main/AndroidManifest.xml bevat geen <queries>. Het app-manifest declareert alleen PROCESS_TEXT."
    - "targetSdk = flutter.targetSdkVersion (35/36), dus ruim boven API 30 waar package visibility geldt."
  falsification_test: >
    Bug 1 zou weerlegd zijn als de test de kaart wel ziet sluiten, of als de
    uitzondering ergens anders vandaan kwam dan invalidateSelf. Bug 2 zou
    weerlegd zijn als url_launcher_android zijn eigen queries meebracht, of als
    canLaunchUrl op API 30+ ook zonder queries true gaf.
  fix_rationale: >
    Bug 1: invalidateSelf achter een ref.mounted-guard. Is de provider al weg,
    dan is er niemand om in te lichten en is overslaan de volledige oplossing.
    Daarbovenop try/finally in de kaart, zodat het sluiten nooit meer aan het
    slagen van de boekhouding erna hangt. Twee lagen omdat het sluiten van dit
    venster het enige is wat de gebruiker ziet.
    Bug 2: <queries> aanvullen met ACTION_VIEW/https (de oorzaak) en de stille
    tak vervangen door een poging plus een zichtbare melding (het echte
    probleem). Beide rijen door dezelfde helper, want twee naast elkaar
    staande rijen met hetzelfde pijltje horen zich hetzelfde te gedragen.
  blind_spots: >
    De manifest-wijziging is niet in een unittest te bewijzen; die is alleen op
    een echt toestel te zien. Daarom is de tweede laag (geen stille tak) de
    laag die wel getest wordt. Verder is niet bewezen dat de tester werkelijk
    op de Open-Meteo-rij tikte; dat blijft de meest waarschijnlijke lezing,
    maar na de fix is de vraag sowieso weg omdat een mislukte poging nu spreekt.
```

## Evidence

- timestamp: 2026-09-21, bron: orkestrator, read-only codelezing
  `_kPrivacyPolicyUrl` (profile_screen.dart:56-57) bevat het juiste adres. De
  melding gaat dus niet over een verkeerde constante. Dat sluit de meest voor de
  hand liggende verklaring meteen uit en stuurt naar de guard.

- timestamp: 2026-09-21, bron: orkestrator, read-only codelezing
  De ListTile "Privacy Policy" en de ListTile "Weather data" staan direct naast
  elkaar (profile_screen.dart:1261-1270), met verschillende launch-strategieen:
  de eerste met guard en `externalApplication`, de tweede zonder guard en zonder
  mode. De tester meldt een **in-app** browser, wat past bij de tweede.

- timestamp: 2026-09-21, bron: tester Androidguju67
  Na killen en herstarten is de toestemmingsvraag weg. De keuze is dus
  gepersisteerd. Dit is het belangrijkste onderscheidende feit voor bug 1: het
  sluit alle hypothesen uit waarin de knop-handler helemaal niet draait.

- timestamp: 2026-09-21, bron: observatie AndroidManifest.xml
  Er staat wel een `<queries>`-blok, maar het declareert uitsluitend
  `PROCESS_TEXT` (het blok dat `flutter create` meelevert voor de tekstselectie
  van de engine). Er is geen `<intent>` voor `android.intent.action.VIEW` met
  scheme `https`. De helft van H2 is daarmee in een minuut bevestigd.

- timestamp: 2026-09-21, bron: ~/.pub-cache/.../url_launcher_android-6.3.32
  Het manifest van de plugin zelf declareert alleen een `WebViewActivity` en
  geen enkele `<queries>`. De app moet het dus zelf doen. `targetSdk` volgt
  `flutter.targetSdkVersion` (35/36), ruim boven API 30. `canLaunchUrl` geeft
  daarom false, ook met Chrome op het toestel.

- timestamp: 2026-09-21, bron: widgettest, directe reproductie
  Beide knoppen laten de kaart staan, precies zoals gemeld. De oorzaak is
  zichtbaar in de stacktrace: `UnmountedRefException: Cannot use the Ref of
  analyticsConsentProvider after it has been disposed`, gegooid op
  `analytics_provider.dart:45` (`ref.invalidateSelf()`), ontsnappend via de
  `await` in `answer()` op `analytics_consent_sheet.dart:29`. De
  `Navigator.pop()` op regel 30 wordt daardoor nooit bereikt. `prefs` bevat na
  afloop wel de keuze, want die schrijfactie staat voor de uitzondering. Dit
  verklaart de melding volledig, inclusief "na herstarten is de vraag weg".

- timestamp: 2026-09-21, bron: codelezing analytics_provider.dart
  `analyticsConsentProvider` is auto-dispose (de Riverpod 3-standaard) en wordt
  op de kaart-route uitsluitend met `ref.read()` benaderd -- door `main.dart:117`,
  `home_screen.dart:180` en de kaart zelf. `read` laat geen luisteraar achter,
  dus de provider wordt direct na elke read weggegooid. Na de twee awaits in
  `setConsent` is de Ref dood.

- timestamp: 2026-09-21, bron: codelezing profile_screen.dart:707-720
  Profiel roept dezelfde `setConsent` aan, maar vanuit een `Consumer` die
  `ref.watch(analyticsConsentProvider)` doet. Daar houdt de watch de provider
  in leven, is `ref.mounted` true, en werkt alles. Dat is precies de reden dat
  deze bug nooit door de eigenaar is gezien: de enige route die hij zelf
  gebruikt, is de route die wel werkt.

## Eliminated

- hypothesis: "De privacy-URL-constante in de app is verkeerd."
  reason: "profile_screen.dart:57 bevat https://joostmouw.github.io/ridewindow/privacy-policy.html, het adres dat ook op de winkelpagina staat. Gecontroleerd op 2026-09-21."

- hypothesis: "De knop-handlers van de toestemmingskaart zijn niet aangesloten (het letterlijke vermoeden uit de melding: ontbrekende onPressed)."
  reason: "analytics_consent_sheet.dart heeft op beide knoppen een onPressed die answer(false) respectievelijk answer(true) aanroept. Bovendien blijkt uit de melding zelf dat de keuze wordt opgeslagen, wat alleen kan als de handler draait."

## Resolution

root_cause: |
  Twee onafhankelijke oorzaken, beide bevestigd door directe waarneming.

  Bug 1. `AnalyticsConsent.setConsent` eindigde op `ref.invalidateSelf()`.
  `analyticsConsentProvider` is auto-dispose en wordt op de route van de
  toestemmingskaart uitsluitend met `ref.read` benaderd (main.dart:117,
  home_screen.dart:180, de kaart zelf), dus hij heeft geen luisteraar en wordt
  na elke read opgeruimd. Na de awaits in `setConsent` is de Ref dood en gooit
  `invalidateSelf()` een `UnmountedRefException`. Die ontsnapte via de `await`
  in `answer()` uit de methode, waardoor `Navigator.pop()` op de regel erna
  nooit werd bereikt. De schrijfactie naar prefs stond ervoor en was al
  geslaagd -- vandaar dat de keuze wel bewaard bleef en de vraag na een
  herstart weg was. Profiel roept dezelfde `setConsent` aan vanuit een
  `ref.watch`, waar de provider wel in leven blijft; dat is de enige route die
  de eigenaar zelf gebruikte en dus waarom dit drie weken onopgemerkt bleef.

  Bug 2. Er is geen URL verwisseld. `_launchPrivacyPolicy` stond achter
  `if (await canLaunchUrl(uri))` zonder `else`. Op targetSdk 35/36 verbergt
  package visibility elke browser tenzij het manifest `<queries>` declareert
  voor `VIEW` met scheme `https`. Het manifest had wel een `<queries>`-blok,
  maar alleen het `PROCESS_TEXT`-blok dat `flutter create` meelevert, en
  `url_launcher_android` brengt zelf niets mee. `canLaunchUrl` gaf dus false,
  de rij deed stil niets, en de tester tikte door naar de rij eronder. Die
  rij, Open-Meteo, had geen guard en geen `LaunchMode.externalApplication`,
  opende dus wel en wel in een Custom Tab -- met "Free Weather API" bovenaan.

fix: |
  Bug 1 (commit 1), twee lagen:
  - `analytics_provider.dart`: `invalidateSelf()` achter `if (ref.mounted)`.
    Is de provider weg, dan luistert er niemand en valt er niets in te lichten.
  - `analytics_consent_sheet.dart`: `try/catch/finally`. De kaart sluit nu
    ongeacht de afloop; een fout wordt via `FlutterError.reportError` gemeld in
    plaats van doorgegooid, want doorgooien liet hem verdwijnen in de
    weggegooide Future van `onPressed`.

  Bug 2 (commit 2):
  - `AndroidManifest.xml`: `<queries>` aangevuld met `VIEW` + scheme `https`.
  - `profile_screen.dart`: `canLaunchUrl`-guard weg. Een nieuwe helper
    `_openExternal` probeert te openen, en meldt het met een SnackBar plus een
    kopieerknop als dat niet lukt. Beide rijen (Privacy Policy en de weerbron)
    lopen nu door diezelfde helper en openen allebei extern.
  - Drie nieuwe strings in EN en NL.
  - `docs/CONSOLE-SETUP-CHECKLIST.md`: F-8 heropend en opnieuw gesloten met de
    werkelijke oorzaak.

  Consistentie-sweep (commit 3):
  - `onboarding_screen.dart`: `_handleNext` had dezelfde vorm als bug 1 --
    `context.go('/home')` stond achter awaits die konden gooien, dus een fout
    bij het wegschrijven van het preset zette een nieuwe gebruiker vast op het
    eerste scherm. Nu in een `finally`, met de fout gemeld.

verification: |
  Alle drie de fixes hebben een regressietest die faalt op de oude code en
  slaagt op de nieuwe, elk gecontroleerd door de oude versie terug te zetten:
  - `test/features/shared/analytics_consent_sheet_test.dart` (3 tests): 3 falen
    voor, 3 slagen na.
  - `test/features/profile_screen_links_test.dart` (4 tests): 3 falen voor
    (test 1 slaagde al, want in de fake gaf `canLaunch` true), 4 slagen na.
  - `test/features/onboarding_screen_test.dart` test 4: nieuw.
  Volledige suite: 703 tests, alles groen. `flutter analyze` op de gewijzigde
  bestanden levert geen nieuwe meldingen (7 bestaande in profile_screen, zowel
  voor als na).

  Op het toestel: de release-APK bouwt en `aapt2 dump xmltree` toont het
  `VIEW`-intent met scheme `https` in de samengevoegde manifest van het
  uiteindelijke artefact. De manifest-helft is daarmee tot aan het artefact
  geverifieerd.

  Niet gedaan, met opzet: de APK op de Oppo zetten. Daar staat een
  Play-installatie, en van Play naar sideload vereist deinstalleren, wat de
  lokale Drift-database en de Calendar-OAuth-grant wist. Dat is een keuze voor
  Joost, geen bijwerking van een bugfix.

  Wat alleen een mens kan bevestigen: dat de kaart op het toestel werkelijk
  sluit bij een tik, en dat de privacy-rij een browser opent. Daarom staat de
  tweede laag van bug 2 er ook: lukt openen toch niet, dan zegt de app het nu
  in plaats van te zwijgen.

files_changed:
  - lib/providers/analytics_provider.dart
  - lib/features/shared/analytics_consent_sheet.dart
  - lib/features/profile/profile_screen.dart
  - lib/features/onboarding/onboarding_screen.dart
  - android/app/src/main/AndroidManifest.xml
  - lib/l10n/app_en.arb
  - lib/l10n/app_nl.arb
  - docs/CONSOLE-SETUP-CHECKLIST.md
  - test/features/shared/analytics_consent_sheet_test.dart
  - test/features/profile_screen_links_test.dart
  - test/features/onboarding_screen_test.dart

sweep_resultaat: |
  1. Andere `canLaunchUrl`-guards: geen. Dit was de enige in de hele app
     (`grep -rn canLaunchUrl lib/` gaf precies één treffer). De tweede
     `launchUrl` zonder guard, Open-Meteo, is meegenomen in de fix.
  2. Andere modals die na een async actie sluiten: één echte treffer,
     `onboarding_screen.dart:_handleNext` (gefixt, commit 3).
     Nagelopen en in orde bevonden: `feedback_dialog.dart` (leest navigator en
     messenger vóór de await en heeft een volledige try/catch met melding),
     `app_tour_overlay.dart` (`markTourSeen()` wordt niet afgewacht, de pop is
     synchroon), `invite_buddies_sheet.dart`, `insights_sheet.dart`,
     `week_agenda_screen.dart` en de city picker in Profiel (allemaal
     synchrone pops). Het verborgen debugmenu in Profiel heeft dezelfde vorm
     (`await` dan `if (ctx.mounted) pop()`), maar is alleen bereikbaar via vijf
     tikken op het versienummer en raakt geen gebruiker; bewust gelaten.
  4. Extra, niet gevraagd maar wel gevonden: de manifest-toelichting die bij
     deze fix hoorde gebruikte `--` als gedachtestreepje, wat in XML binnen een
     comment verboden is. De manifest was daarmee onparseerbaar en
     `assembleRelease` viel om met alleen "Error parsing". Geen enkele test of
     analyze-stap keek hiernaar. Er staat nu een structuurtest op
     (`test/structure/manifest_well_formed_test.dart`) die parseert, apart op
     `--` in comments controleert (het xml-pakket slikt dat, AGP niet) en het
     queries-blok zelf bewaakt.

  3. De drie plekken met het privacy-adres lopen gelijk: de constante in
     `profile_screen.dart:57`, de Store-listing en het OAuth-toestemmingsscherm
     hebben alle drie `https://joostmouw.github.io/ridewindow/privacy-policy.html`
     (`docs/CONSOLE-SETUP-CHECKLIST.md` regel 22 en 98). De pagina is live
     gecontroleerd op 2026-09-21: HTTP 200. Hier was dus niets te repareren.

## Verificatie op het toestel (2026-09-21, orkestrator)

De sessie stond op `awaiting_human_verify` omdat de debugger de APK bewust niet
wilde sideloaden: dat kost op dit toestel de lokale database en de
Calendar-grant. Die afweging is omzeild door via de Play-API te releasen, zodat
het toestel de build als gewone update kreeg.

**Eerst de bugs gereproduceerd op 1.0.35 (46)**, de build die op dat moment bij
de testers stond. Dit ontbrak nog: tot dan toe rustte de diagnose op codelezing
en tests, niet op waarneming van het uitgeleverde artefact.

- Bug 1: tik op "Nee, liever niet" liet de kaart onveranderd staan. Na
  `am force-stop` en opnieuw openen was de vraag weg, wat bevestigt dat de
  schrijfactie wel landde en alleen de `pop()` niet.
- Bug 2: tik op "Privacybeleid", daarna `dumpsys activity activities`. De
  `topResumedActivity` was nog steeds
  `ridewindow.joost.amsterdam/MainActivity`. Er opende geen browser. Dat is een
  meting, geen interpretatie, en sluit de lezing uit waarin de rij wel opent
  maar naar het verkeerde adres wijst.

**Daarna 1.0.36 (47) geverifieerd**, geinstalleerd via de internal track.

- Bug 2: Joost bevestigde dat het privacybeleid nu opent.
- Bug 1: toestemming gereset via Profiel > 5x versienummer > "Reset
  usage-statistics consent", daarna twee keer koud gestart (de vraag komt bij
  de tweede start, `kAskAtOpenCount = 2`). Kaart verscheen, tik op "No thanks",
  kaart sloot meteen.

**Uitgerold:** 1.0.36 (47) via `tool/play_upload.dart` naar internal, daar
geverifieerd, en als dezelfde bytes gepromoveerd naar alpha. Beide tracks staan
op 47.

## Wat deze sessie over het proces leert

Beide bugs waren onzichtbaar voor code review en voor de testsuite, en beide
hadden dezelfde vorm: **een tak die stil niets doet**. Een `if` zonder `else`,
en een `pop()` achter een await die kon gooien. Geen van beide geeft een fout,
een log of een melding; ze laten de gebruiker achter met een scherm dat niet
reageert.

De sweep vond er een derde van precies dezelfde soort in `onboarding_screen.dart`,
op de plek waar een nieuwe gebruiker voor het eerst iets indrukt. Dat is geen
toeval maar een patroon dat het waard is om actief op te zoeken bij elke
volgende wijziging: waar staat er een navigatie of een sluitactie achter een
await, en wat gebeurt er als die await gooit.

En tot slot: dit is gevonden door een vreemde, niet door Joost. Joost weet waar
hij moet drukken en wat er hoort te gebeuren. Dat is precies de blindheid die
externe testers opheffen, en het argument om er meer te hebben.

## Vervolg-sweep 2026-09-21 (OPEN.md punt 2, tweede ronde)

De eerste sweep heeft de drie bekende gevallen gedicht; deze ronde herhaalde de
zoektocht over heel `lib/` met dezelfde vraag: wat ziet de gebruiker als dit
misgaat. Gevonden en gedicht (10 plekken; zes daarvan in de Peloton-flow die nu
bij twintig testers op de gesloten test draait):

- Stille falers in `planned_rides_screen.dart` (`respond`, `chooseOption`),
  `ride_detail_screen.dart` (`_respondToRide`, inclusief de valkuil dat de
  succesmelding van `_withdrawFromRide`/`_rejoinRide` na een mislukking niet
  meer verschijnt — `_respondToRide` geeft nu `bool` terug),
  `invite_buddies_sheet.dart` (maatjes ophalen + vensters voorleggen stonden
  buiten de try/catch), `buddies_tab.dart` (`_shareInvite`, `removeFriend`),
  `account_section.dart` `_confirmAndSignOut`, en de geweigerde
  notificatiepermissie in Profiel.
- Navigatie achter een schrijffout: `welcome_screen.dart` `_goToSignIn` en de
  onboarding-knop in `availability_screen.dart` navigeren nu in `finally`.

Volledige lijst, bewezen regressietests (4 nieuw, suite 714/714) en wat bewust
niet is veranderd: `.planning/quick/260921-stille-takken-sweep/SUMMARY.md`.

**Zoekpatroon blijft staan:** bij elke wijziging controleren op `if (await …)`
zonder `else`, navigatie/sluiten achter `await`, en netwerk- of platform-
aanroepen zonder catch in button-handlers. De vorige aanname dat `_pickWindows`'
switch kon gooien bleek onjuist (sealed `SlotsState` heeft één subtype) — de
aanroepende plek is ingepakt, de switch zelf niet.
