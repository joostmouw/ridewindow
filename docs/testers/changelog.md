# Testers changelog: Ridewindow

> Eén blok per build, vanaf build 41. Bijgehouden terwijl er gebouwd wordt, niet
> achteraf gereconstrueerd. Wie er test en waarom staat in `.planning/TESTERS.md`.

## Build 54: 1.0.43+54

**Datum:** 2026-09-24
**Track:** Alleen internal testing, voor Joosts eigen toesteltest van Clubs fase 34
(plan 34-08, optie b). Niet naar de gesloten test: Clubs gaat pas in fase 36 naar
testers, als het privacybeleid (CLUB-21) is bijgewerkt

**Inhoud**
- Groepen op de Peloton-tab: een groep maken, het groepsscherm met leden en
  beheerders, aanvragen via de groepslink of een voordracht, beheer per lid,
  en een groep verlaten of opheffen
- De groepslink (/#/group/<code>) opent een landingsscherm; de code overleeft
  inloggen en wordt daarna een aanvraag

## Build 53: 1.0.42+53

**Datum:** 2026-09-21
**Track:** Internal testing en, op verzoek dezelfde dag, closed testing (Alpha)

**Inhoud**
- De welkomstintro heeft geluid gekregen: een echte fietsopname die opstart en
  uitrijdt, met trillingen die de hoorbaarheid van de clip volgen. Tikken slaat
  de intro nog steeds over
- De opname lag al klaar maar mocht niet mee in een release zolang niet
  vaststond onder welke licentie hij valt. Dat is nu uitgezocht: Pixabay
  Content License, commercieel gebruik en bewerken toegestaan, geen
  naamsvermelding verplicht
- Elk beeld- en geluidsbestand in de app heeft sindsdien een herkomst die naast
  het bestand staat, ook de intro-animatie
- Eén adres voor de hele app: het privacybeleid noemde nog een ander adres dan
  de Play Console. Beide staan nu op joostmouw@gmail.com

## Build 52: 1.0.41+52

**Datum:** 2026-09-21
**Track:** Internal testing. De gesloten test blijft op build 49 tot Joost deze
build op de Oppo heeft goedgekeurd

**Inhoud**
- Een e-mailaccount aanmaken werkte niet in build 50 en 51: de meegebakken
  publieke Supabase anon key was niet meer geldig en elke signup eindigde
  daardoor vóór e-mailvalidatie met `401 Invalid API key`
- De actuele anon key uit hetzelfde Supabase-project is meegebakken. Een
  rechtstreekse signup-probe komt nu voorbij de gateway; de resterende
  `429 over_email_send_rate_limit` is de tijdelijke uitgaande-maillimiet van
  Supabase en staat los van de app-build
- De app-deep-link `ridewindow://confirm` uit build 51 blijft ongewijzigd

## Build 51: 1.0.40+51

**Datum:** 2026-09-21
**Track:** Internal testing. De gesloten test volgt pas na toestelgoedkeuring
van Joost (release-route, `docs/RELEASE-ROUTE.md`)

**Inhoud**
- De bevestigingsmail van een nieuw e-mailaccount opent nu de app zelf, in
  plaats van een dood internetadres (deep link `ridewindow://confirm`, OPEN.md
  punt 11). Supabase stuurt de browser na het bevestigen naar de app; de
  sessie wordt automatisch opgebouwd, dus je bent direct ingelogd
- Daarvoor is een dashboardstap nodig geweest: in Supabase
  (Authentication → URL Configuration → Additional Redirect URLs) staat
  `ridewindow://**` sinds deze build

## Build 50: 1.0.39+50

**Datum:** 2026-09-21
**Track:** Internal testing. De gesloten test volgt pas na toestelgoedkeuring
van Joost (release-route, `docs/RELEASE-ROUTE.md`)

**Inhoud**
- Inloggen kan nu met elk e-mailadres in plaats van alleen Google: in Profiel
  staat "Inloggen met e-mail" onder "Inloggen met Google" (OPEN.md punt 11)
- Een account maak je in hetzelfde scherm aan met een e-mailadres en een
  wachtwoord; een nieuw account moet eerst per e-mail bevestigd worden
  voordat inloggen werkt
- Daarna werkt alles hetzelfde als bij Google: instellingen en geplande ritten
  worden weer gesynchroniseerd

## Build 49: 1.0.38+49

**Datum:** 2026-09-21
**Track:** Internal testing, daarna als dezelfde bytes gepromoveerd naar de
gesloten test (`--promote 49 --track alpha`). De PWA op
`my-project-joost.web.app` is dezelfde dag meegegaan; die stond nog op 46

**Inhoud**
- Een gedeelde rit draagt nu een eigen teken: drie fietsers achter elkaar, en
  een enkele fietser als je alleen rijdt. Het staat links op de geplande rit op
  Home en in de kop van het ritdetail (schets 014)
- Het vlaggetje bij "Jij organiseert" is een megafoon geworden, zoals de coach
  bij het roeien. Meerijden draagt helemaal geen icoon meer: de zin zegt het al
- Nieuw is de teller onder de rit: een fietsje per persoon, doorzichtig zolang
  iemand nog moet antwoorden, met "3 gaan mee, 1 wacht nog" ernaast. Die stond
  tot nu toe alleen onder je eigen rit, en staat nu onder elke gedeelde rit
- Past die zin niet op de kaart, dan kort de app hem in plaats van hem af te
  kappen. Op Home is dat vrijwel altijd, op een smalle telefoon ook in de lijst

**Feedback opgelost:** geen melding van een tester. Dit komt uit Joosts eigen
waarneming dat een vlaggetje niets zegt over een groepsrit.

**Bewijs:** het merkteken is uit Flutter zelf naar beeld gerenderd en op 14, 16,
20 en 64 px bekeken; acht nieuwe tests rond de teller en de icoonregels; volle
suite 722/722, `flutter analyze` 0 errors. Nog niet op een toestel bekeken.

## Build 48: 1.0.37+48

**Datum:** 2026-09-21
**Track:** Internal testing, geüpload op 2026-09-21 met `tool/play_upload.dart`,
daarna als dezelfde bytes gepromoveerd naar de gesloten test (`--promote 48`).

**Inhoud**
- De vervolg-sweep "stille takken": tien acties die bij een fout zichtbaar
  niets deden, zeggen het nu (zie de SUMMARY in
  `.planning/quick/260921-stille-takken-sweep/`)
  - Peloton: accepteren en afzeggen, en een venster kiezen, zowel op de
    ritkaart als op het ritdetail
  - Uitnodigen: het ophalen van je maatjes en het voorleggen van vensters
    faalden stil
  - Deel-link maken en een maatje verwijderen (Ritten, tab Maatjes)
- Uitloggen zegt het nu als dat mislukt, in plaats van je ingelogd te laten
  zonder enig signaal
- Een herinnering aanzetten terwijl meldingen uit staan, legt dat uit en
  verwijst naar de systeeminstellingen
- Een succesmelding na een mislukking kan niet meer: "je doet niet meer mee"
  zei je ook als het antwoord nooit aankwam
- Welcome en de onboarding-knop kunnen een nieuwe tester niet meer vasthouden
  als een instelling niet weg te schrijven is

**Feedback opgelost:** geen nieuwe meldingen. De les uit Androidguju67's
melding van 21 september (de eerste helft zat in 47) is over de hele app
nagelopen; dit is de tweede helft.

**Bewijs:** vier regressietests die op de vorige code falen; volle suite
714/714, `flutter analyze` 0 errors.

## Build 47: 1.0.36+47

**Datum:** 2026-09-21
**Track:** Internal testing, daarna als dezelfde bytes gepromoveerd naar de
gesloten test (`--promote 47`). Stond op 21 september al bij de testers; dit
blok hoorde er al bij te staan.

**Inhoud**
- De toestemmingskaart voor gebruiksstatistiek ging niet dicht bij beide
  knoppen: je antwoord werd bewaard, maar de kaart bleef staan. Hij sluit nu
  altijd (`2492dda`)
- De privacy-link in Profiel deed niets, en een volgende tik kwam op de
  weerdata-link terecht. Hij opent nu het echte beleid en zegt het als dat
  niet lukt (`35000f5`)
- "Volgende" in onboarding kan niet meer doodlopen op een schrijffout
  (`eff2b7e`)
- De Android-manifest was onparseerbaar door een verboden teken in een
  comment; een structuurtest bewaakt dat nu (`b982362`)

**Feedback opgelost:** Androidguju67 (de toestemmingskaart en de privacy-link).
Zie `.planning/debug/consent-card-en-privacy-link.md`.

**Geverifieerd op het toestel (2026-09-21):** privacybeleid opent, de kaart
sluit bij een tik, via de internal track op de Oppo.

## Build 46: 1.0.35+46

**Datum:** 2026-09-20
**Track:** Internal testing, diezelfde middag gepromoveerd naar de gesloten
test (`alpha`) met `--promote 46`, dus exact dezelfde bytes die op internal
geverifieerd zijn.

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
