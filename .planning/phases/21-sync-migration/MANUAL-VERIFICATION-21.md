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

---

## Device session 5 — 2026-08-05 22:53-23:00, Oppo Find X9 Pro, app 1.0.21+22 (sideload)

**Aanpak gewijzigd:** de Play-route is verlaten voor de rest van de sessie. Elke iteratie kostte
20+ minuten (uploaden, verwerken, uitrollen, opt-in, updaten) tegen 2 minuten voor een sideload,
en §2 — de enige sectie die de Play App Signing-route echt moet bewijzen — was al afgetekend.
`adb uninstall` + `adb install` van de lokaal gebouwde release-APK; versie-assertie
`versionCode=22 versionName=1.0.21` bevestigd vóór elke interpretatie.

De uninstall wist de lokale database. Dat was aanvaardbaar omdat het testmateriaal in Supabase
staat, niet op het toestel — en het leverde een verificatie op die nog openstond.

### MIG-02 — tweede toestel, leeg lokaal + gevulde cloud: **PASS**

Nog nooit eerder op een toestel getest; tot nu toe was alleen de omgekeerde richting bewezen
(leeg account, gevulde telefoon = MIG-05/06).

| Gecontroleerd | Uitkomst |
|---|---|
| Conflictdialoog | Geen — correct, leeg lokaal is geen divergentie |
| Beschikbaarheidsrooster | Identiek aan de opname van 22:46 vóór de uninstall: za 8 en zo 9 vrij vanaf 06:00, rest geblokkeerd |
| Profielinstellingen | "Evening before" weer aan, zoals in de cloud |
| Statustekst | "Synced" |

### §5b — SYNC-03, één rit blijft één rit: **PASS**

Op een verse installatie die alles uit de cloud moest halen toont PLANNED **twee** ritten:
Saturday 12:00–15:00 en Sunday 08:00–10:00. Geen 14:00-kaart, geen 10:00-kaart, geen duplicaten.
Dit is de sterkst mogelijke vorm van deze test: er was geen lokale staat die het resultaat kon
maskeren.

Nog te doen door Joost in het dashboard: bevestigen dat `planned_rides` één rij per rit houdt,
met een `ride_id` dat op `Z` eindigt en `start_at` op 10:00 UTC voor de 12:00-rit.

### §5c — SYNC-03, een verwijderde rit blijft verwijderd: **PASS**

Zondagrit verwijderd via het prullenbak-icoon (bevestigingsdialoog "Unplan this ride?"), daarna
drie voor/achtergrond-cycli:

```
22:59:10.479  drain done — 1 pending, 1 sent (planned_ride), 0 failed   <- de delete, in de
                                                                           drain VOOR de pull
22:59:18.898  drain done — 0 pending, 0 sent, 0 failed                  <- cyclus 2: niets
22:59:27.464  drain done — 0 pending, 0 sent, 0 failed                  <- cyclus 3: niets
```

De rit is niet teruggekomen. De delete vertrok in de eerste drain van de cyclus, precies de
volgorde die plan 21-14 herstelt; vóór 21-14 zou de pull de rit hier weer hebben opgewekt.

Merk ook op dat 21-14's dubbele drain zichtbaar is in elke cyclus: één push vóór de reconcile,
één erna voor wat de merge enqueuet.

### Bevestigd, opnieuw: backlog #57

Élke cyclus stuurt `availability` opnieuw op zonder dat er iets gewijzigd is
(`1 sent (availability)` op 22:59:10, :19 en :27). Functioneel onschadelijk, maar het zijn
schrijfacties zonder aanleiding en het maakt `updated_at` onbruikbaar als "wanneer wijzigde de
gebruiker dit".

### Nog open

§5b's dashboardcontrole, §2's uitlog-ronde, §3 (iPhone), §4 (koude start), §5 (multi-tab),
§6 (account verwijderen).

### Open punt uit sessie 5 — 21-13's cloud-reparatie is niet geoefend

`_repairNonCanonicalRideIds` heeft in deze sessie **geen enkele keer gelogd**, terwijl het bij elke
niet-canonieke rij een regel hoort te schrijven. Uitgezocht wat dat betekent:

Om 21:2x toonde het dashboard **4 rijen** in `planned_rides`. Om 22:53, na de verse installatie,
kwamen er **2 ritten** terug. De twee spookritten waren dus al weg uit de cloud vóór de sideload.

Dat is te herleiden. Zouden de spookrijen er nog gestaan hebben, dan waren er maar twee
mogelijkheden geweest, en beide zijn uitgesloten door wat we zagen:

1. Hun `ride_id` was niet-canoniek → de reparatie was gelopen en had gelogd. Er is niets gelogd.
2. Hun `ride_id` was wél canoniek → ze waren gewoon opgehaald en hadden als kaarten van 14:00 en
   10:00 in beeld gestaan. Die stonden er niet.

Conclusie: Joosts handmatige deletes van eerder op de avond **hebben de cloud wél bereikt**. Wat
telkens terugkwam was de lokale kopie, opgewekt door de pull die vóór de delete liep — precies de
lus die plan 21-14 dicht. Toen de lokale database bij de sideload verdween, was er niets meer om
de rijen opnieuw omhoog te duwen, en bleef de cloud schoon.

