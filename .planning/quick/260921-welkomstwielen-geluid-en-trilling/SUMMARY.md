# SUMMARY — welkomstwielen: spaakgeluid en trillingen bij de intro

**Datum:** 2026-09-21 · **Plan:** `PLAN.md`
**Suite:** groen, `flutter analyze` exact op de baseline van 200 info's.
**Toestel:** goedgekeurd door Joost op de Oppo (ronde 3), via de
eerste-minuut-flow-uitzondering van de release-route: lokaal gesideload met
verse data, genoteerd in `STATE.md`.

## Wat er nu in de app zit

Bij de welkomstintro (eenmalig, vóór onboarding) hoor je een echte fiets
opstarten en uitrijden: het pedaal grijpt in zodra de morph de fiets vorm
geeft (circa 1,0 s), de rammel trekt op met de renner die opstapt, en de
uitrij loopt door tot de opname zelf uitsterft, ruim een seconde nadat het
beeld is aangekomen. De trillingen volgen de hoorbaarheid van de clip:
25 pulsen, dichter op elkaar waar het ratelt (minimale tussenpoes 70 ms) en
uitdunnend in de uitrij (146, 189, 236 ms aan het eind). Wie tikt om te
overslaan breekt de rit af.

## Drie rondes, en waarom

**Ronde 1: verzonnen tikken** (commit `af54d81`). Zeven synthetische
spaaktikken, op de gemeten fasen van het filmpje, met een generator-script
dat ze reproduceerbaar maakte. Op de Oppo oordeelde Joost: trillen werkt,
maar "het geluid slaat nergens op". Te veel piep, te weinig wiel.

**Ronde 2: de echte opname.** Joost stuurde een echte fietsopname en zei
wat hij wilde: "je hoort het opstarten en uitrijden, dus haal het
middenstuk eruit". Analyse van de opname (10,4 s): na het in-grijpende
pedaal trekt het geratel op (0,3-1,0 s), daarna 7 s gelijkmatig, en vanaf
circa 8 s rijdt het geluid uit naar stilte. `tool/rolling_intro_sound.py`
smeedt segment A (0,33-1,05 s) en segment B met een korte overvloeiing
aan elkaar; het gelijkmatige midden vervalt.

**Ronde 3: de uitrij verlengd.** Eerste proef op het toestel: klank goed,
maar de uitrij mocht verder doorlopen ("dat je hem uit hoort te trappen").
Segment B loopt nu van 8,50 s tot 10,35 s: tot de opname zelf stopt, dus
de clip sterft op natuurlijke wijze uit in plaats van afgekapt te worden.
Clip: 2,53 s. Joost: "ja is goed zo."

## De vondsten

1. **Twee spelers betwisten elkaar de audioruimte.** Ronde 1 speelde tik
   en tock op twee AudioPlayers, en de logcat van de Oppo liet bij elke
   afspeling `onAudioFocusChange(-1)` zien: de tweede speler steelt de
   focus van de eerste, wat het geluid kan dempen of afkappen. Ronde 2
   gebruikt daarom één speler; in de log is de focusverlies-ruis volledig
   weg. Les: short sound effects op Android met audioplayers gaan op één
   speler, niet op een per klank.
2. **De wielen draaien nergens in het filmpje.** Frame-naar-frame-analyse
   van de WebP: het is een morph (tekening 0,28-1,0 s, werveling naar de
   fiets 1,0-1,68 s, renner opstappen 1,68-2,0 s, velgen sluiten
   2,0-2,16 s), en het eindbeeld heeft lege velgen zonder spaken. Het
   bronfilmpje heeft muziek, geen wielgeluid. "Op de maat van het
   filmpje" is dus altijd een ontwerpkeuze aan de fasen, geen
   letterlijke synchronisatie.
3. **Trillingen volgen de hoorbaarheid, niet tikken.** "Elke tik een
   trilling" uit ronde 1 is bij een echte rammel onvertaalbaar (het is
   quasi-continu), dus het meetscript levert pulsen per genormaliseerde
   amplitude-som met een 70 ms-vloer. De reeks versnelt vanzelf met de
   optrek en dunt vanzelf uit met de uitrij, en zit in één start/stop
   met het geluid zodat de twee nooit van elkaar kunnen afdriften.
4. **De nummers in de bestandsnaam wezen naar de verkeerde site, de
   metadata van het bestand wel naar de goede.**
   `freesound_community-bicycle-pedal-105846.mp3` leek naar freesound
   105846 te wijzen, maar dat is een synthesizer-kick van iemand anders.
   105846 is een **Pixabay**-id. Opgelost op 2026-09-21 met de
   download-metadata die macOS zelf bewaart:
   `xattr -p com.apple.metadata:kMDItemWhereFroms <bestand>` gaf de
   CDN-link en `https://pixabay.com/`. Bron:
   <https://pixabay.com/sound-effects/bicycle-pedal-105846/>, 10 s, wat
   klopt met de bronopname hierboven. Les: bij een asset met onbekende
   herkomst is de metadata de eerste plek, niet de bestandsnaam.

## Open (blokkeert geen Play-build vanzelf, maar wel de intro meenemen)

- ~~**Licentie van de opname vastleggen.**~~ **Rond op 2026-09-21.**
  Pixabay Content License: commercieel gebruik en bewerken toegestaan,
  naamsvermelding niet verplicht, alleen standalone doorverkoop
  verboden (niet van toepassing). De clip mag mee in een Play-upload.
  Vastgelegd in `assets/sounds/WELCOME_ROLL-LICENSE.txt`.
- **`kSpokeTrackStartDelay`** (150 ms) is een schatting van de decode-
  vertraging van de WebP. Goedgekeurd zoals het staat; bijstellen kan
  op het toestel als een toekomstige proef scheef aanvoelt.
- **De Oppo staat op een locale sideload** met verse data; de
  agendakoppeling moet opnieuw zodra hij weer echt met de app aan de
  slag gaat. De eerstvolgende internal-release via Play herstelt de
  Play-installatie vanzelf.

## Bewijs

- `spoke_track_test.dart`: clip begint niet vóór de wervelfase, uitrij
  binnen het geluidsbudget (uiterlijk 3,6 s), elke puls binnen de clip,
  eerste puls volgt de in-grijpende klik, tussenpozen altijd >= 70 ms,
  het ritre versnelt in het begin en dunt uit aan het eind, en de speler
  bestaat niet in de testomgeving.
- `welcome_spoke_test.dart`: het scherm start de tijdlijn, tikken-om-te-
  overslaan stopt hem, afbraak van het scherm stopt hem.
- `sound_assets_test.dart`: de wav is echt (RIFF), geregistreerd in de
  pubspec-assets, even lang als de Dart-constante zegt (drift tussen clip
  en tijdlijn betekent trillingen die los van het geluid gaan), en het
  smeed-script is erbij.
- Op het toestel: clip speelt 2,1 s (ronde 2) / volledig (ronde 3) op
  één audiospoor, volume 1,0, zonder focusverlies; drie widget-tests met
  een opnamefake bewaken de koppeling.
