# Testers changelog: Ridewindow

> Eén blok per build, vanaf build 41. Bijgehouden terwijl er gebouwd wordt, niet
> achteraf gereconstrueerd. Wie er test en waarom staat in `.planning/TESTERS.md`.

## Build 46: 1.0.35+46

**Datum:** 2026-09-20
**Track:** Internal testing.

**Inhoud**
- **De app crashte na elke herstart van het toestel.** `AndroidManifest.xml`
  noemde sinds 3 juni een receiver `be.tramckrijte.workmanager.
  RescheduleOnBootReceiver`; die klasse bestaat niet, want workmanager heet
  sinds 0.6 anders en heeft helemaal geen boot-receiver meer. Android maakt
  zo'n receiver pas aan als hij vuurt, dus alleen een reboot raakte hem, en
  dan viel het proces om voordat er een scherm was. Gevonden in de logcat van
  build 45 op de Oppo (`7bb52c9`)
- Een test die elke klassenaam in de manifest nakijkt, zodat dit soort
  verwijzing niet nog eens maanden kan blijven staan
- De winkelpagina en deze changelog zijn ontdaan van kwadraatstreepjes, en de
  test die dat in de app bewaakt kijkt nu ook naar deze twee bestanden
  (`c9b4627`)

**Feedback opgelost:** geen. Dit was een vondst op het toestel, precies waar
een Play-installatie voor bedoeld is.

**Geverifieerd op het toestel (2026-09-20, 12:34):** 46 uit Play geinstalleerd,
daarna de Oppo echt opnieuw opgestart. De crashbuffer bleef leeg waar 45 er een
FATAL in achterliet. Wel opgemerkt: direct na de herstart stond er geen
achtergrondtaak gepland; die verschijnt pas zodra de app een keer geopend is.
Dat is dezelfde familie als het openstaande punt #74 en wordt apart bekeken.

## Build 45: 1.0.34+45

**Datum:** 2026-09-20
**Track:** Internal testing, geüpload op 2026-09-20 met
`tool/play_upload.dart` (de eerste release via de API, niet met de hand). Dit is
de build die de inhoud van 43 en 44, die nooit op Play hebben gestaan, naar de
testers brengt.

**Inhoud**
- Alles uit build 43 en 44, zie de blokken daaronder
- "Longest ride here" zei bijna altijd 2 uur, een artefact van de dedup, die
  een lang venster weggooide voor het korte venster dat erin zat (`93d9e27`)
- Releasepapier: notities bij de upload en dit blok zelf

**Feedback opgelost:** geen nieuwe boven op 43 en 44. Ingrid's #69 en #70 zitten
in 43, en de "longest ride here"-tekst hierboven haalt daar de laatste scherpte af.

## Build 44: 1.0.33+44

**Datum:** 2026-09-20
**Track:** nooit naar Play gegaan. Sideload op de Oppo, tweede verificatieronde.

**Inhoud**
- Geen kwadraatstreepjes (em-dashes) meer in de app, met een structuurtest erop
  (`ae161d0`)
- Uitgelogd vertrok er bij het opstarten niets uit de outbox: feedback en
  statistiek bleven liggen tot er toevallig een voorgrond-overgang kwam (`e0aab7a`)
- Eenheden: Fahrenheit, Beaufort en mijl per uur in Profiel. De motor blijft in
  Celsius en km/u; alleen de tekst rekent om (`9adaff6`)
- Zwarte schermbug bij info → OK in Profiel: de OK-knop popte de pagina in
  plaats van de dialoog (`9adaff6`)

**Feedback opgelost:** geen. Dit was een eigen ronde op het toestel, die vijf
dingen vond die alleen op glas te zien zijn. De "longest ride here"-fix volgde ná
de bump en zat al wel in de sideload op de Oppo; naar de testers gaat hij via 45.

## Build 43: 1.0.32+43

**Datum:** 2026-09-19
**Track:** nooit naar Play gegaan. Sideload op de Oppo, voor de verificatieronde
van 19 september.

