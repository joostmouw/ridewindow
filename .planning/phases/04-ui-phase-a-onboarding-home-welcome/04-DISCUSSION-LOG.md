# Phase 04 Discussion Log

**Date:** 2026-06-03
**Phase:** 04 — UI Phase A: Onboarding + Home + Welcome

---

## Areas discussed

### Navigation gate

| Vraag | Opties | Keuze |
|-------|--------|-------|
| Hoe bepaalt go_router bij app-start welk scherm te tonen? | Redirect via SharedPreferences / InitialLocation in main.dart / Splash tussenstap | Redirect via SharedPreferences |
| Na Onboarding: direct naar /home of tussenstap? | Direct naar /home / Locatiepermissie tussenscherm / Je beslist | Direct naar /home |

### Preset uren

| Vraag | Opties | Keuze |
|-------|--------|-------|
| Preset model: vrije uren of geblokkeerde uren? | Presets zetten vrije uren / Presets zetten geblokkeerde uren / Je beslist | Vrije uren (rest = geblokkeerd) |
| Exacte uren per preset | Mockup letterlijk / Ruimere definitie / Je beslist | Mockup letterlijk |
| "Set my own schedule" in Phase 4 | Direct naar /home lege availability / Navigeer naar /availability stub / Deactiveer knop | Navigeer naar /availability stub |
| 3-state model: wanneer implementeren? | Nu in Phase 4 (Map<DateTime, BlockType>) / Phase 4 zaait flat, Phase 6 migreert / Je beslist | Nu in Phase 4 |

**Gebruikersnotitie:** "Niet iedereen werkt van 9 tot 5 — het moet mogelijk zijn om werkuren aan te passen. Onderscheid tussen werk, geblokkeerd (eigen events) en vrij is essentieel."

### Locatie placeholder

| Vraag | Opties | Keuze |
|-------|--------|-------|
| Locatie in Phase 4 (GPS is Phase 7) | Hardcoded Amsterdam / Configureerbare default in config.dart / Leeg veld | Configureerbare default in config.dart |
| Loading state op Home (geen cache) | Skeleton cards / CircularProgressIndicator / Lege staat met tekst | Skeleton cards |

### Week strip gedrag

| Vraag | Opties | Keuze |
|-------|--------|-------|
| Filtert dag-tap de ride-cards? | Ja, tap filtert naar die dag / Puur visueel in Phase 4 / Je beslist | Tap filtert cards |
| Hoe deselect je (terug naar alle week)? | Opnieuw tikken op dezelfde dag / All-tab naast de 7 dagen / Je beslist | Opnieuw tikken deselecteert |

---

## Deferred ideas

- Custom werkuren-picker tijdens onboarding (voor niet-9-to-5 gebruikers) → Phase 6
- Recurring custom blocks (bijv. elke dinsdag voetbal) → Phase 6+
