# OAuth Consent Screen — Fast Publish Checklist (Backlog #31)

## 1. Context

The Google Cloud project `my-project-joost` currently has its OAuth consent screen in **Testing** mode, which caps Google Calendar sign-in to a maximum of 100 manually-added test users. This blocks public launch of the Google Calendar linking feature (CAL-06/07, backlog #31). RideWindow only requests one OAuth scope — `https://www.googleapis.com/auth/calendar.events` (used in `lib/services/calendar_service.dart`) — which Google classifies as a **Sensitive** scope, not **Restricted**. Sensitive scopes do not require Google's formal verification/security-assessment process, so the app can move from Testing to **In production** via the fast "Publish app" route in Cloud Console. This checklist documents the exact manual steps — the actual click can only be performed by Joost in his own authenticated Google Cloud Console session.

## 2. Before you publish — pre-flight check

Confirm each of the following is already filled in on the OAuth consent screen configuration page before clicking Publish:

- [ ] App name is set
- [ ] User support email is set
- [ ] App logo is set (optional but recommended)
- [ ] Application home page URL is set
- [ ] **Privacy policy URL is set to `https://joostmouw.github.io/ridewindow/privacy-policy.html`** — this is a required field; confirm this exact URL is present before publishing
- [ ] Authorized domains include `joostmouw.github.io` (the domain hosting the privacy policy) and any other domains the app uses
- [ ] Scopes list shows only `.../auth/calendar.events` (no other scopes present)

## 3. Step-by-step: Publish app

1. Go to https://console.cloud.google.com/
2. Select project `my-project-joost` from the project switcher (top bar)
3. Navigate: left sidebar hamburger menu → **APIs & Services** → **OAuth consent screen**
4. Confirm "Publishing status" currently shows **Testing**
5. Click the **PUBLISH APP** button
6. A confirmation dialog will appear warning that the app will be available to any user with a Google account, and that apps using sensitive/restricted scopes may require verification. Since RideWindow only uses a Sensitive scope (not Restricted), click **CONFIRM** to proceed — this is expected and safe per the confirmed technical context above.
7. Publishing status should now show **In production**

- [ ] Step 1 — opened Cloud Console
- [ ] Step 2 — selected `my-project-joost`
- [ ] Step 3 — navigated to OAuth consent screen
- [ ] Step 4 — confirmed status was "Testing"
- [ ] Step 5 — clicked "PUBLISH APP"
- [ ] Step 6 — clicked "CONFIRM" on the warning dialog
- [ ] Step 7 — confirmed status now shows "In production"

## 4. What end users will see

When a user first signs in and grants Calendar access after publishing, Google shows a one-time interstitial titled **"Google hasn't verified this app."** The user must click an **"Advanced"** link to reveal a **"Go to RideWindow (unsafe)"** option, and click it to proceed. This appears once per Google account.

**This is EXPECTED and ACCEPTED behavior for the fast-publish route — it is not a defect.** It does not block sign-in; it is simply an extra confirmation click. Full formal Google verification (which would remove this warning entirely) is **not** being pursued — the effort and multi-week timeline tradeoff was judged not worth it for a small personal app.

## 5. After publishing — verification steps

- [ ] OAuth consent screen page shows "In production" status
- [ ] Test sign-in on a Google account that was never added as a test user in Testing mode — sign-in + Calendar authorization should succeed after clicking through the "Google hasn't verified this app" warning
- [ ] Confirm no 100-user cap applies anymore (any Google account can now sign in)

## 6. Rollback note

If ever needed, Google allows returning the app from "In production" back to "Testing" status from the same OAuth consent screen page. This is non-destructive — it does not revoke or affect existing user grants already made while the app was in production.
