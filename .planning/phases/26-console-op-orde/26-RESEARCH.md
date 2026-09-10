# Phase 26: Console op orde - Research

**Researched:** 2026-09-10
**Domain:** Google Play Console operations (testing tracks, tester management, store listing localization) + repo/doc version consistency
**Confidence:** HIGH

## Summary

This phase is almost entirely Google Play Console configuration plus a handful of doc/version-consistency checks — there is no application code to write. Every Console action researched below (promoting a build, opening countries, linking a Google Group, adding a store-listing locale, setting a tester feedback address) is a documented, first-party Play Console feature with a known menu path; none requires a workaround or third-party tool. The one piece of real content work is `docs/testers/changelog.md`, which does not exist yet and needs to be created from scratch, and the store listing needs an nl-NL translation added alongside the already-published en-GB text in `docs/store-listing.md`.

The repo-side half of the phase (CON-06) is largely **already done**, per `STATE.md`'s "Stand na 2026-09-10 avond": `pubspec.yaml` and `lib/core/app_version.dart` both read `1.0.31`/`42` (and a test enforces they stay in sync), the PWA was redeployed and hash-verified at `1.0.31 (42)`, the privacy policy at `docs/privacy-policy.html` already says "Ridewindow", and GitHub `main` is pushed at the same commit. What remains for CON-06 is confirmation/re-verification after build 42 clears Play review, not new work.