**Inhoud**
- Home kent twee gezichten: vensters als lijst, of als één blok per dag met het
  beste venster uitgelicht. "Beste eerst" sorteert op score, niet op oordeel
  (`18507d7`, `b198901`, `f3709fd`)
- Bij een gedeelde rit kun je meerdere vensters voorleggen: de groep stemt en de
  organisator kiest (`008b516`)
- Een gedeelde rit is af te zeggen, met ongedaan maken; afgezegde ritten staan
  onder een eigen filter (`265e282`)
- Anonieme gebruiksstatistiek, pas na een expliciete ja bij de tweede start;
  gebeurtenissen van daarvoor wachten in een wachtkamer (`66286f4`, `8a67953`)
- Notificaties volgen de taal van de app (`3a1beaf`) en de drie schakelaars in
  Profiel doen nu werkelijk iets (`5d4db64`)
- De app volgt de fietser: laatst bekende positie gedeeld met de achtergrondtaak,
  zonstand voor de eigen plek, waarschuwing op Home (`351e0f4`)
- De daglicht-uitleg is dezelfde sheet als de andere drie balken en spreekt hun
  taal (`d072e45`, `ea75154`)
- Het privacybeleid vertelt over de statistiek en wat een maatje van je ziet; de
  link ernaartoe was sinds juli een 404 en wijst nu goed (`187ca5b`, `1738a93`)
- Consistentie-sweep #73: nul hardgecodeerde hoeken, en de weerbalk-uitleg noemt
  hetzelfde getal als de balk (`a388701`, `ff47f2e`)
- PWA: de "zet op beginscherm"-balk is weg te klikken (`b84bd16`) en er zijn geen
  doodlopende schermen meer op de iOS-webapp (`99600e4`)

**Feedback opgelost:** Ingrid (tester) vroeg op 2026-09-09 om het aaneengesloten
goede blok (#69) en om te zien waarom dit venster (#70). Beide staan in deze
build: de blokweergave hierboven. De tester op Aruba zag "licht van 01:32 tot
13:29". De app rekende de zon voor Amsterdam en tekende hem op de klok van
Aruba; de locatiefix hierboven is het antwoord (`351e0f4`).

## Build 42: 1.0.31+42

**Datum:** 2026-09-10
**Track:** Internal testing → Closed testing "Alpha" (actief sinds 2026-09-10 23:24,
beschikbaar voor de geselecteerde testers)

**Inhoud**
- De app heet Ridewindow, overal waar een gebruiker de naam ziet: app, winkelpagina,
  privacybeleid en PWA zeggen nu hetzelfde (`a28886f`)
- De openingsintro is twee keer zo kort: 2,47 s in plaats van 4,94 s (`059e352`)

**Feedback opgelost:** geen. Dit was een eigen keuze (merknaam en een snellere start).

## Build 41: 1.0.30+41

**Datum:** 2026-09-10
**Track:** Closed testing "Alpha"

**Inhoud**
- Daglicht telt mee in de score. Een venster dat een uur na zonsondergang valt scoort
  niet langer perfect; daarvoor gold een vast raam van 06:00–22:00. De zonstand wordt
  lokaal berekend en is geijkt tegen Open-Meteo (`c3bd44f`), en de aftrek is aangesloten
  op de score, met een weerbalk, een regel op de ritkaart en een schuif in Profiel
  (`5aff9d7`)
- De vier oordelen heten nu Toprit, Fijne rit, Te doen en Binnenblijver
- De Peloton-introductie bereikt wie hem nodig heeft (`36b56f0`)

**Feedback opgelost:** Ingrid (tester) vroeg op 2026-09-09 of de app rekening houdt met
het moment van zonsondergang. Daaruit kwam backlog **#68**, en de daglichtscore hierboven
is het antwoord, de eerste testerfeedback die tot een uitgeleverde wijziging leidde.
Uit diezelfde melding kwamen ook #69 (het groene blok) en #70 (waarom dit venster), die
nog openstaan.
