# Productie-aanvraag vastleggen en OPEN.md opschonen

Datum: 2026-10-09. Aanleiding: Joost heeft vanmiddag om 15:53 in Play Console
"Apply for access to production" ingediend (de drie antwoordteksten zijn deze
sessie opgesteld vanuit de projectarchieven). Daarna expliciet akkoord op:
opschonen eerst, dan bug 0a.

## Plan

1. **Punt 3 (feedbackadres) verifiëren.** De changelog van build 53 claimt dat
   privacybeleid en Console allebei op `joostmouw@gmail.com` staan; nameten in
   `docs/privacy-policy.html` in plaats van aannemen.
2. **Punt 9 (debugsessie test-binding-state-leakage) sluiten.** Vaststellen wat
   er van de hypothese klopt door de sessie zelf te lezen en de kopie in
   `debug/` te vergelijken met die in `debug/resolved/`.
3. **De aanvraag vastleggen** in `STATE.md` (Waar|Stand) en `OPEN.md`
   (randvoorwaarden tot de uitslag: track-opzet ongemoeid laten, blijven
   releasen, afkeur-scenario).
4. Daarna **bug 0a** (PLANNED-kaartjes springen bij koude start) diagnosticeren
   als eigen debug-dossier.

## Grenzen

- Alleen `.planning/` en deze taakmap; geen app-code in deze taak.
- Geen commit van andermans onbeheerde bestanden (photos, active-workstream,
  260930-remote-droid-mac-mini blijven staan zoals ze staan).
