# PLAN — lokale login: Ridewindow-account zonder Gmail (OPEN.md punt 11)

**Datum:** 2026-09-21
**Doel:** naast "Inloggen met Google" een e-mail + wachtwoord-login, zodat een
gebruiker een account kan aanmaken en inloggen zonder Google- of Gmail-account.

## Beslissingen van Joost (2026-09-21)

1. **Type:** e-mail + wachtwoord via Supabase — geen lokaal-op-toestel-account.
   Sync, maatjes en alles wat nu op het Supabase-account draait werken mee.
2. **Bevestiging:** aan (huidige instelling) — een nieuw account moet eerst de
   bevestigingsmail aanklikken voordat inloggen werkt.
3. **Plek:** in Profiel, als tweede optie naast "Inloggen met Google".

## Wat al vaststaat (geverifieerd via de auth-settings-API)

- Supabase: `email: true`, `google: true`, `disable_signup: false`,
  `mailer_autoconfirm: false` (bevestiging dus vereist).
- De app heeft geen e-mail-login-UI en geen diep-link-afhandeling; dat laatste
  is geen blokkade: de bevestigingslink opent in de browser, waarna de gebruiker
  terugkomt en inlogt. (Een diep-link naar de app is later mooi, niet nodig.)

## Wat er gebouwd wordt

### AccountSection (lib/features/profile/account_section.dart)

- De uitgelogde rij krijgt een tweede ListTile: "Inloggen met e-mail" (met het
  bestaande `AppIcons.lock`), onder "Inloggen met Google", op zowel native als web.
- Tikken opent een dialoog met twee modi: **inloggen** en **account aanmaken**,
  te wisselen met een tekstknop. Velden: e-mailadres + wachtwoord (verborgen).
- Inloggen: `auth.signInWithPassword(email, password)`. Account aanmaken:
  `auth.signUp(email, password)` — bij `mailer_autoconfirm: false` krijgt de
  gebruiker een melding dat de bevestigingsmail onderweg is, en geen session
  (inloggen kan pas na bevestiging).
- Foutmeldingen in de dialoog ("stille takken" is hier niet genoeg: een
  netwerkfout moet zichtbaar zijn). Onderscheid:
  - combinatie ongeldig → bestaande `accountSignInError`;
  - e-mail nog niet bevestigd → eigen tekst;
  - account bestaat al → eigen tekst;
  - overige fouten → eigen, algemene tekst.
- Na succes: precies dezelfde afronding als Google
  (`_checkAccountSwitch` → accountwissel-check, sync, naam-invulstap blijft
  leeg — D-04 vult alleen in als het veld nog leeg is; een e-mailaccount heeft
  geen afbeeldings-URL, dus de avatar valt terug op het generieke icoon, dat
  al werkt).

### Strings (EN + NL, geen em-dashes)

`signInWithEmail`, `emailSignInTitle`, `emailCreateTitle`,
`emailFieldLabel`, `passwordFieldLabel`, `emailSignInAction`,
`emailCreateAction`, `emailSwitchToCreate`, `emailSwitchToSignIn`,
`emailConfirmSent`, `emailNotConfirmed`, `emailAlreadyExists`,
`accountEmailSignInFailed`, `accountEmailCreateFailed`.

### Tests (test/features/profile_account_section_test.dart)

- De e-mailoptie staat naast Google in de uitgelogde staat.
- Tikken opent de dialoog met beide velden.
- Validatie: lege e-mail zonder '@' of wachtwoord korter dan 6 tekens → fout in
  de dialoog, geen netwerk-aanroep.
- Foutpad: dialoog + geldige waarden op een ongeïnitialiseerde Supabase-client
  (de bekende truc uit Test 12/13) → foutmelding toont, geen crash, geen login.
- Schakelen tussen inloggen en account aanmaken wisselt titel en knoptekst.

## Afbakening (bewust niet)

- ~~Geen diep-link naar de app voor de bevestigingsmail~~ — **komt er wél
  (2026-09-21, na Joosts toestelronde):** de mail opende de app zelf via
  `ridewindow://` (manifest intent-filter), `emailRedirectTo` bij signUp, en
  de ingebouwde deep-link-observer van supabase_flutter wisselt de code om
  voor een sessie. Zie SUMMARY. De enige resterende dashboardstap is de
  whitelist `ridewindow://**` in Additional Redirect URLs.
- Geen wachtwoord-vergeten-flow — Supabase's e-mail-bevestiging dekt het
  aanmaakpad; herstel van een vergeten wachtwoord is een vervolg (kan later
  met dezelfde mail-trigger van Supabase).
- Geen "werkelijk lokaal account" (pincode op toestel) — expliciet afgewezen
  door Joost: het vervalt juist het nut van een account.

## Verificatie

`flutter gen-l10n`, `flutter analyze`, gerichte widget-tests, daarna de volle
suite. Een echte aanmaak + bevestiging is alleen op een toestel te proberen
(Joost, met een eigen e-mailadres) — dat noteer ik in de SUMMARY als
toestel-vervolg.
