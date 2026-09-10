# Epic #71 "Twaalf testers" — van opt-in naar productiegoedkeuring

> Aangemaakt 2026-09-10. Dit bestand is de werkstand van de epic; **begin hier.**
> Backlog-epic: **#71** in `BACKLOG.md`. Loopt naast v4.0, blokkeert niets.
>
> **Stand:** nog niet begonnen. `1.0.30+41` ligt klaar om te uploaden.

## Waar deze epic over gaat

Google eist twaalf testers die veertien dagen aaneengesloten aan een gesloten test
deelnemen voordat je naar productie mag. De verleiding is om dat als een
administratieve horde te zien: twaalf vinkjes halen en wachten.

**Dat is precies de val.** Uit het onderzoek dat Joost verzamelde, één ontwikkelaar
die het proces net doorlopen had:

> Van de twaalf testers uit die subreddit gebruikten er *twee* de app werkelijk,
> en die ook nog onregelmatig.

Google meet niet of er op "word tester" is gedrukt, maar of de app **daadwerkelijk
geopend wordt** over die veertien dagen. Wie twaalf wederzijdse testers verzamelt
die installeren en meteen wegleggen, haalt het aantal en zakt op het gebruik.

## Wat RideWindow hier vóór heeft

Dit is geen app zonder publiek. **Ingrid heeft op 2026-09-09 feedback gegeven die
tot drie backlog-items leidde** (#68 daglicht, #69 het groene blok, #70 waarom dit
venster), en #68 is inmiddels gebouwd en uitgeleverd. Dat is exact het "kernteam"
dat de geciteerde ontwikkelaar beschrijft als de reden dat zijn aanvraag slaagde —
en de meeste indie-developers hebben dat niet.

De opdracht is dus niet *twaalf mensen vinden*, maar **die kern uitbreiden naar
vijf à acht echte fietsers en de rest opvullen.**

## Het inzicht over de veertien dagen

De veertien dagen zijn geen wachttijd. Ze zijn een **bewijsperiode waarin
regelmatig uitbrengen zélf het bewijs is.** De geciteerde ontwikkelaar pushte zes
builds in veertien dagen en noemde dat een reden voor goedkeuring.

Joost bouwde op 10 september alleen al drie builds. Dat ritme is er dus al; wat
ontbreekt is dat het **wordt bijgehouden op een manier die je na dag veertien kunt
overleggen.** Dat is de goedkoopste winst in deze hele epic: geen extra werk, alleen
niet meer weggooien wat je toch doet.

## Wat we op 10 september al leerden over de eerste minuut

Toevallig hebben we die dag een verse installatie gedaan — precies wat een nieuwe
tester meemaakt. Drie waarnemingen:

1. **De app start in de taal van het toestel.** `profile_notifier.dart:196` doet
   `systemLang == 'nl' ? 'nl' : 'en'`. Dat is correct gedrag, maar het betekent dat
   een Nederlandse tester met een Engelstalig toestel een Engelse app krijgt en zelf
   naar Profiel moet om dat te wijzigen. Bij werving via Reddit is Engels juist
   goed; bij fietsmaatjes uit Amsterdam waarschijnlijk niet.
2. **Er lopen drie uitlegoverlays achter elkaar** — op Home, Agenda en Ritten. Elk
   met Vorige / Volgende / Overslaan. Voor een tester die je zelf hebt gevraagd is
   dat mogelijk te veel voordat hij iets heeft gezien.
3. **Uitgelogd is de app leeg.** Geen beschikbaarheid, geen ritten, en de Agenda
   toont dan overwegend grijze uren met een verbodsteken. De eerste indruk hangt
   dus af van of iemand meteen zijn week invult. Wie dat niet doet, ziet een
   lege app en concludeert dat er niets te zien is.

Punt 3 is het scherpst: **de app is pas overtuigend nadat je hem iets over jezelf
hebt verteld.** Dat is een ontwerpaanname die bij bestaande gebruikers onzichtbaar
is en bij elke nieuwe tester meteen op tafel ligt.

## De vijf sporen

### 1. Werving — eigen kring eerst, aanvullen waar nodig

Gekozen richting (Joost, 2026-09-10): **vijf à acht mensen uit de eigen omgeving die
werkelijk fietsen**, aangevuld met test-for-test tot twaalf.

