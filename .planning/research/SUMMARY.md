# Project Research Summary

**Milestone:** v3.0 Accounts & Sociaal (phases 1–2 of `.planning/milestones/v3.0-ACCOUNTS.md`)
**Researched:** 2026-07-25
**Stack decision:** **Supabase** (Auth + Postgres). Revised from Firebase on 2026-07-25, before Phase 18 began. Superseded research: `.planning/research/archive-firebase/`.
**Dimensions:** Architecture (`ARCHITECTURE.md`), Pitfalls (`PITFALLS.md`), Features (`FEATURES.md`)

---

## Executive Summary

RideWindow today is two disconnected local-only data silos — Android SharedPreferences and browser storage — with no concept of identity. This milestone gives it one: Google Sign-In through Supabase Auth, profile/availability/planned-rides in Postgres with row-level security, a defined first-login and second-device conflict story, and feedback that carries the scoring context it refers to.

The research is unusually well-grounded because the integration points were read from the actual codebase rather than assumed. Three findings shape everything downstream:

1. **The hardest-looking requirement is nearly free on this stack.** AUTH-05 asks for one non-racing Google Sign-In path shared by auth and Calendar. `lib/services/calendar_service.dart` already owns a memoized `initialize()` gate built to fix exactly that class of bug. Supabase consumes an ID token from that same singleton; Firebase Auth would have insisted on its own parallel flow. This was the decisive argument for the switch.
2. **The migration/conflict logic is a pure function and can be built first.** It needs no SDK, no network, no UI — just `lastSyncedUid`, two timestamps, and an existence check. It is also the part most likely to be got wrong silently, so it should be written and unit-tested before any infrastructure exists.
3. **Two fields that everything depends on do not exist yet.** Nothing in the app records when profile or availability last changed, and nothing records which account local data belongs to. Without both, MIG-02 and MIG-03 cannot be distinguished at all. This is MIG-04 and it is a prerequisite, not a nicety.

The one thing the stack switch *costs*: Supabase has no offline write queue. That must be built (a small Drift-backed outbox), and it must land with the first cloud write rather than after it.

---

## Key Findings

### Recommended Stack

| Concern | Choice | Confidence |
|---|---|---|
| Auth + database | `supabase_flutter` 2.16.0 (publisher supabase.io, 975 likes, published 18 days before research) | HIGH — verified live on pub.dev |
| Identity flow | `GoogleSignIn.instance.authenticate()` → `supabase.auth.signInWithIdToken()`, sharing `CalendarService`'s existing memoized init | HIGH |
| Web identity flow | `renderButton()` from `google_sign_in/web_only.dart` — `authenticate()` throws on web | HIGH — plugin-level restriction |
| Data model | Postgres tables mirroring the existing local models; JSONB for the 7×24 availability grid | HIGH |
| Authorization | Row-level security, `auth.uid() = user_id`, enabled in the same migration as each table | HIGH |
| Offline | Drift-backed outbox, coalesced per entity, idempotent upserts | MEDIUM — new construction |
| Cross-device propagation | Fetch on foreground. Realtime deliberately deferred | HIGH — matches SYNC-04 as written |
| Hosting | **Unchanged — Firebase Hosting.** Supabase supplies Auth + database only | HIGH |

### Architecture Approach

- `authStateProvider` as a `@Riverpod(keepAlive: true)` stream, mapping Supabase's `AuthState` down to `User?` so call sites stay SDK-ignorant. Must seed from `currentSession` synchronously or a cold start flashes signed-out (AUTH-04).
- Three repositories (profile, availability, planned rides) with an *optional* cloud sink — not two parallel implementations. There is no behavioural divergence to justify polymorphism, only an additive step.
- The repository seam retires a real existing bug-risk: `background_task.dart` holds a third independent copy of the SharedPreferences key strings, with a code comment admitting the duplication. The refactor deletes them.
- `PlannedRidesNotifier` needs the most change — it is currently synchronous and reactive to nothing, so today *nothing* would clear it on sign-out or account switch.
- Account deletion is structurally correct rather than procedural: `on delete cascade` from `auth.users`. `feedback` deliberately uses `on delete set null` so anonymised feedback survives.
- First-login migration is one `rpc()` call to a `plpgsql` function — a real transaction, which is what MIG-05/06 were written to demand.

