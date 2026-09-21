# PLAN — stille-takken-sweep (OPEN.md punt 2)

**Datum:** 2026-09-21 · **Volgt uit:** `.planning/debug/consent-card-en-privacy-link.md`
**Doel:** elke knop of actie die zichtbaar niets doet als er iets misgaat, opsporen en dichten.

## Criteria (uit de debugsessie)

1. Navigatie of het sluiten van een venster staat achter een `await` dat kan gooien.
2. Een `if` rond een platform- of netwerk-aanroep zonder `else`.
3. Vraag bij elke match: *wat ziet de gebruiker als dit misgaat?* Antwoord "niets" => fout.

## Wat al schoon is (geverifieerd deze sessie)

- `canLaunchUrl`: geen enkele andere guard in `lib/` (de enige is al gefixt).
- `_openExternal` in Profiel (privacy + weerbron): heeft de vangnet-snackbar.
- `analytics_consent_sheet`: sluit in `finally`.
- `onboarding _handleNext`: navigeert in `finally`.
- `main.dart`: alle awaits in try/catch (`_recordAppOpen`, `_rescheduleNotifications`).
- `invite_landing_screen`: FutureBuilder toont error-state met retry.
- `feedback_dialog`, `account_section._runAccountSync`, `_confirmAndDeleteAccount`,
  `_disconnectCalendar`: volledige try/catch met melding of bewust best-effort.
- `_applyNotificationPlans` (Profiel) en main's reschedule: lege catch is een
  gedocumenteerde keuze ("meldingen mogen nooit de reden zijn dat een schakelaar
  hapert") -- het omschakelen zelf werkt zichtbaar.
- Verborgen debugmenu (5x versienummer): zelfde vorm, bewust gelaten (gedocumenteerd).

## Gevonden stille falers — wordt gefixt

| # | Plek | Wat er stil misgaat |
|---|---|---|
| 1 | `planned_rides_screen.dart` `RideCardHost.respond` (accepteren/afzeggen op ritkaart) | geen catch; netwerkfout = niets gebeurt |
| 2 | idem `chooseOption` | idem |
| 3 | `ride_detail_screen.dart` `_respondToRide` (accepteren/afzeggen in detail) | idem |
| 4 | `invite_buddies_sheet.dart` `showInviteBuddiesSheet` | `friendsProvider.future` en `_pickWindows` staan buiten de try; plus non-exhaustive `switch` op slots-state kan gooien |
| 5 | `buddies_tab.dart` `_shareInvite` | `createFriendInvite`/`Share.share` zonder catch |
| 6 | idem `removeFriend` onRemove | idem |
| 7 | `account_section.dart` `_confirmAndSignOut` | `auth.signOut()` zonder catch |
| 8 | `profile_screen.dart` `_scheduleNotificationsIfPermitted` | POST_NOTIFICATIONS geweigerd: toggle blijft aan, geen melding, niets gepland |
| 9 | `welcome_screen.dart` `_goToSignIn` | `setBool` kan gooien; navigatie nooit bereikt |
| 10 | `availability_screen.dart` onboarding-knop | idem |

## Aanpak

- Nieuwe strings (EN+NL, geen em-dashes): `pelotonOptionChosenFailed`,
  `pelotonRemoveFailed`, `accountSignOutFailed`, `notifPermissionDenied`.
  `pelotonOptionVoteFailed` ("je antwoord kon niet worden opgeslagen") wordt
  hergebruikt voor accepteren/afzeggen: een uitnodiging beantwoorden is ook een antwoord.
- `NotificationService` krijgt `openSystemSettings()`.
- Daarna: `flutter gen-l10n`, gerichte tests, volle suite, `flutter analyze`.
