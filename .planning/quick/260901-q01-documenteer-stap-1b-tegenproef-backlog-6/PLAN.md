---
id: 260901-q01
slug: documenteer-stap-1b-tegenproef-backlog-6
date: 2026-09-01
status: in-progress
---

# Stap 1b vastleggen — tegenproef op backlog #61

Op 2026-09-01 (18:29–18:42 device-tijd) is stap 1b uit `MORGEN.md` uitgevoerd op de
Oppo Find X9 Pro (PLG110), volledig via `adb`. Uitkomst: **PASS aan beide kanten van
de fix**, met een negatieve controle op de pre-fix build.

Deze quick task legt dat vast. Er verandert **geen** applicatiecode — dit is
uitsluitend documentatie van een handmatige verificatie.

## Taken

1. `MANUAL-VERIFICATION-21.md` — device session 9 toevoegen: opzet, beide helften van
   de fix, de negatieve controle, en de twee correcties op de meetopstelling.
2. `MORGEN.md` — stap 1b aftekenen, stap 2 (§6) als eerstvolgende zetten, en de
   openstaande testdata bijwerken.
3. `REGRESSION-CHECKLIST-21.md` — het openstaande §3-inlogitem (regel 266) aftekenen
   en de kanttekening uit augustus doorhalen met de nieuwe waarneming.

## Verificatie

De documenten beschrijven wat er gemeten is, inclusief wat níét is vastgesteld.
Geen codewijziging, dus geen testsuite-gate.
