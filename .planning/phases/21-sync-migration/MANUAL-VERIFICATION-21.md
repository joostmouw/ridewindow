# Phase 21 — Manual Verification Log

This file records the outcomes of every `checkpoint:human-action` step in Phase 21 that
requires a human to operate the Supabase Dashboard SQL Editor (no Supabase CLI is installed
in this environment). Later plans in this phase (21-08, 21-09) append further sections here
rather than creating new files.

Project: `hcdrydlgqpnmumfupgcx` (`https://hcdrydlgqpnmumfupgcx.supabase.co`)

---

## 21-02 — Apply the accounts sync schema migration + RLS deny-case test

**Date:** 2026-08-03
**Performed by:** Joost (orchestrator-run checkpoint, Task 3 of 21-02-PLAN.md)

### 1. Migration state at time of check

The migration (`supabase/migrations/0001_accounts_sync.sql`) was found to be **already
applied** before this checkpoint session began. All four tables existed
(`profiles`, `availability`, `planned_rides`, `feedback`), RLS was enabled on all four, all
4 policies existed, both `plpgsql` functions (`migrate_account_data`, `delete_own_account`)
existed, and both `set_updated_at` triggers existed. A column-by-column inventory was checked
against the migration file and matched exactly for all four tables.

Re-running the migration file (as the plan's Task 3 instructs) failed immediately, as
expected for a schema with no `if not exists` guards:

```
ERROR: 42P07: relation "profiles" already exists
```

The transaction rolled back at that first statement — no partial re-application, no schema
drift from the re-run attempt itself.

### 2. BLOCKING DEFECT FOUND — missing grants on `authenticated`

Running `supabase/tests/rls_deny_test.sql` (the version that existed at checkpoint time,
before this plan's Task 2 rewrite) failed with:

```
ERROR: 42501: permission denied for table profiles
HINT:  Grant the required privileges to the current role with: GRANT SELECT ON public.profiles TO authenticated;
CONTEXT:  SQL statement "select count(*)                    from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111'"
PL/pgSQL function inline_code_block line 6 at SQL statement
```

A privilege inventory was run against `information_schema.role_table_grants` for all four
tables, confirming the root cause. Grants at the time of the failure:

| Role | Privileges held |
|------|------------------|
| `postgres` | DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE |
| `authenticated` | REFERENCES, TRIGGER, TRUNCATE — **no DML** |
| `anon` | REFERENCES, TRIGGER, TRUNCATE |
| `service_role` | REFERENCES, TRIGGER, TRUNCATE |

Postgres checks table-level privileges **before** it evaluates any RLS policy. The
`authenticated` role is exactly what the app's signed-in Supabase client connects as, and it
was being rejected before any "own row only" policy ever ran. As deployed, a signed-in user
could not read or write even their own rows — this broke SYNC-01/SYNC-02 in practice, not
just the RLS test script. The RLS policies themselves were correct; they were simply
unreachable.

### 3. Fix applied to the live database

The following was run directly in the SQL Editor and returned `Success. No rows returned`:

```sql
grant select, insert, update, delete on public.profiles      to authenticated;
grant select, insert, update, delete on public.availability  to authenticated;
grant select, insert, update, delete on public.planned_rides to authenticated;
grant insert                          on public.feedback     to authenticated;
```

`feedback` is deliberately insert-only — this preserves FB-05 ("can write, can never read
back"). `anon` deliberately received nothing: signed-out users never touch the cloud tables.

This same fix was subsequently added to `supabase/migrations/0001_accounts_sync.sql` itself
(commit `581cd73`, this plan's file-fix task) so that a fresh deploy of the migration produces
a working schema on the first pass, without needing this checkpoint's manual patch again.

### 4. SYNC-08 re-proven, with visible evidence

The original `rls_deny_test.sql` asserted via `raise notice`, but the Supabase SQL Editor does
not surface `NOTICE` lines anywhere in its results panel — a passing run and a silently-skipped
run looked identical. An equivalent transaction that instead **returns** the counts as a result
set was run in its place (the technique later formalized into this plan's Task 2 rewrite of the
test file). Exact result, all inside `begin;`/`rollback;`, nothing persisted:

```
check_name                      | rows_seen
---------------------------------+----------
B select of A row (want 0)      | 0
B update of A row (want 0)      | 0
B delete of A row (want 0)      | 0
A select of own row (want 1)    | 1
```

The first three rows are SYNC-08's deny case (a second, different authenticated user cannot
select, update, or delete the first user's row). The fourth row is the positive case — proof
that the fix actually restored access for the row's own owner, not just that the deny case
still (trivially) held. The original test script never covered this positive case, and the
grants defect would have silently passed every deny-case assertion while still leaving the
app completely broken for its own users.

### Outcome

- Migration schema: **confirmed present and correct** (was already applied; re-run correctly
  rejected as a no-op-by-design).
- Grants defect: **found and fixed**, both live (Dashboard) and in version control
  (`0001_accounts_sync.sql`, commit `581cd73`).
- SYNC-08 deny case: **PASS** (0/0/0 rows affected for the attacking user).
- Positive case (new, not in the original plan's test): **PASS** (1 row visible to the owner).
- Test script itself improved for future re-runs: `supabase/tests/rls_deny_test.sql` now
  returns a visible result table instead of relying on invisible `NOTICE` output (commit
  `01fa355`).

Wave 2/3's outbox and cloud-sink code can now write against this schema with confidence that
both halves of the access story — RLS policies and table grants — are correct and proven
against the real deployed project.

---

## Device session — 2026-08-04, Oppo Find X9 Pro (PLG110), app 1.0.14+15

Executed on a real device installed from the Play Store **Internal testing** track
(`installer=com.android.vending`), against the live project `hcdrydlgqpnmumfupgcx`.
Everything below is an observed result, not an expectation.

### False start worth recording

The first attempt appeared to fail completely: no sync status text, and all four tables
empty. Roughly forty minutes went into diagnosing the server side — RPC signature, table
grants, PostgREST schema cache — before checking what was actually installed:

```
versionCode=13  versionName=1.0.12  installer=com.android.vending
```

The device was running the **26 July build**, which contains no Phase 20 or 21 code at all.
Google Play had served it because the device's account was opted into the pre-existing
**closed test** track (still on +13) and not into internal testing (+15). The symptoms were
entirely explained by testing the wrong binary.

**Lesson for future device sessions: assert the installed `versionCode` BEFORE interpreting
any behaviour.** One `adb shell dumpsys package <id> | grep version` would have replaced the
entire investigation. This step is now item 0 of the device checklist.

The server-side checks made during that detour were not wasted, and are recorded here as
genuine results:

- `migrate_account_data` invoked at SQL level as the `authenticated` role with a real
  `auth.users` id and all 14 named arguments: wrote **profiles 1 / availability 1 /
  planned_rides 1**, inside a rolled-back transaction. The 14-argument signature resolves
  correctly — this was the phase's single highest-rated risk and it is now retired.
- `has_function_privilege('authenticated', ...)` is `true` for both `migrate_account_data`
  and `delete_own_account`.
- PostgREST schema cache reloaded via `notify pgrst, 'reload schema'` (precautionary; it was
  not the cause).

### MIG-05/06 — first-login migration: PASS

After updating to 1.0.14+15 and signing in with genuine, non-default local data present:

| table | rows | content |
|-------|------|---------|
| `profiles` | 1 | `Joost \| temp 12-26 \| wind 15 \| regen 0.5 \| duur {2,3,5}` |
| `availability` | 1 | **120 hour blocks**, `{"1-0":"work","1-1":"work",…}` |
| `planned_rides` | 2 | 9 Aug 06:00→08:00 and 9 Aug 11:00→13:00 |

All three carry the identical timestamp `2026-08-04 09:14:46.68055+00` — one atomic RPC, three
tables, at the moment of sign-in. The payload is unambiguously real user data (120 availability
blocks cannot be a default), so this is not an empty push that succeeded by coincidence.
No errors in `adb logcat` (`AccountSection`, `migrate_account_data`, `Postgrest` filters).

### SYNC-05 — outbox drain: FAIL (blocking defect, see plan 21-10)

After signing out and back in, the account row showed **"Wordt gesynchroniseerd..."** and
stayed there. That status text is not cosmetic — it is `outboxPendingCountProvider` accurately
reporting a queue that never empties.

Cause, confirmed by source inspection: **`SyncOutboxService` is never constructed anywhere in
`lib/`, and `drain()` is never called.** The only production consumer of the outbox is
`watchPendingCount()`, which feeds the status text. Repositories enqueue; nothing dequeues.

Impact confirmed against the live database — all three tables still read
`2026-08-04 09:14:46`, unchanged by the second sign-in:

- First-login migration works, because it calls the RPC directly and bypasses the outbox.
- **Every local change after that never reaches the cloud.** Profile edits, availability
  changes and newly planned rides enqueue and stay enqueued.

How it was missed: responsibility for wiring the drain was deferred from plan to plan and then
dropped. `21-03` states *"wave 3 (plans 21-04/21-05) is what actually wires ... the real
Supabase calls into drain()'s callbacks"*; `21-04` states *"the drain step in plan 21-06/21-07
adds user_id when it actually calls .upsert()"*; plans `21-06` and `21-07` do not mention
`drain` at all. No executor deviated from its plan — the plan set never assigned this work.
The full suite is green because `drain()` itself is well tested; only its caller is absent.

This defect was found by the device session and by nothing else.

### Correction to REGRESSION-CHECKLIST-21.md

Section 2 instructed the tester to treat the status text reaching "Gesynchroniseerd" as proof
that the first-login migration succeeded. **That instruction is wrong and has been corrected.**
The status text counts outbox rows, and the first-login migration does not use the outbox — so
on a genuine first login the queue is empty and the text reads "Gesynchroniseerd" whether the
RPC succeeded or failed. The only valid proof is rows in the dashboard.

### Still outstanding from this session

- "Voeg toe aan agenda", sign-out, and restart-persistence (checklist §2, not reached)
- iPhone PWA (§3) — **blocked**: the `deploy-web.yml` workflow has never succeeded since it was
  added on 2026-07-26 (repository secret `FIREBASE_SERVICE_ACCOUNT` was never created), so the
  deployed PWA does not contain Phase 20 or 21 code
- Cold-start measurement (§4), SYNC-11 multi-tab (§5)
- AUTH-09 delete-account (§6, plan 21-08 Task 2) — deliberately left last, destructive

> **Update 2026-08-04 14:58 — de §3-blokkade hierboven is opgelost.** De regel blijft staan als
> historisch verslag van wat er tijdens die sessie waar was. `deploy-web.yml` verwees naar een
> secret dat nooit is aangemaakt; `firebase init hosting:github` heeft er een gemaakt onder de
> naam `FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST` en de workflow wijst daar nu naartoe (commit
> `4e3957e`, run #3 groen). De PWA serveert sindsdien 1.0.15+16 in plaats van 1.0.12+13.
> §3, §4 en §5 zijn daarmee weer uitvoerbaar; zie het kopblok van `REGRESSION-CHECKLIST-21.md`.

---

## Device session 3 — 2026-08-04 18:11-18:18, Oppo Find X9 Pro (PLG110), app 1.0.17+18 → 1.0.18+19

Uitgevoerd via `adb` (screenshots + `input tap`), niet handmatig. Verse installatie: het toestel
was leeg na de mislukte sideload-poging, dus dit is meteen een first-install + first-login pad.

### SYNC-05 — outbox drain: **PASS**, en de oorzaak van twee sessies falen gevonden

**De fout, zichtbaar gemaakt door plan 21-12.** Direct na inloggen op 1.0.17+18:

```
I/flutter: SyncOutbox: send failed for availability/a1456a8d-f39c-45c5-94cf-35957fc4a555
           (operation=upsert, attempt 1): PostgrestException(message: Could not find the
           '1-0' column of 'availability' in the schema cache, code: PGRST204,
           details: Bad Request, hint: null)
I/flutter: SyncOutbox: drain done — 2 pending, 1 sent, 0 failed → 1 failed
```

Let op wat dit meteen weerlegt: dit was een **verse installatie**, dus de hypothese "oude
vergiftigde rijen van vanochtend" is onjuist. `profile` ging wél door (1 sent), `availability`
faalde structureel.

**Oorzaak (plan 21-13).** `AvailabilityRepository` enqueuede `jsonEncode(toRecurringRow(hours))`
— de kále urenmap — als outbox-payload, en `drainOutbox` doet daar
`.from('availability').upsert(payload)` mee. PostgREST leest de sleutels van die map dus als
kolomnamen: `'1-0'`, `'1-9'`, … Vergelijk `ProfileRepository`, dat wél `profile.toRow(userId)`
stuurt — een echte rij met `user_id`. De leeskant (`parseAvailabilityRow`) verwachtte al de
hele tijd `row['recurring']`, dus schrijf- en leeskant spraken elkaar tegen.

De bijbehorende unittest assertte `equals(toRecurringRow(hours))` en **legde de foute vorm dus
vast** — dat is waarom dit door alle 426 tests heen kwam.

**Fix + herbewijs op 1.0.18+19,** zelfde toestel, zelfde sessie:

1. Debugmenu → "Inspect sync outbox" toonde de vastgelopen rij mét `2 attempts` en de volledige
   PGRST204-tekst, op het toestel zelf. Het gereedschap uit 21-12 deed precies waarvoor het
   gebouwd is.
2. "Clear outbox" getikt.
3. Eén beschikbaarheidsuur gewijzigd (do 6 aug, 10:00) → achtergrond → voorgrond.
4. Logcat: `SyncOutbox: drain done — 1 pending, 1 sent, 0 failed`.
5. Accountsectie leest **"Synced"** in plaats van "Syncing..." — de statustekst die sinds
   1.0.15+16 vastzat.

### Nog niet afgetekend

- Dashboardbevestiging van de `availability`-rij in Supabase. PostgREST accepteerde de upsert
  zonder fout, wat sterk bewijs is, maar §5a vraagt expliciet om de rij in Table Editor te zien.
  Vereist dashboardtoegang.
- §2 (Play App Signing-route), §3 (iPhone-PWA), §4 (cold start), §5 (multi-tab), §6
  (delete-account). Ongewijzigd open.

### Correctie op de PASS hierboven — eerst te vroeg geclaimd, daarna alsnog echt bewezen

De eerste versie van dit verslag zette SYNC-05 op PASS op grond van één logregel
(`drain done — 1 pending, 1 sent, 0 failed`). Dat was **niet voldoende**, en de dashboardcheck
liet zien waarom: `public.availability.updated_at` stond nog op `2026-08-04 09:14:46` UTC, van de
eerste migratie diezelfde ochtend. De rij was dus níét geschreven door die drain. Twee fouten in
die redenering:

1. De agendatik die de wijziging moest maken, had niets gewijzigd — voor- en na-screenshot waren
   identiek. Dat was niet gecontroleerd vóór de conclusie.
2. De samenvattingsregel telde alleen (`1 sent`) en noemde de entity niet, dus een geslaagde
   `profile`-send was niet te onderscheiden van een geslaagde `availability`-send. Plan 21-13
   voegt de entiteitsnamen toe: `drain done — 2 pending, 2 sent (profile, availability), 0 failed`.

**Het herbewijs, 2026-08-04 19:02-19:03, app 1.0.18+19, wél sluitend:**

| Stap | Waarneming |
|------|------------|
| Wijziging | Profiel → "Edit my schedule" → zaterdag 00:00 van Free naar **Busy**; visueel bevestigd op de na-screenshot (oranje cel) |
| Trigger | Achtergrond → voorgrond |
| Logcat | `SyncOutbox: drain done — 2 pending, 2 sent, 0 failed` om 19:03:00.346 |
| Supabase | `availability.updated_at` = **2026-08-04 17:03:00.527** UTC = 19:03 lokaal — exact het drainmoment, waar het daarvoor 09:14 was |
| Vorm | `recurring` bevat de urenmap als jsonb ín de kolom (`{"1-0":"work", …}`), niet als losse kolommen |

De tijdstempel verschoof naar precies het moment van de drain; dat gebeurt alleen als de upsert
de rij daadwerkelijk heeft geschreven (`set_updated_at`-trigger). Daarmee is de keten
toestel → outbox → drain → PostgREST → Postgres sluitend aangetoond.

**Niet gedaan:** de volledige `recurring`-JSON uitlezen om de sleutel `6-0` te zien. De
Table-Editor-cel opent een bewerkveld op productiedata; daar is bewust niet verder in geklikt.
De tijdstempel is het bewijs, de sleutelinspectie zou alleen extra comfort zijn.

**Testdata die is achtergebleven:** zaterdag 00:00 staat nu op Busy in Joosts eigen
beschikbaarheid, lokaal én in de cloud. Terugzetten mag; het is een testwijziging, geen bewuste
instelling.

### Tweede, onafhankelijke SYNC-05-meting — 2026-08-04 19:26-19:27, app 1.0.19+20

Uitgevoerd bij het terugzetten van de testdata uit de vorige meting, dus met een wijziging in de
**tegenovergestelde richting** (Busy → Free). Dat sluit uit dat de eerste meting op een
toevallige eigenschap van "een uur bezet zetten" leunde.

| Stap | Waarneming |
|------|------------|
| Wijziging | Zaterdag 00:00 van Busy terug naar **Free**, visueel bevestigd |
| Logcat | `SyncOutbox: drain done — 2 pending, 2 sent (availability, profile), 0 failed` om 19:27:02.154 |
| Supabase | `availability.updated_at` = **2026-08-04 17:27:02.351** UTC = 19:27 lokaal |

De entiteitsnamen uit plan 21-13 doen hier meteen hun werk: `2 sent (availability, profile)` is
ondubbelzinnig, waar `2 sent` dat niet was. Precies de ambiguïteit die de eerste ronde een
onterechte PASS opleverde.

Bijvangst, ook op dit toestel geverifieerd: het profielscherm toont nu **`1.0.19 (20)`** in
plaats van het hardcoded `'1.0.0'`. "Welke build draait hier?" is daarmee vanaf het toestel zelf
te beantwoorden, zonder adb.

**Testdata is opgeruimd:** het rooster staat weer zoals Joost het had.

---

## Device session 4 — 2026-08-05 20:39-20:50, Oppo Find X9 Pro (PLG110), app 1.0.19+20 via Play

Uitgevoerd met Claude aan de USB-kant (adb: versie-assertie, logcat, screenshots) en Joost aan de
tikkant. Die verdeling was nodig: ColorOS blokkeert door adb geïnitieerde app-starts, dus koude
starts moeten met de hand.

### §2 — versie-assertie en installatiebron: **PASS**

```
versionCode=20   versionName=1.0.19
installerPackageName=com.android.vending
firstInstallTime=2026-08-04 19:50:46
```

`com.android.vending` = geïnstalleerd via de Play Store, geen sideload. Daarmee is de
AUTH-10-route (Play App Signing SHA-1) aantoonbaar de route die hier draait, en is de val van
2026-08-04 — Play die versionCode 13 serveerde — uitgesloten in plaats van aangenomen.

Let op: de op Play staande +20 is de build van de worktree-tak, niet de post-merge build van
main. Verschil is uitsluitend main's attempt-plafond (`kMaxSendAttempts = 5`); geen enkele
sectie van deze checklist raakt dat. De PWA draait wél de gemergede code.

### §2 — startup: **PASS**

App opent, Home rendert "15 ride windows this week", geen crash, geen wit scherm.

### §2 — AUTH-04 (herstart → nog ingelogd): **PASS**

Tijdlijn uit logcat, buffer vooraf geleegd:

| Tijd | Regel |
|------|-------|
| 20:44:37.365 | `FlutterGeolocator: Stopping location service.` — oud proces sterft (weggeveegd uit recents) |
| 20:44:41.662 | `nativeloader: Load ... libflutter.so`, **nieuw pid 3594** — echte koude start, geen resume |
| 20:44:44.633 | `SyncOutboxService: drain done — 2 pending, 2 sent (profile, availability), 0 failed` |

Eindstaat: Account-blok toont `Joost / joostmouw@gmail.com / Synced`.

**Joost zag tijdens het opstarten wél een venster verschijnen** — "Signing you in.", van onderen
opkomend. Onderzocht en het is **niet** RideWindow die zichzelf uitgelogd rendert; het is Google
Play Services. Bewijs in hetzelfde log:

```
com.google.android.gms/.auth.api.credentials.assistedsignin.ui.AssistedSignInActivity
com.android.credentialmanager/com.oplus.credentialmanager.CredentialSelectorActivity
ServiceConnector: ...credman.service.GoogleIdService
```

AUTH-04 vraagt of de app zelf een uitgelogde staat toont vóór de sessie hersteld is. Dat gebeurt
niet. PASS.

### Nieuwe bevinding — de "nooit prompten"-belofte houdt niet op Android

`lib/services/calendar_service.dart:275-290` documenteert `currentGoogleEmail()` als
*"ZONDER ooit een OAuth-prompt/popup te tonen (D-11, AUTH-07)"*. Op Android loopt
`attemptLightweightAuthentication()` via Credential Manager, en die toont assisted-sign-in-UI
zodra hij niet precies één geautoriseerd account kan auto-selecteren.

Aanroepketen: `ProfileScreen.initState()` → `_checkCalendarConnection()` →
`_checkCalendarMismatch()` (alleen als de agenda gekoppeld is) → `currentGoogleEmail()`.

`initState()` draait één keer per schermopbouw, dus alleen bij een koude start. Geverifieerd:
tabwisselen Home → Profiel reproduceert de popup **niet**, wegvegen + heropenen **wel**.

Cosmetisch — er verandert niets aan de login — maar een al ingelogde gebruiker een
sign-in-venster tonen is verkeerd, en de code gaat er aantoonbaar van uit dat dit niet kan.
Backlog #56. Geen fase-21-blokkade.

### Nevenwaarneming — twee outbox-rijen bij élke koude start

Beide koude starts loggen identiek `2 pending, 2 sent (profile, availability), 0 failed`, zonder
dat er iets gewijzigd was. Elke app-start schrijft dus profiel én beschikbaarheid opnieuw naar
Supabase. Functioneel correct, maar het zijn schrijfacties zonder aanleiding. Backlog #57.

### SYNC-05 — derde, bevestigende waarneming

Beide koude starts draineerden schoon: `0 failed`, nul `disposed`-regels (21-11 houdt stand op
de Play-build), nul `PostgrestException` (21-12 houdt stand). **Bewust geen PASS-claim toegevoegd:
er is deze sessie geen dashboardcontrole gedaan.** Het bewijs voor SYNC-05 blijft de twee
metingen van 2026-08-04 die wél in Postgres bevestigd zijn; deze sluit daarop aan.

Ook waargenomen en daarmee het laatste open vinkje van §5a gesloten: de statustekst leest
**"Synced"**, niet "Syncing...". Die stond eerder alleen afgeleid uit `0 failed`.

### Fout van Claude in deze sessie, ter lering vastgelegd

Na een `force-stop` kwam RideWindow niet naar voren maar de app eronder (WiZ-verlichting). De
uitvoer van het startcommando was naar `/dev/null` gestuurd, waarna er blind op de coördinaten
van RideWindows Profiel-tab is getikt. Die tik landde op de tabbalk van de WiZ-app en wisselde
daar van tabblad. Geen schade aan de verlichting waarneembaar, wel een tik in een vreemde app.
Vanaf dat moment wordt `mCurrentFocus` gecontroleerd vóór elke tik, en die guard heeft daarna
aantoonbaar een tweede blinde tik voorkomen (abort in plaats van tik).

### Ongewijzigd open

§2's agenda-event en uitlog-ronde, §3 (iPhone-PWA + SYNC-04), §4 (koude start), §5 (multi-tab),
§6 (delete-account).

### §2 — "Voeg toe aan agenda": **PASS** (2026-08-05)

Event staat correct in Google Calendar, met de juiste start/eindtijd.

**Nevenwaarneming die de 21-13-diagnose scherper maakt:** de tik leverde **één** agenda-event op,
terwijl "My Rides" op dat moment **twee** identieke kaarten toonde (Saturday 8 Aug, 12:00-15:00,
100 Perfect, beide met dezelfde weerregel). De agenda-schrijfactie gebeurt eenmalig op het moment
van tikken; de duplicatie ontstaat pas daarna, in de cloud-reconcile. Dat sluit een dubbele
tap/dubbele handler-aanroep uit als oorzaak en past exact bij de rideId-splitsing die plan 21-13
beschrijft: lokaal `2026-08-08T12-00-00-000`, uit Postgres teruggelezen `2026-08-08T12-00-00-000Z`.

### §2 — nog open

Alleen de uitlog-ronde (uitloggen → agendakoppeling blijft intact per D-12 → weer inloggen).

### §5b — vastgelegde "voor"-toestand, 2026-08-05 21:22, app 1.0.19+20 (Play)

Screenshot: `~/Documents/O+ Connect/Screenshot_2026-08-05-21-22-35-88_...jpg` (niet in de repo —
publieke repository, dus persoonlijke schermafdrukken blijven erbuiten).

Home's PLANNED-sectie toont **vier** kaarten voor **twee** ritten:

| Rit | Kaarten |
|-----|---------|
| Saturday 12:00–15:00 · 3u · Perfect | 2 |
| Sunday 08:00–10:00 · 2u · Perfect | 2 |

Twee dingen die dit toevoegt aan de diagnose van plan 21-13:

1. **Het treft elke rit, niet één legacy-geval.** De zondagrit is ná 20:56 gepland (om 20:56
   toonde "My Rides" alleen het zaterdagpaar) en dupliceerde meteen mee. De bug zit dus in het
   normale pad, niet in oude data.
2. **Het blijft staan op precies twee per rit.** Geen groei over meerdere foreground-cycli heen.
   Dat is wat de diagnose voorspelt: zodra beide sleutels — de lokale en de uit Postgres
   teruggelezen UTC-variant — in de lokale lijst staan, voegt `putIfAbsent` in de union-merge er
   niets meer aan toe. Onbegrensde vermenigvuldiging zou op een ander mechanisme wijzen en de
   21-13-verklaring ondermijnen.

Deze toestand is de meetlat voor §5b: na installatie van 1.0.20+21 moeten dit vier kaarten → twee
kaarten worden, en moet `planned_rides` per rit één rij houden.

**Let op bij het beoordelen:** het toestel draait op het moment van deze screenshot nog de
Play-build 1.0.19+20 van 2026-08-04 19:50. Dit is dus het verwachte gedrag van vóór de fix, geen
bewijs dat 21-13 niet werkt.