**Gevolg voor de aftekening:** dit bevestigt 21-14's diagnose van een andere kant, maar het
betekent ook dat 21-13's cloud-reparatiepad **niet op een toestel geoefend is** — er was niets
meer te repareren. Die code is alleen door unit-tests gedekt. Dat is geen blokkade (het pad is
per definitie een eenmalige opruiming voor rijen van vóór 21-13, en die zijn er niet meer), maar
het hoort niet als "bewezen" te worden weggeschreven.

### §5b — dashboardbevestiging, 2026-08-06: **PASS**

`select ride_id, start_at, end_at, planned_score from planned_rides order by start_at;`

```
ride_id                     start_at                end_at                  planned_score
2026-08-08T10-00-00-000Z    2026-08-08 10:00:00+00  2026-08-08 13:00:00+00  100
```

Eén rij, en alle vier de eigenschappen die plan 21-13 voorspelt kloppen:

- `ride_id` eindigt op `Z` — de sleutel komt uit de UTC-instant, niet uit de lokale ISO-string
- `ride_id` codeert **10:00**, niet 12:00 — dus geen lokale klokwaarde in de sleutel
- `start_at` = 10:00 UTC = 12:00 lokale zomertijd, `end_at` = 13:00 UTC = 15:00 lokaal — het
  tijdstip is niet meer verschoven
- geen tweede rij

Daarmee is §5b volledig afgetekend: de duplicaat is weg **en** het opgeslagen tijdstip klopt. Dat
onderscheid was het hele punt — een fix die alleen de sleutel repareerde zou hier 12:00 UTC hebben
laten staan.

---

## Web-sessie — 2026-08-06/07, PWA op desktop-Chrome én Chrome op Android

Aanleiding: op de desktop-PWA werkt de sync, op de telefoon-PWA staat de account-status op
"Syncing..." en verschijnt de geplande rit niet. Beide op 1.0.22+23, zelfde account.

Gediagnosticeerd via het Chrome DevTools Protocol over `adb forward tcp:9222
localabstract:chrome_devtools_remote`, met een minimale WS-client op stdlib (staat in de
scratchpad, niet in de repo).

### Uitgesloten, met bewijs

| Kandidaat | Waarneming die hem uitsluit |
|---|---|
| Ander account | `uid = a1456a8d-f39c-45c5-94cf-35957fc4a555` op telefoon én desktop |
| Netwerk / RLS / auth | Vanuit de **telefoonpagina zelf** een PostgREST-query op `planned_rides`: **status 200**, met de juiste rij (`ride_id 2026-08-08T10-00-00-000Z`, `start_at 10:00+00`) |
| Stale build | Beide 1.0.22 (23); telefooncache is gewist met behoud van sitegegevens |
| Vastgelopen outbox | Leeg (inspector én geen pending rijen) |
| Sign-in-sync nooit voltooid | `flutter.account.lastSyncedUid` staat gezet op beide |
| Verkeerd scherm | Router gebruikt `StatefulShellRoute.indexedStack`, dus HomeScreen — waar de lifecycle-observer op zit — blijft levend op elk tabblad |

### Wat er wél anders is

Telefoon: `flutter.planned_rides` bevat nog de rit van **31 juli**, in het oude offsetloze
formaat (`"2026-07-31T20:00:00.000"`). Die is verleden tijd en wordt door `readLocal()` uitgefilterd,
dus de lijst oogt leeg. Desktop: de augustusrit in het nieuwe formaat mét `Z`.

De telefoon heeft dus sinds vóór 21-13 geen planned-rides-merge meer geschreven, terwijl hij de
cloud aantoonbaar kan lezen.

### Openstaande vraag — de kern

Draait `reconcileOnForeground()` op web? Dat is **niet vastgesteld**, en de reden is belangrijk
genoeg om op te schrijven: op web bereikt `debugPrint` de browserconsole niet. Op de desktop, waar
de sync aantoonbaar wérkt, staat óók geen enkele `drain done`-regel in de console. Afwezigheid van
logregels bewijst hier dus niets — precies de spiegelvorm van de fout die deze fase eerder maakte
(een logregel als bewijs nemen).

### Twee eigen proeven die ongeldig bleken

Beide keren ving de controle achteraf het, niet de meting. Opgeschreven zodat ze niet herhaald
worden:

1. **`localStorage` rechtstreeks leegmaken en kijken of de reconcile hem hervult.** Werkt niet:
   `shared_preferences` houdt op web een geheugencache aan, dus de app leest die bewerking nooit.
2. **Een tabblad "activeren" met een CDP-screenshot.** Werkt niet: `document.visibilityState` bleef
   `hidden` en `document.hasFocus()` `false`. Er was dus nooit een voorgrond-overgang, en de
   conclusie "het tabblad pikt de wijziging niet op" was ongefundeerd.

Gevolg: SYNC-11 (multi-tab) en de webkant van SYNC-04 zijn **nog niet gemeten**. Daar is een echte
vingerbeweging voor nodig — een tabwissel die het besturingssysteem als zodanig registreert.

### Testdata die is achtergebleven

Een geplande rit **Saturday 8 aug 07:00–09:00** (`start_at 05:00+00`), door mij aangemaakt in het
desktop-tabblad als multi-tab-testwijziging. Mag weg met het prullenbak-icoon.

---

## Web-sessie, vervolg — 2026-08-07, twee waarnemingen door Joost

De twee proeven die ik zelf niet kon doen, zijn gedaan. Beide vragen de tabovergang die een
gesimuleerde activatie niet oplevert; beide zijn geslaagd.

### SYNC-11 — multi-tab: **PASS**

