---
phase: 34-groep-maken-en-beheren
plan: 08
status: complete-with-deferral
requirements: [CLUB-01, CLUB-02, CLUB-03, CLUB-04, CLUB-05, CLUB-06, CLUB-07, CLUB-08, CLUB-09, CLUB-11, CLUB-27, CLUB-28]
completed: 2026-09-24
---

# 34-08 — Toestel en echte gebruikers

## Task 1 — testroute
Joost koos **option-b** (Play internal track), 2026-09-24.

## Task 2 — bouwen en zelf nalopen
- Versie **1.0.43 (54)** (`1ce0daf`), 864/864 tests, analyze zonder errors/warnings.
- Alleen naar **internal**; alpha bleef 1.0.42 (53). Geen promotie.
- Op de Oppo via adb: update uit Play geïnstalleerd (versionCode 54). Schermen in licht én
  donker vastgelegd in `screens/` (Peloton-tab en groepsscherm): contrast, chips en ⋮ leesbaar.
- Tussendoor bleek adb-daemon na een `kill-server` in de sandbox niet te herstarten; later
  vanzelf weer bruikbaar.

## Task 3 — echte doorloop
- Joost maakte de groep **"On the Roll"** en voegde **Jacco** (iPhone-PWA) als maatje direct toe
  (beheerder → direct lid) en maakte hem beheerder. Werkt end-to-end tussen Android en PWA.
- Jacco's eerste poging via de groepslink gaf op de **live PWA** `GoException: no routes for
  location: /group/...` — de live webapp kende de route nog niet. Op Joosts "yes" is de
  **webapp live gezet** (build uit `ca767d6`-lijn, `firebase deploy --only hosting`) en het
  **privacybeleid** kreeg een alinea over groepsleden (`docs/privacy-policy.html`, gepusht naar
  GitHub Pages). Daarmee is CLUB-21 inhoudelijk al gedaan; fase 36 hoeft alleen na te lopen.
  De kale foutpagina staat als **backlog #79**.

## Uitgesteld (bewust, door Joost: "sluit 34 af")
- De **aanvraag-via-link-stroom** (iemand opent de link → "1 aanvraag" → accepteren/afwijzen) is
  op de live database bewezen (62/62 + 83/83) en in widgettests, maar nog niet door een echte
  tweede gebruiker doorlopen. Dat gebeurt in de tweeaccountstest van fase 36 (CLUB-24), of
  eerder zodra iemand de link van "On the Roll" gebruikt.
