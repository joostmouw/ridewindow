# Phase 38: Open deuren begrensd - Context

**Gathered:** 2026-10-11 (avond), door Droid in de tweede terminal; de nulmeting van 37-05 was al af en de wacht van 37-06 stond live.
**Status:** Ready for planning

<domain>
## Phase Boundary

`feedback` en `app_events` kunnen niet meer onbeperkt volgepompt worden, ook niet
door builds die al bij testers en in productie staan: de database zelf weigert na
een dagplafond per toestel én per afzender, en weigert rijen boven de maximale
grootte (RATE-01 t/m RATE-04). Een tester boven de feedbackgrens ziet een
duidelijke melding in de app en zijn feedback blijft bewaard (RATE-05). Anonieme
feedback blijft mogelijk (FB-03): begrenzen mag, blokkeren niet.

Niet in deze fase: mislukte inwisselpogingen en grenzen per account bij
uitnodigingen, ritten en opties (fase 39), e-mailbevestiging en Auth-limieten
(fase 40), captcha en App Check (uitgesteld tot de metingen erom vragen).
</domain>

<decisions>
## Implementation Decisions

Joost wees deze fase toe op 2026-10-11 ("begin daar dan maar eerst mee"). De
plafondgetallen volgen uit de nulmeting (D-18 van 37-NULMETING.md) en worden
Joost ter bevestiging voorgelegd zodra 0016 klaar is, vóór live-toepassing.

### Vondsten die de keuzes sturen
- **F-01:** `feedback` heeft géén `device_id` (0001) en geen enkele
  lengtegrens: `comment` (text) en `context` (jsonb) zijn onbeperkt. `app_events`
  is wél al volledig begrensd door 0008 (naam 1-40, props ≤ 500 tekens,
  app_version ≤ 20, platform enum).
- **F-02:** De insert-grant laat een client toe zelf `created_at` mee te
  sturen (opgemerkt in de kop van 0014). Wie rijen terugdateert, ontloopt een
  telling op `created_at`.
- **F-03:** De outbox **dropt** een rij na vijf keer achter elkaar mislukken
  (`SyncOutboxService.kMaxSendAttempts = 5`, plan 21-12). Een feedbackrij die de
  hele dag geweigerd wordt, verdwijnt daarmee na vijf drains: precies wat RATE-05
  verbiedt. Een weigering mag dus géén poging tellen.
- **F-04:** De analytics-toestel-id ontstaat pas bij een ja en verdwijnt bij
  intrekken van de toestemming (`AnalyticsConsentStore`). Feedback heeft een id
  nodig die los van die toestemming bestaat.
- **F-05:** De SQL Editor heeft geen `request.headers`-GUC, dus de per-afzender
  telling is daar niet te bewijzen; dat kan alleen via een echte PostgREST-aanroep.
  Omgekeerd kan de SQL Editor een custom GUC wél simuleren met
  `set local request.headers = '...'`.

### Migratie (database, plan 38-01)
- **D-01:** Eén migratie `supabase/migrations/0016_rate_limits.sql`:
  `feedback.device_id` (uuid, nullable: builds in het veld sturen hem niet),
  tabel `public.rate_limit_counts` (kind, day, subject, n; pk (kind, day,
  subject)), één security definer-trigger-functie
  `public.enforce_insert_rate_limit()` die op `tg_table_name` splitst, en
  BEFORE INSERT-triggers op beide tabellen. Eén functie, geen helpers: de
  functietelling in CLAUDE.md gaat straks 14 naar 15 (bijgewerkt in fase 40).
- **D-02:** Tellen per Amsterdamse kalenderdag op de **serverklok** (`now()`),
  niet op de rij-gezette `created_at`. Dat sluit terugdateren (F-02).
- **D-03:** Afzender = eerste IP uit `x-forwarded-for` in de
  PostgREST-requestheaders, bewaard als `md5(dag || ip)`. Het dagzout maakt
  koppeling over dagen onmogelijk; de tellerrijen worden bij elke insert
  opgeruimd ouder dan één dag. Ontbreekt de header of is hij leeg (SQL Editor,
  pooler), dan valt die telling netjes weg en blijven toestel en account over.