**Waarneming.** Joost klikt in zijn eigen desktop-tabblad, dat op dat moment al openstond en dus
een echte voorgrond-overgang maakt. Onder PLANNED staan **twee** ritten: Saturday 07:00–09:00 én
12:00–15:00.

De eerste is de rit die ik in een **ander** tabblad had aangemaakt. Het tabblad van Joost heeft die
wijziging dus opgepikt zonder herladen — dat is precies wat SYNC-11 vraagt.

**Wat dit niet zegt.** Dit dekt de propagatierichting (tabblad B ziet wat tabblad A schreef). De
overschrijfvraag uit §5 — of B's eigen volgende schrijfactie A's wijziging weer platslaat — is
hiermee niet los getoetst; dat beide ritten naast elkaar staan in plaats van dat de een de ander
verving, is het sterkste dat deze waarneming daarover zegt.

### SYNC-04, webkant — **PASS**

**Waarneming.** Op de telefoon (Chrome-tabblad): naar een ander tabblad, twee tellen wachten, terug.
Daarna staat de **augustusrit** onder PLANNED, waar eerst de julirit stond.

Dus: `reconcileOnForeground()` draait op web, het lifecycle-event vuurt in Chrome op Android, en de
telefoon schrijft de planned-rides-merge alsnog in het nieuwe `Z`-formaat.

### Correctie op de vorige sectie

De hierboven genoteerde "openstaande vraag — draait `reconcileOnForeground()` op web?" is hiermee
beantwoord met **ja**, en de daaraan gekoppelde verdenking is ingetrokken.

De diagnose van 2026-08-06/07 klopte in wat ze uitsloot (account, netwerk, RLS, build, outbox,
sign-in-sync, scherm) en klopte in wat ze als verschil vond (de telefoon had een oude offsetloze
rit in `flutter.planned_rides` staan). Waar ze naartoe neigde — dat er mogelijk een echte bug in de
voorgrond-reconcile zat — was **fout**. De oorzaak was dat de telefoon in die hele sessie nooit een
voorgrond-overgang heeft gemaakt: mijn CDP-screenshot activeerde het tabblad niet, en zolang het
tabblad `hidden` bleef was er niets om op te reageren. De stale julirit was geen symptoom van een
kapotte reconcile maar van een reconcile die simpelweg nog niet gelopen had.

Dat is de derde keer in deze fase dat een meetopstelling, niet de code, de bevinding produceerde.
De eerdere twee staan hierboven bij "Twee eigen proeven die ongeldig bleken"; dit is het geval
waarin ik die ongeldigheid pas achteraf zag. De les die ik meeneem: op web is een voorgrond-overgang
niet van buitenaf af te dwingen, en elke conclusie over lifecycle-gedrag die niet op een echte
vingerbeweging rust, is geen waarneming maar een vermoeden.

### Gevolg voor §3

Hiermee is SYNC-04 aangetoond op de webkant. Wat §3 daarnaast nog vroeg — installatie vanaf een
iPhone via Safari — vervalt: zie de herschreven §3 in `REGRESSION-CHECKLIST-21.md`, waar iOS
expliciet naar v2 is uitgesteld op grond van de Android-only-constraint in `CLAUDE.md`.

---

## Device session 6 — 2026-08-07 ~12:15, Oppo Find X9 Pro (PLG110), app 1.0.21+22 (sideload)

**Methode, en waarom die deugt.** Gedreven vanaf de Mac over `adb`: `uiautomator dump` voor het
uitlezen van de werkelijk gerenderde view-hiërarchie, `input tap` / `input swipe` voor de bediening.

Dat is nadrukkelijk iets anders dan de webproeven die eerder in deze fase ongeldig bleken. `input
tap` genereert een echt invoerevent op OS-niveau — het toestel kan niet zien dat er geen vinger aan
te pas kwam — en `uiautomator` leest af wat er daadwerkelijk op het scherm staat, niet wat de code
zegt dat er zou moeten staan. Waar de CDP-screenshot een tabblad níet activeerde, activeert deze
methode de app wél. Schermafbeeldingen van elke stap staan in de scratchpad van die sessie.

### Correctie op de aanname over de buildversie

`MORGEN.md` meldde 1.0.22+23 op het toestel. Gemeten via `dumpsys package`: **1.0.21+22**, en het
Version-blok in Profiel bevestigt "1.0.21 (22)". Het getal 1.0.22+23 sloeg op de PWA en op de
bottom-sheet-fix, niet op wat er als APK geïnstalleerd staat. Afgeleid in plaats van gemeten;
rechtgezet.

### Correctie op de aanname over de agendakoppeling

`MORGEN.md` meldde Google Calendar op "Not connected", met als verklaring dat de sideload de
OAuth-grant meenam. Gemeten: **Connected**, met een actieve "Disconnect"-knop. Stap 1 van de
overdracht was dus overbodig. Waarom de eerdere lezing anders was, is niet vast te stellen zonder
het moment zelf; wat telt is dat er wél iets te behouden viel, dus dat de D-12-toets zinvol was.

### §2 — SYNC-04, cross-surface web → native: **PASS** (nevenwaarneming)

Bij het openen van de app stonden onder PLANNED **beide** ritten: Saturday 07:00–09:00 en
12:00–15:00. De eerste is door mij in een desktop-webtabblad aangemaakt. De native app heeft die
dus opgepikt — propagatie van web naar native, in dezelfde richting die §3 vroeg maar dan tussen de
twee oppervlakken die v1 werkelijk uitbrengt.

### §2 — uitlog-ronde (D-12): **PASS**

