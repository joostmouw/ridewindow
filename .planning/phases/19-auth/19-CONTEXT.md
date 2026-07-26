# Phase 19: Auth - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

In- en uitloggen met een Google-account via Supabase (`signInWithIdToken`), zichtbaar en bedienbaar vanuit het bestaande Profielscherm, werkend op Android én web, met een sessie die een herstart overleeft — plus het bewijs dat de Android-release-build, de PWA en "Voeg toe aan agenda" er niet door zijn gebroken.

Levert: `supabase_flutter` in `pubspec.yaml`, `Supabase.initialize()` in `main.dart`, `authStateProvider`, een account-sectie in `/profile`, `serverClientId` op de bestaande gedeelde `GoogleSignIn`-init, een accountwissel-dialoog, een Calendar-mismatch-waarschuwing, een handmatige regressiechecklist en een AAB op het internal testing track.

Expliciet NIET in deze fase: Postgres-schema, RLS-policies, cloud-reads/-writes, de outbox, de drie repositories, de migratie-/conflictresolver, de in-app verwijderknop, account-backed feedback. Dat is fase 20/21/22. Er wordt in fase 19 geen enkele rij naar de database geschreven — een account bestaat wel, maar het draagt nog geen data.

</domain>

<decisions>
## Implementation Decisions

### Account-sectie in Profiel (AUTH-01, AUTH-02)
- **D-01:** De account-UI krijgt een **eigen `_SectionHeader('Account')` als eerste sectie** van `profile_screen.dart`, bóven Naam en de tolerantie-instellingen. Bewust afgeweken van AUTH-02's letterlijke "zelfde plek als de Calendar-rij": inloggen is de nieuwe hoofdfunctie van dit scherm en verdient geen voetnootpositie tussen feedback en versienummer. Fase 21 hangt hier sync-status onder — de sectie is dus alvast de juiste container.
- **D-02:** Ingelogde weergave: **Google-avatar + naam + e-mail**, met "Uitloggen" als `TextButton` in de `trailing` — hetzelfde trailing-patroon als de bestaande Calendar-rij (`profile_screen.dart:698-714`). De avatar komt uit `user.userMetadata['avatar_url']`; er moet een fallback zijn (initiaal of `Icons.account_circle`) als de netwerkafbeelding niet laadt, zodat een offline start geen kapotte rij oplevert.
- **D-03:** Uitgelogde weergave: **"Inloggen met Google" + één belofteregel in de toekomende tijd** — "Binnenkort: je instellingen en geplande ritten op al je apparaten." De toekomende tijd is bewust: sync werkt pas in fase 21, en een belofte in de tegenwoordige tijd levert nu bugmeldingen van testers op. Zet de l10n-sleutels zo op dat fase 21 alleen het woord "Binnenkort:" hoeft te laten vallen — geen nieuwe sleutel.
- **D-04:** **`profile.userName` wordt bij inloggen ingevuld als het leeg is, en nooit overschreven.** Google's voornaam vult een leeg veld; een door de gebruiker ingevulde naam blijft ongemoeid. Let op voor fase 20/21: dit is een stille lokale schrijfactie op het moment van inloggen — als `profile.updatedAt` (MIG-04) er straks is, mag deze auto-invulling die tijdstempel **niet** zo bewegen dat het later op een echte divergentie lijkt. Leg dat vast in fase 20's repository-werk.