- **D-04 (plafonds, uit D-18 van de nulmeting):** `feedback`: account 30/dag,
  toestel 20/dag, afzender 20/dag. `app_events`: toestel 120/dag, afzender
  120/dag. Weigering: `raise exception 'rw_rate_limited:<tabel>:<soort>'`.
  Toestel en account worden alleen geteld als de kolom gevuld is; de afzender
  wordt altijd geteld, juist om `device_id`-rouleren zinloos te maken.
- **D-05 (RATE-03, rijgrootte):** `feedback`: `comment` ≤ 2000 tekens,
  `context` als tekst ≤ 8000 tekens, `rating` null of 1 t/m 5, als CHECKs op de
  tabel. 2000 is ruim boven het 4-regelige invoerveld; 8000 is ~5x een context
  met volledige scorecontext (gemeten orde: ~1-2 KB). `app_events` krijgt geen
  nieuwe checks: 0008 begrenst die tabel al volledig (F-01).
- **D-06:** `rate_limit_counts` krijgt geen grants aan `anon`/`authenticated`
  (het standaard na 0006), RLS aan zónder policies, en de trigger-functie wordt
  van PUBLIC ingetrokken (`revoke ... from public, anon, authenticated`; les
  uit 0015: elke functie neemt standaard PUBLIC-execute).
- **D-07:** `usage_daily_counts` (0014) blijft ongemoeid: de bronnen en
  afzenderkolommen veranderen niet, en de nieuwe `device_id`-kolom op feedback
  raakt de telling (die op `user_id` splitst) niet.

### App (plan 38-02)
- **D-08 (toestel-id op feedback):** Eigen id voor feedback, los van de
  statistiek-toestemming (F-04): uuid v4, aangemaakt bij de eerste
  feedbackversturing, bewaard in SharedPreferences, patroon van
  `analytics_consent_store.dart`. Versturen is bij feedback zélf de toestemming
  (zelfde afweging als 0004). Het privacybeleid beschrijft hem in fase 40 (AFR-01).
- **D-09 (weigering herkennen, RATE-05):** De drain herkent
  `rw_rate_limited` in de gateway-fout (getypeerd als `RateLimitedRefusal`,
  herkend in de `upsertFn`-tak van `drainOutbox` waar het entiteitsbegrip
  bestaat) en laat de rij dan pending staan **zonder poging te tellen** (F-03:
  anders dropt de outbox hem binnen een dag). Andere fouten houden de bestaande
  vijf-pogingen-regel. `app_events`-weigering is stil (statistiek is stil by
  design); feedback-weigering komt bij de gebruiker.
- **D-10 (melding):** Een keepAlive-notifier telt feedback-weigeringen per
  drain; de app-root (de `builder:`-plek waar `top_banners` al hangt) toont
  eenmalig een localized snackbar: bewaard, later opnieuw, limiet voor vandaag
  bereikt. NL en EN allebei in de ARB's.

### Bewijs (plan 38-03, autonoom: false)
- **D-11:** De SQL Editor-test `supabase/tests/rate_limits_test.sql` bewijst de
  databasegrenzen (plafonds, groottes, terugdateren, opruiming, anonieme route
  blijft werken, grants) met gesimuleerde `request.headers` (F-05), in één
  transactie met rollback, zonder productietotalen.