| Moment | Account | Google Calendar |
|---|---|---|
| Vóór | `Joost / joostmouw@gmail.com / Synced` | **Connected** (+ Disconnect-knop) |
| Na uitloggen | "Sign in with Google" | **Connected** (+ Disconnect-knop) |
| Na opnieuw inloggen | `Joost / joostmouw@gmail.com / Synced` | onveranderd |

De bevestigingsdialoog zegt "Your data on this device stays exactly as it is. You can always sign
in again." — en dat klopte: naam "Joost", RIDE LENGTH en de drie notificatie-instellingen stonden
er na het uitloggen nog. Beide geplande ritten stonden na de her-login nog op Home.

**Daarmee is D-12 aangetoond:** uitloggen uit het account sleept de Google Calendar-koppeling niet
mee. Dat zijn twee onafhankelijke autorisaties en ze gedragen zich ook zo.

**§2 is hiermee compleet.**

### Nog open na deze sessie

- §3 — PWA installeren via "Zet op beginscherm" (nieuwe, herschreven vorm)
- §4 — koude start meten (REG-03)
- §6 — account verwijderen (AUTH-09), als laatste
- Afsluitende Play-installatie

---

## Device session 7 — 2026-08-07 12:27-12:40, §3 op de PWA, WebAPK 1.0.22+23

Zelfde methode als sessie 6 (`adb` + `uiautomator` + `input tap`), met één aanvulling die er
inhoudelijk toe doet: **Flutter-web publiceert zijn semantics-boom pas nadat je Flutters eigen
"Enable accessibility"-knop hebt aangetikt.** Zolang die uit staat ziet `uiautomator` precies één
node, en dan lijkt élk scherm leeg. Dat is een valkuil die makkelijk voor een bevinding wordt
aangezien — het is mij vandaag één keer overkomen (zie hieronder) en de controle ving het.
Op een koude start staat de boom altijd weer uit; gebruik daar een **screenshot**, die is passief.

### §3 — installatie: **PASS**

| Stap | Waarneming |
|---|---|
| Installeerbaar | Chrome bood "Install and create shortcut" aan — dat verschijnt alleen als het manifest de installability-criteria haalt |
| Geïnstalleerd | nieuw pakket `org.chromium.webapk.a5a380363e216c9c6_v2`, `firstInstallTime` 2026-08-07 12:29:25 — een **echte WebAPK**, geen bladwijzer |
| Standalone | vensterfocus `com.android.chrome/…webapps.SameTaskWebApkActivity`, niet `ChromeTabbedActivity` — geen adresbalk, en dit is een sterker bewijs dan een screenshot omdat het een ander venstertype is |
| Navigatie | Home → Profiel → Home → Ride Detail → terug: geen dood eind, geen witte pagina |
| Ingelogd | `Joost / joostmouw@gmail.com / Synced`. De WebAPK erft de opslag van Chrome voor dat domein, dus er was geen nieuwe login nodig |
| "Voeg toe aan agenda" | **geverifieerd in de echte agenda**: event "Fietsrit 06:00–08:00" staat op zaterdag 8 augustus, naast de "Fietsrit 12:00–15:00" van de eerdere native test |

De ritkaarten op de PWA kwamen exact overeen met die op de native app (Saturday 07:00–09:00 en
12:00–15:00), dus de cross-surface-controle uit §3 klopt ook aan deze kant.

### **Nieuwe bevinding — een verse installatie haalt geplande ritten niet op tot je hem eenmaal wegzet**

Dit is de opbrengst van §3, en precies de reden om de sectie niet te laten vervallen.

| Toestand | PLANNED-sectie |
|---|---|
| Verse WebAPK, eerste start, lege lokale opslag, wél een geldige sessie | **leeg** |
| Zelfde app, na één achtergrond → voorgrond-cyclus | **beide ritten** |
| Zelfde app, koude start (force-stop + opnieuw), nu mét lokale data | **beide ritten, meteen** |

Geen kwestie van te kort wachten: bij de eerste start had de app ruim een halve minuut gedraaid en
was ik ondertussen naar Profiel en terug genavigeerd. De derde regel is de discriminator — koude
start is niet het probleem, **lege lokale opslag** is het.

**Wat dit betekent.** De pull van planned rides hangt uitsluitend aan de voorgrond-reconcile. Bij een
normale login (`lastSyncedUid` staat al) draait de eerste-login-migratie niet, en de initiële load
telt niet als voorgrond-overgang. Een gebruiker die de PWA op een nieuw toestel installeert en opent,
ziet dus een lege PLANNED-lijst en concludeert redelijkerwijs dat de sync stuk is.

**Dit is de grondoorzaak van de web-sessie van 2026-08-06/07.** Die vond wel het symptoom (de
telefoon had een oude offsetloze julirit) en sloot zeven kandidaten uit, maar landde op "er was
nooit een voorgrond-overgang". Dat klopte, maar het is de helft: de echte vraag is waarom een
oppervlak dat een geldige sessie heeft en de cloud aantoonbaar kan lezen, niet uit zichzelf pullt
bij het laden. Die vraag is nu beantwoord.

**Nog niet vastgesteld:** of dit ook de native app raakt bij een verse installatie met lege lokale
opslag. MIG-02 (device session 5) dekte "leeg lokaal + gevulde cloud" en slaagde daar — maar dat
liep via een échte eerste login op dat toestel, dus via het migratiepad, niet via dit pad. Het
verschil is precies `lastSyncedUid`.

