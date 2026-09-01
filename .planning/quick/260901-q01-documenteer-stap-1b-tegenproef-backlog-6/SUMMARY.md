---
id: 260901-q01
slug: documenteer-stap-1b-tegenproef-backlog-6
date: 2026-09-01
status: complete
---

# Stap 1b vastgelegd — backlog #61 tegengeproefd op het toestel

Uitgevoerd 2026-09-01, 18:29–18:42 device-tijd, Oppo Find X9 Pro (PLG110), volledig via `adb`.
Geen applicatiecode gewijzigd — dit is de vastlegging van een handmatige verificatie.

## Uitkomst

**Backlog #61: PASS aan beide kanten van de fix.**

| Helft | Proef | Uitkomst |
|---|---|---|
| Inlogflow (`account_section.dart:328`) | site-data gewist → verse inlog → direct naar Home | PASS |
| Koude start (`reconcileOnStartup` vanuit `HomeScreen.initState`) | cloud-only rit → force-stop → koude start | PASS |

Negatieve controle: de native app 1.0.21+22 (vóór de fix), zelfde toestel, zelfde sessie, zelfde
cloud, toonde bij koude start géén PLANNED en vulde zich pas na één achtergrond→voorgrond-cyclus.

## Twee correcties op wat er in MORGEN.md stond

1. De wisinstructie (Instellingen → Apps → Gegevens wissen) is fout voor een WebAPK — dat pakket is
   een launcher-shell, de opslag zit in Chrome's profiel voor het origin. Gewist via Chrome →
   Site-instellingen → Alle sites → Delete site data.
2. De precondition ontbrak: er stonden nul geplande ritten (de augustusritten zijn verleden tijd).

## Nevenwaarneming, niet gefixt

Een rit plannen enqueuet wel maar duwt niet: de outbox loopt alleen leeg bij app-start, een
voorgrond-overgang of na inloggen. "Syncing…" bleef daardoor ~45s staan. Verwacht gedrag gegeven de
huidige triggers, maar het lijkt op een vastloper en het betekent dat een rit die je plant vlak
voordat je je telefoon weglegt, pas bij de volgende opening verstuurd wordt.

## Gewijzigde bestanden

- `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md` — device session 9
- `.planning/phases/21-sync-migration/MORGEN.md` — 1b afgetekend, §6 is nu de eerstvolgende
- `.planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md` — §3-inlogitem afgetekend,
  kanttekening uit augustus opgeheven, #61-item toegevoegd
