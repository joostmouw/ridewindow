---
id: 260807-nm1
slug: app-naam-gelijktrekken
date: 2026-08-07
type: quick
mode: fix
---

# De app heet op drie plekken anders

## Aanleiding

Joost zag twee RideWindow-iconen op zijn beginscherm (native app + de PWA die voor §3 is
geïnstalleerd) met **verschillende namen** — één met hoofdletters, één zonder. Nagetrokken in de
bron: drie plekken, drie antwoorden.

| Bron | Waarde | Zichtbaar als |
|---|---|---|
| `android/app/src/main/AndroidManifest.xml:11` `android:label` | `ridewindow` | naam onder het native icoon |
| `web/manifest.json` `name` / `short_name` | `RideWindow` | naam onder het PWA-icoon |
| `web/index.html:33` `apple-mobile-web-app-title` | `ridewindow` | naam op iOS-beginscherm |
| `web/index.html:55` `<title>` | `ridewindow` | browsertabblad |

De canonieke naam is **RideWindow**: zo staat het in `docs/store-listing.md` (de Play-vermelding),
in `pubspec.yaml`'s `description`, en overal in `CLAUDE.md`. De twee kleine-letter-plekken zijn
fouten, geen keuze. `pubspec.yaml`'s `name: ridewindow` blijft ongemoeid — dat is de Dart-package-
naam en die *moet* lowercase snake_case zijn.

## Taken

1. `android:label` → `RideWindow`
2. `web/index.html`: `<title>` en `apple-mobile-web-app-title` → `RideWindow`
3. Een test die de invariant vastlegt: alle gebruikerszichtbare app-namen zijn onderling gelijk.
   Volg het patroon van `pwa_install_meta_test.dart`, dat na quick-260726-ka2 juist herschreven is
   van "assert op een letterlijke waarde" naar "assert dat de bronnen het eens zijn" — dezelfde
   fout niet opnieuw maken.
4. Release-AAB opnieuw bouwen; de build van 12:26 draagt de oude naam.

## Buiten scope

Het **logo**-verschil tussen de twee iconen. Android-adaptive staat op schaal 0.58
(`tools/make_icons.py:159`), web-maskable op 0.60 (regel 171), en de twee platforms croppen
verschillend — netto komt de glyph op de PWA kleiner uit. Dat is echt, maar het vergt een
ontwerpkeuze over hoe groot het merk in het masker hoort te staan, en dat is niet aan mij.
Apart gemeld aan Joost.
