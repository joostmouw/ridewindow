# SUMMARY — stille-takken-sweep (OPEN.md punt 2)

**Datum:** 2026-09-21 · **Plan:** `PLAN.md`
**Commit:** zie git log · **Suite:** 714 tests groen (4 nieuwe), `flutter analyze` 0 errors / 0 warnings.

## Wat de sweep vond

De vorige sessie (2026-09-19/20) had de drie bekende gevallen gedicht: de
toestemmingskaart, de privacy-link en `_handleNext` in onboarding. Dit is de
brede herhaling over heel `lib/`, met dezelfde vraag bij elke plek: *wat ziet de
gebruiker als dit misgaat?*

**Tien plekken stonden nog stil, zes daarvan zaten in de Peloton-flow** — precies
de flow die nu bij twintig testers op de gesloten test draait:

| # | Plek | Fout (vóór de fix) |
|---|---|---|
| 1 | `planned_rides_screen.dart` `respond()` (accepteren/afzeggen op ritkaart) | netwerkfout = knop doet zichtbaar niets |
| 2 | idem `chooseOption()` | idem |
| 3 | `ride_detail_screen.dart` `_respondToRide()` | idem, op het detailscherm |
| 4 | `invite_buddies_sheet.dart` | `friendsProvider.future` en `_pickWindows` stonden buiten de try/catch; de uitnodigknop deed niets bij een fout |
| 5 | `buddies_tab.dart` `_shareInvite()` | deel-link maken/share faalt stil |
| 6 | idem `removeFriend` | maatje verwijderen faalt stil |
| 7 | `account_section.dart` `_confirmAndSignOut` | `auth.signOut()` faalt stil, gebruiker blijft ingelogd zonder signaal |
| 8 | `profile_screen.dart` `_scheduleNotificationsIfPermitted` | POST_NOTIFICATIONS geweigerd: toggle blijft aan, niets gepland, geen melding |
| 9 | `welcome_screen.dart` `_goToSignIn` | `setBool` kan gooien; navigatie nooit bereikt |
| 10 | `availability_screen.dart` onboarding-knop | idem |

## Hoe elke fix eruitziet

- Netwerk-/platformacties: `try/catch` met een eigen melding (geen hergebruik
  van een melding die naar de verkeerde oorzaak wijst — de les van 2026-09-06).
  `pelotonOptionVoteFailed` ("je antwoord kon niet worden opgeslagen") is met
  opzet hergebruikt voor accepteren/afzeggen: een uitnodiging beantwoorden is
  ook een antwoord.
- Navigatie: verhuisd naar `finally` (`welcome`, `availability`) — dezelfde
  vorm als `_handleNext` in onboarding; een fout wordt wel gemeld via
  `FlutterError.reportError`.
- `_respondToRide` geeft nu `bool` terug, zodat `_withdrawFromRide` en
  `_rejoinRide` hun succesmelding niet meer tonen na een mislukking — dat zou
  een nieuwe leugen zijn geweest ("Je doet niet meer mee" terwijl het antwoord
  niet aankwam).
- Geweigerde notificatiepermissie: snackbar met knop naar de
  systeeminstellingen (`NotificationService.openSystemSettings()` toegevoegd),
  dezelfde vorm als de bestaande exacte-alarmwaarschuwing.

## Nieuwe vertalingen (EN + NL, geen em-dashes)

`pelotonOptionChosenFailed`, `pelotonRemoveFailed`, `accountSignOutFailed`,
`notifPermissionDenied`. `flutter gen-l10n` gedraaid.

## Bewust NIET veranderd

- **Verborgen debugmenu** (5x versienummer in Profiel): dezelfde vorm, maar
  alleen bereikbaar via een debug-route; vorige sessie al bewust gelaten.
- **`_applyNotificationPlans` / main's reschedule**: lege catch is een
  gedocumenteerde keuze ("meldingen mogen nooit de reden zijn dat een
  schakelaar hapert"); het omschakelen zelf werkt zichtbaar.
- **`_disconnectCalendar`**: best-effort met snackbar, al goed.
- **`invite_landing_screen`**: FutureBuilder toont al een error-state met
  retry.
- **`_pickWindows`'s switch**: nagekeken, de sealed `SlotsState` heeft één
  subtype, de switch is exhaustief en kan niet gooien. De oproepende plek is
  wél ingepakt (de sheet zelf kan gooien).

## Bewijs

- 4 nieuwe regressietests die op de oude code falen en op de nieuwe slagen:
  - `peloton_options_test.dart`: mislukt antwoord → snackbar; mislukte stem →
    snackbar; kiezen faalt → foutmelding én géén succesmelding.
  - `profile_account_section_test.dart` Test 13: mislukte afmelding
    (ongeïnitialiseerde Supabase, zelfde truc als Test 12) → `accountSignOutFailed`.
- Volle suite 714/714, `flutter analyze` 0 errors / 0 warnings.

## Openstaand uit de sweep

- **Vervolg-wachtwoord:** de scanpatronen zijn `if (await canLaunchUrl(...))`
  zonder `else`, navigatie/sluiten achter `await`, en netwerk/catchloze
  aanroepen in button-handlers. Bij elke nieuwe wijziging meenemen.
- De notificatie-toggle op **web** staat er niet (bewust); de
  geweigerd-melding geldt alleen waar de schakelaars bestaan (native).
