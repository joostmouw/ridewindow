# Phase 19: Auth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 19-Auth
**Areas discussed:** Account-rij in Profiel, Web sign-in knop, Wissel & mismatch, Sleutels & bewijs

---

## Account-rij in Profiel

### Plaatsing van het account-blok

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Eigen sectie bovenaan | Nieuwe `_SectionHeader(Account)` als eerste sectie, boven Naam/tolerantie | ✓ |
| Eigen sectie onderaan, boven 'Over' | Eigen kop maar uit de weg van de dagelijkse instellingen | |
| In 'Over', naast Calendar | Eén ListTile boven de Calendar-rij; minste code, letterlijk AUTH-02 | |

**Notities:** Bewuste afwijking van AUTH-02's letterlijke tekst. Fase 21 hangt sync-status onder dezelfde sectie.

### Ingelogde weergave

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Avatar + naam + e-mail | Google-profielfoto via `userMetadata['avatar_url']`, Uitloggen als TextButton | ✓ |
| Naam + e-mail, geen foto | Icoon i.p.v. foto; geen netwerkafhankelijkheid | |
| Alleen e-mail | Kaalst; ondubbelzinnig voor AUTH-07 | |

**Notities:** Fallback nodig als de netwerkafbeelding niet laadt.

### Bestaand naamveld (`profile.userName`)

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Niets — blijven gescheiden | Google-naam alleen in de account-sectie | |
| Invullen als het leeg is | Auto-invullen bij eerste inlog, nooit overschrijven | ✓ |
| Vragen bij inlog | Eenmalige prompt | |

**Notities:** Gevolg voor fase 20/21 vastgelegd — de auto-invulling mag `profile.updatedAt` (MIG-04) niet zo bewegen dat het op divergentie lijkt.

### Uitgelogde weergave

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Knop + belofte-regel | Uitleg over sync | ✓ (in aangepaste vorm) |
| Alleen de knop | Belooft niets dat nog niet werkt | |
| Knop + neutrale uitleg | Beschrijft alleen het heden | |

**Gebruikers-reactie:** "wat raadt jij aan? En waarom?" — daarna akkoord met het advies.
**Notities:** Advies was optie 1 mét de belofte in de toekomende tijd ("Binnenkort: …"), omdat (a) zonder "waarom" niemand tikt en AUTH-10 dan niet getest raakt, (b) een belofte in de tegenwoordige tijd bugmeldingen oplevert, (c) fase 21 alleen één woord hoeft te verwijderen.

---

## Web sign-in knop

### Platformverschil

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Elk platform zijn eigen | Android eigen ListTile via `authenticate()`, web Google's `renderButton()` | ✓ |
| Overal Google's knop | Eén look, één codepad, minder styling op Android | |
| Eigen rij, Google-knop verstopt | Bottom sheet op web; extra tik en popup-blokkeerrisico | |

**Notities:** Vertakking op `supportsAuthenticate()`, niet op `kIsWeb`.

### Feedback bij succes/fout

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Snackbar, stil bij annuleren | Succes zichtbaar in de sectie; fout via SnackBar; annuleren stil | ✓ |
| Snackbar bij alles | Ook succes bevestigen | |
| Dialoog bij fouten | Technische oorzaak zichtbaar; beter voor eigen diagnose | |

---

## Wissel & mismatch

### Ander Google-account op hetzelfde toestel (AUTH-08)

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Vragen: houden of wissen | uid-vergelijking + één dialoog; nooit stil wissen | ✓ |
| Alleen registreren | uid opslaan, AUTH-08 feitelijk naar fase 21 | |
| Automatisch wissen | Hard voldaan, maar vernietigt data van een nooit-ingelogde gebruiker | |

**Notities:** De uid-vergelijking is het fundament voor fase 21's resolver (MIG-04).

### Calendar-accountmismatch (AUTH-07)

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| In Profiel, bij de Calendar-rij | Waarschuwingsregel + icoon op de bestaande rij | ✓ |
| Bij 'Voeg toe aan agenda' | Bevestigingsdialoog op het beslismoment | |
| Allebei | Maximale dekking, twee teksten, extra tik | |

**Notities:** Bewust géén wrijving op de agenda-flow — dat is REG-04's gate.

### Wat 'Uitloggen' doet

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Alleen Supabase, met bevestiging | Dialoog zegt expliciet dat lokale gegevens blijven | ✓ |
| Alleen Supabase, direct | Consistent met de Calendar-Ontkoppel-knop | |
| Allebei losmaken | Ruimt de mismatch op bij de bron, sloopt een losse koppeling | |

---

## Sleutels & bewijs

### Supabase-URL en anon key

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Constanten in de code | `lib/core/supabase_config.dart`; geen build-commando verandert | ✓ (Claude's aanbeveling) |
| `--dart-define-from-file` | Netter op papier; vergeten vlag = stil kapotte build | |
| Buildtime nu, .env later | TODO die blijft staan | |

**Gebruikers-reactie:** "ik heb geen idee. Weet jij dat niet?" — beslissing aan Claude gelaten.
**Notities:** Uitgelegd dat de anon key publiek van ontwerp is (zit sowieso leesbaar in APK en webbundel) en dat RLS de beveiliging is. Sluit aan bij `18-CONTEXT.md` D-19.

### Afsluiting van de fase (AUTH-10)

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Upload naar internal track | Play Store-installatie testen; enige manier waarop AUTH-10 waar is | ✓ |
| Lokale release-APK eerst | Sneller, maar test de verkeerde SHA-1 | |
| Allebei, in die volgorde | Meeste zekerheid, twee testrondes | |

### Regressiebewijs (REG-01/02/04 + koudestartbasislijn)

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Checklist in de fase-map | `REGRESSION-CHECKLIST.md`, herbruikbaar in fase 21 | ✓ |
| In de plannen zelf | Minder papierwerk, bewijs verspreid | |
| Checklist + koudestart apart | Meetmethode los vastgelegd | |

**Notities:** De meetmethode van de koudestart is alsnog op de checklist gezet (CONTEXT D-19), omdat fase 21's hermeting anders niet vergelijkbaar is.

### Automatische tests

| Optie | Omschrijving | Gekozen |
|-------|--------------|---------|
| Widget + unit, gefakete auth | Drie widget-toestanden via provider-override + unit-tests voor de beslislogica | ✓ |
| Alleen unit, rest handmatig | Account-sectie zonder widgetdekking | |
| Zo weinig mogelijk | Alles handmatig; regressies pas met de hand zichtbaar | |

---

## Claude's Discretie

- Exacte teksten en l10n-sleutelnamen (EN + NL), inclusief wissel- en uitlogdialoog
- Positie van `Supabase.initialize()` in `main.dart` t.o.v. het bestaande parallelle init-blok
- Seeden van `authStateProvider` uit `currentSession` (AUTH-04, geen flikkering)
- Laadstatus van de account-sectie en de avatar-fallback
- Plaatsing en laadstatus van de web-`renderButton()`
- Plan-indeling, volgorde en vorm van de handmatige checklist
- Volledige keuze voor de configuratieaanpak van de Supabase-sleutels (expliciet aan Claude gelaten)

## Deferred Ideas

- "Binnenkort:"-regel laten vervallen zodra sync leeft — fase 21
- `lastSyncedUid` als volwaardig eigendomsveld + `updatedAt` (MIG-04) — fase 20/21
- In-app "Account verwijderen" (AUTH-09) — fase 21
- Sync-status in de account-sectie (SYNC-06) — fase 21
- Tweerichtings-naamsynchronisatie — niet gevraagd, niet gepland
