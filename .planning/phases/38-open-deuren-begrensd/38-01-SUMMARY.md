# 38-01 — Migratie 0016 + SQL-bewijs

Status: af (golf 1). Live toepassen en draaien is 38-03, wacht op Joosts
bevestiging van de plafondgetallen.

## Wat er staat

- `supabase/migrations/0016_rate_limits.sql`: `feedback.device_id` (uuid,
  nullable), drie CHECKs op feedback (comment <= 2000, context als tekst
  <= 8000, rating 1-5), tabel `rate_limit_counts` (pk kind/day/subject, RLS
  aan zonder policies, geen grants), één security definer-triggerfunctie
  `enforce_insert_rate_limit()` met `set search_path = ''` en BEFORE
  INSERT-triggers op beide tabellen, revoke van PUBLIC (les 0015).
  Server-functie nummer 15, verantwoord in de kop; CLAUDE.md/AGENTS.md
  volgen in fase 40 (AFR-02).
- `supabase/tests/rate_limits_test.sql`: 27 checks in één transactie die met
  `rollback` eindigt. Bewijst grantgrens, anonieme route mét getelde afzender,
  de drie groottes, alle vijf plafonds (feedback per toestel/account/afzender,
  app_events per toestel/afzender), roteren-helpt-niet, terugdateren,
  opruiming na een dag, ongeldige header, en geen regressie op
  usage_daily_counts.

## Vondsten tijdens het bouwen

1. **NOT VALID op de CHECKs.** Feedback had tot nu toe geen enkele
   lengtegrens. Een `add constraint` valideert bestaande rijen, en één
   historische te lange rij zou de hele migratie laten mislukken. De drie
   CHECKs komen er daarom als `not valid` bij: nieuwe rijen gecontroleerd,
   bestaande met rust gelaten. In rate_limits_test.sql check 3 bewijst dat de
   grens voor nieuwe rijen wél afdwingt.
2. **Check 8 is scherper geworden dan gepland.** De planningsvariant (21e
   teruggedateerde rij geweigerd) zou óók weigeren als de teller op created_at
   liep: beide landen in hetzelfde oude vakje. De uitgewerkte check zet 20
   rijen met created_at van twee dagen geleden en biedt dan een rij van nú aan:
   geweigerd, en de teller staat op het vakje van vandaag. Alleen
   serverkloktelling gedraagt zich zo; created_at-telling niet.
3. **Twee checks waren eerst niet-deterministisch.** De afzendertelling in
   check 2.2 en 10.2 telde álle sender-rijen van vandaag, inclusief echte
   productietraffiek sinds 0016 live is. 2.2 telt nu alleen de hash van het
   gesimuleerde IP (203.0.113.5, dok-IP, geen botsing mogelijk), 10.2 meet
   het verschil voor/na (patroon van check 8 in usage_counts_test).
4. **`select into` laat de variabele null bij een lege teller.** Check 5
   vangt dat expliciet af (`l_stond := coalesce(l_stond, 0)`), want een null
   bovengrens laat de for-lus stilletjes leeglopen en de 31e rij zou dan niet
   geweigerd worden maar zomaar lukken.
5. **De weigering is transactieschoon.** De trigger verhoogt soms al één of
   twee tellers vóór de derde weigert; omdat `raise exception` de hele insert
   terugrolt, staat er nooit een halve telling. Check 4.2 (teller exact 20 na
   de geweigerde 21e) bewijst dat.
6. **GUC-toestanden zijn afgedekt.** `request.headers` bestaat in vier
   toestanden: afwezig (SQL Editor, pooler), lege string, ongeldig JSON,
   geldig JSON. Alleen de laatste levert een afzender; check 10 bewijst dat
   'geen-json' de insert niet breekt en geen afzender bijtelt.

## Wat er nog niet is

- 0016 is niet toegepast: de SQL Editor en de plafondbevestiging zijn van
  Joost (38-03). Het script is herhaald plakbaar (idempotent waar het kan:
  if-not-exists, drop-if-exists, create-or-replace).
- De PostgREST-probe met de publieke sleutel (RATE-04) staat in 38-03 en
  draait ná het testscrip.
