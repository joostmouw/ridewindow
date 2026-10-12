# 38-03 — 0016 live, en het bewijs over het publieke pad

Status: af. Fase 38 is daarmee dicht (RATE-01 t/m RATE-05).

## Wat er live gebeurde (2026-10-12)

| Tijd (UTC) | Stap | Uitkomst |
|---|---|---|
| vóór 06:15 | Plafonds 30/20/20/120 bevestigd, `0016_rate_limits.sql` in de SQL Editor | `Success. No rows returned` |
| 06:15-06:35 | `rate_limits_test.sql`, vier draaibeurten (zie vondsten) | v4: **27 van 27 `ok = true`** |
| 06:37:51-06:38:07 | `dart run tool/rate_limit_probe.dart` (publieke sleutel, PostgREST) | A: 20 feedback in de vorm van build 70 aangenomen, 21e `rw_rate_limited:feedback:sender`. B: vers `device_id`, weer `feedback:sender`. C: 120 app_events met elk een eigen toestel aangenomen, 121e `rw_rate_limited:app_events:sender` |
| ~06:39 | Opruim-SQL | `feedback_over 0, app_events_over 0, tellers_vandaag 0` |
| 06:40:20 | `--verify-open` | Eén insert aangenomen (201): de grens staat weer open |
| daarna | Opruim-SQL nogmaals, voor die laatste rij | |

Bewijs per eis:

- **RATE-01** checks 2 (anonieme route open, afzender geteld), 4, 5, 6; probe A en B.
- **RATE-02** checks 7.1-7.3; probe C.
- **RATE-03** checks 3.1-3.4 (app_events was al begrensd door 0008).
- **RATE-04** de probe: precies de vorm die build 70 stuurt, langs precies het
  pad dat elke APK neemt. Ook bewezen: PostgREST geeft `x-forwarded-for` echt
  door in `request.headers`, wat de SQL Editor niet kon laten zien (F-05).
- **RATE-05** unit-getest in 38-02; de melding verschijnt pas in de
  eerstvolgende build (D-13).

Dat de 21e feedback precies op het plafond geweigerd werd, betekent ook dat
Joosts IP die ochtend nog geen telling had: geen echte feedback is door de
probe verdrongen.

## Vondsten

1. **De SQL Editor ziet in de slotselect geen tijdelijke tabel.** Bewezen met
   een kaal script (create temp table, insert, select, rollback): 42P01 op de
   tabelnaam, zonder schema in de melding, ook als de select `pg_temp.`
   gebruikt. Een transactie-lokale instelling (`set_config(..., true)`) is in
   diezelfde slotselect wél zichtbaar. Het testraamwerk schrijft de checks nu
   als JSON naar `rw_test.results`; de slotselect pakt die uit zonder
   `pg_temp`-functie en valt terug op een lege set. Alle vijf de SQL-testscripts
   zijn omgezet (rate_limits, usage_counts, rls_deny, clubs_deny,
   clubs_requests_deny). Waarom de editor zich zo gedraagt, is niet
   uitgezocht: het vermoeden is dat Studio de laatste select ook buiten de
   sessie van het script uitvoert (dat verklaart ook de wegvallende
   schemanaam), maar dat is niet bewezen en voor de oplossing niet nodig.
2. **Wat het níét was** (zodat niemand het opnieuw hoeft te proberen):
   - Niet de ongekwalificeerde slotselect. Commit `becae7a` zette er
     `pg_temp.` voor met die verklaring in het bericht; de fout bleef
     identiek. De wijziging zelf is onschadelijk.
   - Niet "oude tabtekst". De versieregel (`f9738b0`) bewees dat versie 3
     echt in de tab stond.
   - Niet de checks 8-11 of `usage_daily_counts`: niets daarvan raakt
     tijdelijke objecten, en het kale script faalde zonder ze.
3. **Testscript v1 miste `id` op app_events** (`694bf74`). `app_events.id` heeft
   geen default (0008, de app maakt de uuid), `feedback.id` wel. De eerste
   draai brak op check 7 en rolde schoon terug.
4. **Lokaal testen kan nu.** Een losse PGlite-installatie (Postgres in
   WebAssembly, via npm, buiten de repo) draaide 0016 letterlijk plus een
   minimaal schema en gaf 27/27, met als tegenproef `RATE-TEST FAILED` zonder
   feedback-trigger. Had dit vóór de eerste live draai gestaan, dan waren
   vondst 3 en een deel van vondst 1 lokaal boven water gekomen. De harness
   staat niet in de repo; als dit vaker nodig is, verdient hij een plek onder
   `tool/`.

## Wat er nog ligt

- De 38-02-melding komt pas bij testers met de volgende build; dan ook de
  versie bumpen (de PWA heet 70 met afwijkende bytes sinds de push van 37).
- CLAUDE.md en AGENTS.md tellen nog dertien server-functies; met 0014 en 0016
  zijn het er vijftien. Bewust uitgesteld tot fase 40 (AFR-02).
- Main is niet gepusht.