### Correctie binnen deze sessie

Na de force-stop-proef las ik "GEEN PLANNED-sectie" uit een `uiautomator`-dump en stond op het punt
dat als een tweede bevinding op te schrijven. De dump bevatte in werkelijkheid alleen
`Enable accessibility` — de semantics-boom stond na de herstart weer uit. Het screenshot liet zien
dat beide ritten er gewoon stonden, en de conclusie draaide 180 graden om. Vierde keer in deze fase
dat de meetopstelling bijna een bevinding produceerde.

## Device session 8 — 2026-09-01 18:00-18:20, §4 koude start geautomatiseerd, PWA 1.0.23+24

**Aanleiding:** §4 stond nog open omdat de vorige poging tot automatiseren strandde. Joost hing de
kabel er weer aan met de opdracht het alsnog te automatiseren.

### Uitkomst — §4 / REG-03

| Meetmoment na de tik | Ride slot zichtbaar |
|---|---|
| 1,52s | 0 / 6 runs |
| 1,77s | 3 / 6 runs |
| 1,93s | 5 / 6 runs |
| 2,03s | **9 / 12 runs** |
| 2,28s | 6 / 6 runs |

**Mediaan ≈ 1,75–1,8s. Nooit vóór 1,55s, altijd binnen 2,3s.**

Dat is geen enkel getal, en dat is met opzet: één meting had hier alles kunnen zeggen wat je wilde
horen. De spreiding is de bevinding. De typische koude start haalt de grens van 2 seconden ruim,
maar **in ongeveer één op de vier starts is het eerste ride slot na 2,0s nog niet zichtbaar**.

**Mijn lezing: PASS, met de staart genoteerd.** De grens is bedoeld als "de app is binnen 2s
bruikbaar", en dat is hij typisch. Wie de staart als blokkerend wil lezen heeft een verdedigbaar
punt — dat is Joost's keuze, niet de mijne, en daarom staat het getal hier in plaats van een vinkje.

> **BLOCKER uit de checklist blijft staan:** fase 19 heeft zijn eigen basislijn nooit gemeten (plan
> 19-07 is nooit afgerond). Er bestaat dus **geen geldige voor/na-vergelijking**. Wat hier staat
> bewijst de grens in absolute zin, meer niet.

### Omstandigheden

- Oppo Find X9 Pro (PLG110), Android 16, serial `3B15AD01LEN00000`
- **Wifi** als primaire transport (LTE stond ook verbonden, `TRANSPORT_PRIMARY` was wifi)
- Batterij 59%, 36,9 °C — geen thermal throttling in zicht
- PWA 1.0.23+24, service worker warm; dit is dus een **terugkerende** gebruiker, niet de allereerste
  start na installatie
- Gestart vanuit de **app-lade**, niet vanaf een beginschermpagina — het icoon staat niet op
  pagina 1 en verder bladeren door Joost's beginscherm leek me niet nodig. De lade-tik is dezelfde
  launcher-intent; het verschil is hooguit de openingsanimatie van de lade, die vóór de meting valt.

### Methode

Per run: `am force-stop` op zowel de WebAPK als `com.android.chrome` (de WebAPK draait in Chrome's
proces), lade openen, naar R springen, dan **één** sample op een exact tijdstip na de tik.

Alle tijdstempels staan in de **device-klok**: `date +%s.%N` draait op het toestel, direct vóór
`input tap` en direct vóór `screencap`. Daarmee valt de USB-latency van adb volledig weg — die zat
in mijn eerste opzet nog wél in het getal en maakte de meting ~0,5s te pessimistisch.

Detectie van "eerste ride slot" is een pixelmeting, geen oordeel: het aandeel lichte pixels in de
middenzone van het scherm springt van 0% naar 84% zodra de eerste ride-kaart staat. Visueel
gecontroleerd op de frames.

Harness: `meet3.py` in de sessie-scratchpad (niet gecommit — wegwerpgereedschap).

### Twee meetvallen, allebei stil

**1. `screenrecord` mag niet op dit toestel.** `Unable to open '...': Permission denied`, óók naar
`/data/local/tmp` waar shell wel degelijk schrijfrechten heeft (`drwxrwx--x shell shell`). Het is
dus geen padprobleem maar policy. **MORGEN.md schreef dit toe aan "de achtergrond-truc in
`adb shell` hield geen stand" — die diagnose was fout.** `screencap` mag wél naar dezelfde map
schrijven, dus het is specifiek schermopname die geblokkeerd is.

**2. Android's task snapshot gaf vier valse metingen.** Mijn eerste geautomatiseerde ronde vond het
ride slot in 4 van 5 runs op **+0,06s** — fysiek onmogelijk. Wat er stond was de *task snapshot*:
Android toont tijdens de launch-animatie een screenshot van hoe de app er bij het afsluiten uitzag,
en dat is precies een scherm vol ride-kaarten. `am force-stop` wist die snapshot niet.

Dat had een gemeten koude start van 0,06s opgeleverd, ruim binnen elke grens, en het zou er
volstrekt geloofwaardig uit hebben gezien. Opgelost door de volgorde te eisen: snapshot (licht) →
leeg/spinner (donker) → echte inhoud (licht), en pas de derde te tellen. De sample-op-vast-tijdstip
methode die uiteindelijk gebruikt is, omzeilt het probleem sowieso — vanaf ~1,5s is de snapshot
allang weg.

### Wat dit niet is

