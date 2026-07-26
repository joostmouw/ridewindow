---
quick_id: 260726-ka2
slug: web-shell-gelijktrekken-met-de-merkkleur
date: 2026-07-26
status: complete
commits:
  - bf5a030
  - e31a1e1
---

# Samenvatting

De PWA-shell stond nog op het oude groen `#2E7D32` en de iOS-splash toonde nog
het vorige logo. Beide zijn gelijkgetrokken met de merkkleuren uit
`lib/theme/app_colors.dart`, en de splash-generatie is in `tools/make_icons.py`
gezet zodat ze niet opnieuw achterop kan raken.

## Wat er is gewijzigd

| Bestand | Wijziging |
|---------|-----------|
| `web/index.html` | `theme-color` → `#234934`, `background-color` → `#C5D4B6`, body-achtergrond → `#C5D4B6` |
| `web/manifest.json` | `theme_color` → `#234934`, `background_color` → `#C5D4B6` |
| `tools/make_icons.py` | `SPLASH_SIZES` + `centred_rect()` + splash-genereerstap |
| `web/splash/*.png` (5) | opnieuw gegenereerd: merk op `#C5D4B6` |
| `test/web/pwa_install_meta_test.dart` | assert op de invariant i.p.v. op een losse hex |

## Waarom de test is herschreven, niet bijgewerkt

De test asserteerde letterlijk `contains('#2E7D32')` en zou dus breken op taak 2.
Het getal verversen zou dezelfde zwakte hebben opgeleverd: een assert op één
waarde in één bestand ving niet wat er 25 juli misging, namelijk dat
`index.html` en `manifest.json` uit elkaar liepen. De test controleert nu dat
die twee het onderling eens zijn — als ze uiteenlopen verft iOS eerst de ene en
dan de andere kleur, en dát is de zichtbare bug.

## Grondoorzaak

Niet de kleur, maar het ontbreken van een generatiestap. `make_icons.py` dekte
alleen iconen; de splash-assets waren op 17 juli handwerk. Toen `792eb44` de
iconen hergenereerde liep de splash stilzwijgend achter. Nu komen beide uit
hetzelfde script.

## Consistentie-sweep

Doorzocht op `#2E7D32` buiten `build/` en `.planning/`:

- **Aangepast:** `web/index.html`, `web/manifest.json`, de test
- **Al goed:** `android/app/src/main/res/values/ic_launcher_background.xml`
  staat al op `#C5D4B6` (meegenomen in `792eb44`); `values*/styles.xml` gebruikt
  `?android:colorBackground` en volgt dus het thema
- **Bewust ongemoeid:** `lib/theme/app_colors.dart` r.86/105/110/112 —
  `lightScorePerfect` c.s., dezelfde hex met een andere betekenis
- **Niet geshipt:** `mockup.html`
- **Openstaand:** `docs/feature-graphic.html` — de Play Store feature graphic
  draait nog op een oud-groen verloop. Echte inconsistentie, maar aanpassen
  betekent opnieuw uploaden naar de Store. Apart besluit.

## Openstaand besluit

`apple-mobile-web-app-status-bar-style` staat op `black`. Met de nu lichte body
(`#C5D4B6`) valt die zwarte balk meer op dan met het oude donkere groen.
`default` past beter bij light mode maar geeft zwarte tekst op donker in dark
mode. Geen enkele waarde dekt beide themes; daarom ongewijzigd gelaten en
voorgelegd in plaats van stilzwijgend gekozen.

## Verificatie

- `flutter test test/web/pwa_install_meta_test.dart` — 9/9 groen
- Hoekpixel van alle 5 splashes gemeten op `(197, 212, 182)` = `#C5D4B6`
- Logo beslaat 0.293–0.296 van de canvasbreedte (oud: 0.297)
- Iconen en Android-mipmaps byte-identiek na hergeneratie — het script is
  deterministisch en de commit raakt alleen de splash-bestanden
