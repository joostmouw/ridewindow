# Fase 27: Wervingsonderzoek, verzendklare teksten (WERV-02)

**Datum:** 2026-09-20
**Hoort bij:** WERV-02 (`.planning/REQUIREMENTS.md`), gebaseerd op de gekozen mix in
`27-KANALEN.md` (D-12) en de context in `27-CONTEXT.md`.

Drie teksten, in D-12's prioriteitsvolgorde. Elke tekst bevat de veertien dagen, de vraag
om regelmatig te openen, het waarom, de terugkoppel-belofte en de eerste-minuut-waarschuwing
(D-07). Dit document levert de tekst, niet de verzending: versturen, uitnodigen en
bijhouden horen bij Fase 30 (WERV-03 t/m WERV-05).

**Afbeelding bij de posts (deviatie op verzoek van Joost tijdens de Task 1-checkpoint,
ververst tijdens Task 3):** elke sectie hieronder draagt een eigen
`**Afbeelding bij de post:**`-regel met instructie. Het basisplaatje is
`docs/promo/home-1.0.35.jpg`: het Home-scherm met de ritvensters, de kernwaarde van de app
in één beeld. Vastgelegd op 2026-09-20 om 14:32 op de huidige build (1.0.35+46) en toont de
Vensters/Blok-schakelaar, de keuze Beste eerst/Op tijd (#69/#70), de dagstrip, een geplande
rit en een "100 Toprit"-kaart. Dit plaatje is actueel; de eerdere kanttekening over een
verouderde screenshot (versie 1.0.30) is daarmee vervallen.

**Controlepunt vóór verzending (Fase 26 plan 03): geen taak voor de lezer van de tekst.** De
testersgroep bestaat al: https://groups.google.com/g/ridewindow-testers. Vóór een van de drie
teksten hieronder daadwerkelijk uitgaat in Fase 30, controleert de verzender twee dingen: (1)
dat de groep in Play Console gekoppeld is onder Closed testing > Alpha > Testers > "Choose
testers", en (2) dat de negen bestaande adressen uit de handmatige lijst "First Testers
RideWindow" als lid aan de groep zijn toegevoegd (die import wordt apart afgehandeld, buiten
dit plan). Alle drie de links (groep, opt-in, installeren) staan hieronder al ingevuld
(`applicationId` in `android/app/build.gradle.kts:37`).

---

## Eigen kring: opt-in-instructie (NL)

Dit is de belangrijkste tekst van dit plan (D-10). Geen wervende pitch: de ontvangers hebben
al ja gezegd. Het gat zit vrijwel zeker op een van drie letterlijke stappen, niet op twijfel.

> Hoi [naam],
>
> Je hebt al ja gezegd op het testen van Ridewindow. Dit is geen nieuwe vraag, maar precies
> wat je nog moet doen om echt aangemeld te staan. Google telt namelijk alleen de laatste
> handeling zelf, en daar lijkt een aantal van jullie nog niet aan toegekomen:
>
> 1. **Accepteer de uitnodiging voor de Google Groep** (mail van Google Groups; check ook je
>    spam als je hem niet ziet), of word direct lid via
>    https://groups.google.com/g/ridewindow-testers.
> 2. **Open de opt-in-link** terwijl je bent ingelogd op datzelfde Google-account waarmee je de
>    groep hebt geaccepteerd: https://play.google.com/apps/testing/ridewindow.joost.amsterdam.
> 3. **Druk op "Word tester"** op de pagina die daarna verschijnt.
>
> Installeren is een aparte, latere stap via
> https://play.google.com/store/apps/details?id=ridewindow.joost.amsterdam. Die stap telt niet
> mee als opt-in. Pas als deze drie stappen staan, sta je bij Google op de lijst, ook al heb je
> de app al geïnstalleerd.
>
> Waarom dit ertoe doet: Ridewindow is de app die ik zelf bouw om in één oogopslag te zien
> wanneer het deze week goed fietsweer is, afgestemd op je eigen agenda. Om productietoegang
> te krijgen bij Google moet de gesloten test **veertien dagen achter elkaar** minstens twaalf
> aangemelde testers hebben. Wie tussentijds uitstapt breekt de reeks en de klok begint
> opnieuw. Dus: open de app die veertien dagen ook echt af en toe, niet alleen op dag één.
>
> Wat je terugkrijgt: meld je iets, een bug, een rare score, een tekst die niet klopt, dan
> hoor je van mij terug zodra het is opgelost, en in welke versie het zit.
>
> Eerste-minuut-tip: de app kan openen in de taal van je telefoon (dus Engels op een Engels
> toestel, ook als je zelf Nederlands leest). Dat zet je om in Profiel. En vul meteen een
> ruwe week beschikbaarheid in na het installeren, anders oogt het eerste scherm leeg.

