# Rate-limit-probe — draaiboek (fase 38, migratie 0016)

Dit is de live-kant van fase 38 ("Dicht huis"): het bewijs dat de dagplafonds
uit 0016 ook gelden op het pad dat een aanvaller echt neemt — PostgREST met
de publieke anon-sleutel, met de code van builds die al bij testers staan en
nooit een update krijgen (RATE-04).

## Volgorde

1. **0016 toepassen** — SQL Editor, hele bestand in één keer plakken en
   draaien. Verwacht: `Success. No rows returned`.
2. **rate_limits_test.sql draaien** — `supabase/tests/rate_limits_test.sql`,
   ook in één keer. Verwacht: één tabel met 27 rijen, `ok = true` overal.
3. **De probe draaien**, vanaf de Mac:

   ```sh
   dart run tool/rate_limit_probe.dart
   ```

   Dit duurt een halve minuut (ongeveer 142 verzoeken na elkaar). De
   verwachte uitvoer staat hieronder.
4. **Opruimen** — de SQL uit het hoofdstuk hieronder plakken en draaien.
5. **Laatste controle** —

   ```sh
   dart run tool/rate_limit_probe.dart --verify-open
   ```

   Verwacht: één insert aangenomen (201). Daarna de opruim-SQL uit stap 4
   nóg één keer plakken: dan is ook die laatste rij weg en staan de
   tellers weer op nul.

## Opruim-SQL

```sql
begin;

-- De proberijen, allebei met hun eigen vaste marker
delete from public.feedback   where comment like 'rate-limit-probe:%';
delete from public.app_events where name = 'rate_limit_probe';

-- De dagtellers van vandaag leeg: dat zijn de probe-onderwerpen en je
-- eigen IP-hash. Eventueel echt verkeer van vandaag krijgt zijn dagruimte
-- één keer terug — onschadelijk, iedereen zit ver onder de plafonds, en
-- de rijen verjaren sowieso na een dag.
delete from public.rate_limit_counts
 where day = (now() at time zone 'Europe/Amsterdam')::date;

commit;

-- De editor toont alleen het laatste resultaat: verwacht drie nullen.
select (select count(*) from public.feedback
         where comment like 'rate-limit-probe:%')          as feedback_over,
       (select count(*) from public.app_events
         where name = 'rate_limit_probe')                  as app_events_over,
       (select count(*) from public.rate_limit_counts
         where day = (now() at time zone 'Europe/Amsterdam')::date) as tellers_vandaag;
```

De SQL is idempotent: nog een keer plakken kan geen kwaad en is in stap 5
ook bedoeld.

## Wat de probe doet, en waarom dat het bewijs is

- **Fase A** — feedback in de vorm van build 70: geen `device_id`, precies
  wat de oude builds bij testers sturen. Verwacht 20x aangenomen (201), dan
  geweigerd met `rw_rate_limited:feedback:sender`.
- **Fase B** — dezelfde insert mét een vers device_id: de aanvaller die de
  nieuwe vorm nabootst en per rij een nieuw toestel kiest. Verwacht: nog
  steeds `rw_rate_limited:feedback:sender`. Roteren helpt niet.
- **Fase C** — app_events met per rij een vers device_id. Verwacht 120x
  aangenomen, dan `rw_rate_limited:app_events:sender`.

Alle rijen dragen vaste markers (`rate-limit-probe:` in het commentaar,
gebeurtenisnaam `rate_limit_probe`), zodat de opruim-SQL ze zonder
uitschieters vindt.

De per-toestel-grens is vanaf één IP niet live te zien: de afzender wordt
eerst gecontroleerd en loopt dus altijd eerder vol dan het toestel. Die
grens beschermt tegen een aanvaller die zijn IP laat wisselen maar een
device_id hergebruikt; het bewijs dat de telling zelf klopt, staat in
`rate_limits_test.sql` (checks 2 t/m 5, draaien zonder IP-header).

## Als het misgaat

- **Inserts blijven aangenomen na het plafond**: 0016 staat (nog) niet
  toegepast. De probe stopt zelf na plafond + 5 inserts en zegt dat; de
  gemarkeerde rijen gaan weg met de opruim-SQL.
- **401 of 403**: dan klopt de publieke sleutel niet — maar dan zou de app
  op elk toestel dezelfde fout geven, dus dat valt direct op.
- **Elke andere onverwachte status**: de probe drukt het volledige body af
  en breekt af; plak dat body in het gesprek, dan is de diagnose snel.
