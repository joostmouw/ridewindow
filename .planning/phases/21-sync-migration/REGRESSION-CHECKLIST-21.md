# Regression Checklist — Phase 21 close-out (single consolidated device session)

This is **one** ordered checklist for **one** device session. It replaces the need to juggle
three separate documents by hand: it reuses Phase 19's exact cold-start method (D-18/D-19,
`.planning/phases/19-auth/REGRESSION-CHECKLIST.md`), folds in Phase 19's own still-outstanding
manual items (plan 19-07 never ran — see `STATE.md`), and folds in plan 21-08's still-outstanding
account-deletion checkpoint (Task 1 shipped and is committed at `139a4f8`; Task 2, the real-device
verification, was never executed).

**Every checkbox below is filled in from an observed result, never assumed.** If a step cannot
be completed, leave it unchecked and write down why next to it in `MANUAL-VERIFICATION-21.md`.

---

## PWA-blokkade opgelost — 2026-08-04 14:58

Eerder op 2026-08-04 was deze checklist niet in één keer uitvoerbaar: §3/§4/§5 draaien tegen de
gedeployde PWA, en die serveerde nog `version.json` = 1.0.12+13 met `main.dart.js` Last-Modified
2026-07-26 — de laatste geslaagde deploy voordat `deploy-web.yml` ging falen. Oorzaak: de workflow
verwees naar een repository-secret `FIREBASE_SERVICE_ACCOUNT` dat nooit is aangemaakt.

**Opgelost.** `firebase init hosting:github` maakte service account `github-action-1257243656` met
de Firebase Hosting Admin-rol en zette de key als secret `FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST`;
`deploy-web.yml` wijst nu naar die naam (commit `4e3957e`). Eerste geslaagde run: #3, 3m 8s. Live
geverifieerd:

```
version.json   → {"version":"1.0.15","build_number":"16"}
main.dart.js   → Last-Modified: Tue, 04 Aug 2026 12:57:48 GMT
```

**Gevolg: alle secties zijn nu uitvoerbaar, in één sessie, in de volgorde waarin ze hier staan.**
De eerder genoteerde splitsing in twee sessies is daarmee vervallen. §6 blijft het laatste item —
niet door een blokkade maar omdat het het testaccount vernietigt dat §3/§4/§5 levend nodig hebben.

Gebruik **1.0.15+16** op Android (§0) — precies de build die nu ook als PWA live staat, dus beide
kanten van §3's cross-device check draaien dezelfde code.

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

**Herzien 2026-08-04 11:57 — gebruik +16, niet +15.** Plan 21-10 (outbox drain, gap closure)
landde ná de baseline hierboven, dus ook +15 is inmiddels stale: §5a kan er per definitie niet
tegen slagen. Opnieuw gebouwd op **1.0.15+16** (`versionCode 16`, `versionName 1.0.15` —
geverifieerd met `aapt2 dump badging`), suite **420/420**, `flutter analyze` schoon,
REG-05 groen, beide release builds exit 0. Actuele artefacten:
`build/app/outputs/flutter-apk/app-release.apk`, `build/app/outputs/bundle/release/app-release.aab`.

---

## 0. Prerequisite — upload before anything else

Everything below that touches sign-in depends on this. Per D-16/AUTH-10, **only the Play App
Signing SHA-1 matches the registered OAuth Android client** — a locally-built/sideloaded APK
cannot complete Google sign-in at all. No build has been uploaded to Play Internal Testing yet,
so this is a hard prerequisite, not an optional nicety.

- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` (version **1.0.16+17**, built
      2026-08-04 16:02) to the Play Console's **Internal testing** track.

      > Must be **+17 or later**. Build +16 was tested on device on 2026-08-04 and §5a FAILED on
      > it: the drain was called but threw `Cannot use the Ref of cloudSyncReconcilerProvider
      > after it has been disposed` on every foreground cycle, so nothing ever drained (see
      > plan 21-11). +17 is the first build in which §5a can pass.
      >
      > Historical: build **+16 or later**. The earlier `1.0.14+15` artifact was built at 09:34, before
      > plan 21-10 wired `drain()` to a caller — section 5a below cannot pass against it, and
      > testing it would reproduce this phase's own versionCode false start. Verify the
      > installed build reports 1.0.15+16 before interpreting any behaviour (see section 2).
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

- [ ] **Assert the installed build FIRST — do not skip, do not interpret anything before this.**
      ```
      ~/Library/Android/sdk/platform-tools/adb shell dumpsys package ridewindow.joost.amsterdam | grep version
      ```
      The `versionCode` MUST match the build you just uploaded. On 2026-08-04 a full session was
      spent diagnosing a "broken" sync that was simply an old binary: Play served versionCode 13
      (the 26 July build, no Phase 20/21 code at all) because the device's account was opted into
      the pre-existing **closed test** track and not into internal testing. Every symptom followed
      from that. If the number is wrong, stop and fix the track opt-in — nothing below means
      anything until it matches.
- [ ] **Startup** — install via the Play Store internal testing link and open the app. Note:
      loads within a few seconds, no crash or white screen.
- [ ] **Sign in** — tap "Inloggen met Google" in Profile's Account section, complete the Google
      flow. Note: the signed-in view (avatar/name/email) appears with no error.
- [ ] **First-login migration proof (MIG, this plan's highest-value item)** — immediately after
      sign-in completes, watch for at most two sequential conflict dialogs (there should be
      **none**, since this is a genuine first login with no prior cloud row). Then open the
      Supabase Dashboard → Table Editor → `profiles` and `availability`
      (and `planned_rides` if you planned a ride in step 1) and confirm rows exist for this
      user containing the exact values you set in section 1 (not defaults).
      - **Do NOT use the sync status text as proof — corrected 2026-08-04.** An earlier version
        of this checklist told you to wait for "Gesynchroniseerd". That is invalid: the text is
        driven by `outboxPendingCountProvider`, which counts rows in the local outbox queue, and
        the first-login migration calls the RPC directly without touching the outbox. On a genuine
        first login the queue is therefore empty and the text reads "Gesynchroniseerd" whether the
        RPC succeeded or failed silently. **Rows in the dashboard are the only valid proof.**
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

## 5a. SYNC-05 — outbox drain proof (plan 21-10, gap closure; plan 21-11, disposed-Ref fix)

Do this **before** section 6 (delete-account is destructive to the test account). This section
proves the fix for the defect found on-device 2026-08-04: `SyncOutboxService` was never
constructed and `drain()` was never called anywhere in `lib/`, so every local change made
*after* first-login migration stayed on the device forever (see
`MANUAL-VERIFICATION-21.md`'s "Device session" entry, "SYNC-05 — outbox drain: FAIL"). Plan
21-10 wired `drain()` into `CloudSyncReconciler.reconcileOnForeground()` (foreground trigger)
and into `AccountSection._runAccountSync()` (right after a sign-in's sync decisions settle) —
this section is the only valid proof that either trigger actually reaches the cloud.

A second defect was found on the same device, same session, right after 21-10's build
(1.0.15+16): both triggers threw "Cannot use the Ref of cloudSyncReconcilerProvider after it
has been disposed" every time, silently swallowed by their own try/catch, so the drain still
never ran. Plan 21-11 fixed this (`cloudSyncReconciler`/`syncOutboxService` are now
`@Riverpod(keepAlive: true)`). The logcat evidence line below is what to grep for to confirm
that fix specifically, separate from the dashboard-level proof that the drain happened at all.

- [ ] While still signed in from section 2 (same account, same session — **do not sign out and
      back in**), open Profile and change one setting you have not already changed today (e.g.
      a different weather-tolerance slider value, or toggle one more availability hour).
- [ ] Background the app (send it to the home screen, do not force-kill it) and bring it back to
      the foreground — this fires `CloudSyncReconciler.reconcileOnForeground()`, which now drains
      the outbox as its last step.
- [ ] **Logcat evidence (plan 21-11):** `adb logcat` captured across that background/foreground
      cycle must contain **zero** occurrences of `Cannot use the Ref of
      cloudSyncReconcilerProvider after it has been disposed` — grep for the literal substring
      `cloudSyncReconcilerProvider after it has been disposed`. Any hit means the keepAlive fix
      regressed and the drain below is masked again, exactly as it was on 1.0.15+16.
- [ ] Open the Supabase Dashboard → Table Editor → `profiles` (or `availability`, matching
      whichever field you changed) and confirm the new value is present for this user's row —
      **without ever having signed out and back in**. This is the one thing that could not happen
      before this plan: previously the row would stay frozen at its first-login migration values
      forever.
- [ ] In the app, confirm the Account section's sync status text reads "Gesynchroniseerd" (not
      stuck on "Wordt gesynchroniseerd...") once the row above is visible in the dashboard.
- [ ] (Optional, extra confidence) Repeat the same check for a change made immediately after a
      fresh sign-in (sign out, sign back in, change a setting, then re-open the app) to prove the
      post-sign-in drain trigger in `AccountSection._runAccountSync()` independently of the
      foreground trigger above.

## 6. AUTH-09 — delete-account, verified against the deployed project (plan 21-08 Task 2, folded in)

> **Laatste item, en dat is geen blokkade maar volgorde.** Deze sectie vernietigt het
> wegwerp-testaccount onherroepelijk, en §3/§4/§5 hebben datzelfde account levend nodig. Draai
> §6 dus pas als die drie zijn afgetekend.
>
> Eerder op 2026-08-04 was §6 uitgesteld naar een tweede sessie omdat de PWA stale was; die
> blokkade is om 14:58 opgelost (zie het blok bovenaan dit bestand). Alles kan nu in één sessie.
>
> Gevolg voor de planning: plan **21-08 blijft open** tot deze sectie gedraaid is — dit ís zijn
> taak 2 (`gate="blocking"`).

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
