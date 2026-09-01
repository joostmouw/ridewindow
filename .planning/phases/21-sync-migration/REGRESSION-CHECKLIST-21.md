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

Gebruik **1.0.19+20** op Android (§0) — precies de build die nu ook als PWA live staat, dus beide
kanten van §3's cross-device check draaien dezelfde code. (Deze regel noemde eerder 1.0.15+16;
sinds de deploy van `631ef14` serveert de PWA 1.0.19+20, zie §0.)

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

> **GECORRIGEERD 2026-08-04 — de premisse hieronder was verouderd en heeft deze fase onnodig
> veel Play-uploads gekost.** De oorspronkelijke tekst luidde: "only the Play App Signing SHA-1
> matches the registered OAuth Android client — a locally-built/sideloaded APK cannot complete
> Google sign-in at all." Dat is sinds **2026-07-26** onwaar: er bestaan twéé Android
> OAuth-clients voor `ridewindow.joost.amsterdam` (zie `docs/CONSOLE-SETUP-CHECKLIST.md`
> §"Android clients") — één op de Play App Signing SHA-1 en één op de upload-key SHA-1
> `B6:19:22:8F:…`, en die tweede dekt lokaal gebouwde release-APK's. `flutter build apk
> --release` + installeren logt dus gewoon in met Google. Alleen een *debug*-build kan dat niet.
>
> **Gevolg:** een Play-upload is geen prerequisite voor alles wat inloggen raakt. Hij is alleen
> een echte eis voor §2 zelf (AUTH-10 bewijst juist de Play-App-Signing-route). Al het overige,
> §5a incluis, kan met een lokale release-APK. Let op: sideloaden over een Play-installatie
> vereist wél eerst de-installeren (andere signing key), en dát wist de lokale database.
>
> Op dit toestel is dat op 2026-08-04 ook praktisch bevestigd: een lokaal gebouwde release-APK
> logde probleemloos in met joostmouw@gmail.com.

Everything below that touches sign-in depends on a build being installed. No build has been uploaded to Play Internal Testing yet,
so this is a hard prerequisite, not an optional nicety.

- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` (version **1.0.19+20**) to the
      Play Console's **Internal testing** track.

      > **Herzien 2026-08-04 19:45 — gebruik +20, niet +18.** De samenvoeging van de twee
      > parallelle 21-12-takken (`631ef14`) landde ná de +18-build en bumpte naar 1.0.19+20;
      > de artefacten van 19:06 zijn dus stale. +20 is de eerste build die *beide* takken bevat:
      > main's attempt-plafond én de samenvattingsregel met entiteitsnamen, het debugmenu
      > "Inspect sync outbox" en de versieweergave op het profielscherm. Op +20 is §5a ook
      > daadwerkelijk bewezen (zie hieronder). Verse artefacten gebouwd 2026-08-04 19:45:
      > `build/app/outputs/bundle/release/app-release.aab` (66.2 MB, `versionName 1.0.19`
      > geverifieerd in de AAB-manifest) en `build/app/outputs/flutter-apk/app-release.apk`
      > (68.3 MB). Post-merge baseline op `631ef14`: suite **434/434**, `flutter analyze`
      > 0 errors / 0 warnings, REG-05 groen.
      >
      > De gedeployde PWA staat op dezelfde code: `version.json` = `{"version":"1.0.19",
      > "build_number":"20"}`, `main.dart.js` Last-Modified 2026-08-04 17:44:53 GMT. Beide
      > kanten van §3's cross-device check draaien dus identieke code — controleer dat opnieuw
      > als er nog een commit op main landt vóór de sessie.
      >
      > Must be **+18 or later**. Two earlier builds were tested on device on 2026-08-04 and both
      > failed §5a for different reasons, so neither is usable:
      > - **+16** — the drain was called but threw `Cannot use the Ref of
      >   cloudSyncReconcilerProvider after it has been disposed` on every foreground cycle, so
      >   nothing ever drained (fixed by plan 21-11).
      > - **+17** — the disposed error was gone (verified: `adb logcat | grep -i disposed` empty),
      >   but the availability payload was the bare recurring map, so PostgREST was handed
      >   `"1-9"`/`"6-14"` as column names and that row could never be accepted (fixed by plan
      >   21-12). The status text stayed on "Syncing...".
      >
      > +18 is the first build in which §5a can pass. It also carries the attempt ceiling that
      > clears the row wedged on the device by the two failed rounds above.
      >
      > Historical: build **+16 or later**. The earlier `1.0.14+15` artifact was built at 09:34, before
      > plan 21-10 wired `drain()` to a caller — section 5a below cannot pass against it, and
      > testing it would reproduce this phase's own versionCode false start. Verify the
      > installed build reports 1.0.15+16 before interpreting any behaviour (see section 2).
