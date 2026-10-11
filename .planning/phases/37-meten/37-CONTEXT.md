# Phase 37: Meten - Context

**Gathered:** 2026-10-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Joost kan per dag zien hoeveel rijen er in `feedback`, `app_events`, maatjes- en
groepsuitnodigingen, groepsritten/vensteropties en nieuwe accounts bijkwamen, en van
hoeveel verschillende afzenders (MEET-01). Een uitschieter komt vanzelf bij hem terecht
(MEET-02). Er ligt een vastgelegde nulmeting waarop de plafonds van fase 38 en 39
gebaseerd worden.

Niet in deze fase: iets begrenzen, een kolom toevoegen aan bestaande tabellen, of
mislukte inwisselpogingen tellen (dat is de teller van fase 39).

</domain>

<decisions>
## Implementation Decisions

Joost liet alle vijf keuzes aan Claude ("doe maar wat jij zou aanraden"). Voorstel
zoals getoond in https://claude.ai/artifact/U3q4VHt43GnAq18PQftTqi is daarmee vastgesteld.

### Vondsten die de keuzes sturen
- **F-01:** De GitHub-repo `joostmouw/ridewindow` is **publiek** (API gaf 200 op 2026-10-11). Alles in een Action-log, job summary of issue is voor iedereen leesbaar.
- **F-02:** `public.feedback` heeft **geen `device_id`** (0001: id, user_id, rating, comment, context, created_at). Anonieme feedback is alleen als rijen te tellen; per afzender alleen via `user_id`. Geen kolom toevoegen in deze fase.
- **F-03:** Een mislukte `redeem_friend_invite`/`redeem_group_invite` schrijft niets weg. Fase 37 meet wat er **aangemaakt** wordt, niet wat er **geprobeerd** wordt.
- **F-04:** `service_role` heeft select op `feedback`, `app_events`, `groups`, `group_members` (0009/0011/0012), maar **niet** op `friend_invites`, `group_invites`, `group_join_requests` en niet op `auth.users` via PostgREST.

### Telling (database)
- **D-01:** Eén nieuwe migratie `supabase/migrations/0014_usage_daily_counts.sql` met een `security definer`-functie `usage_daily_counts(p_days int)` (plpgsql of sql, `set search_path` vast) die **alleen totalen** teruggeeft, nooit rijen.
- **D-02:** Per dag (kalenderdag in `Europe/Amsterdam`) en per bron drie getallen: `rows`, `distinct_senders`, `max_rows_one_sender`. Het laatste is de aanvalshandtekening (veel rijen, weinig toestellen).
- **D-03:** Bronnen en afzenderkolom:
  | Bron | Afzender |
  |---|---|
  | `feedback` | `user_id`; anonieme rijen (`user_id is null`) apart geteld als eigen bron/regel |
  | `app_events` | `device_id` |
  | `friend_invites` | `inviter_id` |
  | `group_invites` | `created_by` |
  | `group_rides` | `owner_id` |
  | `group_ride_options` | de aanmaker-kolom uit 0010 (planner verifieert de naam) |
  | `auth.users` | uitgesplitst naar provider (Google / e-mail) |
- **D-04:** `execute` alleen voor `service_role` en een nieuwe login-rol `usage_monitor`; `revoke execute ... from public, anon, authenticated`. `usage_monitor` krijgt verder niets (geen tabelrechten, geen schema-gebruik buiten wat nodig is om die ene functie aan te roepen).
- **D-05:** De migratie verantwoordt de functie (CLAUDE.md-regel): hij leest `auth.users` en tabellen die zelfs `service_role` niet mag selecteren, en een totaal geeft minder prijs dan select-rechten op ruwe uitnodigingscodes. Dit wordt functie nummer 14; het bijwerken van de telling in `CLAUDE.md`/`AGENTS.md` gebeurt in fase 40 (AFR-02), maar noteer het nu al in de migratiekop.
- **D-06:** Tellingen zijn van rijen die nog **bestaan**. Bronnen waar rijen verdwijnen (ingewisselde of verlopen uitnodigingen, verwijderde accounts) zijn daardoor een ondergrens; de planner/researcher stelt vast welke dat zijn en de migratie- en rapporttekst zegt het erbij.

