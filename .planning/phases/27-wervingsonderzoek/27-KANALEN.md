# Fase 27: Wervingsonderzoek — Kanalenvergelijking

**Datum:** 2026-09-20
**Hoort bij:** WERV-01 (`.planning/REQUIREMENTS.md`)

Dit document levert de keuze, niet de verzending — het daadwerkelijk versturen, het
uitnodigen van de eigen kring en het bijhouden van aanmeldingen horen bij Fase 30
(WERV-03 t/m WERV-05). Elke rij hieronder staat bovendien onder het €0/maand-plafond
uit `CLAUDE.md` (D-04): betaalde testersdiensten of credit-systemen die geld kosten
komen niet in aanmerking, ongeacht hoe gunstig hun overige cijfers zijn.

## Vergelijkingstabel

| Kanaal | Bereik | Doorlooptijd | Doelgroepgehalte | Inspanning Joost | Ervaringen van anderen | Bron | Uitkomst |
|---|---|---|---|---|---|---|---|
| Eigen LinkedIn-post | Afhankelijk van Joost's 1e-graads netwerk + shares; typisch een fractie van connecties ziet een post binnen 48u [ASSUMED — netwerkgrootte onbekend hier] | Snel: binnen 1-3 dagen komt de meeste respons binnen na plaatsen | Gemengd — professioneel netwerk, niet per se fietsers, maar mensen die Joost kennen en dus sneller een paar weken volhouden | Zeer laag — één post schrijven en plaatsen, geen setup nodig | Geen platformdrempel; enige risico is dat een té "product launch"-toon als reclame overkomt bij connecties die geen fietser zijn | linkedin.com/help (algemene postmechaniek) | Afgevallen (D-01) — Joost post pas als de app in productie staat, dus na de gesloten test; kan de werving dus niet helpen. Verhuisd naar een lanceerpost, zie BACKLOG.md. |
| LinkedIn-vacature "vrijwillige tester" | Zoekbereik van job-zoekers met matchende trefwoorden, typisch klein voor een niche-vrijwilligersrol; capped op 10-30 sollicitaties per gratis post | Vertraagd door een extra stap: eerst een LinkedIn Company Page aanmaken (RideWindow heeft er nog geen), dan pas de vacature plaatsen; post zelf staat 14 dagen actief, sluit na 30 | Laag — bereikt mensen die op "vacature" zoeken, niet fietsers; vacatures zijn bedoeld voor bona fide functies, geen fit voor "test mijn app af en toe" | Middel-hoog — Company Page opzetten is eenmalig werk dat nu nog niet bestaat, en een vacature-formulier vraagt meer velden dan een post | Geen directe developer-testimonials gevonden die dit kanaal voor tester-werving gebruikten; het mechanisme zelf is voor banen ontworpen, niet voor tijdelijke vrijwilligersvragen | linkedin.com/help/a517777, linkedin.com/help/a521792, linkedin.com/help/a529397 | Afgevallen (D-01 + mechaniek) — vereist een geverifieerde Company Page die RideWindow niet heeft; valt sowieso af los van D-01. |
| Strava-clubs | Clubgrootte varieert sterk; posts van clubbeheerders verschijnen in de feed van alle leden, niet-beheerders alleen in de club zelf | Gemiddeld — vereist eerst clublidmaatschap/beheerdersrelatie, dan een moment om te posten; geen directe DM-route naar niet-volgers (moet elkaar volgen) | Hoog — Strava-gebruikers zijn per definitie actieve fietsers | Middel — moet clublid zijn en bij voorkeur beheerder, of via reacties op activiteiten individueel uitnodigen (traag, één voor één) | Geen technische self-promo-verbodsregel gevonden op platformniveau; wel is de aanbevolen frequentie 2-4 posts/week door beheerders, dus een eenmalige wervingspost valt op als afwijkend | support.strava.com/club-posts, partners.strava.com | Afgevallen — geen self-service postroute naar niet-volgers (moet elkaar volgen); D-02 maakt dit niet erger maar ook niet beter, het platform zelf is de blokkade. |
| NTFU-toerclubs | NTFU zelf is een federatie (~300 aangesloten clubs, ~1,5 miljoen fietsers in NL) zonder eigen ledenforum voor buitenstaanders — het "kanaal" is in werkelijkheid één specifieke aangesloten club benaderen, niet de NTFU zelf | Traag: er is geen warm contact bij een NTFU-aangesloten club (D-02), dus elke benadering is koud via een clubbestuur/webmaster, zonder self-service opt-in en zonder garantie op toegang | Hoog — toerfietsers, exact de doelgroep | Hoog — een persoonlijk verzoek aan een bestuurslid, geen kanaal dat Joost zelf beheert | Geen directe tester-wervingscases gevonden; NTFU-clubs communiceren via eigen apps (Cyql) en ClubApp-achtige tools, geen open plek voor externe verzoeken | ntfu.nl, wielerflits.nl | Afgevallen — hoogste doelgroepfit maar traag en hoge inspanning zonder garantie op toegang; geen warm contact beschikbaar (D-02). |
| Fiets-Facebookgroepen | Grootte per groep sterk wisselend; niet doorzoekbaar vanuit deze omgeving (Facebook levert geen ledenaantallen op via search) | Er is geen warm contact (D-02), dus elke groep is een koude benadering van een admin/moderator — maar in tegenstelling tot NTFU kan dit, eenmaal toegelaten, snel gaan: "Snel zodra toegelaten tot de groep" | Hoog als de groep specifiek fietsers/toerfietsers is | Laag-middel — moet groepslid worden, groepsregels lezen, soms moderatorgoedkeuring vragen voor een post | Geen RideWindow-specifieke cases; algemeen patroon in FB-groepen is dat kale zelfpromotie wordt verwijderd tenzij ingebed in een echte vraag/verhaal | algemene FB-groepsregels (secundaire bronnen, MEDIUM) | Gekozen — kanaal 2 van de mix (D-12): beste combinatie van doelgroepfit en snelheid onder de cold-approach-aanname, voor de ~5 testers van buiten die WERV-04's buffer nog nodig heeft; zie Gekozen kanalen hieronder. |
| Collega's | Klein, vast aantal — Fanalists-collega's; overlapt vermoedelijk deels met de "9" uit de eigen kring in TESTERS.md, dus mogelijk niet incrementeel | Zeer snel — direct persoonlijk vragen | Onzeker — fietsfrequentie van collega's is niet bekend vanuit dit onderzoek | Zeer laag | N.v.t. — dit is functioneel hetzelfde kanaal als "eigen kring" in TESTERS.md | TESTERS.md-bron | Afgevallen — overlapt grotendeels met de bestaande 9 uit de eigen kring (TESTERS.md), voegt weinig incrementeel volume toe; expliciet benoemd, niet stilzwijgend genegeerd. |
| r/AndroidClosedTesting | Test-for-test community; posts vragen doorgaans om Google Group joinen, app downloaden, testen, screenshot + comment als bewijs | Snel voor opt-ins (dagen), maar self-promo mag vaak alleen in wekelijkse threads — regel varieert en moet per bezoek gecontroleerd worden (D-08) | Laag — testers zijn andere developers die reciprociteit zoeken, geen fietsers; motivatie is de eigen 12-testers-eis afvinken, niet interesse in RideWindow | Middel — vergt wederkerigheid: Joost moet zelf apps van anderen testen om in de wederkerigheidscultuur mee te draaien | TESTERS.md citeert zelf een developer wiens 12 subreddit-testers slechts 2 echte gebruikers opleverden (~17%); reciprocal-testing write-ups noemen dit expliciet als oplossing voor exact dat probleem | dev.to/vmzavas, TESTERS.md-bron | Gekozen — uitsluitend als achtervang (D-12), met een expliciete drempel: pas inzetten als de eigen kring (kanaal 1) en de fiets-Facebookgroep (kanaal 2) samen na een week onder de vijftien aangemelde testers blijven. |
| r/TestersCommunity | Vergelijkbaar met r/AndroidClosedTesting, kleinere/nichere reciprocal-testing subreddit | Vergelijkbaar met r/AndroidClosedTesting | Laag, zelfde reden — andere developers, geen fietsers | Middel, zelfde wederkerigheidsvereiste | Geen aparte cijfers gevonden; zelfde categorie als r/AndroidClosedTesting | genoemd in TESTERS.md | Beoordeeld, niet gekozen — een tweede onafhankelijke wederkerige kanaal is overbodig geworden nu het gat nog maar acht conversies binnen de eigen kring plus ~5 van buiten is (D-12), niet de twintig tot vijfendertig opt-ins waarvoor twee reciprocal-kanalen bedoeld waren. |