### Critical Pitfalls

Ranked by likelihood × cost:

1. **Every Supabase Google-auth tutorial is `google_sign_in` 6.x; this app is 7.2.0.** Including Supabase's own official reference. The 6.x snippet doesn't compile, and the obvious "fix" would break Calendar.
2. **Sign-in on web cannot use `authenticate()`** — Google's rendered button is mandatory, which partially conflicts with AUTH-02's "style it like the Calendar row". A product decision, not just an implementation detail.
3. **No offline write queue.** Fire-and-forget cloud writes fail silently while the UI shows success. The exact shape of this project's historical silent bugs.
4. **RLS is off by default and the anon key is public.** A table created without it is world-writable. `auth.uid() is not null` is authentication, not authorization.
5. **Both SHA-1 fingerprints, including Play App Signing's.** This project has already shipped a Google integration broken for exactly this reason.
6. **Free-tier projects pause after 7 days of inactivity.** New risk introduced by the switch.

### Expected Features

See `FEATURES.md`. Unchanged by the stack decision — the feature landscape, the second-device recommendation, and the MVP cut are all stack-neutral.

---

## Contradictions Between Research Dimensions

- **AUTH-02 vs Pitfall 2.** The requirement asks for a sign-in row matching the Calendar connection row's visual pattern; on web Google's rendered button constrains styling. Not resolvable in code — it needs a deliberate design decision in Phase 19. Flag to `/gsd:ui-phase`.
- **"Sync on every write" vs SYNC-05.** Architecture §2 makes cloud writes fire-and-forget so the UI never blocks; Pitfalls §6 shows that swallows offline failures. Resolved by the outbox: local write is still unconditional and immediate, but the cloud write is *enqueued* rather than fired into the void.
- **Realtime.** Firestore would have given cross-device push for free; Supabase needs Realtime wired explicitly. SYNC-04 asks only for foreground fetch and REQUIREMENTS.md defers realtime — so this is a non-issue *provided nobody re-adds it as a "small improvement"*.

---

## Implications for Roadmap

The five-phase structure (18–22) is unchanged by the stack switch. What changes is the content of some phases.

### Phase 18: Preconditions
Now: Supabase project in a verified EU region (prefer Frankfurt, Ireland, Paris or Stockholm — London and Zurich are outside the EU), Supabase DPA accepted, **two** sub-processors named in the privacy policy (Supabase *and* Google, which stays for Hosting and Calendar), both SHA-1s in Cloud Console only (no Firebase fingerprint surface), Data Safety declaration, the Auth-cap vs Calendar-cap distinction, a spend/pause decision, and the retention/export answer.

Gone: Firestore region, Firebase DPA, Firebase Console fingerprints.
New: the free-tier pause decision, which is a genuine operational choice and belongs in PRE-01's spend ceiling.

### Phase 19: Auth
Now materially *easier* than the Firebase plan on its hardest point (AUTH-05 reuses the existing init gate) and materially harder on one new point: `lib/services/calendar_service.dart` must now be **modified** to pass `serverClientId`, where the Firebase plan listed it untouched. That puts the change directly on the working "Add to calendar" path — REG-04 becomes a sharper gate, not a formality.

Web sign-in via `renderButton()` is new UI surface with no existing analog in this codebase.

### Phase 20: Repository refactor (local-only)
**Entirely unchanged.** No Supabase, no Firebase, no cloud. This phase's value — retiring the key duplication, making `PlannedRidesNotifier` async and auth-reactive, adding the `updatedAt`/`lastSyncedUid` fields — is stack-independent, which is exactly why it was scoped as a separate phase.