Dit meet een terugkerende start met warme service-worker-cache en gevulde lokale opslag. De
**eerste** start na installatie (lege lokale opslag) is stap 1b en is hier niet gemeten.

## Device session 9 — 2026-09-01 18:29-18:42, stap 1b: tegenproef op backlog #61

**Aanleiding:** de #61-fix (quick 260901-nz7, `36f4fca` + `abcf557`) was alleen door tests gedekt.
De cloud-leeskant is zonder levende backend niet waarneembaar, dus dit is de directe tegenproef.
Volledig via `adb` op de Oppo Find X9 Pro (PLG110), PWA **1.0.23+24** en native app **1.0.21+22**.

### Uitkomst — backlog #61: **PASS aan beide kanten**

De fix heeft twee helften, en die zijn apart geproefd. Dat onderscheid staat hier expliciet omdat
één proef makkelijk voor beide door had kunnen gaan:

| Helft van de fix | Waar hij zit | Proef | Uitkomst |
|---|---|---|---|
| Inlogflow | `account_section.dart:328` — `reconcileOnForeground()` in plaats van een kale `drainOutbox()` | site-data gewist, verse inlog, direct naar Home | **PASS** — rit staat er bij het eerste scherm |
| Koude start | `CloudSyncReconciler.reconcileOnStartup()`, aangeroepen vanuit `HomeScreen.initState` (`home_screen.dart:83`) | rit die alleen in de cloud staat, force-stop, koude start | **PASS** — rit staat er bij het eerste scherm |

**Negatieve controle, en dat is wat deze sessie boven een bevestiging uittilt:** de native app
1.0.21+22 (dus **vóór** de fix) staat op hetzelfde toestel, is ingelogd met dezelfde geldige sessie
en kijkt naar dezelfde cloud. Bij koude start toonde die **geen PLANNED-sectie**, terwijl
Tuesday 20:00–22:00 aantoonbaar in de cloud stond; pas na één achtergrond→voorgrond-cyclus
verscheen de rit. De bug reproduceert dus live naast de fix. Zonder die controle had een PASS ook
"de rit stond er toch al" kunnen betekenen.

### Opzet, stap voor stap

1. **Precondition.** "My Rides" was leeg — de augustusritten zijn verleden tijd. Er is dus eerst
   een rit gepland (Tuesday 1 sep 20:00–22:00) op de PWA.
2. **Naar de cloud geduwd.** Zie de noot over de outbox hieronder; dit kostte een expliciete
   voorgrond-cyclus. Bevestigd door de accountregel op `Synced`.
3. **Lokale opslag gewist** (zie de correctie hieronder). Bevestigd doordat de PWA op het
   welkomstscherm opstartte in plaats van op Home.
4. **Verse inlog** als joostmouw@gmail.com via de account-chooser. Geen conflictprompt.
   Direct daarna Home: **Tuesday stond er meteen**, zonder de app ooit weg te zetten.
5. **Cloud-only rit gemaakt** voor de tweede helft: Saturday 5 sep 06:00–09:00 gepland vanaf de
   **native** app en met een voorgrond-cyclus naar de cloud geduwd (`Synced`). De PWA had die rit
   op dat moment lokaal niet.