## Gekozen kanalen

LinkedIn hoort niet bij deze mix — een post van Joost zelf is bewust uitgesteld tot na
productie-toegang (D-01): hij wil pas over de app posten wanneer die daadwerkelijk in
de Play Store staat, en dat is per definitie ná de gesloten test, dus een post nu kan
de werving voor die test niet helpen. Dit beantwoordt expliciet success criterion 2 van
deze fase ("inclusief of een LinkedIn-post van Joost zelf erbij hoort"): nee, niet in
deze fase, wel later. De vacature-variant valt om een tweede, onafhankelijke reden af
(geen Company Page) en zou ook zonder D-01 al niet passen.

De gekozen mix, in D-12's prioriteitsvolgorde:

1. **De eigen kring van tien, als conversiekanaal.** Dit is geen wervingskanaal met een
   bereik-in-onbekenden zoals de andere rijen in de tabel hierboven — het is de
   bestaande testerslijst die nog moet converteren van "gevraagd" naar "aangemeld".
   Het is niettemin het eerste en zwaarste kanaal van de mix, omdat hier het grootste
   deel van het gat zit (zie de rekensom hieronder).
2. **De fiets-Facebookgroep** uit de tabel — gekozen boven Strava-clubs (geen
   self-service postroute) en NTFU-toerclubs (traagst, hoogste inspanning zonder
   garantie op toegang), als beste combinatie van doelgroepfit en snelheid onder de
   cold-approach-aanname die D-02 voor alle fietskanalen vaststelt.