**Afbeelding bij de post:** optioneel: dit is een procedurenotitie aan mensen die al ja
zeiden, geen wervende post, dus een plaatje is hier "leuk om te hebben", niet noodzakelijk.
Wil je er toch een bij: `docs/promo/home-1.0.35.jpg` (zie hierboven, actueel per 2026-09-20).

[Play Console's Testers-tabblad (Closed testing > Alpha > Testers) is leidend voor de
opt-in-link hierboven; wijkt dat tabblad op het moment van versturen af, dan wint het
tabblad.]

---

## Fiets-Facebookgroep (NL)

Koude tekst: Joost is in deze groep geen bekende, dus de tekst introduceert hem en benoemt
dat de post met toestemming van de beheerder/moderator wordt geplaatst (D-02).

> Hoi allemaal,
>
> Ik ben Joost, fietser en developer, en ik bouw in mijn vrije tijd Ridewindow: een app die op
> basis van temperatuur, regen en wind uitrekent wanneer het deze week de beste momenten zijn
> om te fietsen, en dat naast je eigen agenda legt zodat je concrete, boekbare vensters krijgt
> in plaats van vaag advies, bijvoorbeeld "zaterdag 09:00–13:00, 4u, Perfect". (Geplaatst met
> toestemming van de beheerder/moderator van deze groep.)
>
> Ik zoek testers voor de gesloten testfase op Google Play. Wat ik vraag: installeer de app en
> open hem **veertien dagen achter elkaar** af en toe, niet alleen de eerste dag, want de
> test telt alleen mee als die reeks niet wordt onderbroken. Waarom: zonder mensen die de app
> ook echt gebruiken kan ik geen productietoegang aanvragen bij Google, en zonder echte
> fietsers weet ik niet of de score klopt buiten mijn eigen agenda.
>
> Wat je terugkrijgt: elke melding die je doet, een bug, een score die niet klopt, een tekst
> die onduidelijk is, hoor je van mij terug zodra die is opgelost, en in welke versie.
>
> Twee dingen vooraf: de app kan openen in de taal van je telefoon (dus Engels als je toestel
> op Engels staat). Dat zet je zelf om in Profiel. En vul na het installeren meteen een ruwe
> week beschikbaarheid in, anders oogt het eerste scherm leeg.
>
> Zo doe je mee:
>
> 1. Word lid van de testersgroep (Google Groep):
>    https://groups.google.com/g/ridewindow-testers.
> 2. Open de opt-in-link met datzelfde Google-account:
>    https://play.google.com/apps/testing/ridewindow.joost.amsterdam.
> 3. Installeer de app: https://play.google.com/store/apps/details?id=ridewindow.joost.amsterdam.
>
> Reageer gerust hieronder als je meedoet, leuk om te weten wie er zit, en dan kan ik je ook
> gericht om feedback vragen.

**Afbeelding bij de post:** gebruik `docs/promo/home-1.0.35.jpg`: het Home-scherm met de
ritvensters, de kernwaarde van de app in één beeld. Vastgelegd op 2026-09-20 op de huidige
build (1.0.35+46); actueel.

