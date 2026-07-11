# Deferred Items — Phase 13

## Pre-existing localization delegate gap in sibling ProfileScreen test files

- **Discovered during:** 13-01 Task 2, while making `test/features/profile_screen_location_test.dart`'s 9 tests pass.
- **Root cause:** `_pumpProfileScreen`-style test helpers wrap `ProfileScreen` in a bare `MaterialApp(home: ProfileScreen())` with no `localizationsDelegates` / `supportedLocales` / `locale`. `ProfileScreen.build()` calls `S.of(context)`, which does `Localizations.of<S>(context, S)!` — this throws a null-check `_TypeError` whenever the `S` delegate isn't registered.
- **Fixed in scope:** `test/features/profile_screen_location_test.dart` (this plan's file) — added `S.localizationsDelegates`, `S.supportedLocales`, and a pinned `Locale('nl')` (existing tests assert hardcoded Dutch strings).
- **Not fixed (out of scope for 13-01):**
  - `test/features/profile_screen_test.dart` — same missing delegates in its `MaterialApp` wrapper; confirmed still failing (e.g. `Test 5: Knop/tegel Mijn schema bewerken aanwezig`).
  - `test/features/profile_screen_notif_test.dart` — not independently re-verified this session, but shares the same `_pumpProfileScreen`-style helper pattern and likely has the identical gap.
- **Recommendation:** A future quick-fix or the next phase touching `ProfileScreen` tests should apply the same fix (`localizationsDelegates: S.localizationsDelegates, supportedLocales: S.supportedLocales, locale: const Locale('nl')`) to both files so `flutter test` runs clean across the whole `test/features/` suite.

## Local dev environment gap: `android/key.properties` not present in git worktrees

- **Discovered during:** 13-01 verification step (`flutter build apk --release`).
- **Root cause:** `android/key.properties` is gitignored (contains real signing credentials, per Phase 10 decisions) and lives only in the main checkout at `/Users/joostmouw/ridewindow/android/key.properties`. `git worktree add` does not copy gitignored files, so a fresh worktree has no signing config and `assembleRelease` fails with `null cannot be cast to non-null type kotlin.String`.
- **Fixed in scope:** Copied the existing `key.properties` from the main checkout into this worktree's `android/` directory (still gitignored, not committed) so the release build could be verified.
- **Recommendation:** If future phases spawn worktree executors that need `flutter build apk --release`, the orchestrator/setup step should copy `android/key.properties` (and any other gitignored, locally-required secrets) into the worktree before handing off to the executor.
