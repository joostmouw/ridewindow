# Phase 21: Sync + migration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-03
**Phase:** 21-sync-migration
**Areas discussed:** Account verwijderen (AUTH-09), Conflict-dialoog UX (MIG-03), Sync-statusindicator (SYNC-06)

---

## Account verwijderen (AUTH-09)

**Question:** Hoe zwaar moet de bevestiging zijn voordat een account echt verwijderd wordt?

| Option | Description | Selected |
|--------|-------------|----------|
| Dialoog met waarschuwingstekst | Zelfde stijl als bestaande dialogen (account_section.dart:194): "dit kan niet ongedaan worden" + twee knoppen. Laagste bouwmoeite. | ✓ |
| Tik-om-te-bevestigen | Gebruiker typt een woord of e-mailadres voordat de knop actief wordt. Meer frictie, iets meer bouwwerk. | |
| Opnieuw inloggen ter bevestiging | Gebruiker moet vlak voor verwijderen opnieuw door de Google-inlogflow. Zwaarste optie. | |

**User's choice:** Dialoog met waarschuwingstekst (Claude's aanbeveling gevolgd)

**Question:** Wat gebeurt er direct nadat de server bevestigt dat het account verwijderd is?

| Option | Description | Selected |
|--------|-------------|----------|
| Automatisch uitloggen + melding | App logt direct uit, toont een korte snackbar/melding, gebruiker landt op het normale signed-out scherm. | ✓ |
| Apart bevestigingsscherm | Een los scherm dat expliciet bevestigt dat verwijdering gelukt is. | |

**User's choice:** Automatisch uitloggen + melding (Claude's aanbeveling gevolgd)

**Question:** Moet het verwijderen van het account ook de lokale instellingen op het toestel wissen?

| Option | Description | Selected |
|--------|-------------|----------|
| Lokale data blijft staan | Past bij "accounts zijn additief" — verwijderen raakt alleen de server. | ✓ |
| Lokale data ook wissen | Voelt als volledige reset, net als de bestaande "start fresh"-optie bij accountwissel. | |

**User's choice:** Lokale data blijft staan (Claude's aanbeveling gevolgd)

**Notes:** Gebruiker vroeg eerst "wat is account verwijderen?" — Claude legde uit dat dit een Google Play-verplichting is sinds 2024-04-15 (in-app account+data-verwijdering, niet alleen uitloggen) en dat het mechanisme (`on delete cascade` vanaf `auth.users`) al vastligt in 18-CONTEXT.md D-16. Na die uitleg koos de gebruiker dit als eerste te bespreken gebied.

---

## Conflict-dialoog UX (MIG-03)

**Question:** Wanneer een echt conflict optreedt, hoe moet de gebruiker kiezen welke versie wint?

| Option | Description | Selected |
|--------|-------------|----------|
| Simpele twee-knoppen-dialoog | Zelfde AlertDialog-stijl als de bestaande accountwissel-dialoog, geen preview. | ✓ |
| Dialoog met korte samenvatting | Toont bijv. laatste-wijziging-tijdstip per versie. | |
| Volledige diff-preview | Laat precies zien welke velden verschillen. | |

**User's choice:** Simpele twee-knoppen-dialoog (Claude's aanbeveling gevolgd)

**Question:** Als profiel en beschikbaarheid tegelijk conflicteren, hoe presenteer je dat?

| Option | Description | Selected |
|--------|-------------|----------|
| Eén dialoog per domein, na elkaar | Eerst profiel, dan beschikbaarheid. Simpeler te bouwen. | ✓ |
| Eén gecombineerde dialoog | Beide keuzes in één scherm. Complexere UI-state. | |

**User's choice:** Eén dialoog per domein, na elkaar (Claude's aanbeveling gevolgd)

---

## Sync-statusindicator (SYNC-06)

**Question:** Waar en hoe ziet de gebruiker of zijn data gesynchroniseerd is of nog in de wachtrij staat?

| Option | Description | Selected |
|--------|-------------|----------|
| Kleine tekstregel in accountsectie | "Gesynchroniseerd" / "Wordt gesynchroniseerd..." onder naam/e-mail. | ✓ |
| Icoon/badge naast accountnaam | Compacter, minder expliciet, geen bestaand icoon-vocabulaire. | |
| Alleen tonen bij problemen | Standaard niets zichtbaar. | |

**User's choice:** Kleine tekstregel in accountsectie (Claude's aanbeveling gevolgd)

**Question:** Is "gesynchroniseerd" vs "in de wachtrij" voldoende, of een derde status voor herhaalde fouten?

| Option | Description | Selected |
|--------|-------------|----------|
| Twee statussen volstaan | Consistent met de bewust simpele outbox-aanpak (geen backoff, geen foutmeldingen dit milestone). | ✓ |
| Derde status voor herhaalde fouten | Meer zichtbaarheid, maar vraagt extra outbox-logica buiten scope van dit milestone. | |

**User's choice:** Twee statussen volstaan (Claude's aanbeveling gevolgd)

---

## Claude's Discretion

- Exacte snackbar-tekst, knoplabels, en destructieve-knop-styling (bijv. rode verwijder-knop) — standaard Material 3-conventies, geen specifieke bewoording opgelegd.
- Alles al vastgelegd in ARCHITECTURE.md §1–7 (schema, RLS-policyvorm, outbox-mechaniek, `resolveAccountSync`-logica, provider-wiring, bouwvolgorde) is geen onderdeel van deze discussie geweest — dat document is de primaire technische bron voor deze fase.

## Deferred Ideas

None — discussie bleef binnen de fase-scope. Tik-om-te-bevestigen/re-auth (afgewezen voor deletion) en een derde sync-foutstatus (afgewezen voor SYNC-06) zijn bewuste "nee, niet dit milestone"-beslissingen, geen vergeten todo's.
