---
quick_id: 260726-ka2
slug: web-shell-gelijktrekken-met-de-merkkleur
date: 2026-07-26
status: in-progress
---

# Web-shell gelijktrekken met de merkkleuren vóór de PWA-deploy

## Waarom

Commit `b3fcdec` (25 juli) zette de merkkleuren door de app, maar raakte alleen
Dart-code. De PWA-shell is sinds `10963af` (17 juli) onveranderd en draagt nog
`#2E7D32` — het oude groen. De splash-PNG's zijn van diezelfde 17e juli en tonen
het vorige logo, terwijl `web/icons/` op 25 juli wél opnieuw is gegenereerd
(`792eb44`). Gevolg: wie de PWA op zijn iPhone installeert krijgt een oude
splash en een oude statusbalk-kleur voor een app die daarna in de nieuwe
merkkleuren opent.

De splash liep achter omdat `tools/make_icons.py` alleen iconen genereert —
de splash-assets zijn op 17 juli ad hoc gemaakt en daarna nooit meegelopen.
Dat is de eigenlijke bug; de verkeerde kleur is het symptoom.

## Merkkleuren (bron: `lib/theme/app_colors.dart`)

- `brandLight` = `#C5D4B6` — app-achtergrond in light mode
- `brandDark` = `#234934` — seed van het kleurenschema

## Kleurtoewijzing (besluit)

| Doel | Waarde | Reden |
|------|--------|-------|
| `manifest.background_color` | `#C5D4B6` | matcht de app-achtergrond én het splash-canvas → geen kleurflits bij opstarten |
| `index.html` body background | `#C5D4B6` | idem; dit is wat je ziet vóór de canvas verft |
| `manifest.theme_color` | `#234934` | browser-chrome / Android-statusbalk; donker leest beter met lichte tekst |
| `index.html` meta `theme-color` | `#234934` | moet identiek zijn aan manifest, anders flitst het alsnog |
| splash-canvas | `#C5D4B6` | gelijk aan `background_color` |

## Taken

1. **`web/index.html`** — `theme-color` en `background-color` meta's plus de
   body-`background-color` in de `<style>` naar bovenstaande waarden.
2. **`web/manifest.json`** — `background_color` en `theme_color` idem.
3. **`tools/make_icons.py`** — splash-stap toevoegen die de 5
   `apple-splash-*.png` uit dezelfde master genereert als de iconen, op
   `BRAND_LIGHT`. Vereist een rechthoekige variant van `centred()`, want die
   gaat nu uit van een vierkant canvas.
4. **`web/splash/*.png`** — regenereren via het uitgebreide script.
5. **`test/web/pwa_install_meta_test.dart:48`** — assert op `#2E7D32`
   bijwerken. Zonder dit faalt de suite direct na taak 2.

## Bewust buiten scope

- `lib/theme/app_colors.dart` regels 86/105/110/112 (`lightScorePerfect` e.a.):
  dezelfde hex, andere betekenis — dit is de "Perfect"-score-kleur, geen
  merkkleur. Expliciet uitgesloten door de gebruiker.
- `mockup.html` — wegwerp-mockup, wordt niet geshipt.
- `docs/feature-graphic.html` — de Play Store feature graphic staat nog op een
  oud-groen verloop. Dit is een echte inconsistentie, maar hem aanpassen
  betekent opnieuw uploaden naar de Store. Los besluit, apart van deze deploy.

## Al in orde (gecontroleerd, niet aangepast)

- `android/app/src/main/res/values/ic_launcher_background.xml` staat al op
  `#C5D4B6` — meegenomen in `792eb44`.
- `android/.../values*/styles.xml` gebruikt `?android:colorBackground`, dus
  volgt het thema; geen hardcoded kleur.

## Openstaand punt (niet stilzwijgend beslist)

`index.html` heeft `apple-mobile-web-app-status-bar-style="black"`. Met een
lichte body (`#C5D4B6`) valt die zwarte balk meer op dan met het oude donkere
groen. `default` past beter bij light mode maar geeft zwarte tekst op een
donkere achtergrond in dark mode. Er is geen waarde die beide themes dekt.
Blijft daarom op `black` (altijd leesbaar) — apart aan de gebruiker voorgelegd.

## Verificatie

- `flutter test test/web/pwa_install_meta_test.dart` groen
- Geen `#2E7D32` meer in `web/`
- 5 splash-PNG's met mtime van vandaag, juiste afmetingen
- Middelste pixel van elke splash == `#C5D4B6`
