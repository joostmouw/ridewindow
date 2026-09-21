# SUMMARY — welkomstwielen: spaakgeluid en trillingen bij de intro

**Datum:** 2026-09-21 · **Plan:** `PLAN.md`
**Suite:** 740/740 groen (10 nieuw), `flutter analyze` exact op de baseline
van 200 info's, nul nieuwe issues uit de nieuwe bestanden.

## Wat er nu in de app zit

Bij de welkomstintro (eenmalig, vóór onboarding) tikken nu spaakjes onder de
morph: zeven tikken in 1,4 s, zacht en traag zodra de fiets vorm krijgt
(vanaf circa 1,0 s), sneller als de renner opstapt, vol tempo (8 tikken per
seconde) als de velgen dicht zijn, en doorrollend tot het eind. Elke tik
geeft een korte trilling op hetzelfde moment (`selectionClick`, hetzelfde
klikje dat de app elders gebruikt). Wie tik om te overslaan breekt ook de
rit af: geen beeld, geen wiel.

## De vondsten (het waardevolste deel)

1. **De wielen draaien nergens in het filmpje.** Frame-naar-frame-analyse van
   de WebP (206 frames van 12 ms) laat zien dat het een morph is: tekening
   verschijnt 0,28-1,0 s, morph naar fiets 1,0-1,68 s, renner stapt op
   1,68-2,0 s, en de velgen sluiten pas 2,0-2,16 s. In het eindbeeld zijn de
   wielen lege cirkels zonder spaken (gemeten rond beide wielcentra:
   papierluminantie, alleen de framebuis steekt erdoor). "Op de maat van het
   filmpje" kon dus nooit letterlijk synchroniseren op een draaiend wiel;
   het is een ontwerp aan de gemeten fasen geworden.
2. **Het bronfilmpje (~/Downloads, 10 s) heeft muziek, geen spaakgeluiden.**
   Audiospoor geanalyseerd: doorlopend muziekje, wegebt bij 8,2 s. Het geluid
   is dus verzonnen en deterministisch gegenereerd met
   `tool/spoke_tick_sound.py` (alleen Python-stdlib, vaste seed, licentievrij,
   herdraaibaar).
3. **Twee klanken, niet één.** Tik en tock wisselen af (2900 en 2300 Hz): acht
   identieke tikken per seconde klinken als een metronoom, en de afwisseling
   geeft de onregelmaat die een rollend wiel geloofwaardig maakt.

## De keuzes van Joost (2026-09-21)

1. Optrekkende rit (niet letterlijk aan de velgsluiting vastgekluisterd).
2. Elke tik geeft een korte trilling, hetzelfde ritme als het geluid.

## Hoe het gebouwd is

- `lib/features/welcome/spoke_track.dart`: de tijdlijn is een const lijst
  (`kSpokeTicks`) met per tik moment, klank en volume, afgeleid en
  gedocumenteerd per fase. De speler eromheen bundelt geluid en trilling
  achter één start/stop, zodat die twee nooit van elkaar kunnen afdriften.
- Afspelen met **audioplayers 6.8.1** in `lowLatency`-stand (SoundPool), het
  eerste en enige audiopakket van de app. Fouten in het afspelen worden één
  keer gelogd en de intro loopt door: tooi die de rit niet mag breken.
- **Alleen native.** Op web blokkeert de browser autoplay (de intro start
  zonder tik van de gebruiker) en bestaan trillingen niet; zelfde kIsWeb-wacht
  als `emailRedirectTo`. In de testomgeving bestaat de speler ook niet
  (`FLUTTER_TEST`), waardoor de bestaande welkomtests onaangeroerd groen
  bleven; nieuwe widget-tests injecteren een opnamefake via een
  `@visibleForTesting`-parameter.
- `kSpokeTrackStartDelay` (150 ms) compenseert het decoden van de eerste
  frame tussen de initState-klok en het beeld.

## Bewijs

- 6 tijdlijn-tests (`spoke_track_test.dart`): begint niet vóór de
  wervelfase, versnelt monotoon (nooit een stap terug), laatste tik binnen
  het beeld (uiterlijk 2430 ms), tik/tock wisselen af, volume loopt alleen
  omhoog, en de speler bestaat niet in de testomgeving.
- 3 widget-tests (`welcome_spoke_test.dart`): het scherm start de tijdlijn,
  tikken-om-te-overslaan stopt hem, en afbraak van het scherm stopt hem.
- 1 structuurtest (`sound_assets_test.dart`): de wav's bestaan en zijn echt
  (RIFF), staan in de pubspec-assets, en het generator-script is erbij. Dit
  bewaakt het klassieke falingspad: een geluidsasset die vergeten wordt
  geregistreerd faalt stíl, alleen op het toestel.

## Open (op de Oppo, na de volgende internal-release)

1. **Synchronisatie bijstellen.** `kSpokeTrackStartDelay` is een schatting
   (150 ms). Val in het echt de eerste tik duidelijk vóór de werveling,
   verhoog hem; valt hij er ver na, verlaag hem. De intro begint met 276 ms
   stilstaand beeld, dus er is speelruimte.
2. **De klank zelf beoordelen.** Vooraf beluisteren kan op de Mac:
   `afplay assets/sounds/spoke_tick.wav` en `spoke_tock.wav`. Is de tik te
   metalig of te zacht, dan zit de recipe in `tool/spoke_tick_sound.py`
   (constanten onderaan), daarna opnieuw draaien; de tijdlijn verandert niet.
3. **Release volgt de route** (`docs/RELEASE-ROUTE.md`) op Joosts sein;
   versiebump hoort daarbij. Deze taak heeft bewust geen buildnummer
   aangeraakt.
