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
| 9 | **Accessibility audit** — screenreader labels, contrast ratio's, touch targets >=48dp | HOOG | M | Backlog |
| 10 | **Crashlytics / analytics** — Firebase free tier voor crash reports en usage metrics | MEDIUM | M | Backlog |
| 11 | **Test coverage inhaalslag** — openstaande widget tests (Phase 4-05), weather_repository tests, profile scroll tests. **Aanvulling (quick-260714-nfk):** `profile_screen_notif_test.dart` faalt zelfstandig (los van eigen wijzigingen bevestigd via git-bisectie) met "Bad state: No element" / `S.of(context)` null-check-crashes wanneer meerdere Profile-scherm test-bestanden in hetzelfde `flutter test`-proces draaien; `ride_detail_screen_test.dart` toont los ook 13 falende tests. Vermoedelijke oorzaak: Flutter SDK-versiedrift sinds deze tests geschreven zijn, of localization-delegate/test-binding state-lekkage tussen test-bestanden — nader te onderzoeken. **Aanvulling (Phase 17-01, 2026-07-17):** volledige `flutter test`-baseline vastgesteld: 215 passing / 69 failing over 13 bestanden — `ride_detail_screen_test.dart` (13), `insights_sheet_test.dart` (13), `availability_screen_test.dart` (11-12, licht wisselend), `profile_screen_test.dart` (5), `profile_screen_notif_test.dart` (5), `weather_repository_test.dart` (3-5, licht wisselend), `home_screen_test.dart` (4), `detail/ride_detail_screen_calendar_test.dart` (4), `onboarding_screen_test.dart` (3), `welcome_screen_test.dart` (2), `home_screen_location_test.dart` (2), `providers/integration_test.dart` (1), en incidenteel `core/pwa_display_mode_test.dart` of `providers/slots_notifier_test.dart` (1) — de totalen (215/69) zijn stabiel over herhaalde runs maar de exacte verdeling over 2-3 bestanden wisselt licht per run, wat de vermoede test-binding/localization state-lekkage tussen bestanden bevestigt. Geen van deze falingen is veroorzaakt door Phase 17 (geen source-wijzigingen in die plan) | HOOG | M | Backlog |
| 12 | **Scoring engine v2 tuning** — kalibratie op basis van echte tester-feedback ("score zei 85 maar het was koud") | HOOG | M | Done (1be0b62) |
| 13 | **Kledingadvies-tip** — korte aanbeveling per slot op basis van temperatuur, windchill en regen (bijv. "Armwarmers + windjack") | MEDIUM | S | Done (2c7738c) |
| 14 | **Persoonlijke begroeting op Home** — tijdsafhankelijke greeting met naam ("Good morning Joost", "Welcome back Joost") | MEDIUM | S | Done (2c7738c) |
| 15 | **Drag-to-select beschikbaarheid** — sleep over meerdere cellen om ze in een keer te togglen + rij/kolom-headers om hele dag/uur te selecteren | HOOG | M | Done (2c7738c) |
| 16 | **Debug/reset menu** — verborgen menu (5x tik op versienummer) met reset onboarding, wis cache, reset beschikbaarheid, forceer refresh | MEDIUM | S | Done (2c7738c) |
| 17 | **Los tikken/slepen op aaneensluitende uren moet samensmelten tot één tijdvak (Availability + Agenda)** — *(verduidelijkt n.a.v. quick-260714-o54 test-feedback, was: "drag werkt niet")*. Opgelost via een twee-tik-bereik model: 1e tik opent een blok, 2e tik (zelfde dag) vult het bereik aan tot aan de vaste ankertik; sleepgebaar op Availability blijft daarnaast bestaan. Toegepast op zowel de Availability-grid als de Agenda-tab (waar long-press nu ook overal weer-detail-info toont i.p.v. sleep-selectie) | HOOG | M | Done (e5a3683, 52495b9) |
| 18 | **Verlopen tijden grijs tonen in Agenda** — tijdstippen die al voorbij zijn moeten visueel duidelijk gemarkeerd worden (bijv. grijze kleur) in plaats van er hetzelfde uit te zien als toekomstige tijden | MEDIUM | S | Backlog |
| 19 | **Verlopen ride-slots verbergen op Home** — Home-scherm moet alleen ride-vensters tonen waarvan de starttijd nog moet komen; slots waarvan de starttijd al voorbij is moeten niet meer op Home verschijnen | MEDIUM | S | Backlog |
| 31 | **Google OAuth consent screen publiceren (of volledig laten verifiëren)** — Calendar-koppeling (CAL-06/07) werkte mogelijk alleen voor handmatig toegevoegde test-users (Testing-modus, max 100). **Update (2026-07-17, geverifieerd in Cloud Console):** Publishing status bleek al **"In production"** te staan (User type: External) — geen actie nodig, de aanname dat de app nog in Testing-modus stond was onjuist/verouderd. Calendar-koppeling is dus al toegankelijk voor elk Google-account (met het eenmalige "niet geverifieerd door Google"-scherm, want geen formele Google-verificatie aangevraagd — scope is Sensitive, niet Restricted, dus dat is geen blokkade) | HOOG | S/M | Done — already in production, verified 2026-07-17 |
| 33 | **Feedback-formulier voor gebruikers** — "Send feedback"-entry in Profile opent dialog met 1-5 sterren-rating + vrije tekst, verstuurd via mailto: naar joostmouw@gmail.com (geen backend, geen nieuwe dependency) | HOOG | S | Done (9d9d5ab) |
| 34 | **"Plan ride"-knop sticky op Ride Detail** — *(gecorrigeerd, was verkeerd toegeschreven aan Availability — die knop bestaat daar niet)*. Op Ride Detail (lang scherm: Adjust Time → Weather → Hourly-tabel → Plan ride) moet de groene "Plan ride"-knop onderin vastgeplakt (sticky) blijven tijdens het scrollen/aanpassen, i.p.v. pas zichtbaar na volledig doorscrollen. Uitgebreid met een reactieve "Planned" + vinkje-status wanneer het venster al gepland is, en unplan/delete (met bevestiging) vanaf zowel Ride Detail als Home | MEDIUM | S | Done (0b56a92, a109aa2, 5ce3e6e) |
| 35 | **Live teller "X losse tijdvakken" tijdens selecteren op Availability** — tijdens het aanvinken/slepen in de wekelijkse beschikbaarheids-grid toont de app hoeveel losse (niet-aaneengesloten) tijdvakken je nu hebt geselecteerd. Geen claim over exact aantal ritten (dat bepaalt de score-engine later, elders) — puur een live selectie-indicator | MEDIUM | S | Done (1703d60, e5a3683) |
| 36 | **Google Calendar-koppeling zichtbaar/beheerbaar in Profile** — nieuwe "Google Calendar"-rij in Profile's OVER-sectie toont Connected/Not connected (boolean, geen e-mailadres beschikbaar via de scope-only OAuth-flow) via `authorizationForScopes` (prompt-vrije check), met een "Disconnect"-actie via `GoogleSignIn.instance.disconnect()` | MEDIUM | S | Done (8fd1e99) |
| 37 | **Regen-icoontje verschijnt bij droog weer** — root cause: het regenwolk-emoji stond hardcoded in alle takken van de neerslag-tekst in Ride Detail's Hourly-tabel, inclusief de "dry"-tak. Uitgebreid met zon (☀️) bij droog + geen regenkans, en licht-bewolkt (⛅) bij droog + 1-30% regenkans (proxy voor bewolking, want geen echte cloud-cover data beschikbaar) | HOOG | S | Done (c5967b9) |
| 38 | **Tip: Google-account koppelen in iOS Agenda-instellingen** — tester-observatie (Phase 15 iPhone-verificatie): een aangemaakt Calendar-event staat wél in Google Calendar maar niet automatisch in de native iPhone Agenda-app, tenzij het Google-account is toegevoegd via iOS Instellingen → Agenda → Accounts. Overweeg een korte in-app tip/uitleg hierover (bijv. na eerste "Add to calendar" op web/iOS) zodat gebruikers niet denken dat de koppeling niet werkt | LAAG | S | Backlog |

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
| 40 | **Wear OS companion** — tile/complication die volgende slot toont op smartwatch | MEDIUM | L | Backlog |
| 41 | **Sociaal / groepsritten** — "Wanneer kunnen wij allemaal?" met gedeelde beschikbaarheid. Tester-verduidelijking (Jacco, Phase 15 iPhone-test): concreter, kleiner startpunt zou zijn iemand uitnodigen voor één specifieke rit, die persoon accepteert en ziet 'm terug in zijn eigen app — evt. uitgebreid met het zien van elkaars beschikbaarheid om een overlap te vinden | MEDIUM | XL | Backlog |
| 48 | **Lokale ride-matching** — gebruikers in dezelfde omgeving die zich voor hetzelfde slot aanmelden kunnen samen een rit plannen | MEDIUM | XL | Backlog |
| 42 | **Historische analytics** — "Beste maand om te fietsen", trend over seizoenen | LAAG | L | Backlog |
| 43 | **Backend + user accounts** — cross-device sync, maar vereist auth, hosting, GDPR | LAAG | XL | Backlog |
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
*Laatst bijgewerkt: 2026-07-15 (items 31-39 toegevoegd n.a.v. Phase 15 Calendar-verificatie: OAuth consent screen, agenda-event bijwerken bij nieuwe weersdata, feedback-formulier, sticky "Plan ride"-knop, duidelijkere feedback bij niet-aaneengesloten selectie, Calendar-koppeling in Profile, regen-icoon bug bij droog weer (afgerond), tip over iOS Agenda-koppeling, en kwartier-precisie bij Adjust Time; items 17, 34, 35 afgerond — twee-tik-bereik selectiemodel op Availability + Agenda, sticky Planned-knop met unplan/delete, live losse-tijdvakken-teller); 2026-07-17 (item 31: fast-publish route gekozen voor OAuth consent screen, instructies klaargezet voor Joost, zie OAUTH-PUBLISH-CHECKLIST.md — bij controle in Cloud Console bleek Publishing status al "In production" te staan, dus item afgerond zonder dat de "Publish app"-klik nog nodig was)*