6. **Koude start** van de PWA: `am force-stop` op zowel de WebAPK als `com.android.chrome` (de
   WebAPK draait in Chrome's proces), daarna via het launcher-intent geopend. Op het eerste scherm
   stonden **beide** ritten, Tuesday én Saturday.

Stap 6 is bewust immuun voor de task-snapshot-val uit sessie 8: de snapshot van de PWA bij
afsluiten bevatte alléén Tuesday, dus Saturday kan er niet uit komen.

### Correctie op MORGEN.md — de wisinstructie was fout voor een WebAPK

`MORGEN.md` schreef voor: Instellingen → Apps → RideWindow → Opslag → **Gegevens wissen**. Dat is
de juiste hendel voor een native app en de verkeerde voor een WebAPK. `org.chromium.webapk.
a5a380363e216c9c6_v2` is een dunne launcher-shell; de localStorage en IndexedDB van de app leven in
het **Chrome-profiel voor dat origin**. Die instructie was dus vermoedelijk een no-op geweest, en
een lege proef die er als PASS uitziet is precies de meetval die deze fase al vier keer heeft
opgeleverd.

Gewist via: Chrome → Instellingen → Site-instellingen → Alle sites → `my-project-joost.web.app` →
**Delete site data**. Chrome's eigen dialoog bevestigt de redenering letterlijk:

> This will delete all data and cookies stored by https://my-project-joost.web.app **or by its app
> on your Home screen**.

De opslag was 7,5 kB + 1 cookie. Na het wissen startte de PWA op het welkomstscherm — de
onafhankelijke bevestiging dat er echt niets meer stond.

### De outbox loopt niet leeg als je een rit plant

Na het plannen bleef de accountregel ~45 seconden op "Syncing…" staan, ook na hernavigeren. Dat is
**verwacht gedrag, geen vastloper**: "Syncing…" is letterlijk `pendingCount != 0`
(`account_section.dart:548`), en de enige drain-triggers zijn `reconcileOnStartup` (app-start),
`reconcileOnForeground` (voorgrond-overgang) en de inlogflow. Een rit plannen enqueuet wel maar
duwt niet. Eén voorgrond-cyclus zette hem op `Synced`.

Genoteerd omdat het er bij het meten uitziet als een vastgelopen outbox — en omdat een gebruiker
die een rit plant en meteen zijn telefoon weglegt, die rit pas bij de volgende opening verstuurt.
Geen bevinding voor deze fase, wel iets om bij een volgende sync-ronde tegen het licht te houden.

### Testdata die is achtergebleven

Twee geplande ritten op joostmouw@gmail.com: **Tuesday 1 sep 20:00–22:00** en
**Saturday 5 sep 06:00–09:00**. Allebei van mij. §6 hieronder heeft de cloud-kant opgeruimd; de
lokale kopieën staan er nog (dat is juist wat D-03 bewijst) en mogen de prullenbak in.

## §6 — AUTH-09, account verwijderen — 2026-09-01 18:55, PWA 1.0.23+24

Uitgevoerd direct na stap 1b, in dezelfde device-sessie, via `adb`. Bewust op de **PWA** en niet op
de native app: die staat op dit toestel nog op 1.0.21+22, terwijl de PWA de code draait die ook in
de AAB 1.0.23+24 zit.

### App-kant: **PASS**, op alle punten

| Verwachting | Waarneming |
|---|---|
| Uitgangspositie gesynchroniseerd | `Joost / joostmouw@gmail.com / Synced`, met twee geplande ritten in de cloud |
| Eén AlertDialog met "cannot be undone" (D-01) | "Delete account?" — "This cannot be undone. Your profile, availability and planned rides will be permanently removed from the cloud." Cancel / Delete |
| Automatische uitlog | Profile toont weer de signed-out weergave met de `renderButton()`-Google-knop |
| Snackbar | "Account deleted" |
| **Lokale data onaangeroerd (D-03)** | **PASS op alle drie**, gecontroleerd tegen een "voor"-opname van dezelfde schermen |

D-03 is niet op één scherm afgetekend maar op drie, omdat dat de garantie is die nooit mag breken:

- **Notificatie-instellingen** — "Evening before" nog aan, de andere twee nog uit.
- **Beschikbaarheidsrooster** — identiek: doordeweeks geblokkeerd, weekend vrij, en Saturday 6–8
  nog blauw gemarkeerd als gepland.
- **Geplande ritten** — beide staan nog in "My Rides", mét hun score en weerregel.

De app is volledig bruikbaar uitgelogd. Verwijderen haalt dus alleen de server-kant weg, precies
zoals D-03 belooft.

### Dashboardhelft — geverifieerd 2026-09-01 19:0x via de SQL-editor

Gedaan in Joost's eigen browser, met twee **lees**queries in de Supabase SQL-editor (project
`hcdrydlgqpnmumfupgcx`). De native app was op dat moment `force-stop`'t, zodat een outbox-push van
de nog-bestaande sessie de meting niet kon vervuilen.

| Meting | Waarde | Oordeel |
|---|---|---|
| `auth.users` waar `email = 'joostmouw@gmail.com'` | **0** | **PASS** — account weg uit Authentication |
| Weesrijen in `profiles` (geen bijbehorende `auth.users`) | **0** | **PASS** |
| Weesrijen in `availability` | **0** | **PASS** |
| Weesrijen in `planned_rides` | **0** | **PASS** |
| `feedback` totaal / met `user_id` NULL | 0 / 0 | **n.v.t.** — zie hieronder |

De weesrijen-vorm is bewust gekozen boven "tel de rijen in de tabel". Die tabellen zijn niet leeg —
`profiles` 3, `availability` 3, `planned_rides` 2 — maar die rijen horen bij ándere accounts. Nul
weesrijen bewijst twee dingen tegelijk: de rijen van het verwijderde account zijn weg, én de
`on delete cascade` heeft niets laten liggen. Het bewijst bovendien dat de native app geen
spookrijen heeft teruggeduwd.

**De `feedback`-controle is niet gehaald maar vervallen.** De tabel bevat nul rijen, dus er is nooit
testfeedback onder dit account ingestuurd. Het `on delete set null`-gedrag op `feedback.user_id`
is daarmee **niet op de echte database bewezen** — alleen het schema belooft het. Wie dat alsnog wil
aantonen moet eerst feedback insturen onder een account en dat account daarna verwijderen. Ik teken
dit niet af als PASS.

### Nevenwaarneming — 11 accounts in `auth.users`

Naast de verwijderde staan er 11 accounts in `auth.users`, allemaal met adressen in het patroon
`voornaamachternaam.<5 cijfers>@gmail.com`. Dat oogt machinaal gegenereerd in plaats van als een
handvol echte bètatesters. Niet onderzocht en niets mee gedaan — het staat hier alleen genoteerd
zodat het niet stilletjes verdwijnt. Vraag aan Joost: geseed, of zijn dit de closed-test-testers?

---

## Device session 10 — 2026-09-02 08:06-08:15, de Play-installatie (AUTH-10 / D-16)

**Oppo Find X9 Pro (PLG110), volledig via `adb`.** Dit is de sessie die fase 21 sluit: de laatste
open stap was de app één keer vanaf Google Play installeren, omdat alles sinds 5 augustus op een
sideload met de upload-sleutel draaide en Play zijn eigen sleutel gebruikt.

### De de-installatie, en wat die kostte

`adb uninstall ridewindow.joost.amsterdam` → `Success`. Dat wist zoals voorzien de lokale
Drift-database én de Google Calendar-OAuth-grant. Beide zijn hierna opnieuw opgebouwd, dus de kosten
waren alleen tijd.

### Eén ding dat anders liep dan verwacht