### Inlogknop en platformverschil (AUTH-06)
- **D-05:** **Elk platform zijn eigen knop.** Android: een eigen `ListTile` in RideWindow-stijl die `GoogleSignIn.instance.authenticate()` aanroept — daar wordt AUTH-02's visuele patroon letterlijk gehaald. Web: Google's `renderButton()` uit `google_sign_in/web_only.dart` binnen dezelfde sectie, met `authenticationEvents` als bron. Twee looks is hier de juiste prijs: Android is waar de testers zitten.
- **D-06:** De vertakking loopt op **`GoogleSignIn.instance.supportsAuthenticate()`**, niet op `kIsWeb` — de check volgt de werkelijke capability van de plugin (PITFALLS #2).
- **D-07:** Feedback: **geen bevestiging bij succes** (de sectie verandert zichtbaar, dat is het bewijs), **SnackBar bij een fout** met een leesbare melding, en **niets bij annuleren** — annuleren was een keuze, geen fout. Zelfde patroon als de bestaande Calendar-foutafhandeling in `profile_screen.dart`. De technische oorzaak (bijv. een audience-mismatch) hoort in de log te belanden, niet in de snackbartekst.

### Accountwissel en Calendar-mismatch (AUTH-07, AUTH-08, AUTH-03)
- **D-08:** Bij inloggen wordt het Supabase-uid vergeleken met het laatst gebruikte uid. Bij een verschil komt er **één dialoog: gegevens op dit toestel behouden, of opnieuw beginnen.** De gebruiker beslist; er wordt nooit stil gewist. Dit maakt AUTH-08 nú waar in plaats van hem naar fase 21 te schuiven, en de uid-opslag + vergelijking die je hiervoor bouwt is precies het fundament dat fase 21's resolver nodig heeft (MIG-04's `lastSyncedUid`).
- **D-09:** Wat "opnieuw beginnen" precies leegmaakt is aan de planner, maar de reikwijdte is: profielinstellingen, beschikbaarheid en geplande ritten. De forecast-cache (Drift) blijft **altijd** staan — dat is afgeleide data, geen gebruikersdata (zelfde redenering als SYNC-09).
- **D-10:** **Calendar-mismatch (AUTH-07) wordt gewaarschuwd op de bestaande Calendar-rij in Profiel**, met een waarschuwingsicoon en een regel in de trant van "Agenda is gekoppeld aan een ander account: …". Bewust **geen** extra bevestigingsstap in de "Voeg toe aan agenda"-flow: die flow werkt vandaag vlekkeloos en is REG-04's harde gate — er mag geen wrijving bij. De waarschuwing staat op de plek waar de gebruiker het ook kan oplossen (de Ontkoppel-knop staat daar al).
- **D-11:** De mismatch-check moet **niet-promptend** zijn, net als de bestaande `isCalendarConnected()` (backlog #36) — het Profielscherm openen mag nooit een OAuth-dialoog uitlokken.
- **D-12:** **"Uitloggen" beëindigt alleen de Supabase-sessie**, met een korte bevestigingsdialoog die expliciet zegt dat de gegevens op het toestel blijven staan — AUTH-03 zichtbaar gemaakt in plaats van alleen waar. De Calendar-autorisatie wordt **niet** ingetrokken: die heeft een eigen Ontkoppel-knop en werkt ook zonder account.

### Configuratie (Supabase-sleutels)
- **D-13:** De Supabase-URL en anon key komen als **constanten in de code**, in een nieuw `lib/core/supabase_config.dart`. Geen `--dart-define`, geen `.env`. De anon key is publiek van ontwerp — hij zit sowieso leesbaar in elke APK en webbundel; RLS (fase 21) is de beveiliging, niet geheimhouding. Dit stond al zo in `18-CONTEXT.md` D-19 voor de keep-warm-job.
- **D-14:** Reden om `--dart-define` juist af te wijzen: elk build- en deploycommando (`flutter build apk --release`, `flutter build web --release`, de Firebase-deploy) zou de vlag moeten meekrijgen, en één vergeten vlag levert stilzwijgend een build op waarin inloggen kapot is. Dat is exact het faalpatroon waar AUTH-10 tegen bestaat. **Geen enkel bestaand build- of deploycommando verandert in deze fase.**
- **D-15:** Het configbestand krijgt een commentaarregel die uitlegt dat de anon key publiek hoort te zijn, zodat een latere lezer hem niet "per ongeluk gaat beveiligen".

### Bewijs en verificatie (AUTH-10, REG-01, REG-02, REG-04)
- **D-16:** De fase eindigt met een **echte AAB-upload naar het internal testing track**, en inloggen wordt getest vanaf de Play Store-installatie. Dit is de enige manier waarop AUTH-10 waar is: Google hertekent de app met de Play App Signing-sleutel, dus de SHA-1 verschilt van de lokale keystore. Een lokale release-APK bewijst de verkeerde helft.
- **D-17:** Het plan wordt **gesplitst zoals fase 18**: Claude-taken in eigen plannen, en de handmatige stappen (AAB uploaden, Play Console, testen op toestel en op de iPhone-PWA) als één korte, geordende checklist voor de gebruiker — niet verspreid door Claude's taken heen.
- **D-18:** Regressiebewijs komt in **één `REGRESSION-CHECKLIST.md` in `.planning/phases/19-auth/`**, met afvinkbare stappen per platform: Android release (opstarten, inloggen, "Voeg toe aan agenda", uitloggen, herstart → nog ingelogd) en iPhone-PWA (installeren, standalone openen, navigeren, inloggen, "Voeg toe aan agenda"). Het bestand blijft herbruikbaar in fase 21.
- **D-19:** De **web-koudestartmeting** hoort op diezelfde checklist, mét de meetmethode erbij (welk toestel, welke verbinding, hoe gemeten). Fase 21 hermeet en beslist over de 2-secondengrens (REG-03) — die vergelijking is alleen betekenisvol als de methode identiek is.
- **D-20:** Tests: **widget-tests voor de account-sectie in drie toestanden** (uitgelogd / ingelogd / wisseldialoog) door `authStateProvider` te overriden — hetzelfde overridepatroon als de bestaande providertests — **plus pure unit-tests** voor de uid-vergelijking en de mismatch-beslissing. Geen echte netwerkaanroep in de suite. De suite staat sinds de beschikbaarheids-fix op 306/0; die stand moet groen blijven.

### Claude's Discretie
- Exacte teksten en l10n-sleutelnamen (EN + NL), inclusief de formulering van de wissel- en uitlogdialoog.
- Of `Supabase.initialize()` vóór of na `runApp()` staat, en hoe het zich verhoudt tot het bestaande parallelle `tzFuture`/`prefsFuture`-blok — met de harde eis uit ARCHITECTURE.md §1 dat het klaar is voordat een provider `authStateProvider` leest.
- Hoe `authStateProvider` uit `currentSession` seedt zodat een koude start niet één frame lang "uitgelogd" toont (AUTH-04).
- De laadstatus van de account-sectie voordat de auth-state bekend is, en de avatar-fallback.
- Waar precies de web-`renderButton()` in de sectie landt en hoe de laadstatus daarvan eruitziet.
- Plan-indeling en volgorde binnen de fase, en de vorm van de handmatige checklist.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope en requirements
- `.planning/ROADMAP.md` §"Phase 19: Auth" — doel en de vijf succescriteria; let op criterium 4 (AUTH-10 als harde gate) en 5 (REG-01/02/04 + koudestartbasislijn).
- `.planning/REQUIREMENTS.md` — AUTH-01…AUTH-08, AUTH-10, REG-01, REG-02, REG-04 zijn deze fase. **AUTH-09 hoort bij fase 21**, zie de expliciete noot onder "Traceability". Ook relevant: de leidende regel "accounts zijn strikt additief — wie nooit inlogt mag niets merken".
- `.planning/milestones/v3.0-ACCOUNTS.md` — milestone-scope.

### Stackonderzoek (Supabase — lees deze, niet het archief)
- `.planning/research/ARCHITECTURE.md` **§1** — `authStateProvider`/`currentUserIdProvider`, en de twee Supabase-valkuilen: `onAuthStateChange` herhaalt géén synchrone beginwaarde (seed uit `currentSession`, anders flikkert AUTH-04), en `User.id` is een Supabase-UUID, niet de Google-account-id. **§6** — de expliciete lijst nieuwe/gewijzigde bestanden. **§7 stap 3** — de bouwvolgorde waar deze fase in valt.
- `.planning/research/PITFALLS.md` **#1** (alle Supabase-voorbeelden zijn `google_sign_in` 6.x, dit project draait 7.2.0 — `idToken` uit `authenticate()`, `accessToken` uit `authorizationClient`, en hergebruik `_sharedInitialize()`), **#2** (web: `authenticate()` gooit, `renderButton()` is verplicht), **#3** (drie OAuth-client-id's, twee SHA-1's, `serverClientId` op de gedeelde init), **#10** (regressierisico van `supabase_flutter` op een live app).
- `.planning/research/archive-firebase/` — **verouderd. Niet uit plannen.**

### Fase 18 (deze fase bouwt er direct op voort)
- `.planning/phases/18-preconditions/18-CONTEXT.md` — D-07 (Supabase West EU/Parijs, `eu-west-3`, project `https://hcdrydlgqpnmumfupgcx.supabase.co`), D-08 (Google Cloud-project `my-project-joost` wordt hergebruikt — dát is het mechanisme achter AUTH-05), D-19 (anon key is publiek van ontwerp).
- `.planning/quick/260717-no1-backlog-31-google-oauth-consent-screen-p/OAUTH-PUBLISH-CHECKLIST.md` — staat van het consent screen. **Regel 47 is onjuist** (de 100-gebruikerslimiet verdwijnt niet door publiceren); fase 18 heeft dat gecorrigeerd.
- `docs/ACCOUNTS-OPERATIONS.md` — runbook uit fase 18, inclusief de keep-warm-job en "sync werkt niet meer".

### Code die deze fase raakt
- `lib/services/calendar_service.dart:33-44` — het gememoizede `_sharedInitialize()`/`_initFuture`-hek. **Dit is de enige plek waar `GoogleSignIn.instance.initialize()` mag worden aangeroepen** (AUTH-05); auth gebruikt hetzelfde hek, met `serverClientId` erbij. Een tweede init geeft "Bad state: init() has already been called" — een bug die dit project al eens heeft opgelost.
- `lib/main.dart:62-77` — de `kIsWeb`-tak met `CalendarService.warmUpForWeb()` en de WorkManager-init; `Supabase.initialize()` komt hierbij in de buurt te staan zonder deze takken te wijzigen.
- `lib/features/profile/profile_screen.dart:47-134, 690-714` — de `_calendarConnected`-status, `_checkCalendarConnection()`, `_disconnectCalendar()` en de Calendar-`ListTile`. Het patroon dat D-02/D-10 hergebruiken.
- `lib/providers/` — het `@riverpod`-codegen-idioom (`build_runner`); `location_provider.dart` toont het reactieve `await ref.watch(...future)`-patroon.

</canonical_refs>

<code_context>
## Existing Code Insights

### Herbruikbare onderdelen
- **`CalendarService._sharedInitialize()`** — bestaat al precies om dubbele `GoogleSignIn`-init te voorkomen; auth erft dit in plaats van iets nieuws te bouwen. AUTH-05 is hiermee grotendeels een kwestie van niets nieuws maken.
- **De Calendar-rij in `profile_screen.dart`** — leading icon / title / subtitle-status / trailing TextButton + `CircularProgressIndicator` tijdens het checken. Kant-en-klaar patroon voor D-02 en de mismatch-regel.
- **`_SectionHeader`** — het sectiepatroon van het Profielscherm; de Account-sectie is er simpelweg één van.
- **Provider-override in tests** — de bestaande providertests overriden providers al; `authStateProvider` overriden is hetzelfde recept (D-20).

### Gevestigde patronen
- **Riverpod codegen** (`@riverpod` + `.g.dart` via `build_runner`) voor elke provider — `authStateProvider` volgt dat, met `keepAlive: true` (ARCHITECTURE §1).
- **Lazy, niet-promptende statuschecks** — het Profielscherm mag nooit uit zichzelf een OAuth-dialoog openen (CAL-02, backlog #36). Geldt ook voor de mismatch-check.
- **EN/NL l10n** voor elke gebruikerszichtbare tekst — geen kale strings in widgets.
- **Nederlandse commentaren en commitberichten** in dit project.

### Integratiepunten
- `pubspec.yaml` — `supabase_flutter` erbij (onderzoek noemt 2.16.0, geverifieerd 2026-07-25). Géén Gradle-plugin, géén `google-services.json`.
- `lib/main.dart` — `Supabase.initialize(url:, anonKey:)` moet klaar zijn vóór de eerste provider-read van `authStateProvider`.
- `lib/services/calendar_service.dart` — `serverClientId` erbij. **Dit zet de wijziging bovenop het werkende "Voeg toe aan agenda"-pad**; daarom is REG-04 hier een scherpe gate en geen formaliteit.
- `lib/platform/background_task.dart` — wordt in deze fase **niet** aangeraakt en krijgt géén Supabase-afhankelijkheid (REG-05, fase 20).

</code_context>

<specifics>
## Specific Ideas

- **Bewuste afwijking van AUTH-02's letterlijke tekst.** Het requirement vraagt "hetzelfde visuele patroon als de Calendar-rij"; de gebruiker koos een eigen sectie bovenaan met avatar. De *geest* (voelt als de rest van het scherm, trailing-actie zoals Calendar) blijft gehaald, de plaatsing niet. Downstream niet stilzwijgend "corrigeren" naar de requirementtekst.
- **Web mag er anders uitzien dan Android en dat is de beslissing, geen omissie** (D-05). Als een reviewer of verifier dat als inconsistentie aanmerkt: het is bewust, want Google's gerenderde knop is op web verplicht.
- De gebruiker vroeg bij de sleutelvraag expliciet om een aanbeveling in plaats van een keuze. Doortrekken naar de plannen: **leg bij console- en configstappen uit wáárom ze er zijn**, in gewone taal — dezelfde noot als in `18-CONTEXT.md`.
- Staande voorkeur uit fase 18, geldig voor de hele milestone: **"zo gratis en makkelijk mogelijk"** — kies de optie met de minste bewegende delen, en zeg het als de goedkopere optie een echt risico draagt.

</specifics>

<deferred>
## Deferred Ideas

- **Sync-belofte waarmaken** — de "Binnenkort:"-regel uit D-03 vervalt in fase 21, zodra profiel/beschikbaarheid/geplande ritten echt synchroniseren. Eén woord verwijderen, geen nieuwe l10n-sleutel.
- **`lastSyncedUid` als volwaardig eigendomsveld + `updatedAt`** — fase 19 slaat het uid alleen op om een wissel te herkennen (D-08). De echte MIG-04-semantiek (wanneer voor het laatst gewijzigd, welk account laatst gesynct) hoort bij fase 20/21.
- **In-app "Account verwijderen"** — AUTH-09, fase 21. Fase 18 leverde de verzoekroute op de privacybeleidspagina.
- **Sync-status in de account-sectie** (gesynchroniseerd / nog in wachtrij) — SYNC-06, fase 21. D-01 zorgt dat de sectie er dan al staat.
- **Uitleg over automatische naamsynchronisatie** — D-04 vult alleen een leeg veld; een tweerichtings-naamkoppeling is niet gevraagd en niet gepland.

</deferred>

---

*Phase: 19-Auth*
*Context gathered: 2026-07-26*