### Phase 21: Sync + migration
Gains the outbox (new work, ~one Drift table plus drain logic). Loses Firestore's multi-tab persistence problem but must still verify SYNC-11 against Drift's own web behaviour from v2.0 Phase 12. Security testing gets easier and stricter — RLS deny cases are plain SQL against the real database, so SYNC-08's "not only the emulator" clause is satisfied by construction. AUTH-09 becomes a schema property rather than a client-side cleanup routine.

### Phase 22: Account-backed feedback
Simpler: one insert-only table, anonymous rows allowed via a nullable `user_id`, and FB-05's "create but not read" is the *absence* of a select policy rather than a rule to write.

### Phase Ordering Rationale
Unchanged and still correct. Preconditions must precede code because two of its decisions are irreversible; the repository refactor must precede sync because syncing three inline SharedPreferences implementations would triple the work; feedback is last because it depends only on auth and nothing depends on it.

---

## Confidence Assessment

| Area | Confidence | Basis |
|---|---|---|
| Codebase integration points | HIGH | Read directly from `lib/`, with line references |
| Package version and publisher | HIGH | Fetched live from pub.dev 2026-07-25 |
| `google_sign_in` 7.x web restriction | HIGH | Plugin API docs + multiple corroborating sources |
| Postgres schema and RLS shapes | HIGH | Standard, well-documented; derived from actual app models |
| Supabase EU regions | HIGH | Official docs |
| Outbox design | MEDIUM | New construction, no reference implementation in this codebase |
| Free-tier pause policy | MEDIUM-HIGH | Consistent across secondary sources; verify in dashboard during Phase 18 |
| Web cold-start impact of `supabase_flutter` | LOW-MEDIUM | Reasoned from dependency size, **not measured**. REG-03 exists to measure it |

### Gaps to Address

1. **Web cold-start is unmeasured.** The claim that Supabase is lighter than Firebase on the web is well-founded but unverified for this app. REG-03 must measure, on a real device over a real connection, before Phase 21 signs off.
2. **Multi-tab outbox behaviour (SYNC-11)** depends on what v2.0 Phase 12 concluded about Drift's web backend. Read that phase's artifacts before designing the drain logic.
3. **Free-tier pause policy** should be confirmed in the Supabase dashboard during Phase 18 rather than trusted from secondary sources.
4. **The `signInWithIdToken` + `google_sign_in` 7.x combination has no first-party documented example.** The API contract of each half is verified; their composition is not. This is the highest-value thing a Phase 19 spike could de-risk cheaply.

---

## Sources

### Primary (HIGH confidence)
- RideWindow codebase, read directly 2026-07-25 — see per-document source lists.
- [pub.dev — supabase_flutter](https://pub.dev/packages/supabase_flutter)
- [Supabase Docs — signInWithIdToken (Dart)](https://supabase.com/docs/reference/dart/auth-signinwithidtoken)
- [Supabase Docs — Regions](https://supabase.com/docs/guides/platform/regions)
- [pub.dev — google_sign_in](https://pub.dev/packages/google_sign_in) / [google_sign_in_web API docs](https://pub.dev/documentation/google_sign_in_web/latest/)

### Secondary (MEDIUM confidence)
- [Supabase blog — Getting started with Flutter authentication](https://supabase.com/blog/flutter-authentication) — 6.x-era API
- Secondary reporting on Supabase free-tier limits and pause behaviour, cross-checked across several sources 2026-07-25

### Superseded
- `.planning/research/archive-firebase/{ARCHITECTURE,PITFALLS,SUMMARY}.md` — the Firebase-based research, retained for the decision trail

---
*Research synthesis for: RideWindow v3.0 Accounts & Sociaal, Phase 1–2 scope*
*Researched: 2026-07-25 — Supabase stack*