> **De gewone Play Store-pagina van de app is NIET de route — vastgesteld 2026-08-05 22:32.**
> Joosts account zit in de bestaande **closed test**, en de app-pagina serveert daarom de
> Early-Access-listing ("You've got early access to this app", *Last updated Jul 26, 2026*). Er
> verschijnt dan geen Update-knop, ook niet ná een geforceerde herstart van de Play Store, ook niet
> als de internal-testing-release allang uitgerold is. Dat is geen vertraging en geen cache.
>
> Gebruik altijd de **opt-in-link van de internal test**: Play Console → Testing → Internal testing
> → tabblad **Testers** → **Copy link** (`https://play.google.com/apps/internaltest/...`). Open die
> op het toestel, bevestig deelname, en volg "Download it on Google Play". Zo zijn versies 20 en 21
> er ook op gekomen.
>
> Dit is de derde keer dat de track-keuze tijd kost: op 2026-08-04 serveerde Play versionCode 13
> (de closed-test-build van 26 juli) terwijl er internal-testing-builds klaarstonden, wat ~40
> minuten serverdiagnose opleverde voor een probleem dat geen serverprobleem was.

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

- [x] **Assert the installed build FIRST — do not skip, do not interpret anything before this.**
      *(Afgetekend 2026-08-05: `versionCode=20 versionName=1.0.19`,
      `installerPackageName=com.android.vending`, `firstInstallTime=2026-08-04 19:50:46`.
      Play-installatie bevestigd, geen sideload. Zie MANUAL-VERIFICATION-21.md, device session 4.)*
      ```
      ~/Library/Android/sdk/platform-tools/adb shell dumpsys package ridewindow.joost.amsterdam | grep version
      ```
      The `versionCode` MUST match the build you just uploaded. On 2026-08-04 a full session was
      spent diagnosing a "broken" sync that was simply an old binary: Play served versionCode 13
      (the 26 July build, no Phase 20/21 code at all) because the device's account was opted into
      the pre-existing **closed test** track and not into internal testing. Every symptom followed
      from that. If the number is wrong, stop and fix the track opt-in — nothing below means
      anything until it matches.
- [x] **Startup** — install via the Play Store internal testing link and open the app. Note:
      loads within a few seconds, no crash or white screen.
      *(Afgetekend 2026-08-05: Home rendert "15 ride windows this week", geen crash, geen wit scherm.)*
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
- [x] **"Voeg toe aan agenda"** — open a Ride Detail screen and tap "Voeg toe aan agenda". Open
      the real Google Calendar app (or agenda.google.com) and confirm the event exists with the
      correct start/end time and the weather summary in the description.
      *(Afgetekend 2026-08-05: event staat correct in Google Calendar. Let op de nevenwaarneming —
      één agenda-event tegenover twee ritkaarten in de app, wat bevestigt dat de duplicatie uit
      plan 21-13 pas bij de cloud-reconcile ontstaat en niet bij de tik zelf.)*
- [x] **Sign out** — tap "Uitloggen" in the Account section, confirm the dialog. Note: returns to
      the signed-out view, and the calendar connection (if separately connected) stays intact per
      D-12.
      *(Afgetekend 2026-08-07, gedreven via adb op de PLG110, app 1.0.21+22. Vóór: Account
      `Joost / joostmouw@gmail.com / Synced`, Google Calendar **Connected**. Na uitloggen: Account
      toont "Sign in with Google", en Google Calendar staat onveranderd op **Connected** met een
      actieve "Disconnect"-knop — **D-12 PASS**. Ook naam "Joost", RIDE LENGTH en de
      notificatie-instellingen bleven staan. Opnieuw ingelogd op hetzelfde account: "Synced", geen
      foutmelding, en beide geplande ritten stonden nog op Home. Zie MANUAL-VERIFICATION-21.md,
      device session 6.)*