### Zien (MEET-01)
- **D-07:** Nieuw lokaal script `tool/usage_report.dart`, naast `tool/analytics_report.dart`. Standaard laatste 14 dagen als tabel in de terminal; `--days N` en `--html pad.html` zoals het analytics-script.
- **D-08:** Sleutel lezen exact zoals `analytics_report.dart`: `--key`, dan `SUPABASE_SERVICE_ROLE_KEY`, dan `~/.config/ridewindow/supabase-service-role.key`, met dezelfde vormcontrole die een sleutel nooit in een foutmelding laat belanden. Hergebruik of deel die code; niet kopiëren-en-laten-afdrijven als delen eenvoudig kan.
- **D-09:** Het script roept `rpc/usage_daily_counts` aan. Geen getallen in GitHub; geen scherm in de app; geen dashboard-view.

### Seintje (MEET-02)
- **D-10:** Nieuwe GitHub Action (eigen workflowbestand, keep-warm blijft ongemoeid), dagelijks rond 07:00 Nederlandse tijd plus `workflow_dispatch`. Verbindt met `psql` als `usage_monitor` via de Supavisor-pooler (IPv4; GitHub-runners hebben geen IPv6) en toetst **gisteren**.
- **D-11:** Bij een uitschieter **faalt de run**; GitHub mailt dan Joost, hetzelfde signaal waar de keep-warm-job op leunt. De log/summary noemt **alleen bron en regel** (bv. `uitschieter: app_events, één afzender boven de vloer`), **nooit getallen** (F-01). Een infrafout moet in de log onderscheidbaar zijn van een uitschieter.
- **D-12:** Het `usage_monitor`-wachtwoord (of de volledige pooler-URL) staat als GitHub-secret. De service-role-sleutel gaat **niet** naar GitHub (vastgelegd in `.github/workflows/supabase-keep-warm.yml`).
- **D-13:** Geen GitHub-issue (publiek: een aanvaller ziet of hij opgemerkt is), geen pg_cron (kan Joost niet bereiken).
- **D-14 (onderzoek):** Bevestigen dat Supavisor een eigen login-rol accepteert (`usage_monitor.<project-ref>`) op de free tier, en hoe die rol wordt aangemaakt (migratie vs. eenmalige handmatige stap met wachtwoord buiten de repo — een wachtwoord hoort nooit in een migratie). Als het niet kan: terugvallen op een alternatief dat de service-role-sleutel nog steeds buiten GitHub houdt, en dat aan Joost voorleggen.

### Uitschieterregel
- **D-15:** Per bron is één van twee regels genoeg:
  1. **Totaal:** `rows(gisteren) > 5 × mediaan(rows over de 28 dagen ervoor)` **én** `rows(gisteren) > vloer_totaal[bron]`.
  2. **Eén afzender:** `max_rows_one_sender(gisteren) > vloer_afzender[bron]`.
- **D-16:** Dagen zonder rijen tellen als 0 in de mediaan. De vloeren komen uit de nulmeting en staan als constanten in de workflow/het toetsscript, niet in de database. Het lokale script markeert dezelfde uitschieters in zijn tabel (zelfde regel, één implementatie als dat kan).

### Nulmeting
- **D-17:** Twee bronnen:
  1. **Historie:** `usage_daily_counts` over de volledige historie (`app_events` sinds 0008). Drukste echte dag per bron, en per afzender per dag de p95 en het maximum.
  2. **Bovengrens van één toestel:** via adb op de Oppo één bewust zware sessie (elke tab, ritten plannen, groepsrit met opties maken, maatjes- en groepslink aanmaken, twee keer feedback), en tellen wat dat ene toestel/account verstuurde.
- **D-18:** Vastleggen in `.planning/phases/37-meten/37-NULMETING.md`: de gemeten getallen, de vloeren voor D-15, en een voorgesteld plafond per bron voor fase 38 en 39 (vertrekpunt: 10× het drukste echte toestel/account, naar boven afgerond).
- **D-19:** Productiedata lezen gebeurt pas tijdens uitvoering, met Joosts goedkeuring op dat moment (in de discuss-sessie werd het lezen tegengehouden). Alleen totalen in uitvoer, logs en commits.