- **D-12:** Het per-afzender-bewijs en RATE-04 (oude builds zonder update vallen
  onder de grenzen) vereisen een echte aanroep: nieuw `tool/rate_limit_probe.dart`
  doet inserts via PostgREST met de publieke anon-sleutel (publiek by design,
  zit al in elke build) in de vorm van build 70 (feedback zónder `device_id`),
  binnen de grens aanvaard en erboven geweigerd, en met roterende `device_id`'s
  nog steeds geweigerd. De probe schrijft echte rijen; het plan bevat de
  opruim-SQL (rijen én tellers van vandaag, zodat Joost's eigen quota vrijkomen)
  en de probe voert alleen de meting uit, print geen inhoud van productierijen.
- **D-13:** RATE-05's toestelbewijs is unit-getest plus de live probe; de
  melding zélf verschijnt pas in de eerstvolgende build (bewust: de productiebuild
  niet updaten om een melding te forceren). Optioneel later: de Oppo een dag tot
  de grens laten gaan.

### Claude's Discretion
De exacte SQL-vorm van de trigger (arrays van onderwerpen vs. herhaalde
blokken), de namen van ARB-sleutels, en of de probe per stap de HTTP-status of
de foutmelding rapporteert.
</decisions>

<canonical_refs>
## Canonical References

### Milestone
- `.planning/ROADMAP.md` §Phase 38 — doel en succescriteria 1-5
- `.planning/REQUIREMENTS.md` — RATE-01 t/m RATE-05, randvoorwaarden (€0/maand,
  alleen plpgsql, uitgelogd blijft werken, FB-03 begrenzen niet blokkeren)
- `.planning/phases/37-meten/37-NULMETING.md` — gemeten getallen, vloeren en
  voorgestelde plafonds (D-18)
- `.planning/BACKLOG.md` §"75 — Epic Dicht huis" — open deuren A/B en de
  volgorde meten dan begrenzen

### Schema en rechten
- `supabase/migrations/0001_accounts_sync.sql` — feedback-tabel en -policy
- `supabase/migrations/0004_feedback_anonymous_insert.sql` — anonieme route (FB-03)
- `supabase/migrations/0008_app_events.sql` — app_events, bestaande lengtechecks
- `supabase/migrations/0014_usage_daily_counts.sql` — serverklok-patroon
  (Europe/Amsterdam), functie- en grantstijl
- `supabase/migrations/0015_revoke_public_execute_0001.sql` — les: elke nieuwe
  functie van PUBLIC intrekken
- `supabase/tests/usage_counts_test.sql` — expect-helperpatroon, rollback,
  `set local role`, gesimuleerde jwt-claims

### App
- `lib/services/sync_outbox_service.dart` — drain-contract, kMaxSendAttempts (F-03)
- `lib/providers/cloud_sync_reconciler_provider.dart` — insertRow-tak voor
  feedback en analytics
- `lib/services/feedback_service.dart`, `lib/domain/services/feedback_payload.dart`
- `lib/data/repositories/analytics_consent_store.dart` — patroon voor de
  feedback-toestel-id (D-08)
- `lib/features/profile/feedback_dialog.dart` — dialoog, onmiddellijke "bedankt"
- `lib/features/shared/top_banners.dart` — de builder-plek voor de melding (D-10)
</canonical_refs>

<code_context>
## Existing Code Insights

- De feedbackrit gaat altijd via de outbox (`FeedbackService.submit` →
  `enqueueOrCoalesce` → `drainOutbox` → `CloudSyncGateway.insertRow`), dus de
  enige plek waar een weigering waarneembaar is, is de drain, en de rij moet
  daar pending blijven.
- `buildFeedbackRow` zet de rij puur; er bestaan unit-tests op de vorm, dus de
  nieuwe `device_id` komt er als parameter bij, niet als veld in de service.
- De ARB's (`app_nl.arb` leidend, `app_en.arb` even goed meebijhouden) eisen
  geen em-dashes; `test/structure/no_em_dash_test.dart` bewaakt ze.
- De publieke sleutel staat in `lib/core/supabase_config.dart` (publiek by
  design); de probe herimporteert die, geen tweede kopie.
</code_context>

<deferred>
## Deferred Ideas

- Mislukte inwisselpogingen tellen, grenzen per account bij uitnodigingen en
  ritten: fase 39.
- Privacybeleid + CLAUDE.md/AGENTS.md-functietelling bijwerken: fase 40 (AFR-01/02).
- Een eigenlijke 429 + Retry-After van PostgREST: het standaard 400-vak volstaat;
  de app herkent de melding aan de prefix en heeft de tijdsduur niet nodig
  (de outbox probeert de volgende drain toch weer).
</deferred>

---

*Phase: 38-open-deuren-begrensd*
*Context gathered: 2026-10-11*
