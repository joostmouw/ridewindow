# Phase 21: Sync + migration - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning

<domain>
## Phase Boundary

A signed-in user's profile, availability, and planned rides sync to Postgres (Supabase) and stay consistent across Android and web. First-login and second-device migration resolve to a defined, tested behavior instead of an accident. One user's data is provably unreadable by another (RLS). A signed-in user can delete their account, which removes their server-side data. This phase turns `.planning/research/ARCHITECTURE.md` — already a complete technical design (schema, RLS, outbox, conflict resolver, build order) — into shipped code. Discussion here deliberately did not re-litigate that document; it captured the three genuine UX/product decisions the architecture research left open.

</domain>

<decisions>
## Implementation Decisions

### Account deletion (AUTH-09)
- **D-01:** Confirmation is a single `AlertDialog` with explicit "this cannot be undone" warning text and two buttons (Cancel / Delete) — same visual pattern as the existing account-switch dialog in `account_section.dart:194`. No type-to-confirm text field, no re-authentication step. Rationale: small tester group, the warning text itself carries the weight, and re-auth would be materially more build effort for a hobby app's scale.
- **D-02:** On confirmed server-side deletion, the app signs out automatically (same effect as the existing sign-out path) and shows a short snackbar/toast ("Account verwijderd"). No dedicated confirmation screen — the user lands on the normal signed-out UI.
- **D-03:** Deletion does **not** clear local on-device data (profile, availability, planned rides stay exactly as they are). Only the server rows are removed. This matches the existing "accounts are additive" principle (PROJECT.md / CLAUDE.md) — the app must keep working fully locally after sign-out, and deletion is a server-only action, not a local reset. Explicitly **not** the same behavior as the existing "start fresh" branch of the account-switch dialog (`account_section.dart` `differentAccount` case) — that clears local data for a different reason (a new account arriving on the device) and must not be reused or confused with this flow.

### Conflict-dialog UX (MIG-03)
- **D-04:** When `resolveAccountSync` (ARCHITECTURE.md §5) returns `promptUser` for a domain, show a simple two-button `AlertDialog` ("Dit toestel" / "Cloud"/"Ander toestel") with no diff preview and no timestamp summary — same minimal-dialog philosophy as D-01. This is a rare path (most sign-ins resolve via MIG-01 empty-account or MIG-02 different-account, neither of which prompts), so it does not warrant a richer UI investment.
- **D-05:** Profile and availability conflicts are resolved independently (already true in ARCHITECTURE.md §5 — `resolveAccountSync` runs per domain) and, if both conflict at the same sign-in, are presented as **two sequential dialogs**, not one combined screen — profile first, then availability. Simpler to build, each dialog stays single-purpose.

### Sync status indicator (SYNC-06)
- **D-06:** Sync status is a small text line inside the existing account section (e.g. "Gesynchroniseerd" / "Wordt gesynchroniseerd...") — not a separate icon/badge, not a dedicated screen, not "only show on error". The account section is already where the user looks for sign-in state, so this reuses an existing attention point rather than adding a new one.
- **D-07:** Exactly two visible states — synced / pending — matching the outbox's deliberately simple retry design in ARCHITECTURE.md §4a (no backoff schedule, no permanent-failure bookkeeping this milestone). No third "sync failed" status. If a write keeps failing, it stays visually "pending" — surfacing failure state explicitly is out of scope for this phase, consistent with the architecture research's own scope fence.

### Claude's Discretion
- Exact snackbar copy, dialog button label wording, and destructive-button styling (e.g. red delete button) — standard Material 3 conventions apply, no specific wording was mandated.
- Everything already fixed in ARCHITECTURE.md §1–7 (schema, RLS policy shape, outbox mechanics, `resolveAccountSync` logic, provider wiring, build order) is locked technical design, not open for re-decision during planning — the planner should treat that document as the primary technical source of truth for phase 21, not re-derive it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Technical design (primary source of truth for this phase)
- `.planning/research/ARCHITECTURE.md` — complete design: §1 auth state provider, §2 repository seam (extends the plain-Dart repositories shipped in Phase 20 with an optional cloud sink), §3 Postgres schema + RLS, §4 sync trigger points, §4a the offline outbox, §5 migration/conflict resolver (`resolveAccountSync`), §6 explicit new/modified file list, §7 suggested build order

### Prior phase decisions this phase depends on
- `.planning/phases/18-preconditions/18-CONTEXT.md` — D-07 (Supabase project provisioned, `eu-west-3` Paris), D-16 (account deletion via `on delete cascade` from `auth.users` — the mechanism D-01/D-02 above build UI around), D-15 (two-sub-processor privacy policy already covers this phase's data flows, no policy change needed here)
- `.planning/phases/19-auth/19-CONTEXT.md` — existing auth UI patterns (`account_section.dart`), the already-shipped `account_switch_resolver.dart` (the local-only, scaled-down half of what ARCHITECTURE.md §5 calls the full `resolveAccountSync` — this phase builds the cloud-aware full version, does not replace the existing one)
- `.planning/phases/20-repository-refactor-local-only/20-01-SUMMARY.md`, `20-02-SUMMARY.md`, `20-03-SUMMARY.md` — the plain-Dart repository pattern (`AvailabilityRepository`, `ProfileRepository`, `PlannedRidesRepository`) this phase's cloud sink extends, per ARCHITECTURE.md §2

### Requirements
- `.planning/REQUIREMENTS.md` — SYNC-01 through SYNC-12, MIG-01 through MIG-08, AUTH-09, REG-03 (all mapped to this phase per ROADMAP.md)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/features/profile/account_section.dart:194-210` — existing `AlertDialog` two-button pattern for the account-switch conflict, directly reusable as the visual template for D-01 (deletion confirm) and D-04 (sync conflict prompt)
- `lib/domain/services/account_switch_resolver.dart` — pure, SDK-free resolver already shipped in Phase 19 for the local-only half of account-switch detection; ARCHITECTURE.md §5's `resolveAccountSync` is the cloud-aware superset this phase adds, not a replacement
- `lib/data/repositories/{profile,availability,planned_rides}_repository.dart` — plain-Dart repositories from Phase 20, ready to receive an optional `SupabaseClient? cloud` constructor parameter per ARCHITECTURE.md §2

### Established Patterns
- Repository pattern: constructor-injected `SharedPreferences`, public key constants, `save(..., {bool stamp = true})`, `readUpdatedAt()` returning null when absent — set by Phase 20, must be followed for the cloud-sink extension, not reinvented
- Pure resolver functions with no SDK dependency (`availability_key.dart`, `account_switch_resolver.dart`) — the convention `resolveAccountSync` and any new pure logic in this phase should follow

### Integration Points
- `lib/features/profile/account_section.dart` — where D-01 (delete button + dialog), D-04/D-05 (conflict dialogs, triggered from the sign-in flow already in this file), and D-06/D-07 (sync status text) all land
- `lib/main.dart` — `Supabase.initialize()` addition point per ARCHITECTURE.md §6

</code_context>

<specifics>
## Specific Ideas

No UI mockups or specific visual references were given beyond "reuse the existing dialog pattern" (D-01, D-04) — the user confirmed Claude's recommended options at every decision point in this discussion rather than describing a different vision.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. The outbox's lack of a permanent-failure UI (D-07) and the deletion flow's lack of type-to-confirm/re-auth (D-01) were both considered and explicitly declined for this milestone, not deferred as future work items — if they're wanted later, that's a product decision for a future milestone, not a known-pending todo.

</deferred>

---

*Phase: 21-sync-migration*
*Context gathered: 2026-08-03*
