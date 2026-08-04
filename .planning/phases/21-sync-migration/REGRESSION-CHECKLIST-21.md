# Regression Checklist — Phase 21 close-out (single consolidated device session)

This is **one** ordered checklist for **one** device session. It replaces the need to juggle
three separate documents by hand: it reuses Phase 19's exact cold-start method (D-18/D-19,
`.planning/phases/19-auth/REGRESSION-CHECKLIST.md`), folds in Phase 19's own still-outstanding
manual items (plan 19-07 never ran — see `STATE.md`), and folds in plan 21-08's still-outstanding
account-deletion checkpoint (Task 1 shipped and is committed at `139a4f8`; Task 2, the real-device
verification, was never executed).

**Every checkbox below is filled in from an observed result, never assumed.** If a step cannot
be completed, leave it unchecked and write down why next to it in `MANUAL-VERIFICATION-21.md`.

**Automated baseline confirmed before this checklist was written (2026-08-04):**
- `flutter test` (full suite): **418 passed / 0 failed** (run at 07:33 UTC, before the
  documented pre-existing `notification_service_test.dart` "scheduleEveningBefore tijdberekening"
  time-dependency bug's 19:00 UTC trigger window — if a re-run after 19:00 UTC shows exactly
  1 failure in that one test, that is the known pre-existing bug, not a regression; do not
  re-open it).
