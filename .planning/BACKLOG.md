# Backlog: RideWindow Post-v1

Items voor na de v1 internal testing release. Geprioriteerd in horizonnen: v1.x (snelle iteraties na feedback), v2 (grote features), v3+ (toekomstvisie).

---

## v1.x — Quick wins na validatie

Kleine verbeteringen die snel uit te rollen zijn op basis van eerste tester-feedback.

| # | Item | Waarde | Effort | Status |
|---|------|--------|--------|--------|
| 1 | **Android home screen widget** — toont volgende ride slot op een oogopslag | HOOG | M | Done (2691d59) |
| 2 | **Windrichting indicator op ride cards** — "meewind/tegenwind retour" label | MEDIUM | S | Done (2c7738c) |
| 3 | **"Feels like" op home card chips** — apparent temperature zichtbaar zonder detail te openen | MEDIUM | S | Done (2c7738c) |
| 4 | **Settings export/import** — JSON-bestand als poor man's backup zonder backend | LAAG | S | Backlog |
| 5 | **Pull-to-refresh op Home** — handmatige forecast refresh naast achtergrond-refresh | HOOG | S | Done (ca6f0f8) |
| 6 | **Buienradar / Windy deep-link** — "Bekijk radar" knop op Ride Detail voor live regenradar | LAAG | S | Backlog |
| 7 | **Onboarding skip + undo** — mogelijkheid om onboarding over te slaan en later in te stellen | LAAG | S | Backlog |
| 8 | **Haptic feedback** — subtiele vibratie bij slider-drempels en chip-toggles | LAAG | S | Done (ca6f0f8) |
| 9 | **Accessibility audit** — screenreader labels, contrast ratio's, touch targets >=48dp. **Opgelost (2026-07-18/19, quick-260718-f1m, zie `.planning/quick/260718-f1m-backlog-9-accessibility-audit-screenread/`):** app had 0 Semantics-widgets. Toegevoegd: tooltips/Semantics-labels op 9 icon-only knoppen + de twee custom grid-cellen (Availability 7x24, Agenda 7x17) — de kern-interacties waren voorheen 100% onbruikbaar via screenreader. Touch targets: Availability-cellen/headers en Agenda-rijen naar 48dp (Agenda-grid omgezet naar scrollbare vaste-hoogte-rijen i.p.v. Expanded), Profile info-knop 28dp→48dp, Onboarding terug-knop default hersteld. Contrast: `acceptableFg` (3.46:1→5.11:1) en `textHint` licht+donker (2.85:1/3.62:1→beide >4.5:1) gecorrigeerd in `app_colors.dart`. Eén productiewijziging (`ride_detail_screen.dart`: tooltips op 5 iconen, geen gedragswijziging). `flutter test` bevestigd op 282/2 na merge (identiek aan #11's eindstand, geen regressie) | HOOG | M | Opgelost |
| 10 | **Crashlytics / analytics** — Firebase free tier voor crash reports en usage metrics | MEDIUM | M | Backlog |
| 11 | **Test coverage inhaalslag** — openstaande widget tests (Phase 4-05), weather_repository tests, profile scroll tests. **Aanvulling (quick-260714-nfk):** `profile_screen_notif_test.dart` faalt zelfstandig (los van eigen wijzigingen bevestigd via git-bisectie) met "Bad state: No element" / `S.of(context)` null-check-crashes wanneer meerdere Profile-scherm test-bestanden in hetzelfde `flutter test`-proces draaien; `ride_detail_screen_test.dart` toont los ook 13 falende tests. Vermoedelijke oorzaak: Flutter SDK-versiedrift sinds deze tests geschreven zijn, of localization-delegate/test-binding state-lekkage tussen test-bestanden — nader te onderzoeken. **Aanvulling (Phase 17-01, 2026-07-17):** volledige `flutter test`-baseline vastgesteld: 215 passing / 69 failing over 13 bestanden — `ride_detail_screen_test.dart` (13), `insights_sheet_test.dart` (13), `availability_screen_test.dart` (11-12, licht wisselend), `profile_screen_test.dart` (5), `profile_screen_notif_test.dart` (5), `weather_repository_test.dart` (3-5, licht wisselend), `home_screen_test.dart` (4), `detail/ride_detail_screen_calendar_test.dart` (4), `onboarding_screen_test.dart` (3), `welcome_screen_test.dart` (2), `home_screen_location_test.dart` (2), `providers/integration_test.dart` (1), en incidenteel `core/pwa_display_mode_test.dart` of `providers/slots_notifier_test.dart` (1) — de totalen (215/69) zijn stabiel over herhaalde runs maar de exacte verdeling over 2-3 bestanden wisselt licht per run, wat de vermoede test-binding/localization state-lekkage tussen bestanden bevestigt. Geen van deze falingen is veroorzaakt door Phase 17 (geen source-wijzigingen in die plan). **Opgelost (2026-07-18, debug-sessie `test-binding-state-leakage`, zie `.planning/debug/resolved/test-binding-state-leakage.md`):** oorzaak was NIET cross-file state-lekkage (die hypothese is expliciet weerlegd) maar 4 gestapelde lagen van dezelfde bugklasse — testbestanden misten app-level config die productie wel heeft (localizationsDelegates/supportedLocales, theme-extension, ProviderScope, locale:) — plus ~8 losse, onafhankelijke drift-issues (verouderde tekst/asserties) die pas zichtbaar werden nadat de lagen eronder gefixed waren. 215/69 → 282/2. De laatste 2 (`providers/slots_notifier_test.dart`, `providers/integration_test.dart`, beide dezelfde assertie over SlotsNotifier-herberekening) zijn een apart, nog niet onderzocht probleem — bewust buiten scope gehouden, mogelijk een aparte toekomstige debug-sessie waard. Eén productiewijziging: `lib/features/detail/ride_detail_screen.dart` kreeg een additionele, optionele `notificationServiceFactory`-DI-parameter (spiegelt bestaand `calendarServiceFactory`-patroon) | HOOG | M | Grotendeels opgelost — 282/2, restant apart probleem |
| 12 | **Scoring engine v2 tuning** — kalibratie op basis van echte tester-feedback ("score zei 85 maar het was koud") | HOOG | M | Done (1be0b62) |
| 13 | **Kledingadvies-tip** — korte aanbeveling per slot op basis van temperatuur, windchill en regen (bijv. "Armwarmers + windjack") | MEDIUM | S | Done (2c7738c) |
| 14 | **Persoonlijke begroeting op Home** — tijdsafhankelijke greeting met naam ("Good morning Joost", "Welcome back Joost") | MEDIUM | S | Done (2c7738c) |
| 15 | **Drag-to-select beschikbaarheid** — sleep over meerdere cellen om ze in een keer te togglen + rij/kolom-headers om hele dag/uur te selecteren | HOOG | M | Done (2c7738c) |
| 16 | **Debug/reset menu** — verborgen menu (5x tik op versienummer) met reset onboarding, wis cache, reset beschikbaarheid, forceer refresh | MEDIUM | S | Done (2c7738c) |
| 17 | **Los tikken/slepen op aaneensluitende uren moet samensmelten tot één tijdvak (Availability + Agenda)** — *(verduidelijkt n.a.v. quick-260714-o54 test-feedback, was: "drag werkt niet")*. Opgelost via een twee-tik-bereik model: 1e tik opent een blok, 2e tik (zelfde dag) vult het bereik aan tot aan de vaste ankertik; sleepgebaar op Availability blijft daarnaast bestaan. Toegepast op zowel de Availability-grid als de Agenda-tab (waar long-press nu ook overal weer-detail-info toont i.p.v. sleep-selectie) | HOOG | M | Done (e5a3683, 52495b9) |
| 18 | **Verlopen tijden grijs tonen in Agenda** — tijdstippen die al voorbij zijn moeten visueel duidelijk gemarkeerd worden (bijv. grijze kleur) in plaats van er hetzelfde uit te zien als toekomstige tijden | MEDIUM | S | Backlog |
| 19 | **Verlopen ride-slots verbergen op Home** — Home-scherm moet alleen ride-vensters tonen waarvan de starttijd nog moet komen; slots waarvan de starttijd al voorbij is moeten niet meer op Home verschijnen. **Opgelost (2026-07-25, quick-260725-knl):** `notBefore`-parameter op `SlotGenerator.generate()`, gevoed door de nieuwe `nowProvider`. Werkt in één keer door op Home, Agenda en de home-screen widget, want alle drie draaien dezelfde pipeline | MEDIUM | S | Opgelost (93efbf8) |
| 31 | **Google OAuth consent screen publiceren (of volledig laten verifiëren)** — Calendar-koppeling (CAL-06/07) werkte alleen voor handmatig toegevoegde test-users. **Update (2026-07-17):** Publishing status stond al op **"In production"** (User type: External, waarschijnlijk al zo gezet tijdens Phase 15) — Joost hoefde dus niet meer zelf op "Publish app" te klikken. **Belangrijke nuance (Joost's eigen correctie):** "In production" betekent NIET dat de gebruikerscap weg is — Google's OAuth user cap van 100 unieke gebruikers (lifetime van het project) blijft gelden zolang de `calendar.events`-scope (Sensitive) niet formeel door Google geverifieerd is, ongeacht publishing status. "In production" scheelt alleen dat gebruikers niet meer vooraf als test-user hoeven te worden toegevoegd. Voor een klein persoonlijk project met vrienden is 100 gebruikers ruim voldoende, dus dit is geen praktische blokkade — maar het is niet "onbeperkt". Volledige Google-verificatie (verwijdert de cap + de "niet geverifieerd"-waarschuwing) blijft een aparte, bewust nog niet gekozen optie voor als de 100-cap ooit in zicht komt | HOOG | S/M | Done — already in production; 100-user lifetime cap remains until/unless full Google verification is pursued |
| 33 | **Feedback-formulier voor gebruikers** — "Send feedback"-entry in Profile opent dialog met 1-5 sterren-rating + vrije tekst, verstuurd via mailto: naar joostmouw@gmail.com (geen backend, geen nieuwe dependency) | HOOG | S | Done (9d9d5ab) |
| 34 | **"Plan ride"-knop sticky op Ride Detail** — *(gecorrigeerd, was verkeerd toegeschreven aan Availability — die knop bestaat daar niet)*. Op Ride Detail (lang scherm: Adjust Time → Weather → Hourly-tabel → Plan ride) moet de groene "Plan ride"-knop onderin vastgeplakt (sticky) blijven tijdens het scrollen/aanpassen, i.p.v. pas zichtbaar na volledig doorscrollen. Uitgebreid met een reactieve "Planned" + vinkje-status wanneer het venster al gepland is, en unplan/delete (met bevestiging) vanaf zowel Ride Detail als Home | MEDIUM | S | Done (0b56a92, a109aa2, 5ce3e6e) |
| 35 | **Live teller "X losse tijdvakken" tijdens selecteren op Availability** — tijdens het aanvinken/slepen in de wekelijkse beschikbaarheids-grid toont de app hoeveel losse (niet-aaneengesloten) tijdvakken je nu hebt geselecteerd. Geen claim over exact aantal ritten (dat bepaalt de score-engine later, elders) — puur een live selectie-indicator | MEDIUM | S | Done (1703d60, e5a3683) |
| 36 | **Google Calendar-koppeling zichtbaar/beheerbaar in Profile** — nieuwe "Google Calendar"-rij in Profile's OVER-sectie toont Connected/Not connected (boolean, geen e-mailadres beschikbaar via de scope-only OAuth-flow) via `authorizationForScopes` (prompt-vrije check), met een "Disconnect"-actie via `GoogleSignIn.instance.disconnect()` | MEDIUM | S | Done (8fd1e99) |
| 37 | **Regen-icoontje verschijnt bij droog weer** — root cause: het regenwolk-emoji stond hardcoded in alle takken van de neerslag-tekst in Ride Detail's Hourly-tabel, inclusief de "dry"-tak. Uitgebreid met zon (☀️) bij droog + geen regenkans, en licht-bewolkt (⛅) bij droog + 1-30% regenkans (proxy voor bewolking, want geen echte cloud-cover data beschikbaar) | HOOG | S | Done (c5967b9) |
| 38 | **Tip: Google-account koppelen in iOS Agenda-instellingen** — tester-observatie (Phase 15 iPhone-verificatie): een aangemaakt Calendar-event staat wél in Google Calendar maar niet automatisch in de native iPhone Agenda-app, tenzij het Google-account is toegevoegd via iOS Instellingen → Agenda → Accounts. Overweeg een korte in-app tip/uitleg hierover (bijv. na eerste "Add to calendar" op web/iOS) zodat gebruikers niet denken dat de koppeling niet werkt | LAAG | S | Backlog |
| 49 | **Onboarding coach-marks zijn te doorzichtig** — tester-feedback (Slack, 2026-07-25): "the onboarding steps are too see-through, makes them hard to read". Bevestigd op de meegestuurde schermfoto (`/Users/joostmouw/Documents/O+ Connect/IMG_2991.jpg`): de "Filter by day" (1/3) coach-mark laat de ride-cards en dag-chips eronder doorschijnen, waardoor titel en body-tekst slecht leesbaar zijn. Fix-richting: hogere scrim-opacity achter de overlay, of een ondoorzichtige tonal surface (MD3 surfaceContainerHigh) achter de coach-mark-kaart i.p.v. semi-transparant | HOOG | S | Backlog |
| 50 | **"Tap share icon"-banner dismissible of mee-scrollend maken** — tester-feedback (Slack, 2026-07-25): de banner bovenaan staat permanent vast en "eats away at space you could use for the rest of the content". Twee opties: (a) een X-knop rechts om hem te sluiten (voorkeur van de tester), of (b) hem mee laten scrollen met de content zodat hij wegscrolt bij naar beneden scrollen. Kleinere, losstaande variant van #51 | MEDIUM | S | Backlog |
| 51 | **Navigatie herstructureren: top app bar met logo + Profile, bottom nav naar 3 tabs** — tester-voorstel (Slack, 2026-07-25) als alternatief voor #50, uitgetekend op `/Users/joostmouw/Documents/O+ Connect/IMG_2991.jpg`: top app bar met het logo links en de Profile-knop rechts (pijl op de foto wijst Profile van onder naar boven), waardoor de bottom nav terugvalt naar drie ride/planning-specifieke tabs (Home, Agenda, Rides). Profile functioneert dan meer als algemene instellingen, uit de weg van de dagelijkse flow. De "tap share icon"-banner uit #50 wordt in dat geval een van de onboarding-stappen i.p.v. een permanente banner. Raakt routing (`go_router` shell) + meerdere schermen, dus duidelijk groter dan #50 — kies één van beide, niet allebei | MEDIUM | M | Backlog |
| 53 | **Testers werven voor de closed test — poort naar productie, én de eerste promotieronde** — Play Console eist vóór "Apply for access to production" een closed test met **minimaal 12 opted-in testers, doorlopend minstens 14 dagen**. Stand op 2026-07-26: **4 testers opted-in** — er zijn er dus nog 8 nodig, en de 14-dagenklok begint pas echt te lopen als die 12 er staan. Bij de aanvraag worden ook vragen over de closed test gesteld (Play Console biedt een "Preview questions"-link — vooraf doornemen). **Reddit is hier het werkinstrument, niet alleen het lanceerkanaal:** subreddits met wielrenners/woon-werkfietsers (denk r/cycling, r/bicycling, r/Netherlands, r/Amsterdam, r/Wielrennen) zijn zowel de plek om die 8 testers vandaan te halen als straks het publiek voor de echte lancering. Twee losse momenten dus: (a) nu — wervingspost gericht op testers, met de opt-in-link; (b) later — lanceringspost als de app in productie staat. Let op de regels per subreddit: veel fietssubreddits weren kale self-promotion, dus post als "ik bouwde dit voor mezelf, zoek testers" en niet als advertentie; check per subreddit de zelfpromotie-regels en of er een vaste dag/thread voor is | HOOG | M | Backlog |
| 52 | **Draaiende wielen bij de fietser op het welkomstscherm** — tester-wens (Joost, 2026-07-25): de wielen van de fietser op "Your perfect ride moment" moeten draaien alsof hij rijdt, en de haren subtiel wapperen in de wind. **Onderzocht en geblokkeerd op de huidige aanpak:** het welkomstscherm toont de 🚴-emoji (`welcome_screen.dart`), en dat is geen plaatje dat de app bezit maar een glyph die het besturingssysteem tekent — Android gebruikt Noto Color Emoji, macOS/iOS gebruikt Apple Color Emoji met andere vorm, kleuren en wielpositie, en de Flutter-testomgeving rendert zelfs een leeg vierkantje. Een draaiend wiel dat op één platform precies over het grijze wiel valt, staat op een ander platform ernaast. Uitlijnen op de emoji kan dus principieel niet. **Twee werkende routes:** (a) een vaste illustratie meeleveren in `assets/` — dan staat de wielpositie overal gelijk en kan er tot op de pixel een draaiend wiel overheen; Noto's fietser mag meegeleverd worden (Apache/OFL), Apple's artwork niet. (b) Een eigen merkillustratie in `#234934`, in lagen gesplitst zodat wielen en haar apart animeerbaar zijn — past ook beter bij de nieuwe merkstijl, want de emoji is bont waar de rest van de app twee groentinten gebruikt. **Afgekeurd:** een met de hand getekende fietser via `CustomPainter`. Het lijnwerk-fiets*frame* met spaakwielen zag er goed uit, maar de rijder las als een hoekige donkere wig in plaats van een persoon; zes rondes coördinaten bijstellen met visuele verificatie per ronde brachten daar geen verbetering in. Bij een herstart: begin bij een echte illustratie, niet bij stokfiguur-streken. Losse spaken zijn wel nodig — een draaiende cirkel zonder spaken is niet van een stilstaande te onderscheiden — en geef het haar een eigen cyclus die geen veelvoud is van die van de wielen, anders oogt de beweging mechanisch | LAAG | M | Backlog |
| 55 | **Inloggen vindbaarder maken zonder het te verplichten** — de accountfunctie zit nu volledig weggestopt in Profile, dus wie er niet naar zoekt ontdekt nooit dat instellingen tussen telefoon en laptop kunnen meereizen. Ontstaan uit Joost's vraag (2026-08-04) of de app niet gewoon met een loginscherm moet openen. **Dat is bewust afgewezen en moet afgewezen blijven:** `REQUIREMENTS.md` regel 8 legt vast dat accounts strikt additief zijn — *"A user who never signs in must notice no change whatsoever. Nothing that works today may start requiring an account."* Een loginmuur zou (a) de privacyclaim onwaar maken dat data uitgelogd het toestel nooit verlaat — die staat letterlijk in het gepubliceerde privacybeleid, (b) het grootste deel van fase 21 overbodig én onjuist maken, want die hele fase bestaat om uitgelogd-werken te behouden, en (c) precies de drempel opwerpen waar nieuwe gebruikers afhaken bij een app die zich in tien seconden moet bewijzen. **Wel te doen:** een eenmalige, wegklikbare uitnodiging die pas ná een paar sessies verschijnt (niet bij eerste start — dan concurreert hij met onboarding), met een concrete belofte in plaats van "maak een account": iets als "Je instellingen ook op je laptop? Log in met Google". Eén keer wegklikken = nooit meer tonen, opslaan in SharedPreferences naast de bestaande onboarding-vlaggen. Overweeg als tweede, rustiger plek een regel in Profile die uitlegt wát inloggen oplevert in plaats van alleen een knop. Raakt #49/#50 qua patroon (wegklikbare hints) — als die twee samen worden opgepakt, dit meenemen in dezelfde stijl | MEDIUM | S | Backlog |
| 54 | **PWA-URL van `my-project-joost.web.app` naar `ridewindow.web.app`** — de huidige URL komt van de Firebase project-ID die ooit bij het aanmaken is gekozen; de default hosting-site erft die letterlijk. Project-ID's zijn onveranderlijk, dus hernoemen kan niet — maar één project kan meerdere hosting-sites hebben, dus `firebase hosting:sites:create ridewindow` geeft `ridewindow.web.app` als die naam globaal vrij is (niet vooraf te checken zonder hem te claimen). **Drie dingen moeten mee, anders breekt er iets:** (a) `firebase.json` een `"site": "ridewindow"` geven, anders blijft `deploy-web.yml` naar de oude site deployen; (b) `ridewindow.web.app` toevoegen aan de authorized domains van de Google OAuth-client — zonder dat breekt Google-login op de PWA onmiddellijk, en dat is precies het soort fout dat pas op een toestel zichtbaar wordt; (c) de URL-verwijzingen in `.planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md` §3 en §5 bijwerken. Bewust uitgesteld op 2026-08-04 tot ná de fase-21-toestelsessie, omdat die sessie juist tegen de bestaande URL draait. Overweeg meteen of een echt eigen domein niet logischer is dan een tweede `.web.app`-subdomein | LAAG | S | Backlog |
| 56 | **`currentGoogleEmail()` toont wél een Google-venster op Android** — gevonden op toestel 2026-08-05 (zie `MANUAL-VERIFICATION-21.md`, device session 4). `lib/services/calendar_service.dart:275-290` documenteert de methode als *"ZONDER ooit een OAuth-prompt/popup te tonen (D-11, AUTH-07)"*, maar `GoogleSignIn.instance.attemptLightweightAuthentication()` loopt op Android via Credential Manager, en die toont `AssistedSignInActivity` ("Signing you in.") zodra hij niet precies één geautoriseerd account kan auto-selecteren — wat bij meerdere Google-accounts op het toestel de regel is, niet de uitzondering. Keten: `ProfileScreen.initState()` → `_checkCalendarConnection()` → `_checkCalendarMismatch()` → `currentGoogleEmail()`. Reproduceert alleen bij een koude start (initState draait één keer); tabwisselen doet het niet. Cosmetisch — de login verandert niet — maar een al ingelogde gebruiker een sign-in-venster tonen bij het openen van Profiel is verkeerd, en erger: de code gaat er aantoonbaar van uit dat dit niet kan gebeuren, dus de aanname staat ook in het commentaar dat toekomstige lezers misleidt. **Richtingen:** (a) de mismatch-check verplaatsen naar een moment dat de gebruiker zelf uitlokt in plaats van `initState()`; (b) het e-mailadres van de agenda-koppeling cachen bij het koppelen, zodat de vergelijking geen live Google-aanroep nodig heeft; (c) als het venster onvermijdelijk blijkt, minstens het commentaar en D-11/AUTH-07 corrigeren zodat de belofte klopt. Begin met (b) — die haalt de aanroep helemaal weg uit het opstartpad | MEDIUM | S | Backlog |
| 57 | **Elke koude start schrijft profiel én beschikbaarheid opnieuw naar Supabase** — waargenomen 2026-08-05: twee opeenvolgende koude starts logden allebei `drain done — 2 pending, 2 sent (profile, availability), 0 failed` zonder dat er iets gewijzigd was. Er wordt dus bij elke app-start geënqueued en verstuurd. Functioneel correct (`0 failed`, en de upsert is idempotent), maar het zijn netwerkschrijfacties zonder aanleiding: het kost dataverkeer, het zet `updated_at` in Postgres op elke start — waardoor die kolom niet meer bruikbaar is als "wanneer wijzigde de gebruiker dit echt" — en het maakt logdiagnose lastiger, want een drain met werk is niet te onderscheiden van een drain zonder. Uitzoeken waar de enqueue vandaan komt (vermoedelijk `enqueueCurrentState()` op het sign-in/reconcile-pad dat ook bij een bestaande sessie draait) en alleen enqueuen bij een echte wijziging **Opgelost 2026-09-03** (quick 260903-bey, `1ac8f3f`) — en het vermoeden in dit item was fout. `enqueueCurrentState()` hangt uitsluitend aan `SyncDecision.pushLocalToCloud` en draait alleen bij het inloggen. De echte oorzaak is een lus die zichzelf voedt: de reconcile neemt een nieuwere cloud-rij over met `save(stamp: false)`, maar `save()` enqueuede onvoorwaardelijk — de `stamp`-vlag dekte de tijdstempel wel en de enqueue niet. De drain duwt de rij terug omhoog, de trigger `profiles_set_updated_at` (`before update`) zet `updated_at = now()`, en de volgende koude start ziet de cloud opnieuw als nieuwer met het hele verstreken tijdsverschil. Dat maakte `updated_at` onbruikbaar als invoer voor `resolveAccountSync()`, wat zwaarder weegt dan het dataverkeer. `save()` heeft nu een eigen `enqueue`-vlag; de vier plekken die een cloud-rij overnemen geven `enqueue: false`. Bewust niet aan `stamp` gekoppeld — `setUserNameFromSignIn()` schrijft met `stamp: false` én moet de cloud wél bereiken; daar staat een test op. Meetbaar geworden dankzij #60, en de test faalt aantoonbaar zonder de fix | MEDIUM | S | Opgelost (1ac8f3f) |
| 58 | **Agenda-events staan altijd in het Nederlands, ongeacht de app-taal** — gevonden op toestel 2026-08-05: de app draaide in het Engels, maar het aangemaakte Google Calendar-event heette "Fietsrit 12:00–15:00" met omschrijving "~24°C, droog, 7km/u wind". Twee hardcoded plekken in `lib/services/calendar_service.dart`: de titel op regel ~188 (`'Fietsrit ...'`) en `buildWeatherSummary()` (`'droog'`, `'km/u wind'`, `'Geen weerdata beschikbaar'`). Geen van beide loopt via de l10n-laag, terwijl de rest van de app EN/NL-pariteit heeft (380/380 sleutels). **Waarom dit is blijven liggen is het interessante deel:** `buildWeatherSummary` is bewust een `static` pure functie zonder `BuildContext` — precies wat hem makkelijk unit-testbaar maakte (`calendar_service_test.dart` test hem direct) — en precies daardoor is hij nooit langs `AppLocalizations` gekomen. Dezelfde eigenschap die de test mogelijk maakte, hield de vertaling buiten de deur. **Fix:** de opgemaakte strings als parameters injecteren of een `S`-instantie meegeven aan de aanroeper, zodat de functie puur blijft én vertaald wordt; de bestaande tests kunnen dan met een expliciete vertaaltabel draaien in plaats van met de Nederlandse literals | MEDIUM | S | Backlog |
| 59 | **Agenda-events gebruiken een hardcoded `Europe/Amsterdam`** — `calendar_service.dart:197` en `:201` zetten `EventDateTime(timeZone: 'Europe/Amsterdam')` vast. Voor een gebruiker buiten die zone komt het event op het verkeerde tijdstip in zijn agenda te staan, en dat is een correctheidsfout, geen cosmetische. Anders dan #58 is dit geen ontbrekende vertaling maar een verkeerde aanname over waar de gebruiker is — dezelfde categorie als de rideId-tijdzonebug uit plan 21-13, en daarmee het derde tijdzone-incident in deze codebase. **De fix ligt al klaar:** `main.dart:44` haalt de echte IANA-zone van het toestel op via `FlutterTimezone.getLocalTimezone()` voor de notificaties. Diezelfde waarde doorgeven aan `EventDateTime` volstaat. Overweeg meteen of die zone niet één keer centraal beschikbaar gemaakt moet worden in plaats van per aanroeper opnieuw opgehaald — dan is er ook één plek om naar te kijken als er een vierde tijdzonebug opduikt | MEDIUM | S | Backlog |
| 60 | **`CloudSyncReconciler` injecteerbaar maken — vijf keer op rij de beperkende factor**. **Opgelost 2026-09-03** (quick 260903-b44, `8c04df9`): de cloudkant loopt door een nieuwe `CloudSyncGateway` (zes leden, elk precies één bestaande aanroep) met `SupabaseCloudSyncGateway` als productie-default, in het DI-patroon dat `AccountSyncService` en `RideDetailScreen` al gebruikten. Bewust géén mock van `SupabaseClient` — die heeft een fluent builder, dus dan toets je de builder. `cloud_sync_reconciler_gateway_test.dart` legt nu vast wat voorheen alleen een toestelsessie kon zien: push-vóór-pull (21-14), twee drains per cyclus, dat de opstart-reconcile werkelijk leest, en 21-13's reparatie van niet-canonieke `ride_id`'s — dat laatste pad is op een echt toestel niet meer uit te lokken. Geen gedragswijziging; suite 459/459 | HOOG | M | Opgelost (8c04df9) |
| 61 | **Een verse installatie haalt geplande ritten niet op tot de app eenmaal is weggezet** | HOOG | S | Backlog |
| 63 | **Tester op iPhone komt niet terug uit het beschikbaarheidsscherm** — gemeld 2026-09-06 via WhatsApp, met screenshot. Route: Profiel → "Edit my schedule" (`profile_screen.dart:831`, `context.push('/availability')`). De tester: *"Ik kan niet terug uit dit scherm"* en *"Wel met swipe"* — de iOS-veegterug werkt dus wel, alleen de knop is onvindbaar. **Wat de code zegt, en waarom dat het interessante deel is:** `availability_screen.dart` heeft in alle drie zijn takken (loading/error/data) een gewone vaste `AppBar` met `leading: const SafeBackButton()`, en `SafeBackButton` rendert altijd een icoon — `arrow_back` als er te poppen valt, anders `home_outlined`. Er ontbreekt dus geen knop. Op de screenshot begint de inhoud (de dagkoppen Mon–Sun) echter pál aan de bovenrand: geen statusbalk, geen app bar. Werkhypothese: **iOS standalone-PWA + safe-area** — de app bar valt onder de notch/statusbalk of buiten de viewport, wat op Android nooit opvalt. **Let op: de voor de hand liggende oorzaak is al uitgesloten** — `web/index.html` heeft `viewport-fit=cover` (regel 27) én `padding: env(safe-area-inset-*)` op `html, body` (regel 62). Ga daar dus niet naar zoeken. De verdachte is juist die padding zélf: Flutter-web positioneert zijn glass pane absoluut over de body, dus body-padding en Flutter's eigen `MediaQuery.padding` kunnen elkaar dubbeltellen of tegenwerken. Tweede, saaiere mogelijkheid die eerst uitgesloten moet worden: de tester heeft de screenshot bijgesneden en de app bar stond er gewoon. **Niet reproduceerbaar op eigen hardware — de tester heeft een iPhone, wij niet.** Vraag daarom om één screenshot mét de bovenrand erop, of om Safari-inspectie, vóór er iets gebouwd wordt | HOOG | S | Backlog |

**Waarom dit item anders is dan de rest van deze lijst.** Fase 21 heeft vijf gap-closure-plannen nodig gehad (21-10 t/m 21-14) en bij élk daarvan gold dezelfde beperking: de defecte laag was niet gedragsmatig testbaar, dus het bewijs moest van een toestel komen of van een structurele broncode-scan. Vier keer landde een bug in productie die een gewone test had gevangen als het seam had bestaan.

| Plan | Wat er stuk was | Wat de test kón controleren |
|------|-----------------|------------------------------|
| 21-10 | `drain()` had geen aanroeper | alleen: staat er ergens `drain(` in `lib/` |
| 21-11 | de aanroep faalde op een disposed `Ref` | gedrag, via `ProviderContainer` — dit is de enige die het wél kon |
| 21-12 | de payload was geen legale rij | de payloadvorm, niet of PostgREST hem accepteert |
| 21-13 | de sleutel overleefde `timestamptz` niet | round-trip binnen Dart, niet door de database |
| 21-14 | push gebeurde ná pull | alleen: staat `drainOutbox()` vóór `_reconcile*` in de brontekst |

**De oorzaak, concreet.** `lib/providers/cloud_sync_reconciler_provider.dart` grijpt op vijf plaatsen rechtstreeks naar `Supabase.instance.client` (regels 82, 151, 208, 222 en in `readCloudPlannedRides`). De klasse neemt alleen een `Ref` aan (`CloudSyncReconciler(this._ref)`), geen client en geen leesfuncties. Daardoor is er geen enkele manier om van buitenaf te observeren wat hij doet: niet welke tabellen hij leest, niet in welke volgorde hij pusht en pullt, niet wat hij verstuurt. Een test kan alleen de brontekst lezen — en dat is precies het soort test dat 21-10 groen hield terwijl de outbox write-only was.

**Wat de wijziging inhoudt.** Geef `CloudSyncReconciler` zijn cloud-toegang als geïnjecteerde functies, zoals `SyncOutboxService.drain()` dat al doet met `upsertFn`/`deleteFn` — dat patroon staat er dus al in deze codebase en werkt. Concreet: een `readProfile`/`readAvailability`/`readPlannedRides`/`upsert`/`delete`-set, in productie samengesteld uit `Supabase.instance.client` in de provider-functie (waar dat hoort), in tests vervangen door fakes die hun aanroepen opnemen. Dan wordt `reconcileOnForeground()`'s volgorde een gewone assertie op een opgenomen aanroeplijst in plaats van een regex over broncode, en wordt "wat gaat er naar welke tabel" toetsbaar zonder Supabase.

**Waarom HOOG en niet MEDIUM.** Dit is geen opruimwerk maar de enige wijziging die het patroon doorbreekt. Zolang het seam ontbreekt, kost elke volgende syncbug opnieuw een toestelsessie om te vinden — deze fase heeft er vijf gekost. De prijs is één refactor van één bestand plus het omschrijven van `outbox_drain_wiring_test.dart`'s structurele asserties naar gedragstests.


---

## v2 — Grote features

Significante toevoegingen die een nieuwe milestone/release-cyclus vereisen.

| # | Item | Waarde | Effort | Status |
|---|------|--------|--------|--------|
| 20 | **iOS port** — Flutter codebase is iOS-ready; Apple Dev Account ($99/jr), TestFlight, App Store review | HOOG | L | Backlog |
| 21 | **Multi-locatie / opgeslagen plekken** — "Hoe is het weer in Mallorca volgende week?" met favorieten | MEDIUM | M | Backlog |
| 22 | **Fietstype-profielen** — road / gravel / MTB met verschillende scoring-gewichten per profiel | MEDIUM | M | Backlog |
| 23 | **Strava-integratie** — import van recente ritten om score achteraf te valideren ("was de score klopte?") | MEDIUM | L | Backlog |
| 24 | **Route-weer overlay** — GPX/route importeren en per-segment weer tonen (Epic Ride Weather territory) | MEDIUM | XL | Backlog |
| 25 | **Google Calendar import** — geblokkeerde uren automatisch ophalen uit agenda i.p.v. handmatig grid | HOOG | M | Backlog |
| 26 | **Kledingadvies** — op basis van temperatuur + windchill een suggestie (arm warmers, regenjas, etc.) | MEDIUM | M | Backlog |
| 27 | **14-daagse forecast** — uitbreiding van 7 naar 14 dagen met afnemende betrouwbaarheid indicator | MEDIUM | S | Deels (10d, 7a6dbbe) |
| 28 | **Themed branding + app icon polish** — custom launcher icon, splash screen animatie, store screenshots | MEDIUM | M | Backlog |
| 29 | **Lokalisatie (EN/NL)** — i18n met `flutter_localizations` + ARB bestanden | MEDIUM | M | Backlog |
| 30 | **Offline modus** — duidelijke UX wanneer geen internet; toon laatst gecachte forecast met stale-indicator | HOOG | M | Backlog |
| 32 | **Agenda-event bijwerken bij nieuwe weersdata** — als de forecast voor een al-toegevoegd tijdvak verandert (temp/regen/wind), moet het bestaande Google Calendar-event automatisch worden bijgewerkt i.p.v. verouderd te blijven staan. Vereist het al-toegevoegde event terug te vinden (bijv. via een opgeslagen event-ID per slot) en te updaten i.p.v. opnieuw aan te maken | MEDIUM | M | Backlog |
| 39 | **Kwartier-precisie bij "Adjust Time" op Ride Detail** — tester-feedback (Jacco): de Start/End-tijd aanpassen op Ride Detail gaat nu alleen per heel uur (bevestigd in code: `Duration(hours: 1)`-stappen); hij zou verwachten dit ook per kwartier te kunnen bijstellen, vooral relevant zodra je ritten met anderen afspreekt (zie #41). Vereist een keuze hoe score/weer wordt afgeleid voor niet-hele-uur-tijden, aangezien de onderliggende Open-Meteo-data zelf per uur is (dichtstbijzijnde uur hergebruiken, of interpoleren) | MEDIUM | M | Backlog |

---

## v3+ — Toekomstvisie

Ideen die pas relevant worden als v1+v2 gevalideerd zijn.

| # | Item | Waarde | Effort | Status |
|---|------|--------|--------|--------|
| 62 | **Epic "Peloton" — vrienden + gezamenlijke ride windows** — overkoepelende richting waar #41 en #48 onder vallen; zie de uitgewerkte sectie onderaan | HOOG | XL | Backlog — epic, nog geen scope |
| 64 | **Epic "Eigen gezicht" — merkidentiteit: typografie, iconografie en emoji die van deze app zijn** — het logo bestaat al en is het vertrekpunt; zie de uitgewerkte sectie onderaan | HOOG | L | Backlog — epic, nog geen scope |
| 65 | **Epic "Peloton v2" — samen plannen zoals de goede apps het doen** — uitnodigen voor geschoorde vensters in plaats van één vast moment, meekijken zonder account, en maatjes vinden via gebruikersnaam. Afgeleid uit Partiful, Komoot, Howbout en Strava; zie de uitgewerkte sectie onderaan | HOOG | XL | Backlog — epic, volgorde vast, scope per slice open |
| 66 | **Afgezegde ritten blijven bereikbaar** — afzeggen is nu een deur die één kant op gaat: een rit met status `declined` valt uit `pendingRideInvites`, `joinedGroupRides` én `ownedGroupRides` tegelijk en is nergens meer aan te wijzen, terwijl de rij bestaat en RLS een terugweg toestaat. De snackbar met ongedaan-maken (2026-09-08) dekt de misklik, niet "morgen toch wel". Geldt net zo goed voor het afwijzen van een uitnodiging | MEDIUM | S | Backlog — opgekomen bij `260908-j2q-peloton-afzeggen` |
| 67 | **Notificaties zijn hardgecodeerd Nederlands** — zes teksten in `notification_service.dart` (regels 103, 104, 139, 140, 177 en het bijbehorende body). Een Engelstalige gebruiker krijgt dus Nederlandse meldingen op zijn vergrendelscherm. Dezelfde klasse als de rondleiding die op 2026-09-08 is vertaald, en verwant aan #58 (agenda-event heet "Fietsrit"). **De reden dat het er nog staat is echt maar niet onoverkomelijk:** notificaties worden gepland zonder `BuildContext`, dus `S.of(context)` kan niet. `AppLocalizations.delegate.load(Locale(profile.locale))` levert wél een `S` zonder context, en de locale staat al in het profiel. Opgemerkt bij de afrondsweep van 2026-09-08 | MEDIUM | S | Backlog |
| 68 | **De app houdt geen rekening met daglicht** — `slots_notifier.dart:105` hanteert een hardgecodeerd venster van 06:00–22:00 en er staat nergens in de codebase een zonsopgang of zonsondergang. Gevolg: op 2026-09-10 was de bovenste aanbeveling *donderdag 20:00–22:00, score 100*, terwijl de zon in Amsterdam om **20:07** ondergaat — 1 uur 53 van dat "perfecte" venster is donker. Gemeld door Ingrid (tester, 2026-09-09): *"hou je al rekening met hoe laat de zon ondergaat? Want tot 22u fietsen staat er, maar dan is het al bijna donker"*. **Dit raakt de kernwaarde uit CLAUDE.md** ("als de score fout is, of het venster in de praktijk onberijdbaar, faalt de app"). Open-Meteo levert `is_day` per uur én `daily=sunrise,sunset` op dezelfde gratis aanroep; beide worden nu niet opgevraagd. Let op bij het ontwerp: hard uitsluiten breekt de winter (in december is het licht van 08:45 tot 16:30, en dan houdt een avondfietser niets over) | **HOOG** | M | Backlog — bug, gemeld 2026-09-09 |
| 69 | **De lijst toont de losse vensters, niet het groene blok** — een tester met 2/3/4/5 uur toegestaan kreeg op één zaterdag 09:00–11:00 (100), 06:00–09:00 (99) én 11:00–13:00 (95) achter elkaar, en vroeg: *"waarom geeft die dan niet van 8-11 of van 9-13?"* (Ingrid, 2026-09-09). Dat is geen fout — `SlotGenerator.dedup` gooit 08:00–11:00 weg omdat het voor 67% overlapt met het beter scorende 09:00–11:00 — maar het is wél een ander model dan dat van de gebruiker. De app beantwoordt *"welk venster van N uur is het beste"*; zij vraagt *"wanneer is het vandaag goed, en hoe lang kan ik weg"*. Mogelijke richting: per dag het aaneengesloten goede blok tonen met het beste venster erin gemarkeerd | MEDIUM | M | Backlog — opgekomen uit testfeedback 2026-09-09 |
| 70 | **Waarom dit venster en niet dat ernaast** — dezelfde tester vroeg *"of zijn die twee uur dan specifiek echt score 100 en de andere net niet perfect?"* Het antwoord is ja, maar de app laat het nergens zien: het weggegooide alternatief en zijn score zijn onzichtbaar. `insights_sheet.dart` legt al uit *waarom een score die score is*; wat ontbreekt is *waarom dít venster en niet het uur ernaast*. Klein en dicht bij iets dat al bestaat | MEDIUM | S | Backlog — opgekomen uit testfeedback 2026-09-09 |
| 40 | **Wear OS companion** — tile/complication die volgende slot toont op smartwatch | MEDIUM | L | Backlog |
| 41 | **Sociaal / groepsritten** — "Wanneer kunnen wij allemaal?" met gedeelde beschikbaarheid. Tester-verduidelijking (Jacco, Phase 15 iPhone-test): concreter, kleiner startpunt zou zijn iemand uitnodigen voor één specifieke rit, die persoon accepteert en ziet 'm terug in zijn eigen app — evt. uitgebreid met het zien van elkaars beschikbaarheid om een overlap te vinden | MEDIUM | XL | Backlog — opgenomen in milestone v3.0, zie `.planning/milestones/v3.0-ACCOUNTS.md` |
| 48 | **Lokale ride-matching** — gebruikers in dezelfde omgeving die zich voor hetzelfde slot aanmelden kunnen samen een rit plannen | MEDIUM | XL | Backlog |
| 42 | **Historische analytics** — "Beste maand om te fietsen", trend over seizoenen | LAAG | L | Backlog |
| 43 | **Backend + user accounts** — cross-device sync, maar vereist auth, hosting, GDPR | LAAG | XL | Backlog — opgenomen in milestone v3.0, zie `.planning/milestones/v3.0-ACCOUNTS.md` |
| 44 | **Monetisatie** — freemium model (gratis basis, premium voor multi-locatie/widget/14d) | LAAG | L | Backlog |
| 45 | **In-app navigatie deep-links** — "Start in Komoot" / "Open in Google Maps" vanuit Ride Detail | LAAG | S | Backlog |
| 46 | **Weerradar kaartweergave** — embedded radar map (Windy-achtig) i.p.v. deep-link | LAAG | XL | Backlog |
| 47 | **Machine learning scoring** — leer van gebruikersfeedback welke condities zij als "goed" ervaren | LAAG | XL | Backlog |

---

## Bronnen

- Items 1-4, 20-24: afgeleid uit `.planning/research/FEATURES.md` v1.x en v2+ secties
- Items 5-12: geidentificeerd uit huidige codebase gaps en deferred items
- Items 25-30: logische uitbreidingen op bestaande architectuur
- Items 40-47: uit PROJECT.md "Out of Scope" + FEATURES.md "Anti-Features" — bewust geparkeerd voor v3+

---

*Aangemaakt: 2026-06-06*
*Laatst bijgewerkt: 2026-07-15 (items 31-39 toegevoegd n.a.v. Phase 15 Calendar-verificatie: OAuth consent screen, agenda-event bijwerken bij nieuwe weersdata, feedback-formulier, sticky "Plan ride"-knop, duidelijkere feedback bij niet-aaneengesloten selectie, Calendar-koppeling in Profile, regen-icoon bug bij droog weer (afgerond), tip over iOS Agenda-koppeling, en kwartier-precisie bij Adjust Time; items 17, 34, 35 afgerond — twee-tik-bereik selectiemodel op Availability + Agenda, sticky Planned-knop met unplan/delete, live losse-tijdvakken-teller); 2026-07-17 (item 31: fast-publish route gekozen voor OAuth consent screen, instructies klaargezet voor Joost, zie OAUTH-PUBLISH-CHECKLIST.md — bij controle in Cloud Console bleek Publishing status al "In production" te staan, dus item afgerond zonder dat de "Publish app"-klik nog nodig was); 2026-07-25 (items 49-51 toegevoegd n.a.v. beta-tester feedback via Slack: te doorzichtige onboarding coach-marks, permanente "tap share icon"-banner, en een voorgestelde nav-herstructurering met top app bar — schets in `/Users/joostmouw/Documents/O+ Connect/IMG_2991.jpg`); 2026-07-26 (item 53 toegevoegd: closed test heeft 12 opted-in testers nodig gedurende 14 dagen voordat productietoegang aangevraagd kan worden — stand 4 — met Reddit als wervings- én lanceerkanaal)*


---

## 61 — Een verse installatie haalt geplande ritten niet op tot de app eenmaal is weggezet

> **Gefixt 2026-09-01** in quick 260901-nz7 (`36f4fca`, `abcf557`) — `reconcileOnStartup()` vanuit
> `HomeScreen.initState`, plus dezelfde blinde vlek gedicht in de inlogflow (`_runAccountSync()`
> reconcilet nu in plaats van alleen te drainen; `onSignIn()` dekte alleen profile en
> availability). **Nog niet op een toestel bewezen** — de tegenproef staat in
> `.planning/phases/21-sync-migration/MORGEN.md`. Blijft open tot die meting er is.

**Waargenomen 2026-08-07** op een net geïnstalleerde PWA (WebAPK, 1.0.22+23), ingelogd als
joostmouw@gmail.com, met twee geplande ritten in de cloud.

| Toestand | PLANNED-sectie |
|---|---|
| Verse installatie, eerste start, lege lokale opslag, geldige sessie | **leeg** |
| Zelfde app, na één achtergrond → voorgrond-cyclus | **beide ritten** |
| Zelfde app, koude start (force-stop + opnieuw), nu mét lokale data | **beide ritten, meteen** |

De derde regel is de discriminator: koude start is niet het probleem, **lege lokale opslag** is het.
Het was ook geen kwestie van te kort wachten — de app had bij de eerste start ruim een halve minuut
gedraaid en was ondertussen naar Profiel en terug genavigeerd.

**Diagnose.** De pull van planned rides hangt uitsluitend aan de voorgrond-reconcile. Bij een
normale login (`lastSyncedUid` staat al) draait de eerste-login-migratie niet, en de initiële load
telt niet als voorgrond-overgang. Er is dus geen pad dat bij het opstarten uit de cloud leest.

**Waarom dit HOOG is.** Dit is precies het eerste wat een gebruiker op een tweede toestel doet:
installeren, inloggen, kijken of zijn ritten er zijn. Die ziet een lege lijst en concludeert
redelijkerwijs dat de sync stuk is. Het is ook de grondoorzaak van de hele web-sessie van 6/7
augustus, die anderhalve dag onderzoek heeft gekost voordat duidelijk was dat de code deed wat hij
moest doen — alleen niet op het moment dat ertoe deed.

**Nog niet vastgesteld.** Of de native app hetzelfde doet bij een verse installatie met lege lokale
opslag. MIG-02 dekte "leeg lokaal + gevulde cloud" en slaagde, maar liep via een échte eerste login
en dus via het migratiepad. Het verschil is precies `lastSyncedUid`.

**Samenhang.** Raakt [[60]]: zolang `CloudSyncReconciler` rechtstreeks naar
`Supabase.instance.client` grijpt, is dit gedrag niet in een test vast te leggen.

Volledige waarneming: `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md`, device
session 7.

---

## 62 — Epic "Peloton": vrienden toevoegen en elkaar uitnodigen voor een gedeeld ride window

> Vastgelegd 2026-09-02 op aangeven van Joost, tijdens het afsluiten van fase 21. Richting, geen
> scope: er is nog niets besloten over fasering, datamodel of UI.

**Wat het is.** De accounts uit v3.0 zijn nu nog eenzijdig — ze bestaan om jouw eigen data tussen
jouw eigen toestellen te laten meereizen. Peloton draait dat om: accounts worden onderling
zichtbaar. Gebruikers voegen elkaar toe als vriend en nodigen elkaar uit voor een ride window dat
voor beide partijen schikt — het snijvlak van beider beschikbaarheid, gescoord op hetzelfde
weermodel dat de app al gebruikt.

**Waarom het nu pas kan.** Dit is de eerste feature die een gedeelde server-kant écht nodig heeft.
Tot v3.0 was de server een gemak (sync); hier is hij de functie zelf — twee gebruikers moeten
elkaars beschikbaarheid kunnen zien zonder elkaars toestel. Fase 21 heeft daarvoor het fundament
gelegd: Supabase Auth, RLS die per gebruiker afschermt, en `availability` en `planned_rides` die al
server-side staan.

**Wat er conceptueel bij komt kijken, zonder er nu keuzes over te maken:**

- **RLS wordt fundamenteel ingewikkelder.** De huidige policies zeggen "je ziet alleen je eigen
  rijen" — dat is precies wat SYNC-08 bewijst. Peloton vereist "je ziet ook de beschikbaarheid van
  wie jou als vriend heeft geaccepteerd", en dat is de klasse fouten waar dit soort apps op
  omvalt. Dit verdient een eigen security-fase, geen policy-aanpassing onderweg.
- **Beschikbaarheid wordt gedeelde data.** Vandaag staat het weekrooster server-side maar leest
  niemand het behalve jijzelf. Zodra een vriend het mag zien, is het persoonsgegeven-met-publiek —
  het privacybeleid en de sub-processors-uitleg moeten mee.
- **Het snijvlak zelf is nieuwe domeinlogica**, geen UI-werk: twee (of meer) roosters kruisen,
  daaroverheen de weerscore, en dan de bestaande slot-generator. Dat is precies de kern van de app,
  dus het hoort met dezelfde teststrengheid als `SlotGenerator`.
- **Uitnodigen is een toestandsmachine** (uitgenodigd → geaccepteerd → afgewezen → afgezegd), en
  die moet offline overleven — de outbox uit fase 21 kent nu alleen upserts van eigen data.
- **Agenda-koppeling krijgt een tweede betekenis:** een geaccepteerde uitnodiging hoort in beide
  agenda's te belanden. Raakt #32 (event bijwerken) en #58/#59 (taal en tijdzone van events, allebei
  nu nog hardcoded — en bij twee deelnemers in verschillende zones is #59 geen cosmetisch item meer).
- **De 100-user OAuth-cap (#31) wordt relevant.** Een sociale feature waarvan het nut met het
  aantal deelnemers groeit, botst op een lifetime-cap van 100 unieke Google-gebruikers zolang de
  `calendar.events`-scope niet formeel geverifieerd is.

**Samenhang.** Consolideert [[41]] (sociaal/groepsritten — Jacco's kleinere startpunt: één persoon
uitnodigen voor één rit, die accepteert en ziet 'm in zijn eigen app) en [[48]] (lokale
ride-matching). #41's startpunt is waarschijnlijk de eerste bruikbare slice van deze epic; #48 is de
uitbreiding naar mensen die je nog niet kent en hoort daar nadrukkelijk ná.

---

## 64 — Epic "Eigen gezicht": typografie, iconografie en emoji die van deze app zijn

**De vraag van Joost (2026-09-06).** De app moet een eigen merk en imago dragen — lettertype, emoji
en beeldtaal die niet ergens vandaan gepakt zijn maar bij déze app horen en bij wat hij doet. Het
logo is al gemaakt en is het vertrekpunt, niet een los element.

**Waar de app nu staat — dit is geen groen veld.** Wat al af is verdient het om niet opnieuw
gedaan te worden:

- **Kleur is al eigen.** `lib/theme/app_colors.dart` draagt de officiële merkkleuren
  `brandLight #C5D4B6` en `brandDark #234934`, en `seed = brandDark` voedt het hele
  Material 3-schema. De getinte oppervlaktetrappen en de contrastcontroles (4.5:1) zijn doorgemeten.
- **Vorm en beweging staan apart** in `app_shapes.dart` en `app_motion.dart` — er is dus al een
  tokenlaag om aan te haken, geen losse waarden door de schermen heen.
- **Het logo bestaat**: `photos/app_icon_rounded_square.png`, met `tools/make_icons.py` dat alle
  formaten regenereert.

**Wat er dus werkelijk ontbreekt — de twee gaten waar deze epic over gaat:**

1. **Er is geen eigen lettertype.** `pubspec.yaml` heeft geen `fonts:`-blok en nergens in
   `lib/theme/` staat een `fontFamily`. De app draait dus op het systeemlettertype: Roboto op
   Android, San Francisco op iOS, iets anders op het web. De app ziet er op de iPhone van de tester
   letterlijk anders uit dan op het toestel hier, en geen van beide is een keuze geweest. Dit is het
   grootste enkele verschil tussen "een Material-app" en "deze app".
2. **De emoji zijn systeememoji.** `lib/features/shared/clothing_tip.dart` zet het kledingadvies
   neer als losse Unicode-tekens (`\u{1F455}` t-shirt, `\u{1FA73}` korte broek, `\u{1F9E5}` jas)
   in een `Text` met `fontSize: 20`. Die worden door het besturingssysteem getekend — dus Android's
   Noto, Apple's eigen set, en op het web weer wat anders. Precies "ergens vandaan gepakt". Het is
   bovendien de plek waar de app zijn karakter laat zien (kledingadvies is het meest menselijke
   stukje van het product), dus het is de eerste plaats om eigen beeldtaal neer te zetten.

**Randvoorwaarden die deze epic sturen:**

- **€0/maand blijft staan.** Een licentie voor een commercieel lettertype botst met de begroting
  uit `CLAUDE.md`. Zoek in de open-source hoek (SIL OFL) en kies bewust — een OFL-font mag mee in
  de app-bundel, ook commercieel.
- **APK-grootte is een echte kostenpost.** Een variabel font in twee gewichten is al snel
  honderden kB; icoonassets als SVG of als eigen icoonfont schelen daarin. Subset op de tekens die
  de app werkelijk gebruikt (EN + NL, dus geen volledige Latin-Extended).
- **Toegankelijkheid mag niet inleveren.** De contrastratio's in `app_colors.dart` zijn met zorg op
  4.5:1 gezet; een nieuw lettertype verandert de waargenomen zwaarte van tekst. Herweeg de
  hint-kleuren na de wissel in plaats van aan te nemen dat ze blijven kloppen.
- **Emoji vervangen raakt de leesbaarheid van betekenis.** Een eigen pictogram voor "lange mouw"
  moet zonder tekst herkenbaar zijn, anders is een systeememoji die iedereen kent beter. Toets dat
  op iemand die de app niet kent, niet op onszelf.

**Waar het logo binnenkomt.** Het icoon draagt al een vormtaal (rondingen, lijndikte, de
groentonen). Die is de bron voor zowel de icoonset als de fontkeuze — de volgorde is dus: eerst het
logo ontleden tot een paar expliciete regels, dán font en iconen daaraan toetsen. Andersom levert
een verzameling losse smaken op.

**Samenhang.** Raakt de MD3-herontwerpplannen (zie het geheugenitem "MD3 visual redesign") en
#58/#59 zijdelings: `clothing_tip.dart` bevat naast emoji ook Nederlandse labels ("kort/kort") in
een verder Engelse app, dus wie dit bestand toch openlegt kan die hardcoded taal meteen meenemen.

---

## 65 — Epic "Peloton v2": samen plannen zoals de goede apps het doen

Vervolg op [[62]], opgesteld 2026-09-07 na een vergelijking van vier apps die dit probleem al hebben
opgelost. Volgorde ligt vast, scope per slice niet.

### Het uitgangspunt: wat wij kunnen en zij niet

Partiful, Komoot, Howbout en Strava plannen allemaal **een moment**. Geen van vier weet of dat
moment goed weer is om te fietsen. Dat is precies wat deze app als enige kan, en daar hoort de
sociale laag omheen te zitten. De richtinggevende zin van deze epic:

> **Nodig niet uit voor één rit, maar voor de beste vensters van deze week.** De eigenaar vinkt twee
> of drie geschoorde vensters aan ("za 09:00–13:00 — Perfect", "zo 07:00–09:00 — Great"), de maatjes
> vinken aan wat hen past, en de app bevestigt het hoogst scorende venster dat iedereen kan.

Dat is Partiful's datumpoll × Howbout's beschikbaarheidsoverlap × onze weerscore. De eerste twee
kunnen die derde stap niet zetten. Het leunt bovendien op de bestaande `SlotGenerator` in plaats van
op iets nieuws — de kandidaten zijn gewoon de best scorende slots.

### Wat we van wie overnemen

| App | Wat zij doen | Wat wij ervan nemen |
|---|---|---|
| **Partiful** | Uitnodiging opent in de browser, gast reageert met alleen een naam — geen account, geen installatie. Meerdere datumopties, gasten vinken meerdere aan | Slice 1 en 2 hieronder. Dit is de grootste bereikwinst én de zwaarste ingreep |
| **Komoot** | Group Tours: deelnemers via QR (ook printbaar, voor een terugkerende clubrit), via wie je volgt of via een link. Past de eigenaar de route aan, dan krijgt iedereen dat direct | Slice 4 (wijziging propageert met melding) en slice 6 (QR). Het datamodel kan de eerste al — één gedeelde rit, keuze 2 uit [[62]] — er is alleen geen melding |
| **Howbout** | 10M gebruikers, puur hierop gebouwd: zie meteen wanneer vrienden vrij zijn, met Google/Outlook/iCloud eroverheen zodat niets botst. Stemmen over tijden | Slice 3. Bevestigt dat het snijvlak van roosters de kern is en geen extraatje — dat stond al als [[41]] |
| **Strava** | Herkent achteraf dat jullie samen reden en koppelt de activiteiten. Clubs als vaste groep naast losse vrienden | Later: clubs (slice 7). De automatische koppeling achteraf vereist opgenomen ritten en die heeft deze app niet |

### Volgorde

**Slice 0 — eerst dichten wat kapot is.** Geen van het onderstaande heeft zin zolang deze twee open
staan; beide zijn op 2026-09-07 op een toestel vastgesteld en staan uitgewerkt in
`.planning/PELOTON.md`:

- Een **geaccepteerde rit is bij de genodigde nergens zichtbaar** — niet in "My rides", niet op
  Home, niet op de Peloton-tab. De belofte "de rit verschijnt bij de ander" is daarmee nog niet
  waar. Dit is het echte gat.
- **Profielzichtbaarheid klopt niet**: B ziet A in zijn maatjeslijst, A ziet B niet. Oorzaak nog
  onbekend, kandidaten en de beslissende query staan in `PELOTON.md`. Wie onzichtbaar is in een
  maatjeslijst, is ook onvindbaar via gebruikersnaam of contacten — dit is de fundering onder
  slice 5.

**Slice 1 — meekijken zonder account** (Partiful). Vandaag moet je maatje eerst een account maken
voordat hij weet waarvoor hij wordt uitgenodigd. Dit draait dat om: `/invite/:code` toont de rit
mét weerscore en de "wat trek je aan"-tip, en hij kan reageren; een account is pas nodig als hij de
app zelf wil gebruiken. **Dit is architectureel de zwaarste stap:** alle RLS gaat nu uit van
`authenticated`, dus er moet een pad komen waarin een niet-ingelogde bezoeker precies één rit mag
zien en precies één antwoord mag geven, op grond van een token in de URL — en niets anders. Dat is
een eigen security-ontwerp, geen policy-aanpassing onderweg.

**Slice 2 — meerdere vensters voorleggen.** Het idee uit het uitgangspunt. Bouwt op slice 1 (ook
gasten moeten kunnen stemmen) en op de bestaande slot-generator.

**Slice 3 — "wanneer kunnen wij allebei"** (Howbout, was [[41]]). Het snijvlak van beider roosters
met de weerscore eroverheen. Vereist dat A B's beschikbaarheid mag lezen: de zwaarste RLS-vraag van
het hele epic, en de reden dat dit bewust nog niet gebouwd is. Beschikbaarheid wordt hiermee gedeelde
data, dus het privacybeleid moet mee.

**Slice 4 — verzet de eigenaar de tijd, dan weet iedereen het** (Komoot). Het model kan dit al;
wat ontbreekt is de notificatie. Raakt de bestaande `flutter_local_notifications`-laag.

**Slice 5 — maatjes vinden** *(keuze van Joost, 2026-09-07)*. De deel-link blijft altijd bestaan.
Daarnaast, in deze volgorde:

- **Gebruikersnaam + zoeken.** Je kiest zelf een unieke handle; anderen zoeken daarop. Opt-in, en je
  e-mailadres komt er nooit aan te pas — dat laatste is de reden dat zoeken op e-mailadres eerder is
  afgewezen ([[62]]): daarmee kun je uitproberen welke adressen een account hebben, en dat lek dicht
  je achteraf niet. **Let op de consequentie:** vandaag is vriend worden meteen definitief, en dat
  mag omdat de code een gedeeld geheim is. Zodra iemand je kan vínden, vervalt die aanname en is een
  **verzoek-en-accepteren-stap nodig** — anders zet een willekeurige vreemde zichzelf in je lijst.
  Vereist verder: een `handle`-kolom op `profiles` met uniciteit (hoofdletterongevoelig), een
  zoek-RPC die alleen naam en handle teruggeeft, en snelheidsbegrenzing.
- **Contacten matchen.** Joost wil dit expliciet. Bewust achteraan: het vraagt contacten-permissie,
  hashing die niet triviaal terug te rekenen is (een kale SHA-256 van een telefoonnummer is dat wél,
  de zoekruimte is klein), een aparte alinea in het privacybeleid en een extra verklaring in Play's
  Data Safety. En het levert pas iets op als er genoeg gebruikers zijn — met een handvol testers
  matcht het niets.
- **QR-code** (Komoot). Goedkoop en meteen nuttig als je naast elkaar staat: de code en de
  `/invite/:code`-route bestaan al, er komt alleen een scherm met een QR en een scanner bij.

**Slice 6 — ga / misschien / kan niet.** Alle vier de apps hebben drie toestanden; wij hebben er
twee (`accepted`/`declined`, plus `invited`). "Misschien" is precies het antwoord dat mensen willen
geven als het weer nog kan omslaan — bij deze app dus extra relevant.

**Slice 7 — clubs** (Strava). Een vaste groep in plaats van losse maatjes, voor de dinsdagochtendrit.
Pas zinvol als slice 1 t/m 3 staan.

### Wat we bewust niet overnemen

- **Chat per rit** (Howbout). WhatsApp heeft dat gewonnen. Bouw liever een goede deelknop
  dáárnaartoe — de app deelt nu al een tekst met code en link via `Share.share`.
- **Challenges en ranglijsten** (Strava). Andere app, andere missie. Dit gaat over "wanneer kan ik
  rijden", niet over wie het hardst ging.
- **Live tracking tijdens de rit** (Komoot, Strava). Batterij, privacy, en het valt buiten de
  kernwaarde.

### Randvoorwaarden die over de hele epic gelden

- **€0/maand.** Notificaties naar deelnemers mogen geen betaalde push-dienst vereisen; blijf bij
  lokale notificaties plus de bestaande Supabase-vrije-laag zolang dat kan.
- **De 100-user OAuth-cap ([[31]])** wordt hier pijnlijk: een sociale feature waarvan het nut groeit
  met het aantal deelnemers, botst op een lifetime-cap van 100 unieke Google-gebruikers zolang de
  `calendar.events`-scope niet formeel geverifieerd is. Slice 1 verzacht dit deels, want een gast
  heeft geen Google-login nodig.
- **Het privacybeleid loopt achter.** Sinds [[62]] ziet een maatje al je naam en de ritten waarvoor
  je uitgenodigd bent, en dat staat er nog niet in. Slice 3 (gedeelde beschikbaarheid) en slice 5
  (contacten) maken die achterstand groter, niet kleiner.

**Bronnen:** [Komoot Group Tours](https://support.komoot.com/hc/en-us/articles/360022828232-How-to-create-a-group-Tour-and-invite-people-to-it),
[Komoot QR-uitnodiging](https://support.komoot.com/hc/en-us/articles/6382678428698-Invite-participants-with-QR-code-to-a-group-Tour),
[Partiful RSVP](https://help.partiful.com/en-us/articles/15525505-how-do-i-rsvp-to-an-event-on-partiful),
[Partiful](https://partiful.com/), [Howbout](https://howbout.app/),
[Strava Group Activities](https://support.strava.com/hc/en-us/articles/216919497-Group-Activities).
