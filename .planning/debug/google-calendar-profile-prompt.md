---
slug: google-calendar-profile-prompt
status: awaiting_human_verify
trigger: "Een tester ziet bij het openen van Profiel ongevraagd de Google-accountkiezer."
created: 2026-09-21
updated: 2026-09-21
---

# Debug: ongevraagd Google-venster bij Profiel

## Symptoom

Bij het openen van Profiel verschijnt op Android soms een Google-accountkiezer,
zonder dat de gebruiker op een inlog- of Calendar-knop heeft gedrukt. De
toestand is reproduceerbaar wanneer er meerdere Google-accounts op het toestel
staan en de Calendar-grant ontbreekt.

## Aanroepketen vóór de fix

`ProfileScreen.initState()` roept `_checkCalendarConnection()` aan.

1. `CalendarService.isCalendarConnected()`
2. `authorizationForScopes()` zonder prompt
3. bij `true`: `_checkCalendarMismatch()`
4. `CalendarService.currentGoogleEmail()`
5. `attemptLightweightAuthentication()`

## Bevestigde oorzaak

`google_sign_in` 7.x documenteert `authorizationForScopes()` als niet-
interactief, maar dat geldt niet voor `attemptLightweightAuthentication()`.
De lokale packagebron `google_sign_in_android-7.2.15` voert bij die methode eerst
een auto-select-flow uit en daarna, als dat niet lukt, een tweede Credential
Manager-flow zonder accountfilter. Die tweede flow mag een accountkeuzescherm
tonen. De eerdere code-aanname dat deze methode altijd stil is, is dus fout.

De bestaande toestelverificatie in
`.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md` bevestigt
dezelfde keten en hetzelfde gedrag.

## Uitgevoerde fix

1. De passieve Profiel-route gebruikt geen
   `attemptLightweightAuthentication()` meer.
2. `CalendarService` bewaart de primaire Calendar-id lokaal na een expliciete
   `addRideSlotToCalendar()`- of `getEvents()`-actie, alleen wanneer die id een
   e-mailadres bevat.
3. De mismatchcontrole leest alleen die lokale cache. Een succesvolle
   disconnect wist de cache.
4. Een structuurtest bewaakt dat de oude promptende route niet terugkomt. Twee
   unit-tests bewaken de cache.

## Verificatie

- `google_sign_in_android-7.2.15` is lokaal gelezen: de lightweight-methode
  voert na mislukte auto-select een tweede, niet-gefilterde Credential
  Manager-flow uit die een accountkiezer mag tonen.
- Gerichte Calendar-tests: groen.
- Gerichte Profiel-tests: groen.
- Structuurtest voor de auth-route: groen.
- Volledige suite: **710 tests groen**.
- `flutter build apk --release`: groen, APK gebouwd.
- `flutter analyze` meldt geen errors, maar wel de bestaande 7 `info`-meldingen
  in `profile_screen.dart`; er kwam geen nieuwe analyzer-melding bij.

De nieuwe APK is niet op de Play-installatie gezet: sideloaden kan de lokale
Drift-database en de Calendar-grant van het testtoestel raken. Daarom blijft
alleen de echte-toestelcontrole nog open.

## Blind spot

Een bestaand Calendar-grant van vóór deze fix heeft nog geen lokale
identiteitscache. In dat geval blijft de status zichtbaar, maar verschijnt er
geen mismatch-waarschuwing totdat de gebruiker opnieuw bewust een
Calendar-actie uitvoert. Dat is veiliger dan opnieuw een Google-accountkiezer
openen.
