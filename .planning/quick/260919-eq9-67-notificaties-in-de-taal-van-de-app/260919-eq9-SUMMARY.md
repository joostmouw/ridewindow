---
quick_id: 260919-eq9
slug: 67-notificaties-in-de-taal-van-de-app
status: complete
date: 2026-09-19
commits:
  - 3a1beaf
---

# Quick 260919-eq9 — #67 notificaties in de taal van de app

## Wat er gedaan is

De drie `schedule*`-methoden van `NotificationService` krijgen een `S` mee en halen titel en
body daaruit. De twee `const AndroidNotificationChannel`-velden zijn vervangen door kanaal-id-
constanten plus een `ensureChannels(S)`. Aanroepers leveren `S` aan: Ride Detail met
`S.of(context)` (vóór de eerste await gepakt), `main.dart` met `S.delegate.load(locale)`.

## De drie vondsten

**1. Het was geen vertaalklus.** Alle negen sleutels bestonden al in `app_nl.arb` én
`app_en.arb` (`notifEveningTitle`, `notifEveningBody`, `notifMorningTitle`, `notifMorningBody`,
`notifWeeklyTitle`, en vier kanaalsleutels). `notification_service.dart` hield er simpelweg een
tweede, Nederlandse kopie naast. De i18n-ronde had het bestand overgeslagen.

**2. `init()` werd nergens aangeroepen.** De kanalen ontstonden impliciet via `zonedSchedule`.
Android legt een kanaalnaam vast bij *aanmaak*; latere meldingen met dezelfde id veranderen hem
niet. De naam in de Android-instellingen bevroor dus in de taal van de eerste melding ooit.
Nu gaat de vertaalde naam mee in `AndroidNotificationDetails` (dus de eerste aanmaak klopt al),
en werkt een `ref.listen` op `appLocaleProvider` de naam bij bij een taalwissel.

**3. Bijwerken, niet opnieuw aanmaken.** De taakomschrijving vroeg om "opnieuw aanmaken bij een
taalwissel". Dat is bewust niet gedaan: `createNotificationChannel` met een bestaande id werkt
naam en omschrijving bij en laat de keuzes van de gebruiker (geluid, trilling, belang) staan.
Een delete-en-recreate zou die wissen. Een taalwissel mag geen instellingen kosten.

## Wat dit openlegt — buiten scope, wel melden

`scheduleMorningOf` en `scheduleWeeklyDigest` worden nergens in `lib/` aangeroepen; alleen
tests raken ze. Profiel toont wel drie schakelaars ("Avond van tevoren", "Ochtend van de dag",
"Wekelijks overzicht"), maar alleen de avond-van-tevoren-knop op Ride Detail plant werkelijk
iets. Twee van de drie notificatiesoorten bestaan dus niet voor de gebruiker. Apart te wegen —
relevant vóór de werving, want het is een schakelaar die niets doet.

## Verificatie

- `flutter analyze` op de vijf gewijzigde bestanden: schoon (alleen bestaande `require_trailing_commas`-infos elders in de bestanden)
- `flutter test test/platform/notification_service_test.dart`: 8/8
- `flutter test` (volledige suite): 574/574 groen

## Niet met eigen ogen gezien

De melding is niet op de Oppo uitgelokt. De teksten zijn in tests bewezen, de kanaalnaam in
Android-instellingen niet. Een taalwissel op het toestel is de enige echte proef.