[Play Console's Testers-tabblad (Closed testing > Alpha > Testers) is leidend voor de
opt-in-link hierboven; wijkt dat tabblad op het moment van versturen af, dan wint het
tabblad.]

---

**Herkomst van de regelcontrole (Task 1, uitgevoerd 2026-09-20).** WebFetch op zowel
`reddit.com` als `old.reddit.com` werd op toolniveau geweigerd ("unable to fetch"); de
Claude-in-Chrome-extensie weigerde `reddit.com` eveneens ("not allowed due to safety
restrictions"); WebSearch leverde alleen artikelen van derden op over Google's 12/14-testerseis,
geen letterlijke subreddit-regels. Joost heeft daarom zelf r/AndroidClosedTesting geopend en de
regellijst geplakt, voor zover hij die kon vinden:

- **Regel 1 ("Violation"):** tekst "You are no longer able to participate in this community."
- **Regel 2 ("Sharing other subreddit link is prohibited"):** bestaat om brigading, harassment,
  spam en cross-subreddit drama te voorkomen; ook omzeilingspogingen (aangepaste namen,
  gecodeerde verwijzingen, hints naar een andere subreddit) zijn niet toegestaan. Overtreding
  kan leiden tot verwijdering van content en verdere moderatie.
- **Regel 3 ("Hate speech, Harassment and Abuse"):** standaardregel op beschermde kenmerken.

Er is **geen zelfpromotieregel gevonden** bij deze handmatige controle; vastgelegd als "niet
gevonden bij handmatige controle op 2026-09-20", niet als "zelfpromotie is toegestaan". Regel 2
is de regel die de tekst hieronder direct raakt: de post mag geen andere subreddit noemen of
hinten (dus geen r/TestersCommunity, geen r/AndroidAppTesters, in geen enkele vorm); de tekst
hieronder voldoet daaraan.

**Tweede controleronde, dezelfde dag: Regel 1 opgelost.** Joost heeft de subreddit-feed zelf
geladen en ~20 posts geplakt (2026-09-20). Daaruit blijkt dat het account "Lid geworden" is van
de subreddit en een actieve knop "Post maken" heeft. Het account kan dus gewoon posten. Regel
1's formulering ("You are no longer able to participate in this community") is een regeltitel,
geen banner die aan een geband account wordt getoond. Het eerder genoteerde open risico
("mogelijk geband, onbevestigd") is daarmee **vervallen**; het enige dat blijft staan is de
standaard D-08-afspraak: wie deze tekst in Fase 30 daadwerkelijk verstuurt, verifieert de regels
op dat moment opnieuw, in plaats van op deze vastlegging te vertrouwen.

**Gebruiken afgelezen uit de feed op 2026-09-20** (geen geschreven regels; dit zijn patronen
die Joost zag in ~20 posts, vastgelegd als waargenomen gedrag, niet als subreddit-regel):

1. Geen flair in gebruik. Sommige posts zetten wel een tag tussen haakjes in de TITEL, zoals
   `[T4T]`, `[Test-for-test | 18+]`, `[Brazil]`; optioneel, niet afgedwongen.
2. Wederkerigheid is de norm. Vrijwel elke post biedt "test for test" / "I'll test yours back"
   aan. Posts zonder dat aanbod (een kale Play-link, geen tegenprestatie) krijgen geen
   engagement. De tekst hieronder biedt daarom expliciet terugtesten aan: dit stond al in het
   plan als D-12's wederkerige toon, en de feed bevestigt dat het de norm is, geen aardigheidje.
3. Links staan in de POSTTEKST zelf, nooit pas in een comment. Het standaardpatroon is een
   genummerde 3-stappenlijst: (1) de Google Groep joinen, (2) opt-in op
   `play.google.com/apps/testing/<id>`, (3) installeren via
   `play.google.com/store/apps/details?id=<id>`. Meerdere posts waarschuwen expliciet dat
   "joining the group alone doesn't opt you into the Play test" en dat je "the SAME Google
   account" voor alle stappen moet gebruiken; precies dezelfde wrijving die D-10 al voor
   Joost's eigen kring identificeerde. De tekst hieronder spiegelt die structuur.
4. De veertien dagen worden altijd expliciet genoemd: "stay opted in for at least 14 consecutive
   days", "keep it for 14 days".
5. Lengte: de goed-lopende posts zijn één korte alinea over wat de app doet, dan de genummerde
   stappen, dan welke feedback gewenst is; twee tot drie korte alinea's. Kale-link-posts worden
   genegeerd.
6. Zichtbare valkuilen in de feed, vermeden in de tekst hieronder: nooit vragen om een
   Google-e-mailadres publiekelijk te plaatsen (meerdere posts waarschuwen hiertegen); nooit
   positieve reviews aanbieden of vragen; één post stelt expliciet "Honest feedback only, no
   positive-review swaps". Ook: zware pure-T4T-posts (die met de ruilhandel openen in plaats van
   met wat de app is) krijgen veel downvotes (20+), dus de tekst opent met wat Ridewindow doet,
   niet met het ruilaanbod.