- De kern: mensen als Ingrid. Zij openen de app omdat hij ze iets oplevert, niet
  omdat ze punten sparen.
- De opvulling: `r/AndroidClosedTesting`, `r/TestersCommunity`, de TestersCommunity-app.
  Bied terugtesten aan — dat verhoogt aantoonbaar de kans dat mensen de app
  geïnstalleerd houden.
- Niche als tussenweg: wielrenclubs en fiets-Discords leveren tragere werving maar
  testers die doelgroep zijn. Overwegen als de eigen kring onder de vijf blijft.

**Open vraag:** hoeveel mensen kan Joost realistisch persoonlijk vragen? Dat getal
bepaalt hoe groot de opvulling moet zijn en is het eerste dat we moeten weten.

### 2. Bewijsvoering voor Google

Een changelog per build, gekoppeld aan wie welke feedback gaf en in welke versie het
is opgelost. Niet achteraf reconstrueren — meelopen.

Na dag veertien vraagt Google om een motivatie. Met deze administratie zijn de
antwoorden een kwestie van overschrijven:

- *Hoe heb je testers verzameld?* → gerichte bètagroep uit de doelgroep, aangevuld
  met developer-communities.
- *Welke feedback kreeg je en wat deed je ermee?* → "in `1.0.30` is daglicht
  toegevoegd na melding van een tester dat 20:00–22:00 op score 100 stond terwijl de
  zon om 20:07 onderging."
- *Waarom is de app klaar?* → stabiel over N builds, crashvrij, kern uitgebreid getest.

Dat eerste voorbeeld is echt en al gebeurd. Het is meteen het sterkste bewijs dat de
feedback-lus werkt.

### 3. Google Group voor de testers

De test-track koppelen aan een Google Group in plaats van adressen één voor één in de
Console te typen. Scheelt werk bij elke nieuwe tester en maakt de opt-in-instructie
één vaste tekst die je kunt hergebruiken.

Hoort hierbij: de uitnodigingstekst zelf. Wat je stuurt bepaalt of iemand de app
opent of alleen installeert. Minimaal erin: dat het veertien dagen duurt, dat je
vraagt hem een paar keer per week te openen, en waaróm dat nodig is.

### 4. Onboarding van een nieuwe tester

Zie de drie waarnemingen hierboven. Het gaat om de eerste minuut: taal, de drie
overlays, en de lege staat.

Verwant maar niet hetzelfde als de introductie die vandaag aan het Peloton-tabblad is
toegevoegd (`36b56f0`) — daar bleek dat een woord uitleg nodig had; hier gaat het om
of het scherm überhaupt iets te zien geeft.

### 5. Feedback terugkrijgen

Nu moet een tester uit zichzelf iets sturen. `Feedback versturen` staat in Profiel,
onder OVER, achter twee keer scrollen. Ingrids feedback kwam dan ook niet via de app
maar rechtstreeks bij Joost.

Twee vragen: is er een moment in de app waarop je erom kunt vragen zonder te
zeuren, en wil je de feedback via Play (telt mee voor Google's beoordeling) of via
je eigen kanaal (rijker, maar onzichtbaar voor Google)?

## Wat er bewust niet in zit

- **Betaalde testdiensten.** BetaTesting en dergelijke garanderen aantallen, maar
  kosten geld en de €0/maand-grens uit `CLAUDE.md` is een expliciete keuze. Pas
  overwegen als de gratis route na twee weken vastloopt.
- **Marketing.** Dit gaat over de twaalf testers die Google eist, niet over groei na
  de lancering. Dat is een andere epic.

## Eerste stappen

1. Bundel `1.0.30+41` uploaden en de winkelpagina bijwerken (icoon, screenshots,
   omschrijvingen — zie `docs/store-listing.md`). Zonder een fatsoenlijke pagina
   werf je niemand.
2. Vaststellen hoeveel mensen Joost persoonlijk kan vragen.
3. Google Group opzetten en de uitnodigingstekst schrijven.
4. De changelog-administratie beginnen bij build 41, niet later.

Pas daarna de wervingsronde. Eerst het huis op orde, dan mensen uitnodigen.