`am start -a android.intent.action.VIEW -d "market://details?id=..."` opende **HeyTap Market**, de
eigen store van Oppo, niet Google Play. Dat scheelde geen fout maar wel een verkeerde
installatiebron — precies het soort verschil dat deze sectie moet bewaken. Met
`-d "https://play.google.com/store/apps/details?id=..." -p com.android.vending` erbij komt Play zelf
naar voren. Op dit toestel is het `-p com.android.vending` dat het werk doet.

### De installatie zelf — **PASS**

Play toonde de kaart "RideWindow (Internal Early Access)" met de rode regel "This app is for
developer testing and may be unsecure or unstable", en na de Install-tik "You're an internal tester".
Geverifieerd na afloop:

| Controle | Uitkomst |
|---|---|
| `installerPackageName` | **`com.android.vending`** — geen sideload |
| `versionCode` / `versionName` | **24 / 1.0.23** |
| `firstInstallTime` | 2026-09-02 08:06:52 |
| In-app profielscherm | **Version 1.0.23 (24)** |

Nevenwaarneming: `minSdk` leest nu **32** waar de sideload 24 gaf. Dat is Play die een
toestelgerichte split levert, geen wijziging in `build.gradle`.

### Inloggen vanaf een Play-gesigneerde build — **PASS** (AUTH-10, eerste helft)

Verse start: welkomstscherm → onboarding ("Evenings & weekends") → Home met echte forecast
("32 ride windows this week"). Daarna Profiel → "Sign in with Google" → accountkiezer → 
joostmouw@gmail.com.

- De accountkiezer verscheen en de inlog voltooide **zonder `ApiException: 10`** — dat is de fout die
  je krijgt als de SHA-1 van de Play App Signing-sleutel niet bij de OAuth-client staat, en precies
  het risico waarvoor D-16/AUTH-10 een échte Play-installatie eisen.
- Statustekst ging van "Syncing…" naar **"Synced"**.
- Na `am force-stop` + koude start: nog steeds ingelogd, **"Synced"**, geen flits van uitgelogd.

**Geen conflictdialoog**, zoals het hoort bij een eerste login zonder eerdere cloudrij — het account
was in §6 verwijderd, dus dit was werkelijk een verse migratie.

### Google Calendar vanaf een Play-gesigneerde build — **PASS** (AUTH-10, tweede helft)

Beide richtingen geproefd, want een koppeling die alleen leest bewijst de schrijfkant niet:

| Richting | Proef | Uitkomst |
|---|---|---|
| Lezen | Profiel → Edit my schedule → import-knop | blauwe **Calendar**-blokken in het rooster |
| Status | koude start → Profiel | **"Connected"** |
| Schrijven | Ride Detail → "Add to Google Calendar" | event in de echte agenda |

Het geschreven event, uitgelezen uit de agenda-provider van het toestel:

```
Row: 3812 title=Fietsrit 20:00–22:00, dtstart=1788372000000, dtend=1788379200000, calendar_id=10
```

`1788372000000` is woensdag 2 september 2026 20:00 CEST, `1788379200000` is 22:00 — exact het
geplande venster. Het event was al naar het toestel gesynchroniseerd op het moment van meten.

### Twee dingen die deze sessie bevestigde en die géén PASS zijn

- **Backlog #58 reproduceert vanaf een Play-build.** De app stond in het Engels; het event heet
  "Fietsrit 20:00–22:00". De hardcoded Nederlandse titel in `calendar_service.dart` is dus niet iets
  van de sideload-omgeving.
- **De Google Calendar-rij in Profiel ververst zijn status niet.** Direct na de import stond hij nog
  op "Not connected" en pas na een koude start op "Connected". Oorzaak is zichtbaar in de code:
  `_checkCalendarConnection()` draait alleen in `initState()`, en terugnavigeren vanuit "My schedule"
  bouwt `ProfileScreen` niet opnieuw op. Cosmetisch, maar het leest als een kapotte koppeling op het
  moment dat je hem net gelegd hebt. Raakt backlog #56, dat over dezelfde `initState`-keten gaat.

### Wat deze sessie **niet** bewijst

De rijen die de eerste-login-migratie vandaag in `profiles` / `availability` heeft geschreven zijn
**niet in het Supabase-dashboard nagekeken** — alleen Joost komt daar. Het RPC-pad zelf is wel
bewezen, op 2026-08-04 (device session 4, MIG-05/06: profiel, 120 uurblokken en 2 ritten in één
atomaire RPC, met echte waarden in het dashboard). Wat vandaag daar bovenop staat is dat dezelfde
keten vanaf een Play-gesigneerde build draait en dat de sessie een koude start overleeft. Wie de
laatste centimeter wil: `select count(*) from profiles where id = auth.uid()`-achtige controle in de
SQL-editor, of gewoon de Table Editor.

### Testdata die is achtergebleven

- Geplande rit **woensdag 2 september 20:00–22:00** in de app — van mij.
- Agenda-event **"Fietsrit 20:00–22:00"** op woensdag 2 september in Joost's echte Google Calendar —
  van mij, mag weg.
- De beschikbaarheid staat nu op het onboarding-preset "Evenings & weekends", niet op Joost's eigen
  rooster. Dat is geen verlies dat vandaag ontstond: de cloudkopie ging al weg met §6 (account
  verwijderd) en de lokale kopie met de de-installatie van vanochtend. Joost zal zijn rooster
  opnieuw moeten zetten — dat is de prijs die in MORGEN.md vooraf is benoemd en geaccepteerd.