7. Regel 2 blijft gelden: geen andere subreddit noemen of hinten.

**Deze tekst is nu geschreven en wordt vastgehouden als achtervang (D-12): hij gaat pas uit
als de eigen kring en de fiets-Facebookgroep samen na een week onder de vijftien aangemelde
testers blijven.**

## r/AndroidClosedTesting (EN): achtervang

Engels, genummerde 3-stappenlijst in de posttekst zelf (norm 3 hierboven), leidt met wat de app
is vóór het ruilaanbod (norm 6), noemt de veertien dagen expliciet (norm 4), en vermijdt de twee
zichtbare valkuilen: geen verzoek om een publiek e-mailadres, geen review-ruil (norm 6). Geen
verwijzing naar een andere subreddit (Regel 2). Optioneel: een titel-tag zoals `[T4T]` is bij
sommige posts te zien maar niet verplicht (norm 1); aan degene die in Fase 30 post.

> Ridewindow: a cycling app that scores upcoming hours for temperature, rain and wind and
> turns them into concrete, bookable ride windows against your own calendar (e.g. "Saturday
> 09:00–13:00, 4h, Perfect"). Looking for a few testers to help me clear Google's closed-testing
> requirement. Happy to test back.
>
> 1. Join the Google Group: https://groups.google.com/g/ridewindow-testers
> 2. Opt in using the SAME Google account as step 1, at:
>    https://play.google.com/apps/testing/ridewindow.joost.amsterdam
> 3. Install from: https://play.google.com/store/apps/details?id=ridewindow.joost.amsterdam
>
> Joining the group alone does not opt you into the test. Step 2 is the one Google actually
> counts. Please stay opted in for **at least 14 consecutive days**; the streak resets if the
> opted-in count drops below the required number mid-way.
>
> Happy to test yours back: tell me what you need (install + X days, or a specific flow to
> check) and I'll do it. Honest feedback only, no positive-review swaps.
>
> You'll hear back from me on anything you report, a bug, an odd score, unclear copy, once
> it's fixed, and which version it landed in.
>
> First-minute heads-up: the app may open in your phone's language (English, even if you'd
> expect Dutch). Switch it in Profile. Fill in a rough week of availability right after
> installing, otherwise the first screen looks empty.
>
> (Please don't post your Google account email publicly, DM me if needed.)
>
> Thanks!

**Afbeelding bij de post:** gebruik `docs/promo/home-1.0.35.jpg`. Zelfde plaatje als bij de
Facebookgroep: vastgelegd op 2026-09-20 op de huidige build (1.0.35+46); actueel.

[Play Console's Testers-tabblad (Closed testing > Alpha > Testers) is leidend voor de
opt-in-link hierboven; wijkt dat tabblad op het moment van versturen af, dan wint het
tabblad.]

---

*Fase: 27-wervingsonderzoek*
*Teksten geschreven: 2026-09-20*
