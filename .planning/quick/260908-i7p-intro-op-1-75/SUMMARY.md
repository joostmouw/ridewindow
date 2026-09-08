---
quick_id: 260908-i7p
slug: intro-op-1-75
date: 2026-09-08
status: complete
---

# De intro speelt op 1,75×

## Wat en waarom

Joost, na de vier tempo's naast elkaar te hebben gezien op een lokale
vergelijkingspagina: **normale afspeelvolgorde, 1,75×**. Op ware snelheid duurt
de intro 8,65 s, en dat is lang voor iets dat je precies één keer ziet.

De omgekeerde variant is óók gebouwd en bekeken (fiets → monogram, eindigend op
het logo) maar niet gekozen.

## Hoe

`tool/webp_speed.py` patcht de framelengte in de ANMF-chunks van 42 ms naar
24 ms. De gecomprimeerde beelddata wordt niet aangeraakt: het bestand is ná de
ingreep **exact even groot** (1.784.544 bytes) als ervoor. Dat is het bewijs dat
er geen scherpte verloren is — een ronde door ffmpeg of Pillow zou wél
hercoderen, en dat zie je in het monogram als eerste.

206 × 24 ms = 4944 ms.

## Wat er meeschoof

`_settleAt` in `welcome_screen.dart` van 6800 naar **3144 ms**. Dat getal is
afgeleid, niet gekozen: het is de duur van de animatie min de 1,8 s die het
verschuiven zelf duurt, zodat beide bewegingen samen eindigen. Stond dat niet
goed, dan zou het scherm stilstaan terwijl de rit al klaar is.

De 1,8 s van het verschuiven blijft ongemoeid — die is apart afgeregeld en op
900 ms schoot de renner het scherm in.

Dat het een afgeleide is, staat nu bij de constante zelf, zodat een volgende
tempowijziging niet stilzwijgend de timing breekt.

## Verificatie

- Framelengtes na de patch nagelezen uit het bestand: 206 × 24 ms.
- Bestandsgrootte ongewijzigd.
- `flutter test test/features/welcome_screen_test.dart` — groen.
