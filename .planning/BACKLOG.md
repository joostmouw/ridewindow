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
| 11 | **Test coverage inhaalslag** — openstaande widget tests (Phase 4-05), weather_repository tests, profile scroll tests | HOOG | M | Backlog |
| 12 | **Scoring engine v2 tuning** — kalibratie op basis van echte tester-feedback ("score zei 85 maar het was koud") | HOOG | M | Done (1be0b62) |
| 13 | **Kledingadvies-tip** — korte aanbeveling per slot op basis van temperatuur, windchill en regen (bijv. "Armwarmers + windjack") | MEDIUM | S | Done (2c7738c) |
| 14 | **Persoonlijke begroeting op Home** — tijdsafhankelijke greeting met naam ("Good morning Joost", "Welcome back Joost") | MEDIUM | S | Done (2c7738c) |
| 15 | **Drag-to-select beschikbaarheid** — sleep over meerdere cellen om ze in een keer te togglen + rij/kolom-headers om hele dag/uur te selecteren | HOOG | M | Done (2c7738c) |
| 16 | **Debug/reset menu** — verborgen menu (5x tik op versienummer) met reset onboarding, wis cache, reset beschikbaarheid, forceer refresh | MEDIUM | S | Done (2c7738c) |

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

---

## v3+ — Toekomstvisie

Ideen die pas relevant worden als v1+v2 gevalideerd zijn.

| # | Item | Waarde | Effort | Status |
|---|------|--------|--------|--------|
| 40 | **Wear OS companion** — tile/complication die volgende slot toont op smartwatch | MEDIUM | L | Backlog |
| 41 | **Sociaal / groepsritten** — "Wanneer kunnen wij allemaal?" met gedeelde beschikbaarheid | MEDIUM | XL | Backlog |
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
*Laatst bijgewerkt: 2026-06-18*
