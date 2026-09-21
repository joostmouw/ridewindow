# SUMMARY — lokaal account: Ridewindow-account zonder Gmail (OPEN.md punt 11)

**Datum:** 2026-09-21 · **Plan:** `PLAN.md`
**Commit:** zie git log · **Suite:** 727 tests groen (5 nieuwe), `flutter analyze`
0 errors / nul nieuwe warnings (baseline 200 info's, ongewijzigd).

## Wat er nu kan

In Profiel staat onder "Inloggen met Google" een tweede, gewone optie:
**Inloggen met e-mail**. Die opent een dialoog met twee modi — inloggen
(`signInWithPassword`) en account aanmaken (`signUp`) — en gebruikt Supabase'
**e-mail-authenticatie met elk geldig e-mailadres** (geen Gmail nodig). Na een
succesvolle inlog draait de app precies dezelfde afronding als na Google:
accountwissel-check, sync, naam-invulstap blijft leeg (D-04 vult alleen als het
veld nog leeg is). De avatar valt terug op het generieke icoon (er is geen
Google-profiel-URL bij een e-mailaccount — het bestaande pad dat dat al deed).

## De keuzes van Joost (2026-09-21)

1. E-mail + wachtwoord via Supabase — geen lokaal-op-toestel-account. Sync,
   maatjes en alles wat op het Supabase-account draait werken mee.
2. E-mailbevestiging **aan** (dashboard-instelling, ongewijzigd): een nieuw
   account moet de bevestigingsmail aanklikken voordat inloggen werkt.
3. Plek: Profiel, als tweede optie naast Google.

## Wat er gebouwd is

- `AccountSection` (native AND web): tweede ListTile "Inloggen met e-mail" met
  het bestaande `AppIcons.lock`. Web-tak: een `TextButton.icon` onder de
  Google-knop.
- `_EmailSignInDialog`: dialoog met e-mail + wachtwoord, inloggen/aanmaken
  wisselbaar, foutmeldingen in de dialoog zelf ("stille takken"-les: een fout
  hoort zichtbaar te zijn op de plek waar de gebruiker hem oplost, niet pas als
  snackbar achteraf).
- **Bevestigingsmail-uitzondering:** bij `mailer_autoconfirm: false` levert
  `signUp` geen sessie op; de dialoog zegt dan letterlijk "controleer je
  e-mail" (nodig: `emailConfirmSent`). Daarna log je gewoon in.
- 13 nieuwe ARB-strings (EN+NL, geen em-dashes), `flutter gen-l10n` gedraaid.

## Foutmeldingen (altijd gericht, nooit de ruwe API-tekst)

- ongeldige combinatie / param-fout → `accountEmailSignInFailed`;
- "not confirmed" → `emailNotConfirmed`;
- "already registered" → `emailAlreadyExists`;
- overige → `accountEmailSignInFailed` / `accountEmailCreateFailed`.

Validatie is client-zijde, vóór elke netwerk-aanroep: geen `@` of wachtwoord
< 6 tekens → `emailInvalidError` / `passwordTooShortError`, geen netwerk-call.

## Bewijs

- 5 nieuwe widget-tests (Test 14-18 in `profile_account_section_test.dart`):
  optie zichtbaar naast Google · dialoog opent met beide velden · validatie
  vangt vóór netwerk · geldige invoer op ongeïnitialiseerde Supabase-client
  (de bekende truc uit Test 12/13) toont de fout en blijft open · wisselen
  wisselt titel én knoptekst, en het foutpad gebruikt de aanmaak-variant.
- Suite 727/727, `flutter analyze` 200 issues = baseline (0 errors/warnings
  nieuw).

## Toestel-vervolg (alleen op de Oppo te doen, met een eigen e-mailadres)

1. Profiel → "Inloggen met e-mail" → "Account aanmaken" met een testadres.
2. Bevestigingsmail openen (landt in de browser; geen diep-link naar de app —
  bewust, zie PLAN.md afbakening) en terugkomen.
3. Inloggen met dat adres + wachtwoord: naam is leeg (invulstap), avatar is het
  generieke icoon, sync en maatjes werken.

## Toestel-ronde 2026-09-21: gevonden

- De e-mail-login werkt; de **bevestigingslink van Supabase wijst naar
  `http://localhost:3000`**, wat op een toestel een dood adres is. Oorzaak:
  een nieuw Supabase-project heeft als standaard "Site URL" localhost:3000 en
  díe staat in elke bevestigingsmail. De bevestiging zelf wordt óók verwerkt
  als je de link opent (het token wordt opgemaakt op Supabase's eigen
  redirect-pagina, alleen de laatste doorverwijzing naar localhost faalt), dus
  **daarna gewoon inloggen** werkt al.
- **Fix (dashboardsetting, door Joost):** Supabase-dashboard →
  Authentication → URL Configuration → Site URL →
  `https://my-project-joost.web.app`. Daarna eindigen alle auth-mails (ook
  toekomstig wachtwoord-herstel) op een pagina die laadt.

## Bewust niet

- Geen diep-link voor de bevestigingsmail (browser volstaat; een link naar de
  app is later mooi, niet nodig).
- Geen wachtwoord-vergeten-flow (kan later met Supabase's e-mail-trigger).
- Geen "werkelijk lokaal account" (pincode) — expliciet afgewezen door Joost:
  daarmee vervalt het nut van het account (cloudkopie, maatjes, meerdere
  toestellen).