**Primary recommendation:** Treat this phase as a checklist-execution phase, not a build phase. Structure plans around the five success criteria directly, sequence Console actions in dependency order (promote → open countries → link Google Group → add feedback address happen in the same "Manage track" flow and can be one task), and make the changelog file and nl-NL store listing addition the only tasks that produce new repo content. Every Console step needs a `checkpoint:human-verify` or is performed by Joost directly — per his own operating preference (`docs/testers/CONSOLE-SETUP-CHECKLIST.md` precedent, and `feedback_uploads_zelf.md`), Claude does not click through Play Console; Claude prepares exact instructions/values and Joost executes, or Claude verifies read-only state via commands like `curl` for the PWA/privacy policy.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Track promotion (internal → closed) | External service (Play Console) | — | Google-owned config; no app code involved |
| Country/region availability | External service (Play Console) | — | Per-track setting in Play Console UI/API only |
| Tester management (Google Group link) | External service (Play Console + Google Groups) | — | Play Console references an externally-created Google Group by email address |
| Tester feedback address | External service (Play Console, per-track "Testers" tab) | Static/Docs (privacy policy) | The address shown to testers is a Console field; it should agree with the address already published in the privacy policy |
| Store listing localization (nl-NL) | External service (Play Console) | Docs (`docs/store-listing.md`) | Play Console is where the translation is entered; the repo doc is the source-of-truth draft that gets copy-pasted in |
| Version/name consistency (PWA, privacy policy, GitHub main) | CDN/Static (Firebase Hosting, GitHub Pages) | Repo (docs, pubspec.yaml) | These are static artifacts whose deployed state must match the repo state already pushed |
| Changelog | Repo (docs) | — | Pure documentation, no runtime component |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CON-01 | Elke build gaat eerst naar internal testing, wordt vanaf een Play-installatie op de Oppo getest, en pas daarna gepromoot naar de gesloten test | Promotion mechanics documented below (Common Pitfalls #1); build 42 already followed this route per STATE.md — the remaining step is verifying the Oppo test happened from a **Play install**, not the current sideload, and confirming 42's closed-test review outcome |
| CON-02 | Een tester in elk land waar Google Play beschikbaar is kan zich aanmelden voor de gesloten test | Countries/regions tab documented below; current state is BE/IT/NL/UK/US only (HANDOFF.json) |
| CON-03 | Een tester ziet in Play een feedback-adres dat bij Ridewindow hoort | Per-track "Testers" tab feedback channel documented below; current state is empty (HANDOFF.json) |
| CON-04 | Een tester meldt zich aan via één vaste link — een Google Group is gekoppeld aan de gesloten test | Google Groups-as-tester-list mechanics documented below; current state is a manual email list with no group (HANDOFF.json) |
| CON-05 | Een bezoeker met Nederlands als Play-taal ziet de winkelpagina in het Nederlands (nl-NL) | "Manage translations" flow documented below; `docs/store-listing.md` already contains ready-to-paste NL and EN copy |
| CON-06 | PWA, gepubliceerd privacybeleid en GitHub `main` tonen dezelfde versie en naam (Ridewindow) als de laatste Play-build | Verified largely already satisfied — see Summary and Common Pitfalls #5 for the residual re-check needed once 42 clears review |
| PROOF-01 | Een changelog per build, vanaf build 41, legt vast: versie, datum, track, inhoud, en welke tester-feedback ermee is opgelost | File does not exist; template and draft content for builds 41/42 provided in Code Examples |

## Project Constraints (from CLAUDE.md)

- **€0/month ceiling from v3.0 onward** — nothing in this phase should introduce a paid Console feature or service. Google Play Console track/testing/translation features used here are all free; no action item should add cost.
- **Android-only for v1** — the store listing and closed test are Android-only; do not extend scope to iOS App Store or Apple Developer account setup.
- **No backend expansion** — this phase touches no `plpgsql` functions, no Edge Functions, no new server-side code. Purely Console configuration and static docs.
- **Privacy** — `docs/privacy-policy.html` already names `joost@fanalists.com` as the contact for account-deletion requests and is the closest thing to an established "belongs to Ridewindow" address in this project. Any Console feedback-address decision in this phase should stay consistent with that existing public commitment rather than introducing a third address.
- **Performance/timeline** — side-project pace; this phase has no code-performance dimension.

## Standard Stack

### Core

No packages are installed or upgraded in this phase — it is Console configuration and Markdown docs. The one existing repo tool relevant to it:

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|---------------|
| `tool/play_upload.dart` (existing, in-repo) | n/a — custom script | Automates upload → track update via Play Developer API | Already built in the prior quick-task (2026-09-08); requires a service-account key that is **not yet configured** (`~/.config/ridewindow/play-service-account.json` does not exist) — see Environment Availability |

**Installation:** N/A — no new packages for this phase.

**Version verification:** N/A — no packages recommended.

## Package Legitimacy Audit

Not applicable — this phase installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```
Joost (build owner)
   │
   ▼
tool/play_upload.dart or manual Console upload
   │
   ▼
[Play Console: Internal testing track]  ← build 42 already here
   │  Joost installs from the Play-served internal link on the Oppo,
   │  tests including the fresh-start intro (CON-01)
   ▼
"Promote release" (Closed testing ▸ Alpha ▸ Manage track ▸ Promote release,
 or create release ▸ Add from library)
   │
   ▼
[Play Console: Closed testing track "Alpha"]
   │
   ├─▶ Countries/regions tab → Select all countries/regions (CON-02)
   ├─▶ Testers tab → Google Groups → group email address (CON-04)
   ├─▶ Testers tab → Feedback channel → email/URL (CON-03)
   └─▶ Store presence ▸ Main store listing ▸ Manage translations → add nl-NL,
       paste copy from docs/store-listing.md (CON-05)
   │
   ▼
Tester opt-in link (one URL, stable as long as the Google Group is linked)
   │
   ▼
New tester anywhere in the world joins the Google Group → opts in via the
link → installs the Play-tested, Play-signed build → sees Ridewindow,
same version, in their own Play-store language if nl-NL/en-GB match theirs
```

Separately, and independent of the Console flow above:

```
Repo (main, pushed) ──┬─▶ Firebase Hosting (PWA) — already redeployed at 1.0.31 (42)
                       ├─▶ GitHub Pages (docs/privacy-policy.html) — already says Ridewindow
                       └─▶ docs/testers/changelog.md — NEW FILE, does not yet exist
```

### Recommended Project Structure

```
docs/
├── store-listing.md          # existing — EN+NL copy ready to paste into Console
├── privacy-policy.html       # existing — already says Ridewindow, no changes expected
├── CONSOLE-SETUP-CHECKLIST.md # existing — accounts/OAuth reference, not testing-track reference; do not conflate
└── testers/
    └── changelog.md          # NEW — one entry per build, starting at 41
```

### Pattern: Console changes needing human execution

**What:** Every Play Console mutation in this phase (promote, countries, testers, translations) is a UI action behind Joost's own Google account. `tool/play_upload.dart` only covers *uploading a bundle to a track*, not promoting between tracks, editing countries, linking a Google Group, or adding a translated listing — those are separate Console screens with no existing script.
**When to use:** For every CON-0X task, write the plan action as "Joost performs X in Console at path Y with value Z" (a `checkpoint:human-verify` style task), not as something Claude executes. Claude's role is preparing exact values (e.g. the finished nl-NL copy, the feedback address to type in) and verifying the *externally-visible* result afterward (e.g. curling the opt-in link, checking the store listing renders in Dutch via `?hl=nl`).
**Example:** For CON-05, the task is not "add Dutch translation" as a code task — it's "hand Joost the exact NL short/full description strings from `docs/store-listing.md` (already written), have him paste them into Store presence ▸ Main store listing ▸ Manage translations ▸ nl-NL, verify by viewing the listing with `&hl=nl` in the Play Store URL."

### Anti-Patterns to Avoid

- **Writing code to "automate" a one-time Console setting.** Country availability, tester Google Group linking, and feedback address are one-time (or rarely-changed) settings. Scripting them via the Play Developer API (which does expose an `edits.tracks` endpoint that could set countries) is disproportionate effort for a solo dev doing this once — use the Console UI directly, matching the "not a coding phase" framing.
- **Re-deriving app-name/version display logic.** `lib/core/app_version.dart` already exists specifically to keep the in-app version single-sourced against `pubspec.yaml`, enforced by `test/core/app_version_test.dart`. Do not add a second version constant anywhere for this phase's checks — read the existing one.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| One stable sign-up link for testers | A custom invite page / shortlink | Play Console's built-in opt-in link, generated once a Google Group (or email list) is attached to the closed-testing track | Native, no maintenance, exactly matches CON-04's "one link" requirement |
| Collecting tester feedback | A custom feedback form/email alias just for this | The existing per-track "Feedback channel" field in the Testers tab, pointed at the address already named in the privacy policy | Testers already see this field on the opt-in page; adding a second channel fragments feedback right before Phase 28 needs to unify it into one register |
| Country-by-country opt-in management | Manually adding country codes as tester requests come in | "Select all countries/regions" (single action, syncs with production by default) | One click covers every current and future country; avoids "app not available in your country" support requests during the werving phase |

**Key insight:** Every mechanism CON-01 through CON-05 need already exists as a first-party Play Console feature. The work in this phase is *configuration*, not construction — resist the urge to add tooling around any of it.

## Common Pitfalls

### Pitfall 1: A build promoted to closed testing doesn't "count" unless promoted, not re-uploaded
**What goes wrong:** Uploading the same AAB separately to the closed track (rather than using "Promote release" / "Add from library" on the exact internal-testing release) can create a build that technically satisfies the store but breaks the "internal-tested-then-promoted" chain of custody CON-01 asks for, and Google's 12-testers/14-days closed-test clock only counts activity on the closed track itself — internal testing contributes nothing toward it.
**Why it happens:** Play Console offers both "Add from library" (reuses the exact tested bundle) and a fresh upload; they look similar in the UI.
**How to avoid:** Always use Closed testing ▸ create release ▸ **Add from library**, selecting the exact bundle already live on internal, never a fresh `flutter build appbundle` re-run for the promotion step.
**Warning signs:** Two different version codes momentarily visible across internal and closed after a "promotion" — a sign a fresh upload happened instead of a promotion.

### Pitfall 2: Managed publishing is off — saves go to review immediately
**What goes wrong:** HANDOFF.json records `"managed_publishing": "uit — opslaan in de listing gaat direct naar review en live"`. Any Console edit (adding nl-NL, changing countries, editing the feedback address) is submitted for review the moment it's saved — there is no draft/staging step to catch mistakes before Google (and testers) see them.
**Why it happens:** Managed publishing is opt-in per app; this app has it off, likely from earlier phases prioritizing fast iteration.
**How to avoid:** Have Joost double-check values (especially the nl-NL copy paste and the feedback address) before clicking Save, since there's no "review before it's live" buffer. Sequence tasks so translation content is finalized in the repo doc first, then pasted once.
**Warning signs:** None visible until the listing/track is already live with the mistake — this is why the plan should front-load "get the text right in the doc" before the Console-paste step.

### Pitfall 3: Country availability syncs with production by default
**What goes wrong:** Play Console notes that track country/region availability is synced with production availability unless explicitly decoupled. Since production doesn't exist yet for this app, this is currently low-risk, but if a future phase edits production countries assuming it's independent of the closed track, it could silently change tester availability too (or vice versa).
**Why it happens:** Google's default behavior links tracks for convenience.
**How to avoid:** When opening all countries for the closed track (CON-02), note in the changelog/handoff that this also sets the baseline for production's eventual country list (relevant to Phase 32).
**Warning signs:** N/A for this phase — flag for Phase 32 planning.

### Pitfall 4: Android developer verification deadline (Sept 30, 2026)
**What goes wrong:** Google requires all Android developers to complete identity verification by **September 30, 2026**, or their apps become uninstallable on certified Android devices — enforcement starts in Brazil, Indonesia, Singapore, and Thailand only, with global rollout in 2027. `HANDOFF.json` already flags this as relevant to Phase 26 because CON-02 opens the closed test to every country. [CITED: android-developers.googleblog.com, June 2026 rollout post; thehackernews.com Sept 30 deadline coverage]
**Why it happens:** New 2026 Google Play policy, independent of this app's own testing-track work.
**How to avoid:** Have Joost check Play Console Home for a verification action item (most apps are auto-registered) before or during this phase — a five-minute check, not a blocker, but worth confirming now rather than discovering it in October when it could affect testers in those four countries.
**Warning signs:** A notification badge/stipje on a Console menu item, as HANDOFF.json already anticipated.

### Pitfall 5: CON-06 is largely already satisfied — don't redo verified work
**What goes wrong:** Re-running the PWA deploy, re-editing the privacy policy, or re-pushing `main` when STATE.md already records all three as done and hash-verified for `1.0.31 (42)` on 2026-09-10 wastes a session re-proving what's already true, and risks introducing a *new* mismatch if the re-deploy happens before build 42's closed-test review completes and something changes.
**Why it happens:** Phase boundaries can make prior-session verification feel untrusted.
**How to avoid:** Treat CON-06 as a **verification task** (curl the PWA, diff `docs/privacy-policy.html` against the live GitHub Pages copy, confirm `main`'s HEAD matches) rather than a **build task**, unless the verification finds an actual mismatch.
**Warning signs:** None — this is a "trust but verify" note for the planner, since the underlying claim (already done) comes from this project's own STATE.md, not external research.

## Code Examples

### Changelog file structure (PROOF-01)

No existing file to follow; propose this format, consistent with the project's existing plain-Markdown doc style (see `docs/store-listing.md`):

```markdown
# Testers changelog — Ridewindow

> Eén item per build vanaf 41. Wordt bijgehouden terwijl builds uitgaan, niet
> achteraf gereconstrueerd (zie `.planning/TESTERS.md`).

## Build 41 — 1.0.30+41

- **Datum:** 2026-09-10 (in de gesloten test)
- **Track:** Closed testing — Alpha
- **Inhoud:**
  - Daglicht telt mee in de score — een uur na zonsondergang scoort niet meer
    als perfect (was: hardgecodeerd venster 06:00–22:00)
  - De vier oordelen krijgen namen: Toprit, Fijne rit, Te doen, Binnenblijver
  - Peloton-introductie bereikt nu wie hem nodig heeft
- **Feedback opgelost:** Ingrid (tester, 2026-09-09) — *"hou je al rekening met
  hoe laat de zon ondergaat?"* → daglicht-scoring toegevoegd. Eerste
  tester-feedback die tot een fix leidde (backlog #68).

## Build 42 — 1.0.31+42

- **Datum:** 2026-09-10
- **Track:** Internal testing (live) → Closed testing — Alpha (in review)
- **Inhoud:**
  - App heet overal Ridewindow (was RideWindow onder het icoon)
  - Openingsanimatie twee keer zo kort: 2,47 s in plaats van 4,94 s
- **Feedback opgelost:** geen — dit was een eigen keuze (merknaam, snellere start)
```

The exact build-41/42 content above is sourced from this repo's own commit history (`3de37e6`, `36b56f0`, `9414a9c`, `a28886f`, `059e352`, `7f29940`) and `docs/store-listing.md`/`TESTERS.md`'s own description of Ingrid's report — [VERIFIED: git log, this repo].

### Verifying deployed version/name consistency (CON-06)

```bash
# PWA — check the deployed manifest and index.html
curl -s https://my-project-joost.web.app/manifest.json | grep -i ridewindow
curl -s https://my-project-joost.web.app/version.json 2>/dev/null  # if Flutter web build emits one

# Privacy policy — confirm the live copy matches the repo file
diff <(curl -s https://joostmouw.github.io/ridewindow/privacy-policy.html) docs/privacy-policy.html

# GitHub main — confirm pushed HEAD matches local
git log origin/main -1 --format=%H
git log main -1 --format=%H
```

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|-------------------|---------------|--------|
| Manually inviting individual testers by email | Linking a Google Group as the tester list | Long-standing Play Console feature, still current in 2026 | One stable opt-in link (CON-04), testers self-manage via group membership without touching Console again |
| Closed test country availability defaulting to a handful of hand-picked countries | "Select all countries/regions" as the explicitly recommended option | Current Play Console guidance | Avoids "not available in your country" errors during global werving (Phase 27/30) |

**Deprecated/outdated:** Nothing found specific to this phase's mechanics — the Console features used here (tracks, Google Groups tester lists, feedback channel, translations) are stable, long-standing Play Console features, not recent additions.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | `joost@fanalists.com` (the address already named in `docs/privacy-policy.html` for account deletion) is an acceptable "belongs to Ridewindow" feedback address for CON-03, rather than requiring a dedicated `*@ridewindow.*` or similar address | Project Constraints, Don't Hand-Roll | Low — worst case Joost prefers a different/new address, which is a five-minute Console edit, not a rework of this research |
| A2 | The closed-testing track in Play Console is literally named "Alpha" (as HANDOFF.json's `closed_testing_alpha` key suggests) rather than a generic "Closed testing" track with no sub-name | Architecture Patterns diagram, Code Examples | Low — cosmetic; doesn't change the mechanics, only the track label used in plan/changelog text |
| A3 | No Play Developer API automation exists for country/translation/tester-group settings beyond the existing `tool/play_upload.dart` (which only covers bundle upload) — confirmed by reading the script's own README, not by testing the API directly | Architecture Patterns anti-patterns | Low — if wrong, it only means an optional automation path exists that this research didn't surface; manual Console configuration remains valid either way |

## Open Questions

1. **Has build 42's closed-testing review completed?**
   - What we know: STATE.md records it "in review sinds ±23:15" on 2026-09-10, the same day as this research.
   - What's unclear: Review outcome — could be approved, rejected, or still pending by the time this phase is planned/executed.
   - Recommendation: First task in the plan should be a status check (read-only, in Console) before any promotion/country/tester work, since CON-01's "promoted after Oppo Play-testing" step depends on 42 being the active closed-test build.

2. **What value should the Testers-tab feedback address actually be?**
   - What we know: HANDOFF.json records it as currently empty; the privacy policy already publishes `joost@fanalists.com`.
   - What's unclear: Whether Joost wants that same address surfaced to testers, or a distinct one (e.g. something that visibly says "Ridewindow" in the local part).
   - Recommendation: Ask Joost directly during planning/discuss rather than assuming — flagged as A1 above.

3. **Is the Google Group for testers already created, or does this phase also need to create it?**
   - What we know: HANDOFF.json records testers currently as "9 adressen in lijst 'First Testers RideWindow', geen Google Group" — no group exists yet.
   - What's unclear: Whether Joost wants the 9 existing addresses migrated into the new group, or the group started fresh.
   - Recommendation: Plan should include "create a Google Group at groups.google.com" as an explicit human step before "link it in Play Console," since the two are separate systems (Google Groups is not part of Play Console).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Play Console access (Joost's Google account) | All CON-0X tasks | Assumed yes — Joost operates this project's Console per prior sessions | — | None needed; this is the primary path |
| `tool/play_upload.dart` + service-account key | Optional automation of the promotion/upload step | ✗ — `~/.config/ridewindow/play-service-account.json` does not exist on this machine | — | Manual Console upload/promotion, which is already Joost's stated preference (`feedback_uploads_zelf.md`) |
| Google Groups (groups.google.com) | CON-04 | Not verifiable from this repo/session — separate Google product | — | None — required for CON-04; no in-Console alternative produces a single stable link without it (an email list also gets an opt-in link, but adding/removing testers then requires touching Console each time) |
| `curl` / network access | CON-06 verification | ✓ (used above) | — | — |

**Missing dependencies with no fallback:** None — every dependency either exists or has a documented, already-preferred fallback (manual Console over the automation script).

**Missing dependencies with fallback:** `tool/play_upload.dart`'s service-account key — fallback is manual upload, which matches Joost's existing workflow preference anyway.

## Sources

### Primary (HIGH confidence)
- [Set up an open, closed, or internal test — Play Console Help](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en) — track setup, promotion, feedback channel mechanics
- [Distribute app releases to specific countries — Play Console Help](https://support.google.com/googleplay/android-developer/answer/7550024?hl=en) — countries/regions tab, "select all," production sync behavior
- [Translate and localize your app — Play Console Help](https://support.google.com/googleplay/android-developer/answer/9844778?hl=en) — "Manage translations" flow for adding nl-NL
- [Understanding Android developer verification — Android Developer Console Help](https://support.google.com/android-developer-console/answer/16561738?hl=en) — verification requirement mechanics
- [Android developer verification — Android Developers Blog, June 2026](https://android-developers.googleblog.com/2026/06/android-developer-verification.html) — Sept 30, 2026 deadline, four-country initial enforcement
- This repo: `.planning/STATE.md`, `.planning/HANDOFF.json`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/TESTERS.md`, `.planning/BACKLOG.md`, `docs/store-listing.md`, `docs/privacy-policy.html`, `docs/CONSOLE-SETUP-CHECKLIST.md`, `tool/README-play-release.md`, `release-notes/{en-US,nl-NL}.txt`, `lib/core/app_version.dart`, `pubspec.yaml`, `web/manifest.json`, git log/history — all read directly in this session

### Secondary (MEDIUM confidence)
- [Google sets timeline for Android developer verification enforcement — Help Net Security, June 2026](https://www.helpnetsecurity.com/2026/06/19/android-developer-verification-rollout-markets/) — corroborates the Sept 30 deadline and four-country scope
- [Google Sets Sept. 30 Deadline for Android Developer Verification in Four Countries — The Hacker News](https://thehackernews.com/2026/06/google-sets-sept-30-deadline-for.html) — corroborates same

### Tertiary (LOW confidence)
- Various 2026 "how-to" blog posts (testerscommunity.com, primetestlab.com, appdadz.com, closedtesthelp.com) surfaced by WebSearch and used only where they matched the official support.google.com pages above — not cited standalone for any claim in this document

## Metadata

**Confidence breakdown:**
- Standard stack: N/A — no packages/stack for this phase
- Architecture (Console mechanics): HIGH — every mechanism cross-checked against official support.google.com pages, several corroborated by 2+ independent sources
- Pitfalls: HIGH for Console-specific pitfalls (sourced from official docs + this repo's own HANDOFF.json); MEDIUM for the developer-verification deadline (dated policy news, corroborated by 3 sources but inherently time-sensitive)
- Changelog content (builds 41/42): HIGH — sourced directly from this repo's own commit history and TESTERS.md, not external research

**Research date:** 2026-09-10
**Valid until:** ~30 days for Console UI mechanics (stable, long-standing features); the developer-verification deadline (Sept 30, 2026) is itself a hard date — re-check Play Console Home for a verification action item at execution time regardless of this document's age
