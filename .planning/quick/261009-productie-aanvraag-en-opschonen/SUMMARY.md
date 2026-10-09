# SUMMARY: productie-aanvraag vastgelegd, OPEN.md opgeschoond

Datum: 2026-10-09.

## Gedaan

- **Productie-aanvraag vastgelegd** in `STATE.md` (nieuwe Waar|Stand-sectie) en
  `OPEN.md` (nieuwe bovenste sectie met de randvoorwaarden tot de uitslag:
  track-opzet ongemoeid laten, blijven releasen, wat te doen bij afkeuring of
  goedkeuring).
- **OPEN.md punt 3 (feedbackadres) geverifieerd en gesloten.** Alle vier de
  plekken in `docs/privacy-policy.html` noemen `joostmouw@gmail.com` — de claim
  uit de changelog van build 53 klopt. Geen wijziging nodig, alleen de status.
- **OPEN.md punt 9 (debugsessie test-binding-state-leakage) gesloten.** De
  sessie was al op 2026-07-18 afgerond: `debug/resolved/` bevat de eindversie
  met `status: resolved` en sluitingsnotitie. In `debug/` stond een oudere
  kopie op `awaiting_human_verify`; de diff was 40 regels (alleen de status en
  de sluitingsnotities), dus de kopie bevatte niets unieks en is verwijderd.
  De hypothese bleek bevestigd (missende `S.localizationsDelegates` en
  thema-extensie in test-wrappers, géén cross-file lekkage) en het symptoom is
  weg: de suite staat op 1087 groen (build 66, vandaag).

## Vondsten

- **Een verhuisde debugsessie laten staan op de oude plek maakt een spook.**
  Punt 9 bestond alleen omdat de kopie in `debug/` na de verhuizing naar
  `resolved/` niet was opgeruimd; drie maanden later las een sessie dat als
  "nooit afgerond". Bij een verhuizing hoort de oude plek weg.
- **Een changelog-claim controleren kost één grep.** Punt 3 stond twee weken
  open als "beslissing bij Joost" terwijl de beslissing in build 53 al genomen
  en doorgevoerd was. De les uit punt 14 geldt hier ook: verifieer in het
  systeem zelf, niet in de notitie erover.

## Niet gedaan

- Bug 0a (PLANNED-kaartjes springen bij koude start): volgende stap, eigen
  debug-dossier.
- Bug 0b (update-balk): bewust laten liggen tot na de uitslag van Google.