### Claude's Discretion
Alle bovenstaande keuzes (Joost: "doe maar wat jij zou aanraden"). Vrij voor de planner: de exacte retourvorm van de functie (tabel vs. jsonb), de naam van het workflowbestand, of de toetslogica in bash/psql of in een klein Dart-script zit, en de precieze cron-tijd rond zomer-/wintertijd.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone en epic
- `.planning/ROADMAP.md` §Phase 37 — doel en succescriteria 1–4
- `.planning/REQUIREMENTS.md` — MEET-01, MEET-02, leidend principe en randvoorwaarden v4.3
- `.planning/BACKLOG.md` §"75 — Epic Dicht huis" — open deuren A–E en de volgorde meten → begrenzen
- Ontwerp milestone: https://claude.ai/artifact/2iWe1d2BbCanxrTgvsyG9b
- Voorstel deze fase: https://claude.ai/artifact/U3q4VHt43GnAq18PQftTqi

### Schema en rechten
- `supabase/migrations/0001_accounts_sync.sql` — `feedback`-tabel (geen device_id), geen select-policy
- `supabase/migrations/0002_peloton.sql` — `friend_invites` (`inviter_id`), `group_rides` (`owner_id`), `redeem_friend_invite`
- `supabase/migrations/0004_feedback_anonymous_insert.sql` — anonieme feedbackroute (FB-03), mag niet dicht
- `supabase/migrations/0005_tighten_table_grants.sql`, `0006_tighten_grants_schema_wide.sql` — grantbeleid; `service_role` krijgt niets vanzelf
- `supabase/migrations/0008_app_events.sql`, `0009_app_events_service_role_select.sql` — `app_events`, `device_id`, index
- `supabase/migrations/0010_group_ride_options.sql` — `group_ride_options`
- `supabase/migrations/0011_feedback_service_role_select.sql` — patroon voor een smalle service_role-grant
- `supabase/migrations/0012_groups.sql` — `group_invites` (`created_by`), bewust geen service_role-select op invites
- `CLAUDE.md` §Constraints "No backend" — lijst van plpgsql-functies en de verantwoordingsregel

### Tooling
- `tool/analytics_report.dart` — sleutel lezen, vormcontrole, `--days`/`--html`; patroon voor `usage_report.dart`
- `.github/workflows/supabase-keep-warm.yml` — waarom de service-role-sleutel niet in GitHub hoort; failed-run als signaal

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tool/analytics_report.dart`: `_readKey`, `_keyPattern`, argumentparsing en HTML-uitvoer; projecturl `https://hcdrydlgqpnmumfupgcx.supabase.co`.
- `.github/workflows/supabase-keep-warm.yml`: guard-stap voor ontbrekende secrets, `--fail-with-body`-stijl van diagnosticeerbare fouten.

### Established Patterns
- Elke migratie is een Nederlandstalig verhaal: waarom, wat bewust níet, en een controlequery onderaan. 0014 volgt dat.
- Grants worden expliciet en smal gegeven; een nieuwe tabel/functie krijgt niets vanzelf.
- Sleutels staan in `~/.config/ridewindow/` met rechten 600, nooit in de repo of een log.

### Integration Points
- Nieuwe migratie 0014 (handmatig toepassen in de Supabase SQL-editor, zoals eerdere migraties).
- Nieuw workflowbestand in `.github/workflows/` met secrets in repo-instellingen (eenmalige stap voor Joost of via `gh`, dat lokaal niet geïnstalleerd is).
- Nieuw script in `tool/`.

</code_context>

<specifics>
## Specific Ideas

- Joost hoeft niet te zoeken: het seintje is een mail van GitHub, het script is de plek voor details.
- "Veel rijen, weinig afzenders" is het patroon om op te letten; daarom de derde kolom.

</specifics>

<deferred>
## Deferred Ideas

- `device_id` of afzenderhash op `feedback` — hoort bij fase 38 (gehasht IP als afzender).
- Mislukte inwisselpogingen zichtbaar maken — komt vanzelf met de teller in fase 39.
- Telling van functies in `CLAUDE.md`/`AGENTS.md` bijwerken (13 → 14+) — fase 40, AFR-02.

</deferred>

---

*Phase: 37-meten*
*Context gathered: 2026-10-11*
