# Milestones

## v2.0 iOS Web App (Shipped: 2026-07-17)

**Phases completed:** 7 phases, 11 plans, 25 tasks

**Key accomplishments:**

- Flutter web platform scaffolded via `flutter create --platforms web .`, `workmanager`/`home_widget` call sites in `lib/main.dart` guarded behind `kIsWeb`, CanvasKit web release build and Android release APK both confirmed green — manual browser navigation check (Task 3) still awaiting human verification.
- DriftWebOptions wired into AppDatabase with version-matched sqlite3.wasm (3.3.4) and compiled drift_worker.dart.js committed to web/ — native Android path proven unaffected via successful release APK build. Manual browser persistence verification (Task 3) not yet performed.
- Guarded GpsPermissionNotifier.openSettings() against the web-unsupported openAppSettings() crash and promoted ProfileScreen's manual city picker to a primary, load-bearing CTA when browser geolocation is denied or times out — Task 3's real-browser grant/deny/timeout verification is pending human execution.
- Web tab-resume now triggers a gated `ref.invalidate(weatherProvider)`, the "Last updated" label is always visible when known, and a failed refresh after a prior success now shows stale ride slots with an offline banner instead of a blank screen — Task 3's real-browser verification is pending.
- CalendarService.warmUpForWeb() eagerly and safely warms GoogleSignIn.instance on web (memoized against a real concurrency race found during manual testing), wired via a real Web OAuth Client ID in web/index.html — manually verified end-to-end against a real Google account creating a real Calendar event on http://localhost:5000.
- Flutter web app deployed live to Firebase Hosting at https://my-project-joost.web.app, with the Plan 15-01 OAuth "Add to calendar" flow manually verified end-to-end in a desktop browser and independently confirmed on real iPhone Safari by two separate testers (first-tap success, no retry needed) -- satisfying CAL-07's "not just localhost" and mandatory real-device hard gates.
- Regenerated every Flutter-placeholder PWA icon/splash asset from the real RideWindow logo (with a corrected, properly-centered, alpha-clean crop) and wired manifest.json/index.html with RideWindow branding plus the iOS meta tags (viewport-fit=cover, apple-touch-icon, apple-touch-startup-image x5) needed for a correct Home Screen icon, splash screen, and safe-area detection.
- A testable `isStandaloneDisplayMode`/`isIosBrowserMode` detection seam (conditional-import-based, native-Android-safe) plus a persistent top-of-screen "Add to Home Screen" banner wired into `MaterialApp.router`, satisfying PWA-03 with zero shared_preferences persistence per D-04.
- One shared `SafeBackButton` widget (back-arrow+pop when `Navigator.canPop()`, else home-icon+`go('/home')`) closes a real, already-existing standalone-mode dead end on `AvailabilityScreen`'s onboarding-arrival path, plus two latent cold-launch gaps on `RideDetailScreen` and the invalid-`DetailArgs` error page.
- RideWindow's PWA deploy verified end-to-end on a real iPhone in Safari: branded install icon, standalone-mode launch with correct splash and safe-area, and working in-app back navigation.
- Re-verified firebase.json's SPA rewrite + sqlite3.wasm Content-Type against a real production redeploy (zero config changes needed), corrected the automated-test baseline to 215/69/13-files in STATE.md and BACKLOG.md, and confirmed flutter build apk --release still succeeds after all Phase 11-16 web additions.

---
