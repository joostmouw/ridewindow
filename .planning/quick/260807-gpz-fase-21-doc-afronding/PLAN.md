---
id: 260807-gpz
slug: fase-21-doc-afronding
date: 2026-08-07
type: quick
mode: docs
---

# Fase 21 — documentatie bijwerken na de drie antwoorden van 2026-08-07

## Aanleiding

De web-sessie van 2026-08-06/07 eindigde met twee ongemeten punten (SYNC-11 en de webkant
van SYNC-04) en één openstaand besluit (§3 vraagt een iPhone die er niet is). Joost heeft
vandaag alle drie beantwoord:

1. **Desktop-tabblad:** beide ritten zichtbaar → een tabblad pikt een wijziging van elders op.
2. **Telefoon-tabblad na een echte tabwissel:** de augustusrit verschijnt → de voorgrond-reconcile
   vuurt wél in Chrome op Android.
3. **§3:** iOS uitstellen naar v2, §3 herschrijven naar wat op Android aantoonbaar is.

Antwoord 2 zet mijn eigen eerdere conclusie recht: er was nooit een voorgrond-overgang, dus
"het tabblad pikt de wijziging niet op" was ongefundeerd. Dat moet als correctie in het log,
niet stilzwijgend verdwijnen.

## Taken

1. **MANUAL-VERIFICATION-21.md** — nieuwe sessiesectie voor 2026-08-07 met SYNC-11 en de
   webkant van SYNC-04 als PASS, inclusief de expliciete intrekking van de eerdere
   "misschien een bug"-lezing en wat deze meting wél en níet dekt.
2. **REGRESSION-CHECKLIST-21.md** — §3 herschrijven: iOS-PWA uitgesteld naar v2 (met verwijzing
   naar de Android-only-constraint in CLAUDE.md), Android-WebAPK-installatie via "Zet op
   beginscherm" in de plaats, SYNC-04 aangetekend als al bewezen op 2026-08-07.
3. **MORGEN.md** — het web-blok sluiten en de openstaande lijst terugbrengen tot alleen de
   stappen die nog een toestel nodig hebben.

## Afbakening

Documentatie-only. Geen broncodewijziging, geen build, geen deploy. De suite hoeft niet te
draaien; wel een `git status` schoon achterlaten en per taak atomisch committen.

## Verificatie

- Geen enkele PASS in de docs zonder een genoteerde waarneming die hem draagt.
- §3 bevat geen iPhone-stap meer en verwijst expliciet naar v2.
- MORGEN.md bevat geen vragen meer die al beantwoord zijn.
