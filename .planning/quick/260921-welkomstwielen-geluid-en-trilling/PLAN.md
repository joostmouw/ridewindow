# PLAN — welkomstwielen: spaakgeluid en trillingen bij de intro (2026-09-21)

## Wens van Joost

Bij de intro (het snelle filmpje met het fietsje, `welcome_ride.webp`) moet je
een wiel met spaakjes horen tikken, en op hetzelfde ritme trillingen voelen.
Geluid en trillingen moeten overeenkomen met het filmpje.

## Wat het filmpje werkelijk doet (gemeten, 2026-09-21)

De WebP is 206 frames van 12 ms (2,47 s). Frame-naar-frame-analyse levert deze
fasen op:

| Fase | Frames | Tijd | Wat er te zien is |
|---|---|---|---|
| Stille start | 0-22 | 0-0,28 s | niets beweegt |
| Tekening verschijnt | 23-83 | 0,28-1,0 s | het monogram tekent zichzelf |
| Morph / werveling | 84-139 | 1,0-1,68 s | het monogram wordt de fiets |
| Renner stapt op | 140-167 | 1,68-2,0 s | de renner komt op de fiets |
| Velgen sluiten | 168-180 | 2,0-2,16 s | de wielen worden complete cirkels |
| Stille einder | 181-205 | 2,16-2,47 s | beeld staat stil, Flutter schuift omhoog |

Twee harde bevindingen die het ontwerp bepalen:

1. **De wielen draaien nergens als wiel.** Het is een morph, en het eindbeeld
   heeft lege velgen zonder spaken (gemeten rond beide wielcentra:
   achtergrondluminantie op papier­niveau, alleen het frame buis steekt door
   het wiel). Er bestaat dus geen letterlijk draaiend spaakpatroon om
   syn­chroniseren; "op de maat van het filmpje" is een ontwerpkeuze.
2. **Het bronfilmpje heeft muziek maar geen spaakgeluiden** (audiospoor
   geanalyseerd: een doorlopend muziekje dat bij 8,2 s wegebt). Het geluid
   moet dus verzonnen en gegenereerd worden.

## De keuzes van Joost (2026-09-21, gevraagd naar aanleiding van bovenstaand)

1. **Optrekkende rit**: zachte trage tikken zodra de fiets vorm krijgt
   (circa 1,0 s), sneller als de renner opstapt (1,68-2,1 s), doorrollend tot
   het eind van de intro. Niet letterlijk aan de velgsluiting vastgekluisterd.
2. **Elke tik geeft een korte trilling**, hetzelfde ritme als het geluid.

## Ontwerp

### Tijdlijn (puur Dart, testbaar)

- Fase 1 (1.000-1.680 ms): interval 330 ms, zacht (volume circa 0,4). De
  werveling waar de fiets vorm krijgt.
- Fase 2 (1.680-2.100 ms): interval lineair van 330 naar 125 ms, volume
  0,4 naar 0,8. De renner stapt op, het wiel komt op gang.
- Fase 3 (2.100-2.400 ms): interval 125 ms, volume 0,8. De velgen zijn dicht,
  de rit rolt door terwijl het beeld omhoog schuift.
- Laatste tik uiterlijk 2.430 ms; de intro eindigt op 2.472 ms.
- Elke tik wisselt tussen `tick` en `tock` (twee iets verschillende klanken,
  anders klinkt 8 tikken per seconde als een machine), elke tik trilt kort.
- Tik op het scherm = rit afbreken (het overslaan bestond al; het geluid en
  de trilling stoppen dan ook).

De fasen-tijden zijn afgeleid van de frameanalyse hierboven, niet gekozen.

### Geluid

- Twee korte synthetische spaaktikken (`spoke_tick.wav` + `spoke_tock.wav`,
  elk circa 70 ms): een metalige ping met snelle demping plus een tik aan het
  begin. Gegenereerd door `tool/spoke_tick_sound.py` (alleen Python-stdlib),
  zodat het geluid reproduceerbaar en licentievrij is; draai het script opnieuw
  om de klank aan te passen.
- Afspelen met `audioplayers` in `lowLatency`-stand (SoundPool op Android,
  bedoeld voor precies dit soort korte herhaalde geluiden). Dit is de eerste
  audiopakket in de app; geen van de bestaande pakketten kan geluid afspelen.
- **Alleen native.** Op het web blokkeert de browser autoplay op een intro
  die zonder tik start, en trillingen bestaan daar niet. Zelfde kIsWeb-wacht
  als `emailRedirectTo`.
- Geluid is tooi: faalt het afspelen (geen kanaal beschikbaar), dan logt de
  app dat een keer en loopt de intro gewoon door. Geen "stille takken"-zaak:
  er is niets wat de gebruiker op die plek kan oplossen.

### Trillingen

- `HapticFeedback.selectionClick()` per tik: het korte klikje van de
  systeemtrilling, geen nieuw pakket nodig.

### Testbaarheid

- De tijdlijn is een pure functie/klasse (`SpokeTrack`) met unit-tests:
  begint niet vóór de wervelfase, versnelt monotoon, stopt vóór het einde,
  en produceert na `stop()` niets meer.
- De speler gaat achter een interface zodat widget-tests met een fake
  draaien; de echte speler wordt in een testomgeving niet aangemaakt.

## Verificatie

- `flutter analyze` op baseline (200 info's, geen nieuwe warnings).
- Volledige suite groen, plus nieuwe tests voor de tijdlijn en het scherm.
- Geluid vooraf beluisteren op de Mac (`afplay assets/sounds/spoke_tick.wav`).
- Op de Oppo pas echt te beoordelen: voelt de synchronisatie met het beeld?
  Daar zit een kleinmeeteiland: de WebP begint te lopen na het decoderen, de
  tijdlijn start in `initState`. Er zit een afstemconstante in de speler die
  bijgewerkt wordt zodra Joost het op het toestel heeft gezien.

## Buiten scope

- Geen geluid op de PWA (autoplay-blokkade; bewust native-only).
- Geen webversie van de trillingen.
- Geen volumeregelaar of instelling: het scherm is eenmalig (onboarding-
  redirect), het geluid duurt 1,4 s en volgt de mediasysteme van het toestel.
- Geen release in deze taak; die volgt de release-route als Joost het op het
  toestel heeft goedgekeurd.