- `flutter test test/structure/background_task_no_supabase_test.dart` (REG-05): **PASS**.
- `flutter build apk --release`: **exit 0**.
- `flutter build appbundle --release`: **exit 0**.
- Version bumped **1.0.13+14 → 1.0.14+15** (the +14 artifacts predate plan 21-08's commit
  `139a4f8` and are stale; +15 contains everything through 21-08 Task 1 and this plan's Task 1).
  Fresh artifacts: `build/app/outputs/flutter-apk/app-release.apk`,
  `build/app/outputs/bundle/release/app-release.aab`.

---

## 0. Prerequisite — upload before anything else

Everything below that touches sign-in depends on this. Per D-16/AUTH-10, **only the Play App
Signing SHA-1 matches the registered OAuth Android client** — a locally-built/sideloaded APK
cannot complete Google sign-in at all. No build has been uploaded to Play Internal Testing yet,
so this is a hard prerequisite, not an optional nicety.

- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` (version 1.0.14+15) to the
      Play Console's **Internal testing** track.
- [ ] Wait for it to finish processing, then copy the internal-testing opt-in/download link.
- [ ] On the Android test device, install **via that Play Store link** — not the local APK,
      not `adb install`.

## 1. Set up distinguishing local data BEFORE first sign-in (feeds MIG signature proof, section 5)

Do this on the Android device, signed out, before tapping "Inloggen with Google" for the first
time with the test account:

- [ ] In Profile, change at least one weather tolerance value and the display name/theme away
      from its default.
- [ ] In Availability, mark a handful of hours across at least two different days (a mix of
      recurring blocks, not just one cell).
- [ ] (Optional but recommended) Plan at least one ride, so `planned_rides` also has a
      non-empty payload for the migration RPC to carry.

This matters because a `migrate_account_data` signature mismatch is easiest to prove wrong
against real, non-empty, non-default data — an empty/all-default payload could silently
"succeed" against a broken signature by coincidence (e.g. all-null arguments matching a
different overload).

## 2. Android release — Play Store internal testing install (Phase 19 leftover, §1)

Source: install via the Play Store internal testing link only (see §0). Reused verbatim from
`.planning/phases/19-auth/REGRESSION-CHECKLIST.md` §1 — this was never run (plan 19-07 was left
open) and is folded in here rather than left as a separate outstanding item.

- [ ] **Startup** — install via the Play Store internal testing link and open the app. Note:
      loads within a few seconds, no crash or white screen.
- [ ] **Sign in** — tap "Inloggen met Google" in Profile's Account section, complete the Google
      flow. Note: the signed-in view (avatar/name/email) appears with no error.
- [ ] **First-login migration proof (MIG, this plan's highest-value item)** — immediately after
      sign-in completes, watch for at most two sequential conflict dialogs (there should be
      **none**, since this is a genuine first login with no prior cloud row) and watch the sync
      status text under the email. Expect it to settle on "Gesynchroniseerd" within a few
      seconds. Then open the Supabase Dashboard → Table Editor → `profiles` and `availability`
      (and `planned_rides` if you planned a ride in step 1) and confirm rows exist for this
      user containing the exact values you set in section 1 (not defaults).
      - **What a `migrate_account_data` signature failure looks like — read this before
        concluding "sign-in is broken":** Google sign-in itself is a separate, independent flow
        from the migration RPC. A signature mismatch does **not** block sign-in and does **not**
        produce a Google/OAuth-shaped error dialog — the app's own sync code swallows the RPC
        error silently (`try`/`catch` around `_runAccountSync()`, logged via `debugPrint`, never
        shown to the user). The *symptom* is: sign-in succeeds normally, but the sync status
        text stays on "Wordt gesynchroniseerd..." indefinitely (or briefly shows it and never
        reaches "Gesynchroniseerd"), and the `profiles`/`availability`/`planned_rides` tables in
        the dashboard show **no rows** for this user despite real local data existing. If you see
        that combination, do not diagnose it as "Google sign-in is broken" — it is not. Connect
        the device via USB with USB debugging enabled and run
        `adb logcat | grep -i "migrate_account_data\|PostgrestException"` right after signing
        in; a signature mismatch surfaces there as a Postgres error naming
        `migrate_account_data` (e.g. "could not choose a best candidate function" or an
        argument-type/count mismatch), which is the concrete proof of a signature defect, not an
        auth defect.
- [ ] **"Voeg toe aan agenda"** — open a Ride Detail screen and tap "Voeg toe aan agenda". Open
      the real Google Calendar app (or agenda.google.com) and confirm the event exists with the
      correct start/end time and the weather summary in the description.
- [ ] **Sign out** — tap "Uitloggen" in the Account section, confirm the dialog. Note: returns to
      the signed-out view, and the calendar connection (if separately connected) stays intact per
      D-12.
- [ ] **Restart → still signed in** — sign back in, fully kill the app (swipe from recent apps,
      not just backgrounding), reopen it. Note: the Account section shows the signed-in state
      immediately, no flash of "signed out" first (AUTH-04).

## 3. iPhone PWA install + cross-device propagation (Phase 19 leftover §2, folded with SYNC-04)

Source: the live PWA at `https://my-project-joost.web.app`, installed on a real iPhone via
Safari — not desktop browser, not a simulator. Reused from
`.planning/phases/19-auth/REGRESSION-CHECKLIST.md` §2, combined here with SYNC-04's cross-device
check so the same sign-in session proves both at once.

- [ ] **Install** — open the PWA URL in Safari on the iPhone, use "Add to Home Screen". Note: the
      correct app icon appears on the home screen.
- [ ] **Open standalone** — open the app from the home-screen icon. Note: no Safari address bar
      chrome visible (standalone mode), opens on the Home screen.
- [ ] **Navigate** — move between Home, a Ride Detail screen, and Profile. Note: no dead
      navigation ends, back buttons work, no white page on a route change.
- [ ] **Sign in with the SAME account used on Android in section 2** — tap the rendered Google
      button (`renderButton()`, D-05/D-06 — deliberately different look from Android's ListTile)
      in the Account section, complete the flow. Note: signed-in view appears with no error, and
      the values you set in section 1 (which now live in the cloud from section 2's migration)
      appear correctly on this second device — this is the pull side of a normal (non-first-login)
      reconcile.
- [ ] **SYNC-04 — cross-device propagation** — on the Android device (still signed in), make a
      small profile or availability change (e.g. toggle one more availability hour). Background
      the Android app. On the iPhone PWA, bring the app to the foreground (or pull-to-refresh /
      navigate away and back if there is no explicit foreground trigger). Confirm the change made
      on Android appears on the iPhone within a reasonable time.
- [ ] **"Voeg toe aan agenda"** — open a Ride Detail screen and tap "Voeg toe aan agenda". Confirm
      in the real Google Calendar that the event appears.

## 4. Web cold-start measurement (D-19 / REG-03)

This is a **measurement method**, not just a number. Section 3 of
`.planning/phases/19-auth/REGRESSION-CHECKLIST.md` defines the exact method to reuse so the
before/after comparison means something — reproduced verbatim below.

**BLOCKER: Phase 19's own baseline was never actually measured.** Plan 19-07 (the plan meant to
fill in `19-auth/REGRESSION-CHECKLIST.md` §3) was left open — every field in that section is
still an unfilled placeholder (`_(bv. ...)_`), and every checkbox in it is unchecked. There is no
authoritative pre-cloud-reads number to compare today's post-cloud-reads measurement against.
**Do not silently treat this as "no baseline needed" — record today's number anyway (it still
proves REG-03's 2-second budget holds in absolute terms), but note explicitly in
`MANUAL-VERIFICATION-21.md` that no valid before/after comparison exists, and that this gap
traces back to Phase 19's own unclosed plan 19-07.**

- [ ] **Device:** _(e.g. "iPhone 13, iOS 18.x, Safari")_ — record the exact model and browser.
- [ ] **Connection type:** _(e.g. "4G, not throttled" or "Chrome DevTools Fast 3G throttling,
      measured on desktop" — pick one and record which)_.
- [ ] **Measurement method:** time between tapping the PWA icon (or loading the URL in a cold tab
      / after fully closing the app) and the first visible ride slot on the Home screen. Timed
      with a stopwatch or the device's own system clock — not a guess, an actual timing.
- [ ] **Measured value:** _(e.g. "1.4s")_ — record the number and the date/time of measurement.
- [ ] **Measurement conditions:** record anything that could affect the measurement (cold vs warm
      cache, first open after install vs a repeat launch, network conditions at that moment).
- [ ] **Budget check:** if the measured value exceeds 2 seconds, this is a **blocking
      regression** — do not mark Phase 21 complete; report the number back instead of proceeding
      to section 5.

## 5. SYNC-11 — multi-tab safety (deployed PWA, desktop browser)

- [ ] Open `https://my-project-joost.web.app` in two browser tabs, both signed into the same
      account used above.
- [ ] In tab A, edit an availability hour or a profile setting.
- [ ] Foreground tab B (switch to it, or bring it into focus). Confirm tab B picks up tab A's
      change rather than silently overwriting it with stale in-memory state (no data loss, no
      stale overwrite when tab B's own next write happens).

## 6. AUTH-09 — delete-account, verified against the deployed project (plan 21-08 Task 2, folded in)

Plan 21-08's UI (dialog, RPC call, sign-out, snackbar) is built and committed (`139a4f8`), but
its own device+dashboard verification was never run. **Do this last**, since it is destructive
to the test account's cloud data and you will want SYNC-04/SYNC-11/first-login migration proven
first against a still-alive account.

- [ ] On the Android device (or the iPhone PWA — either surface exercises the same RPC), confirm
      you are signed in with the same disposable test account used above, and that it has real,
      non-empty rows in `profiles`/`availability` (and `planned_rides` if you planned a ride) —
      confirm via the sync status text ("Gesynchroniseerd") that everything has reached the
      cloud before proceeding.
- [ ] Tap "Delete account" / "Account verwijderen", confirm the dialog (the single AlertDialog
      with the "this cannot be undone" warning — D-01). Expect: automatic sign-out, "Account
      verwijderd"/"Account deleted" snackbar, landing on the normal signed-out Profile view.
- [ ] Open the Supabase Dashboard → Table Editor. Check `profiles`, `availability`,
      `planned_rides` for that user's rows — expect **zero rows** in all three.
- [ ] Check `feedback` (only if you submitted test feedback under this account) — expect the
      row(s) to survive with `user_id` now `NULL`, not deleted (`on delete set null`).
- [ ] Check Authentication → Users — expect the account no longer listed.
- [ ] Confirm the app's local on-device data (profile settings, availability grid) on the test
      device is untouched and the app is fully usable signed-out (D-03) — this is the one
      guarantee that must never break: deletion only removes server-side rows.

## 7. Record everything

- [ ] Fill in every checkbox above in `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md`
      with the real observed outcome, not an assumption. This file plus that log together form
      the phase's permanent verification record.
