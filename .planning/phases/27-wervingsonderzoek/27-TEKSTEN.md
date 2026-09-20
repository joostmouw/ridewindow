# Fase 27: Wervingsonderzoek — Verzendklare teksten (WERV-02)

**Datum:** 2026-09-20
**Hoort bij:** WERV-02 (`.planning/REQUIREMENTS.md`), gebaseerd op de gekozen mix in
`27-KANALEN.md` (D-12) en de context in `27-CONTEXT.md`.

Drie teksten, in D-12's prioriteitsvolgorde. Elke tekst bevat de veertien dagen, de vraag
om regelmatig te openen, het waarom, de terugkoppel-belofte en de eerste-minuut-waarschuwing
(D-07). Dit document levert de tekst, niet de verzending — versturen, uitnodigen en
bijhouden horen bij Fase 30 (WERV-03 t/m WERV-05).

**Afbeelding bij de posts (deviatie op verzoek van Joost tijdens de Task 1-checkpoint):**
elke sectie hieronder draagt een eigen `**Afbeelding bij de post:**`-regel met instructie.
Het basisplaatje is `docs/screenshots/01_home.png` — het Home-scherm met de ritvensters, de
kernwaarde van de app in één beeld. Let op bij elk gebruik: die screenshot is vastgelegd op
2026-09-10 voor versie 1.0.30 (commit `0704c39`); de app staat inmiddels op 1.0.35+46 en Home
is zichtbaar veranderd sindsdien (de Vensters/Blok-schakelaar en de keuze Beste eerst/Op tijd
uit #69/#70 staan er niet op). Ververs de screenshot vanaf het toestel vlak vóór een post
daadwerkelijk de deur uitgaat in Fase 30 — presenteer dit plaatje nooit ongezien als actueel.

---

## Eigen kring — opt-in-instructie (NL)

Dit is de belangrijkste tekst van dit plan (D-10). Geen wervende pitch — de ontvangers hebben
al ja gezegd. Het gat zit vrijwel zeker op een van drie letterlijke stappen, niet op twijfel.

> Hoi [naam],
>
> Je hebt al ja gezegd op het testen van Ridewindow — dit is geen nieuwe vraag, maar precies
> wat je nog moet doen om echt aangemeld te staan. Google telt namelijk alleen de laatste
> handeling zelf, en daar lijkt een aantal van jullie nog niet aan toegekomen:
>
> 1. **Accepteer de uitnodiging voor de Google Groep** (mail van Google Groups — check ook je
>    spam als je hem niet ziet).
> 2. **Open de opt-in-link** terwijl je bent ingelogd op datzelfde Google-account waarmee je de
>    groep hebt geaccepteerd: [opt-in-link].
> 3. **Druk op "Word tester"** op de pagina die daarna verschijnt.
>
> Installeren is een aparte, latere stap — die telt niet mee als opt-in. Pas als deze drie
> stappen staan, sta je bij Google op de lijst, ook al heb je de app al geïnstalleerd.
>
> Waarom dit ertoe doet: Ridewindow is de app die ik zelf bouw om in één oogopslag te zien
> wanneer het deze week goed fietsweer is, afgestemd op je eigen agenda. Om productietoegang
> te krijgen bij Google moet de gesloten test **veertien dagen achter elkaar** minstens twaalf
> aangemelde testers hebben — wie tussentijds uitstapt breekt de reeks en de klok begint
> opnieuw. Dus: open de app die veertien dagen ook echt af en toe, niet alleen op dag één.
>
> Wat je terugkrijgt: meld je iets — een bug, een rare score, een tekst die niet klopt — dan
> hoor je van mij terug zodra het is opgelost, en in welke versie het zit.
>
> Eerste-minuut-tip: de app kan openen in de taal van je telefoon (dus Engels op een Engels
> toestel, ook als je zelf Nederlands leest) — dat zet je om in Profiel. En vul meteen een
> ruwe week beschikbaarheid in na het installeren, anders oogt het eerste scherm leeg.

**Afbeelding bij de post:** optioneel — dit is een procedurenotitie aan mensen die al ja
zeiden, geen wervende post, dus een plaatje is hier "leuk om te hebben", niet noodzakelijk.
Wil je er toch een bij: `docs/screenshots/01_home.png`, met dezelfde ververs-kanttekening als
hierboven.

---

## Fiets-Facebookgroep (NL)

Koude tekst — Joost is in deze groep geen bekende, dus de tekst introduceert hem en benoemt
dat de post met toestemming van de beheerder/moderator wordt geplaatst (D-02).

> Hoi allemaal,
>
> Ik ben Joost, fietser en developer, en ik bouw in mijn vrije tijd Ridewindow: een app die op
> basis van temperatuur, regen en wind uitrekent wanneer het deze week de beste momenten zijn
> om te fietsen, en dat naast je eigen agenda legt zodat je concrete, boekbare vensters krijgt
> in plaats van vaag advies — bijvoorbeeld "zaterdag 09:00–13:00, 4u, Perfect". (Geplaatst met
> toestemming van de beheerder/moderator van deze groep.)
>
> Ik zoek testers voor de gesloten testfase op Google Play. Wat ik vraag: installeer de app en
> open hem **veertien dagen achter elkaar** af en toe — niet alleen de eerste dag, want de
> test telt alleen mee als die reeks niet wordt onderbroken. Waarom: zonder mensen die de app
> ook echt gebruiken kan ik geen productietoegang aanvragen bij Google, en zonder echte
> fietsers weet ik niet of de score klopt buiten mijn eigen agenda.
>
> Wat je terugkrijgt: elke melding die je doet — een bug, een score die niet klopt, een tekst
> die onduidelijk is — hoor je van mij terug zodra die is opgelost, en in welke versie.
>
> Twee dingen vooraf: de app kan openen in de taal van je telefoon (dus Engels als je toestel
> op Engels staat) — dat zet je zelf om in Profiel. En vul na het installeren meteen een ruwe
> week beschikbaarheid in, anders oogt het eerste scherm leeg.
>
> Interesse? Reageer hieronder of stuur een bericht, dan stuur ik je de opt-in-link.

**Afbeelding bij de post:** gebruik `docs/screenshots/01_home.png` — het Home-scherm met de
ritvensters, de kernwaarde van de app in één beeld. Let op: die screenshot is vastgelegd op
2026-09-10 voor versie 1.0.30 (commit `0704c39`); de app staat inmiddels op 1.0.35+46 en Home
is zichtbaar veranderd sindsdien (de Vensters/Blok-schakelaar en de keuze Beste eerst/Op tijd
uit #69/#70 staan er niet op). Ververs deze screenshot vanaf het toestel vlak vóór de post
daadwerkelijk de deur uitgaat in Fase 30 — presenteer dit plaatje niet ongezien als actueel.

---

**Herkomst van de regelcontrole (Task 1, uitgevoerd 2026-09-20).** WebFetch op zowel
`reddit.com` als `old.reddit.com` werd op toolniveau geweigerd ("unable to fetch"); de
Claude-in-Chrome-extensie weigerde `reddit.com` eveneens ("not allowed due to safety
restrictions"); WebSearch leverde alleen artikelen van derden op over Google's 12/14-testerseis,
geen letterlijke subreddit-regels. Joost heeft daarom zelf r/AndroidClosedTesting geopend en de
regellijst geplakt, voor zover hij die kon vinden:

- **Regel 1 — "Violation":** tekst "You are no longer able to participate in this community."
- **Regel 2 — "Sharing other subreddit link is prohibited":** bestaat om brigading, harassment,
  spam en cross-subreddit drama te voorkomen; ook omzeilingspogingen (aangepaste namen,
  gecodeerde verwijzingen, hints naar een andere subreddit) zijn niet toegestaan. Overtreding
  kan leiden tot verwijdering van content en verdere moderatie.
- **Regel 3 — "Hate speech, Harassment and Abuse":** standaardregel op beschermde kenmerken.

Er is **geen zelfpromotieregel gevonden** bij deze handmatige controle — vastgelegd als "niet
gevonden bij handmatige controle op 2026-09-20", niet als "zelfpromotie is toegestaan". Regel 2
is de regel die de tekst hieronder direct raakt: de post mag geen andere subreddit noemen of
hinten (dus geen r/TestersCommunity, geen r/AndroidAppTesters, in geen enkele vorm) — de tekst
hieronder voldoet daaraan. Regel 1's formulering is dubbelzinnig: het kan een regeltitel zijn,
of de banner die Reddit een geband account toont; dit kon niet worden vastgesteld. **Open
risico:** vóór er in Fase 30 daadwerkelijk wordt gepost, eerst bevestigen dat het account nog
kan posten in deze subreddit — kan dat niet, dan vervalt dit achtervangkanaal en moet
`27-KANALEN.md`'s mix worden herzien. Deze tekst is een vastgehouden achtervang (D-08/D-12) die
mogelijk een tijd ongebruikt blijft; wie hem in Fase 30 daadwerkelijk verstuurt, verifieert de
regels op dat moment opnieuw, in plaats van op deze vastlegging te vertrouwen.

**Deze tekst is nu geschreven en wordt vastgehouden als achtervang (D-12) — hij gaat pas uit
als de eigen kring en de fiets-Facebookgroep samen na een week onder de vijftien aangemelde
testers blijven.**

## r/AndroidClosedTesting (EN) — achtervang

Engels, wederkerige-testen-toon (aanbod om terug te testen). Geen verwijzing naar een andere
subreddit (Regel 2, zie hierboven).

> Hi all,
>
> I'm building Ridewindow, a cycling app that scores upcoming hours for temperature, rain and
> wind and turns them into concrete, bookable ride windows against your own calendar (e.g.
> "Saturday 09:00–13:00, 4h — Perfect"). Looking for a few testers to help me clear Google's
> closed-testing requirement.
>
> What I'm asking: install the app and open it across **14 consecutive days** — not just
> install-and-forget. The streak resets if the opted-in count drops below Google's threshold
> mid-way, so regular opens matter more than a single install.
>
> What I offer: happy to test your app back in return — reciprocal. Tell me what you need
> (install + X days, or a specific flow to check) and I'll do it.
>
> You'll hear back from me on anything you report — a bug, an odd score, unclear copy — once
> it's fixed, and which version it landed in.
>
> Two things to expect in the first minute: the app may open in your phone's language (English,
> even if you'd expect Dutch) — switch it in Profile. And fill in a rough week of availability
> right after installing, otherwise the first screen looks empty.
>
> Link: [Play opt-in link]
>
> Thanks!

**Afbeelding bij de post:** gebruik `docs/screenshots/01_home.png`. Zelfde kanttekening als bij
de Facebookgroep: die screenshot is van 2026-09-10, versie 1.0.30 (`0704c39`); ververs hem
vanaf het toestel vlak vóór verzending in Fase 30 — Home is sindsdien zichtbaar veranderd
(#69/#70).

---

*Fase: 27-wervingsonderzoek*
*Teksten geschreven: 2026-09-20*