- [x] **Restart → still signed in** — sign back in, fully kill the app (swipe from recent apps,
      not just backgrounding), reopen it. Note: the Account section shows the signed-in state
      immediately, no flash of "signed out" first (AUTH-04).
      *(Afgetekend 2026-08-05. Koude start bewezen via een nieuw pid in logcat; Account-blok toont
      direct `Joost / joostmouw@gmail.com / Synced`. Er verschijnt wél een "Signing you in."-venster,
      maar dat is Google Play Services' `AssistedSignInActivity` — niet de app die zichzelf uitgelogd
      rendert. Aparte bevinding, backlog #56. Zie MANUAL-VERIFICATION-21.md, device session 4.)*

## 3. PWA install + cross-device propagation (Phase 19 leftover §2, folded with SYNC-04)

> **Herschreven 2026-08-07 — iOS uitgesteld naar v2.** Deze sectie vroeg oorspronkelijk om
> installatie op een echte iPhone via Safari. Joost heeft geen iPhone, en `CLAUDE.md` legt vast dat
> **v1 Android-only** is: geen Apple Developer-account tot Android het concept bewijst. Een
> iOS-installatiecheck toetst dus een platform dat deze release niet uitbrengt.
>
> Wat vervalt: Safari-specifiek installatiegedrag (Add to Home Screen, standalone zonder
> adresbalk, iOS-eigenaardigheden rond service workers). Dat is **niet** afgetekend maar
> **uitgesteld** — het hoort bij de iOS-scope van v2, samen met de rest van het Apple-spoor.
>
> Wat blijft: alles wat de installatieroute toetst die webgebruikers van v1 daadwerkelijk krijgen.
> "Zet op beginscherm" in Chrome op Android bouwt een echte WebAPK, dus installatie, standalone
> modus en navigatie zijn hier volwaardig te toetsen — geen surrogaat maar een andere, even echte
> installatie.

Source: the live PWA at `https://my-project-joost.web.app`, installed on the Android device via
Chrome's "Zet op beginscherm" (which produces a real WebAPK) — not a desktop browser, not an
emulator. Reused from `.planning/phases/19-auth/REGRESSION-CHECKLIST.md` §2, combined here with
SYNC-04's cross-device check.

- [x] **Install** — open the PWA URL in Chrome on Android, use "Zet op beginscherm" / "Installeer
      app". Note: the correct app icon appears on the home screen, distinct from the native app's
      icon if both are installed.
      *(PASS 2026-08-07. Chrome bood "Install and create shortcut" aan — dat verschijnt alleen bij
      een manifest dat de installability-criteria haalt. Resultaat: pakket
      `org.chromium.webapk.a5a380363e216c9c6_v2`, firstInstallTime 12:29:25. Echte WebAPK.)*
- [x] **Open standalone** — open the PWA from its home-screen icon. Note: no Chrome address bar
      visible (standalone mode), opens on the Home screen.
      *(PASS 2026-08-07. Vensterfocus `…webapps.SameTaskWebApkActivity`, niet `ChromeTabbedActivity`
      — een ander venstertype, dus sterker bewijs dan een screenshot.)*
- [x] **Navigate** — move between Home, a Ride Detail screen, and Profile. Note: no dead
      navigation ends, back buttons work, no white page on a route change.
      *(PASS 2026-08-07. Home → Profiel → Home → Ride Detail → terug. Geen dood eind, geen witte
      pagina.)*
- [x] **Sign in with the SAME account used on Android in section 2** — tap the rendered Google
      button (`renderButton()`, D-05/D-06 — deliberately different look from the native app's
      ListTile) in the Account section, complete the flow. Note: signed-in view appears with no
      error, and the values you set in section 1 (which now live in the cloud from section 2's
      migration) appear correctly on this second surface — this is the pull side of a normal
      (non-first-login) reconcile.
      *(PASS 2026-08-07, met kanttekening. `Joost / joostmouw@gmail.com / Synced`; de WebAPK erft
      Chromes opslag voor het domein, dus er was geen nieuwe login nodig. **Maar de PLANNED-lijst
      was bij de eerste start leeg** en vulde zich pas na één achtergrond→voorgrond-cyclus — zie de
      nieuwe bevinding in MANUAL-VERIFICATION-21.md, device session 7. De pull-kant werkt dus, maar
      niet bij het laden.)*
      *(**Kanttekening opgeheven 2026-09-01, device session 9.** Backlog #61 is gefixt en op het
      toestel tegengeproefd op PWA 1.0.23+24: na een echte verse inlog — site-data gewist, dus lege
      lokale opslag — stond de geplande rit meteen in PLANNED, zonder de app weg te zetten. Ook de
      koude start mét geldige sessie haalt nu een cloud-only rit binnen. De pull-kant werkt dus
      **wel** bij het laden.)*
- [x] **Backlog #61 — geplande ritten komen binnen zonder voorgrond-cyclus** — de fix heeft twee
      helften en die zijn apart geproefd (device session 9, 2026-09-01, PWA 1.0.23+24):
      de inlogflow (`account_section.dart:328`) en de koude start
      (`CloudSyncReconciler.reconcileOnStartup()` vanuit `HomeScreen.initState`). Beide **PASS**.
      Negatieve controle op dezelfde telefoon: de native app 1.0.21+22 (vóór de fix), ingelogd met
      dezelfde sessie en dezelfde cloud, toonde bij koude start géén PLANNED en vulde zich pas na
      één achtergrond→voorgrond-cyclus. De proef meet dus de fix en niet iets anders.
- [x] **SYNC-04 — cross-device propagation** — **PASS, 2026-08-07.** The two surfaces are the
      native Android app and the PWA. On the native app (still signed in), change one availability
      hour or plan a ride; background it; bring the PWA to the foreground and confirm the change
      arrives. Observed: after a real tab switch away and back in Chrome on Android, the August
      ride replaced the stale July one. See `MANUAL-VERIFICATION-21.md`, "Web-sessie, vervolg —
      2026-08-07". Note that a *real* foreground transition is required — a simulated activation
      leaves `document.visibilityState` on `hidden` and proves nothing.
- [x] **"Voeg toe aan agenda"** — open a Ride Detail screen in the PWA and tap "Voeg toe aan
      agenda". Confirm in the real Google Calendar that the event appears.
      *(PASS 2026-08-07. Event "Fietsrit 06:00–08:00" staat op zaterdag 8 augustus in de echte
      Google Calendar, naast de "Fietsrit 12:00–15:00" van de eerdere native test.)*

**Uitgesteld naar v2 (niet afgetekend, niet vervallen):** installatie en standalone gedrag van de
PWA op iOS/Safari. Hoort bij de iOS-scope van v2.

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

- [x] **Device:** Oppo Find X9 Pro (PLG110), Android 16, geïnstalleerde PWA (WebAPK
      `org.chromium.webapk.a5a380363e216c9c6_v2`), niet een browsertabblad. **Gemeten 2026-09-01
      18:00-18:20 op 1.0.23+24.**
- [x] **Connection type:** wifi als primaire transport (LTE stond ook verbonden), niet gethrottled.
      Batterij 59%, 36,9 °C.
- [x] **Measurement method:** geautomatiseerd via `adb`. Per run één `screencap` op een exact
      tijdstip na de tik op het lade-icoon; alle tijdstempels in de **device-klok** (`date +%s.%N`
      op het toestel, direct vóór `input tap` en vóór `screencap`), zodat USB-latency wegvalt.
      "Eerste ride slot" is een pixelmeting: het aandeel lichte pixels in de middenzone springt van
      0% naar 84% zodra de eerste ride-kaart staat.
- [x] **Measured value:** **mediaan ≈ 1,75-1,8s.** Verdeling over 36 starts: 0/6 op 1,52s,
      3/6 op 1,77s, 5/6 op 1,93s, 9/12 op 2,03s, 6/6 op 2,28s. Nooit vóór 1,55s, altijd binnen 2,3s.
- [x] **Measurement conditions:** terugkerende start — service worker warm, lokale opslag gevuld.
      Per run `am force-stop` op zowel de WebAPK als `com.android.chrome` (de WebAPK draait in
      Chrome's proces). Gestart vanuit de app-lade; het icoon staat niet op pagina 1 van het
      beginscherm. De eerste start ná installatie (lege lokale opslag) is stap 1b, niet dit.
- [x] **Budget check:** **PASS met een genoteerde staart.** De typische start haalt de 2 seconden,
      maar in ~1 op de 4 starts is het slot op 2,0s nog niet zichtbaar. Wie die staart blokkerend
      wil noemen heeft een verdedigbaar punt — dat is een keuze, geen meetfout, en daarom staat het
      getal er in plaats van een kaal vinkje. Zie `MANUAL-VERIFICATION-21.md`, device session 8,
      inclusief twee meetvallen die stil een veel te mooi getal hadden opgeleverd.

## 5. SYNC-11 — multi-tab safety (deployed PWA, desktop browser)

- [x] Open `https://my-project-joost.web.app` in two browser tabs, both signed into the same
      account used above.
- [x] In tab A, edit an availability hour or a profile setting. **Done 2026-08-07:** a ride was
      planned for Saturday 07:00–09:00 from a second tab.
- [x] Foreground tab B (switch to it, or bring it into focus). Confirm tab B picks up tab A's
      change rather than silently overwriting it with stale in-memory state (no data loss, no
      stale overwrite when tab B's own next write happens). **PASS 2026-08-07:** tab B showed
      **both** rides (07:00–09:00 and 12:00–15:00) — the new one arrived and the existing one was
      not replaced. See `MANUAL-VERIFICATION-21.md`, "Web-sessie, vervolg — 2026-08-07", including
      the note on what this observation does *not* separately prove about the overwrite direction.

## 5a. SYNC-05 — outbox drain proof (plan 21-10, gap closure; plan 21-11, disposed-Ref fix; plan 21-12, availability payload-shape fix)

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

A third defect was found on the same 2026-08-04 device session, after the disposed-Ref fix
made the drain actually run: `AvailabilityRepository` enqueued the bare
`toRecurringRow(hours)` map (e.g. `{"1-9":"work","6-14":"custom"}`) instead of a real
`public.availability` row, so PostgREST received weekday-hour strings as **column names** —
a write that could never succeed under any network condition. `profiles`/`planned_rides` were
already correct, which is why a profile change appeared to sync while the account row stayed
stuck on "Wordt gesynchroniseerd..." forever. Plan 21-12 fixed the payload shape
(`{'user_id': userId, 'recurring': toRecurringRow(hours)}`), added a `debugPrint` on every
failed send (previously silent), and dropped rows that fail 5 times in a row so a
pre-existing wedged row cannot block the account forever.

> **UITGEVOERD EN GESLAAGD — 2026-08-04, twee onafhankelijke metingen op 1.0.18+19 en
> 1.0.19+20.** Het volledige bewijs staat in `MANUAL-VERIFICATION-21.md`, secties "Device
> session 3" en "Tweede, onafhankelijke SYNC-05-meting". Kort: een beschikbaarheidsuur is in
> twee tegengestelde richtingen gewijzigd (Free→Busy, daarna Busy→Free), elke keer bevestigd
> met zowel een logcat-regel (`drain done — 2 pending, 2 sent (availability, profile),
> 0 failed`) als een `availability.updated_at` in Postgres die naar exact het drainmoment
> sprong. De keten toestel → outbox → drain → PostgREST → Postgres is daarmee sluitend.
>
> Let op de correctie die in dat verslag staat: de éérste poging kreeg ten onrechte een PASS
> op grond van alleen een logregel `1 sent`, terwijl `availability.updated_at` aantoonbaar
> onaangeroerd bleef — die send was een `profile`-rij. Eén logregel is dus géén bewijs; de
> dashboardtijdstempel is dat wel. Daarom staan de entiteitsnamen nu in de samenvattingsregel.
>
> Eén vinkje hieronder blijft bewust open: de statustekst "Gesynchroniseerd" is niet
> vastgelegd in het verslag. De drain meldde `0 failed`, dus de teller hoort op nul te staan,
> maar dat is afgeleid en niet waargenomen — controleer het in de eerstvolgende sessie.

- [x] **Availability specifically (plan 21-12):** while still signed in, open Availability and
      block or unblock at least one hour. Background/foreground the app (or wait for the next
      foreground cycle) to trigger the drain, then open the Supabase Dashboard → Table Editor →
      `availability` and confirm `recurring` for this user's row now reflects the change — this
      is the exact write path that could never succeed before 21-12.
- [ ] **Wedged row clears (plan 21-12):** the availability row enqueued in the broken shape
      during the 2026-08-04 morning session (120 hour blocks) must stop blocking the account —
      within a few foreground cycles after installing a build containing this plan, the
      Account section's sync status text must settle on "Gesynchroniseerd", not stay stuck on
      "Wordt gesynchroniseerd...". If it does not clear within 5 foreground cycles, check
      logcat for a `SyncOutboxService: dropping availability/...` line (the attempt-ceiling
      drop) rather than assuming the fix regressed — a dropped row is expected to be replaced
      by the fresh write from the bullet above, not retried in its old broken shape.
- [x] While still signed in from section 2 (same account, same session — **do not sign out and
      back in**), open Profile and change one setting you have not already changed today (e.g.
      a different weather-tolerance slider value, or toggle one more availability hour).
- [x] Background the app (send it to the home screen, do not force-kill it) and bring it back to
      the foreground — this fires `CloudSyncReconciler.reconcileOnForeground()`, which now drains
      the outbox as its last step.
- [x] **Logcat evidence (plan 21-11):** `adb logcat` captured across that background/foreground
      cycle must contain **zero** occurrences of `Cannot use the Ref of
      cloudSyncReconcilerProvider after it has been disposed` — grep for the literal substring
      `cloudSyncReconcilerProvider after it has been disposed`. Any hit means the keepAlive fix
      regressed and the drain below is masked again, exactly as it was on 1.0.15+16.
- [x] Open the Supabase Dashboard → Table Editor → `profiles` (or `availability`, matching
      whichever field you changed) and confirm the new value is present for this user's row —
      **without ever having signed out and back in**. This is the one thing that could not happen
      before this plan: previously the row would stay frozen at its first-login migration values
      forever.
- [x] In the app, confirm the Account section's sync status text reads "Gesynchroniseerd" (not
      stuck on "Wordt gesynchroniseerd...") once the row above is visible in the dashboard.
      *(Afgetekend 2026-08-05 — waargenomen, niet meer afgeleid: het Account-blok leest "Synced".
      Dit was het laatste open vinkje van §5a.)*
- [ ] (Optional, extra confidence) Repeat the same check for a change made immediately after a
      fresh sign-in (sign out, sign back in, change a setting, then re-open the app) to prove the
      post-sign-in drain trigger in `AccountSection._runAccountSync()` independently of the
      foreground trigger above.

## 5b. SYNC-03 — één geplande rit blijft één rit (plan 21-13)

Gevonden op toestel 2026-08-05: één tik op "Schedule" leverde twee identieke kaarten in
"My Rides" (Saturday 8 Aug, 12:00–15:00, 100 Perfect, tweemaal). `rideId` werd afgeleid uit de
lokale ISO-string, en alles wat door de `timestamptz`-kolom gaat komt als UTC terug — twee
sleutels voor dezelfde rit, dus de union-merge hield ze allebei.

> **Lees dit vóór je oordeelt.** De duplicaten zijn echte data, lokaal én in
> `public.planned_rides`, en er zit een tweede fout onder: rijen van vóór 21-13 zijn opgeslagen
> met een tijdstip dat de lokale offset verschoven is (een offsetloze string werd door Postgres
> in de sessiezone gelezen). Een build die alleen stopt met nieuwe duplicaten maken, toont dus
> nog steeds twee kaarten tot de reparatie heeft gedraaid. **Beoordeel op convergentie na een
> foreground-cyclus, niet op het eerste scherm na installatie.**

- [x] Open "My Rides" direct na installatie. Noteer wat je ziet — één of twee kaarten voor de
      Saturday 8 Aug-rit. Eén kaart mag al meteen: `readLocal()` klapt lokale duplicaten samen
      zonder netwerk.
      *(Afgetekend 2026-08-05, sessie 5: verse installatie, alles uit de cloud gehaald, twee
      ritten in PLANNED en geen enkele duplicaat. Sterkere vorm dan hier gevraagd — er was geen
      lokale staat die het resultaat kon maskeren.)*
- [ ] Breng de app naar de achtergrond en weer naar de voorgrond (dat draait de reconcile), en
      controleer in `adb logcat` op de regel
      `CloudSyncReconciler: herstelde planned_rides-sleutel ... -> ...` of
      `... niet canoniek, rij verwijderd`. Die regel is het bewijs dat de reparatie gelopen heeft.
- [x] Open de Supabase Dashboard → Table Editor → `planned_rides` en bevestig dat er voor deze
      gebruiker **precies één** rij voor die rit staat, met een `ride_id` dat op `Z` eindigt.
      *(Afgetekend 2026-08-06 via SQL Editor: één rij, `ride_id = 2026-08-08T10-00-00-000Z`.)*
- [x] Controleer dat `start_at` het júiste tijdstip bevat: voor een rit van 12:00 lokale tijd in
      de zomer moet daar 10:00 UTC staan, niet 12:00 UTC. Stond er 12:00, dan is de verschoven
      waarde blijven staan en is de reparatie niet gelopen.
      *(Afgetekend 2026-08-06: `start_at = 2026-08-08 10:00:00+00`, `end_at = 13:00:00+00` —
      exact 12:00-15:00 lokale tijd. Sleutel én tijdstip kloppen dus allebei.)*
- [ ] Plan een verse rit, background/foreground de app drie keer, en bevestig dat er nooit een
      tweede kaart bijkomt.
- [ ] Let in logcat op `planned_rides-rij ... verwijderd ZONDER lokale tegenhanger`. Die regel
      hoort er niet te staan; verschijnt hij toch, noteer de gelogde inhoud — dat is een rit die
      alleen in de cloud stond en niet te herstellen was.

## 5c. SYNC-03 — een verwijderde rit blijft verwijderd (plan 21-14)

Gevonden 2026-08-05 bij het opruimen van de duplicaten uit §5b: handmatig verwijderde ritten
kwamen bij elke sync terug. `reconcileOnForeground()` las de cloud vóór het de outbox leegde, dus
de union-merge zette een zojuist verwijderde rit terug voordat de delete ooit verstuurd was.
Verwijderen wérkte daardoor helemaal niet zolang je ingelogd was.

- [ ] Verwijder een geplande rit met het prullenbak-icoon. De kaart verdwijnt meteen.
- [ ] Achtergrond/voorgrond de app **drie keer**. De rit mag niet terugkomen.
- [ ] Supabase Dashboard → `planned_rides`: de rij is weg en blijft weg.
- [ ] In `adb logcat` hoort de drain-regel vóór eventuele reconcile-activiteit te komen. Een
      `drain done — ... sent (planned_ride...)` direct na een voorgrondcyclus is het teken dat de
      delete daadwerkelijk vertrokken is.

> **Gebruik dit meteen om de spookritten van §5b op te ruimen.** Saturday 14:00–17:00 en
> Sunday 10:00–12:00 zijn kopieën met een verschoven tijdstip. Ze zijn intern consistent — de
> sleutel klopt bij hun eigen `start_at` — dus 21-13's herstelroutine herkent ze niet als kapot,
> en er bestaat geen heuristiek die ze van een echt geplande rit onderscheidt. Handmatig
> verwijderen is de juiste route, en dankzij 21-14 blijft dat nu ook zitten.

## 6. AUTH-09 — delete-account, verified against the deployed project (plan 21-08 Task 2, folded in)

> **Laatste item, en dat is geen blokkade maar volgorde.** Deze sectie vernietigt het
> testaccount onherroepelijk, en §3/§4/§5 hebben datzelfde account levend nodig. Draai
> §6 dus pas als die drie zijn afgetekend.
>
> **Accountkeuze, bevestigd door Joost op 2026-08-04: dit gebeurt met `joostmouw@gmail.com`,
> zijn eigen account — niet met een wegwerpaccount.** De checklist schreef oorspronkelijk een
> disposable account voor; die eis is hier bewust losgelaten. Wat dat betekent: na §6 zijn de
> cloud-rijen van dit account weg en verdwijnt de `auth.users`-rij. De lokale data op het
> toestel blijft onaangeroerd (D-03 — dat is juist wat §6 moet bewijzen), dus de eerstvolgende
> login migreert diezelfde data gewoon opnieuw omhoog. Er gaat niets blijvend verloren; reken
> alleen op een extra migratieronde na afloop.
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

- [ ] On the Android device (or the installed PWA — either surface exercises the same RPC), confirm
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
