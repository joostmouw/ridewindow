# Phase 06: UI Phase C — Profile + Availability + Tolerance Sliders
# Beslissingscontext

**Gemaakt:** 2026-06-03
**Gebaseerd op:** ROADMAP.md fase 6, technische beperkingen van de orchestrator, codebase-analyse

---

## Fase-doel

Een gebruiker kan de app volledig personaliseren — tolerantie-sliders aanpassen, rijlengtes
selecteren, de weekelijkse beschikbaarheidskalender bewerken — en ziet slots op Home direct
bijgewerkt na het opslaan.

---

## Vereisten

| ID | Omschrijving | Status |
|----|-------------|--------|
| PROF-01 | 3 tolerantie-sliders (temperatuur, regen, wind) in ProfileScreen | gepland |
| PROF-02 | Rijlengte-chips (2u / 3u / 4-5u) togglebaar; minstens één actief | gepland |
| PROF-04 | Material 3 light/dark thema-voorkeur; systeem-default acceptabel | gepland |
| AVAIL-01 | 7×24 beschikbaarheidsraster; cellen zijn bewerkbaar | gepland |
| AVAIL-02 | 3 celstaten: vrij / geblokkeerd / werk | gepland |
| AVAIL-03 | Beschikbaarheidswijzigingen persisteren direct naar SharedPreferences | gepland |

---

## Beslissingen

### D-06-01 — ThemeModeProvider als functionele provider
**Beslissing:** `themeModeProvider` is een `@riverpod` functionele provider die
`profileProvider.requireValue.theme` (String) omzet naar `ThemeMode`.
- `'system'` → `ThemeMode.system`
- `'light'` → `ThemeMode.light`
- `'dark'` → `ThemeMode.dark`
**Reden:** Minimale boilerplate; geen AsyncValue nodig (theme-string al in profileProvider).

### D-06-02 — Slider debouncing via onChangeEnd
**Beslissing:** Tolerantie-sliders gebruiken `onChangeEnd` (niet `onChanged`) om
`profileNotifier.updateTolerances()` aan te roepen. Lokale `StatefulWidget` state houdt de
live-slider-waarde bij tijdens slepen.
**Reden:** Voorkomt 30+ SharedPreferences-schrijfacties per swipe; de UI reageert direct
maar persisteert alleen bij loslaten.

### D-06-03 — ProfileScreen is ConsumerStatefulWidget
**Beslissing:** ProfileScreen gebruikt `ConsumerStatefulWidget` vanwege:
1. Lokale state voor live slider-waarden (vóór onChangeEnd)
2. Ref.watch voor profileProvider en beschikbaarheidsnavigatieknop
**Reden:** Dezelfde reden als HomeScreen — lokale state + Riverpod-consumption.

### D-06-04 — AvailabilityScreen is ConsumerWidget
**Beslissing:** AvailabilityScreen gebruikt `ConsumerWidget` (geen lokale state nodig).
Elke celtap roept direct `availabilityNotifier.toggleCustomHour(dt)` aan.
**Reden:** Alle state zit in AvailabilityNotifier; geen lokale buffer nodig.

### D-06-05 — Rooster huidige week, maandag als startdag
**Beslissing:** Het beschikbaarheidsrooster toont de lopende week (maandag t/m zondag).
Weekstart = `DateTime.now()` teruggerekend naar maandag (weekday - DateTime.monday).
Uren 0–23 als rijen, dagen maandag–zondag als kolommen.
**Reden:** Consistent met de week-strip in HomeScreen.

### D-06-06 — Werk-blokken zijn niet-toggelbaar vanuit het rooster
**Beslissing:** Cellen met `BlockType.work` reageren niet op taps. Alleen `BlockType.custom`
en vrije cellen worden getoggled. Visueel zichtbaar via de oranje kleur voor custom vs.
blauw/grijs voor work.
**Reden:** Werk-preset is gezaaid via onboarding; gebruikers kunnen hun werkschema niet
per uur verwijderen vanuit dit scherm (toekomstige verbetering).

### D-06-07 — /profile route toegevoegd aan router.dart
**Beslissing:** `/profile` route toegevoegd aan router.dart met import van ProfileScreen.
HomeScreen bottomNav `onDestinationSelected(1)` navigeert via `context.go('/profile')`.
**Reden:** Vereist door ROADMAP success criterion 5; al voorbereid in HomeScreen comment.

### D-06-08 — Beschikbaarheidsnavigatieknop in ProfileScreen
**Beslissing:** ProfileScreen heeft een `ListTile` of `ElevatedButton` "Mijn schema bewerken"
die navigeert naar `/availability`. Geen sub-route; de bestaande route wordt hergebruikt.
**Reden:** Eenvoudige navigatieknop is voldoende voor v1.

### D-06-09 — Thema-selectie via SegmentedButton
**Beslissing:** Drie opties (Systeem / Licht / Donker) worden weergegeven als
`SegmentedButton<String>` (Material 3). Aanroept `profileNotifier.setTheme(value)`.
**Reden:** Material 3 native component; geen extra pakket nodig.

### D-06-10 — Sliderwaarden
| Slider | Min | Max | Stap | Stuurt aan |
|--------|-----|-----|------|-----------|
| Temp min | 0°C | 20°C | 1°C | `tempMinIdealC` |
| Temp max | 15°C | 35°C | 1°C | `tempMaxIdealC` |
| Regen | 0mm | 5mm | 0.1mm | `rainMaxIdealMm` |
| Wind | 0km/u | 50km/u | 1km/u | `windMaxIdealKmh` |

---

## Uitgestelde ideeën (NIET plannen)

- Notificatie-toggles in ProfileScreen (fase 8)
- Locatie-override in ProfileScreen (fase 7)
- Kalenderweek-navigatie (volgende/vorige week) in AvailabilityScreen (post-v1)
- Werkschema-bewerkbaarheid vanuit AvailabilityScreen (post-v1)
- Animaties bij celtaps in het rooster (post-v1)

---

## Niet-onderhandelde technische feiten

1. `ProfileNotifier.updateTolerances()` bestaat al — geen nieuwe mutator nodig
2. `ProfileNotifier.toggleDuration()` bestaat al met last-chip-guard
3. `ProfileNotifier.setTheme()` bestaat al
4. `AvailabilityNotifier.toggleCustomHour()` bestaat al
5. `SlotsNotifier` kijkt al naar `profileProvider` en `availabilityProvider` via `ref.watch`
   → slider-/raster-wijzigingen herberekenen slots AUTOMATISCH (Riverpod reactiviteit)
6. `BlockType` enum bestaat in `availability_notifier.dart`
7. AvailabilityScreen-stub bestaat in `lib/features/availability/availability_screen.dart`