3. **r/AndroidClosedTesting**, uitsluitend als achtervang, met de expliciete drempel
   uit D-12: pas inzetten als kanaal 1 en 2 samen na een week onder de vijftien
   aangemelde testers blijven.

**De rekensom (D-13/D-10/D-11), gecorrigeerd op 2026-09-20.** Google's Console-teller
stond op 2026-09-20 op **2 aangemeld** ("2 testers currently opted in"). D-13 ging ervan
uit dat de eigen kring **tien** mensen telt. Dat blijkt niet te kloppen. De Play-lijst
"First Testers RideWindow" bevat tien adressen, maar dat zijn geen tien mensen: twee
deelnemers staan er met twee accounts in, en een van de tien adressen is Joost zelf. De
bereikbare eigen kring is daarmee **zeven** mensen, niet tien.

Nuance die hierbij hoort: Google telt **accounts**, niet personen. De twee deelnemers met
een dubbel account zouden dus elk twee keer kunnen meetellen als ze op twee toestellen
opt-in doen. Dat is mogelijk maar niet aannemelijk, en het is geen basis om op te plannen:
reken met zeven, en beschouw een achtste of negende account als meevaller.

De gecorrigeerde rekensom naar de vijftien die WERV-04 vraagt:

**2 aangemeld + maximaal 5 conversies binnen de eigen kring + ~8 van buiten = 15**

Wat daaruit volgt, en dat is de kern van de correctie: **het gat naar buiten is groter dan
deze fase aannam.** De oude rekensom liet ongeveer vijf testers van buiten over; de
gecorrigeerde laat er ongeveer acht over, en dat nog alleen als alle vijf de resterende
mensen in de eigen kring daadwerkelijk converteren. Dat verzwakt de kanaalkeuze niet, het
versterkt hem:

- **kanaal 2 (de fiets-Facebookgroep) wordt belangrijker**, niet minder belangrijk: het
  moet nu het leeuwendeel van de externe aanwas leveren in plaats van een restje.
- **de drempel onder kanaal 3 (r/AndroidClosedTesting) gaat eerder af.** Die drempel staat
  op "kanaal 1 en 2 samen na een week onder de vijftien"; met een kleinere eigen kring is
  dat een waarschijnlijker uitkomst dan bij het opstellen werd aangenomen. De achtervang is
  daarmee geen formaliteit meer maar een reëel scenario, en de tekst ervoor hoort klaar te
  liggen (dat doet hij, zie `27-TEKSTEN.md`).

Dit blijft desondanks geen volumekanaal-probleem (D-03, herzien): acht opt-ins van buiten
is nog altijd geen twintig tot vijfendertig, dus er is geen reden om een tweede
reciprocal-kanaal op te tuigen. Een tweede reciprocal-kanaal is daarmee nog steeds niet
nodig; zie ook de tabelrij voor r/TestersCommunity hierboven. De marge is wel dunner dan
gedacht, dus als kanaal 2 tegenvalt is de achtervang de eerste stap, niet een vierde kanaal.

D-11 stelt vast dat er **twee latten** zijn, niet één, en de kanaalkeuze moet aan beide
voldoen: de Console-teller (alleen opt-ins, twaalf tegelijk, veertien aaneengesloten
dagen — wie tussentijds uitstapt breekt de reeks en de klok begint opnieuw) én de
productie-toegang-vragenlijst daarna, die vraagt of testers alle functies gebruikten en
of het gebruik op echt productiegebruik leek. De eigen kring en de fiets-Facebookgroep
scoren op beide latten beter dan een reciprocal-kanaal: hun testers hebben een reden om
de app daadwerkelijk te gebruiken (bekendheid met Joost, of interesse in fietsen), terwijl
reciprocal-testers vooral hun eigen vinkje najagen — precies het patroon dat de vragenlijst
onderscheidt van echt gebruik.

**r/TestersCommunity** is beoordeeld maar niet gekozen: zie de Uitkomst-kolom van de
tabel — een tweede onafhankelijk wederkerig kanaal is overbodig bij een gat van vijf, niet
de twintig tot vijfendertig opt-ins waarvoor zo'n tweede kanaal bedoeld zou zijn.

**Strava-clubs, NTFU-toerclubs en collega's** zijn eveneens beoordeeld en niet gekozen:
Strava-clubs bieden geen self-service postroute naar niet-volgers; NTFU-toerclubs zijn het
traagst en kosten de hoogste inspanning zonder garantie op toegang; collega's overlappen
grotendeels al met de eigen kring uit TESTERS.md en voegen weinig incrementeel volume toe.
Zie de Uitkomst-kolom van de tabel voor de volledige redenering per kanaal.
