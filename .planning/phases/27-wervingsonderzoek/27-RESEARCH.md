# Phase 27: Wervingsonderzoek - Research

**Researched:** 2026-09-17
**Domain:** Tester-recruitment channels for Google Play closed testing (Dutch cycling app, solo dev, €0 budget)
**Confidence:** MEDIUM — Google's own rules and LinkedIn's own job-posting policy are HIGH confidence (fetched directly from official help pages); channel reach/experience data is MEDIUM (cross-verified developer write-ups); RideWindow-specific reach numbers (Joost's own network size on each platform) are unverifiable from here and are flagged ASSUMED / Open Questions.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WERV-01 | Voor elk kandidaat-kanaal (eigen LinkedIn-post, LinkedIn-vacature, Strava-clubs, NTFU-toerclubs, fiets-Facebookgroepen, collega's, r/AndroidClosedTesting) vastleggen: bereik, doorlooptijd, doelgroepgehalte, inspanning, ervaringen van anderen → gemotiveerde keuze 2-3 kanalen | `## Channel Comparison Matrix` covers all 7 named channels plus 2 extra (r/TestersCommunity, TestersCommunity-app) already referenced in TESTERS.md, for 9 total. `## Recommended Channel Mix` gives the motivated choice, explicitly addressing the LinkedIn-post-vs-vacature question. |
| WERV-02 | Per gekozen kanaal een verzendklare tekst (NL/EN) die de veertien dagen, het regelmatig openen, en het waarom uitlegt | `## What Makes a Recruitment Message Convert` gives the evidence-based ingredients; `## Message Skeletons` gives a NL/EN starting draft per recommended channel type, to be finished and shown as HTML by the planner/executor per the phase's success criterion 3. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **€0/month ceiling, ongoing.** Paid testing services (BetaTesting and similar) are explicitly out of scope — confirmed independently in `REQUIREMENTS.md`'s Out of Scope table. No channel recommendation below may require payment.
- **App starts in device language**, NL or EN, no in-app override until the user visits Profile. TESTERS.md already flagged this: an NL-speaking tester with an EN-phone gets an English app. This directly shapes WERV-02 — texts must tell the tester what language to expect and that it can be changed, per channel language (Reddit → EN app is fine; Dutch cycling circles → say the app may open in English and how to switch).
- **Privacy:** location permission is the only sensitive one; a published privacy policy exists. Recruitment texts linking testers to the Play opt-in page will surface the Data Safety section — nothing new to build here, just don't contradict the "no tracking" promise in outreach copy.
- **GSD workflow enforcement**: this document is research only; the ready-to-send texts and any channel setup (LinkedIn Page, Reddit posts, Google Group config) are execution and belong to the planner's task breakdown, not to this file.

## Summary

Google's own requirement, confirmed directly from `support.google.com` [VERIFIED: Google Play Console Help], is 12 testers opted in continuously for 14 days before applying for production access, and testers who opt out and back in don't count toward that continuity. Google's support page does not state a hard technical block on inactive testers, but the production-access questionnaire explicitly asks whether "testers used all available app features" and whether "tester usage matched expected production user behavior" [CITED: support.google.com/googleplay/android-developer/answer/14151465] — which is the mechanism behind the documented 2026 rejection wave for low-engagement tests that `REQUIREMENTS.md` already records ("sinds april 2026... afgewezen op gebrek aan gebruik"). Multiple independent 2026 sources describe Google moving from a simple opt-in count to session/retention-based evaluation of the closed test [CITED: multiple, MEDIUM confidence, see Sources].

**The corrected target (per the coordinator's update on 2026-09-17):** the binding constraint is 12 genuinely *active* testers over 14 continuous days, not 12 opt-ins. Own circle tops out at ~9 opt-ins (and TESTERS.md already notes those 9 are largely the 7 already in the Play list) — even at a generous activity rate, own circle alone will not reliably clear 12 active testers with margin. TESTERS.md's own cited data point — a developer whose 12 subreddit-sourced testers produced only 2 real users, ~17% activation — sets a hard floor for what "reach" is worth if the channel has no audience fit. The practical conclusion: **raw reach now matters, but only multiplied by a channel's realistic activation rate.** A channel that can plausibly deliver 20 signups at 50% activation (≈10 active) outperforms a channel that delivers 8 signups at 90% activation (≈7 active) on raw count, but the second is cheaper to reach and safer against Google's usage-pattern review, which explicitly looks for organic-looking behavior, not synchronized mass opt-ins [CITED: appconsolelab.com, MEDIUM confidence]. Both belong in the mix — that is why WERV-01 asks for 2-3 channels, not one.

**Primary recommendation:** combine (1) a personal LinkedIn status update from Joost — not a "vacature" job post, see below — for its uniquely high expected activation rate among people who already know him, (2) one or two Dutch cycling Facebook groups or a local NTFU-affiliated touring club, reached via a genuine ask to a group admin/board member rather than a cold post, for audience fit and moderate volume, and (3) `r/AndroidClosedTesting` with real reciprocal testing (not a drive-by post) as the volume backstop, explicitly budgeted against its documented ~17% activation floor. Skip the LinkedIn "vacature": LinkedIn's own help pages state free job posts must be attached to a verified Company Page [VERIFIED: linkedin.com/help], which RideWindow does not have, cap out at 10-30 applications and 14 days of visibility, and surface to people searching for jobs — not to cyclists. A personal post has none of those constraints and reaches the same network for free.

## Architectural Responsibility Map

Not applicable. This phase's deliverable is a recruitment-channel decision and outreach texts, not software with client/server/data tiers — there is no capability-to-tier mapping to produce.

## Standard Stack

Not applicable. No packages, libraries, or code are installed or written in this phase. (Package Legitimacy Audit is therefore omitted — nothing to audit.)

## Channel Comparison Matrix

Reach and effort figures marked **[ASSUMED]** depend on Joost's actual network size on each platform, which cannot be verified from this environment (Reddit and Facebook are not fetchable here — see `## Environment Availability`). Everything else is sourced.

| Kanaal | Bereik (realistisch) | Doorlooptijd tot ~signups | Doelgroepgehalte | Inspanning Joost | Ervaring van anderen | Geschatte activatiegraad |
|---|---|---|---|---|---|---|
| **Eigen LinkedIn-post** | Afhankelijk van Joost's 1e-graads netwerk + shares; typisch een fractie van connecties ziet een post binnen 48u [ASSUMED — netwerkgrootte onbekend hier] | Snel: binnen 1-3 dagen komt de meeste respons binnen na plaatsen | Gemengd — professioneel netwerk, niet per se fietsers, maar mensen die Joost kennen en dus sneller een paar weken volhouden | Zeer laag — één post schrijven en plaatsen, geen setup nodig | Geen platformdrempel; enige risico is dat een té "product launch"-toon als reclame overkomt bij connecties die geen fietser zijn | Hoog **[ASSUMED, o.b.v. bekendheid-verhoogt-retentie-evidentie hieronder]** — eigen netwerk, geen anonimiteit, sociale druk om door te zetten |
| **LinkedIn-vacature "vrijwillige tester"** | Zoekbereik van job-zoekers met matchende trefwoorden, typisch klein voor een niche-vrijwilligersrol; capped op 10-30 sollicitaties per gratis post [CITED: linkedin.com/help/a517777] | Vertraagd door een extra stap: eerst een LinkedIn Company Page aanmaken (RideWindow heeft er nog geen), dan pas de vacature plaatsen; post zelf staat 14 dagen actief, sluit na 30 [CITED: linkedin.com/help/a517777] | Laag — bereikt mensen die op "vacature" zoeken, niet fietsers; vacatures zijn bedoeld voor bona fide functies, geen fit voor "test mijn app af en toe" [CITED: linkedin.com/help/a521792, a529397] | Middel-hoog — Company Page opzetten is eenmalig werk dat nu nog niet bestaat, en een vacature-formulier vraagt meer velden dan een post | Geen directe developer-testimonials gevonden die dit kanaal voor tester-werving gebruikten; het mechanisme zelf is voor banen ontworpen, niet voor tijdelijke vrijwilligersvragen | Onduidelijk/laag — verkeerde intentie-match tussen "vacature" en "help 14 dagen mee testen" |
| **Strava-clubs** | Clubgrootte varieert sterk; posts van clubbeheerders verschijnen in de feed van alle leden, niet-beheerders alleen in de club zelf [CITED: support.strava.com/club-posts] | Gemiddeld — vereist eerst clublidmaatschap/beheerdersrelatie, dan een moment om te posten; geen directe DM-route naar niet-volgers (moet elkaar volgen) [CITED: support.strava.com] | Hoog — Strava-gebruikers zijn per definitie actieve fietsers | Middel — moet clublid zijn en bij voorkeur beheerder, of via reacties op activiteiten individueel uitnodigen (traag, één voor één) [CITED: partners.strava.com] | Geen technische self-promo-verbodsregel gevonden op platformniveau; wel is de aanbevolen frequentie 2-4 posts/week door beheerders, dus een eenmalige wervingspost valt op als afwijkend | Middel-hoog **[ASSUMED]** — sterke doelgroepfit compenseert klein bereik |
| **NTFU-toerclubs** | NTFU zelf is een federatie (~300 aangesloten clubs, ~1,5 miljoen fietsers in NL totaal volgens Wielerflits [CITED, MEDIUM]) zonder eigen ledenforum voor buitenstaanders — het "kanaal" is in werkelijkheid één specifieke aangesloten club benaderen, niet de NTFU zelf | Traag — vereist toestemming van een clubbestuur/webmaster om iets te mogen posten in hun nieuwsbrief/Facebookgroep/WhatsApp; geen self-service opt-in | Hoog — toerfietsers, exact de doelgroep | Hoog — een persoonlijk verzoek aan een bestuurslid, geen kanaal dat Joost zelf beheert | Geen directe tester-wervingscases gevonden; NTFU-clubs communiceren via eigen apps (Cyql) en ClubApp-achtige tools [CITED: ntfu.nl], geen open plek voor externe verzoeken | Onbekend, potentieel hoog bij toegang, maar toegang is de bottleneck |
| **Fiets-Facebookgroepen** | Grootte per groep sterk wisselend; niet doorzoekbaar vanuit deze omgeving (Facebook levert geen ledenaantallen op via search) [Open Question] | Snel zodra toegelaten tot de groep; sommige groepen staan self-promotion expliciet niet toe, zelfs niet via DM aan leden [CITED, MEDIUM — algemene FB-groepsregels] | Hoog als de groep specifiek fietsers/toerfietsers is | Laag-middel — moet groepslid worden, groepsregels lezen, soms moderatorgoedkeuring vragen voor een post | Geen RideWindow-specifieke cases; algemeen patroon in FB-groepen is dat kale zelfpromotie wordt verwijderd tenzij ingebed in een echte vraag/verhaal | Middel **[ASSUMED]** |
| **Collega's** | Klein, vast aantal — Fanalists-collega's; overlapt vermoedelijk deels met de "9" uit de eigen kring in TESTERS.md, dus mogelijk niet incrementeel | Zeer snel — direct persoonlijk vragen | Onzeker — fietsfrequentie van collega's is niet bekend vanuit dit onderzoek | Zeer laag | N.v.t. — dit is functioneel hetzelfde kanaal als "eigen kring" in TESTERS.md | Hoog als ze al fietsen, maar volume is beperkt en mogelijk al meegeteld |
| **r/AndroidClosedTesting** | Test-for-test community; posts vragen doorgaans om Google Group joinen, app downloaden, testen, screenshot + comment als bewijs [CITED, MEDIUM — meerdere dev-write-ups] | Snel voor opt-ins (dagen), maar self-promo mag vaak alleen in wekelijkse threads — regel varieert en moet per bezoek gecontroleerd worden (niet vanuit deze omgeving te verifiëren, Reddit is hier niet bereikbaar) [Open Question] | Laag — testers zijn andere developers die reciprociteit zoeken, geen fietsers; motivatie is de eigen 12-testers-eis afvinken, niet interesse in RideWindow | Middel — vergt wederkerigheid: Joost moet zelf apps van anderen testen om in de wederkerigheidscultuur mee te draaien | TESTERS.md citeert zelf een developer wiens 12 subreddit-testers slechts 2 echte gebruikers opleverden (~17%); reciprocal-testing write-ups noemen dit expliciet als oplossing voor exact dat probleem [CITED: dev.to/vmzavas] | **Laag, ~17% als ondergrens** [CITED: TESTERS.md-bron], hoger bij actieve wederkerigheid maar nooit gegarandeerd |
| **r/TestersCommunity** (genoemd in TESTERS.md, niet in WERV-01 maar wel relevant context) | Vergelijkbaar met r/AndroidClosedTesting, kleinere/nichere reciprocal-testing subreddit | Vergelijkbaar | Laag, zelfde reden | Middel, zelfde wederkerigheidsvereiste | Geen aparte cijfers gevonden; zelfde categorie als hierboven | Laag, zelfde categorie |
| **TestersCommunity-app** (genoemd in TESTERS.md) | 50.000+ developers geclaimd door de dienst zelf [CITED: testerscommunity.com — **commerciële bron, belang bij eigen groei, licht wantrouwen op**]; credit-systeem: test 3 apps → 60 credits → eigen app listen; of "Packs" van 16 developers die elkaar 16 dagen dagelijks testen | Snel voor opt-ins zodra credits verdiend zijn | Laag, zelfde reden als Reddit test-for-test — andere developers, geen fietsers | Middel-hoog — credits verdienen kost tijd (3 apps testen vóór je zelf mag listen), Packs vereisen dagelijkse discipline van 16 mensen tegelijk | Vendor-eigen contentmarketing beschrijft dit als succesvol; geen onafhankelijke derde-partij bevestiging gevonden | Onbekend, vermoedelijk vergelijkbaar met Reddit test-for-test gezien hetzelfde mechanisme (reciprociteit tussen developers, niet fietsers) |

**Wat hierboven ontbreekt en waarom:** exacte ledenaantallen voor specifieke Nederlandse fiets-Facebookgroepen, Strava-clubs, en NTFU-aangesloten clubs zijn niet op te halen vanuit deze onderzoeksomgeving — Facebook-groepen zijn niet doorzoekbaar en Reddit is hier niet bereikbaar (zie Environment Availability). Dit is een expliciete hiaat, geen gok; zie Open Questions.

## Recommended Channel Mix

**Gekozen: (1) eigen LinkedIn-post, (2) één specifieke fiets-Facebookgroep of NTFU-club via een persoonlijk verzoek aan een beheerder, (3) `r/AndroidClosedTesting` met echte wederkerigheid.**

Motivatie, gegeven het gecorrigeerde doel van ~12 actieve testers (niet ~12 opt-ins) bovenop een onzekere eigen kring van ~9 opt-ins met een onbekend maar niet-100%-activatiepercentage:

1. **Eigen LinkedIn-post — hoogste verwachte activatiegraad per aanmelding.** Kost vrijwel niets, en de reikwijdte is weliswaar klein maar de conversie naar daadwerkelijk gebruik is naar verwachting hoog omdat het Joost's eigen netwerk is — dezelfde sociale-druk-dynamiek die TESTERS.md al benoemt voor de eigen kring. Dit is het "hoge-fit, lage-inspanning"-kanaal.

2. **Eén fiets-Facebookgroep of NTFU-club, bereikt via een persoonlijk verzoek in plaats van een kale post.** Dit levert audience fit (echte fietsers) én een kans op dubbele-cijfers-bereik als de groep groot genoeg is en de beheerder meewerkt. De keuze tussen Facebook-groep en NTFU-club hangt af van welke Joost al kent of makkelijk kan bereiken — dat is een Open Question die hij zelf moet beantwoorden (zie hieronder), niet iets dit onderzoek kan bepalen zonder toegang tot zijn eigen netwerk.

3. **`r/AndroidClosedTesting` als volumebackstop, met bewuste wederkerigheid.** Dit kanaal heeft de laagste doelgroepfit en het slechtste gedocumenteerde activatiepercentage (~17% ondergrens), maar het is het enige kanaal dat op afroep dubbele-cijfers-opt-ins kan leveren binnen dagen. Gebruik het bewust als aanvulling, niet als hoofdroute — en reken op verlies: als 6 extra actieve testers nodig zijn en dit kanaal op 17-30% activeert, zijn 20-35 opt-ins uit dit kanaal nodig, wat qua Joost's tijd (wederkerig testen) een reëel prijskaartje heeft. Weeg dat expliciet af tegen kanaal 2 zodra concrete cijfers voor kanaal 2 bekend zijn.

**Strava-clubs en collega's vielen af** — niet omdat ze slecht zijn, maar omdat Strava geen self-service-postroute naar niet-volgers biedt (traag, één-voor-één) en collega's grotendeels al in de "9" van de eigen kring zitten en dus weinig incrementeel volume toevoegen. **De LinkedIn-vacature valt af**: het vereist een Company Page die niet bestaat, is gebouwd voor sollicitanten niet voor fietsers, en een gewone post bereikt hetzelfde netwerk zonder die drempel.

**Combinatie-logica:** kanaal 1 en 3 zijn qua publiek vrijwel disjunct (Joost's professionele netwerk vs. andere Android-developers), kanaal 2 is disjunct van beide (fietsers die Joost niet kent). Geen overlap in doelgroep betekent geen dubbel werk en een bredere dekking dan drie keer hetzelfde publiek aanspreken.

## What Makes a Recruitment Message Convert

Evidence, not opinion, on what turns a signup into someone who keeps opening the app:

- **Personal contact improves retention over anonymous/automated recruitment.** In randomized-trial recruitment research (a stricter evidence bar than marketing blogs), personal contact with participants measurably improves both recruitment and retention compared to fully automated web-based recruitment, which yields large numbers fast but suffers high attrition [CITED: NCBI/PMC — recruitment and retention in internet-based trials, MEDIUM confidence — different domain (health trials) but the mechanism (personal contact → retention) generalizes reasonably to this use case].
- **Telling testers why the 14 days matters, and asking for a specific cadence, is not optional decoration.** TESTERS.md's own draft language already captures the minimum: the test runs 14 days, ask them to open it a few times a week, and explain why. This matches general onboarding-message findings that changing an empty-state message or an explanation can move retention more than a feature change [CITED: general UX/retention literature, MEDIUM confidence, see Sources].
- **Reciprocity explicitly increases install retention in test-for-test contexts.** TESTERS.md already states this and independent developer write-ups confirm it: offering to test back is what keeps reciprocal-testing partners from abandoning the app after opting in, because "nobody wants to be the one who breaks someone else's streak" [CITED: dev.to/vmzavas].
- **Closing the loop ("we fixed this because you reported it") sustains engagement beyond the first session.** This is already proven inside RideWindow itself — TESTERS.md documents the daylight-scoring fix that came from Ingrid's real feedback as the strongest evidence available for the eventual Google application. The same mechanic (tell testers what changed because of them) is a known retention lever in beta-testing literature [CITED, MEDIUM confidence, see Sources] and should be built into the message even at first-invite stage ("you'll hear back when something changes because of what you find").
- **Set the first-minute expectation up front, because the app itself does not yet manage it.** TESTERS.md documents three concrete first-minute frictions: the app opens in device language (an NL tester on an EN phone gets English), three explainer overlays play back to back, and a signed-out/empty-availability state looks broken rather than incomplete. Until Phase 29 (Eerste minuut) ships fixes, the recruitment text is the only place these can be pre-empted — e.g. "the app may open in English depending on your phone; you can switch it in Profile" and "fill in a rough week right after installing, otherwise the first screen looks empty."

## Message Skeletons

Starting drafts only — the planner/executor turns these into the actual verzendklare HTML-previewed texts per WERV-02's success criterion. Each includes the three required ingredients: the 14 days, the ask to open regularly, and the why.

**NL — persoonlijk netwerk (LinkedIn-post, fietsgroep, NTFU-club):**
> Ik bouw al een tijd aan RideWindow, een app die per week laat zien wanneer het écht goed fietsweer is — niet alleen droog, maar ook wind en temperatuur meegewogen — en dat naast je eigen agenda legt. Om 'm in de Play Store te krijgen moet Google zien dat een groep mensen de app twee weken lang af en toe echt gebruikt, geen losse installatie. Zou je willen meedoen als tester? Dat betekent: de app installeren via een linkje, en de komende twee weken een paar keer per week kijken of er een goed moment staat. Ik hoor graag wat er niet klopt of ontbreekt — en je hoort terug als ik iets oplos naar aanleiding van wat je meldt.

**EN — r/AndroidClosedTesting / reciprocal testing:**
> Looking for a few testers for RideWindow, a cycling-specific weather + availability app (Android) — I'll happily test back. Needs 14 consecutive days of real, repeated use (not just an opt-in) for Play production access, so please open it a few times over two weeks rather than just installing once. Opt-in link + Google Group: [link]. Happy to test your app in return — drop your link.

Both drafts need Joost's review before use; they are not yet shown as HTML per the phase's success criterion — that step belongs to plan execution, not research.

## Common Pitfalls

### Pitfall 1: Counting opt-ins instead of active testers
**What goes wrong:** Hitting 12 (or even 20-25) opted-in accounts feels like the job is done, but Google evaluates usage during the 14 days, not the opt-in click alone.
**Why it happens:** The Play Console tester count is the visible, trackable number; actual in-app usage is not shown anywhere in Console in the same obvious way.
**How to avoid:** Track activity per tester (this becomes WERV-05 in Phase 30) from day one, not just the headcount.
**Warning signs:** A tester who opted in on day 1 and never appears again in any feedback/changelog reference by day 5-6.

### Pitfall 2: A dropped tester resets the continuity clock
**What goes wrong:** If a tester opts out (or effectively stops counting) before 14 continuous days elapse, the streak does not carry over [VERIFIED: support.google.com/googleplay/android-developer/answer/14151465 — "Testers who opt in, test for fewer than 14 days, and then opt out do not count toward the requirement"].
**Why it happens:** Drop-off is normal in volunteer testing, especially from reciprocal-testing channels.
**How to avoid:** Recruit with margin (the 20-25 total target already reflects this) and start the clock only once comfortably above 12 opted-in with real engagement, exactly as TESTERS.md already concludes.
**Warning signs:** Any tester below the visible activity threshold for 2+ days (this is WERV-05's job in Phase 30).

### Pitfall 3: Reciprocal-testing communities look like free volume but convert poorly
**What goes wrong:** r/AndroidClosedTesting, r/TestersCommunity, and the TestersCommunity app can produce opt-ins quickly, but the testers are other developers chasing their own 14-day requirement, not people interested in cycling — TESTERS.md's own cited case (2 of 12 real users) is the documented failure mode.
**Why it happens:** The community's shared incentive is mutual box-checking, not product interest.
**How to avoid:** Treat this channel as a volume backstop only, budget for a low activation rate, and lean on genuine reciprocity (test back, don't just post and wait) to push the rate above the ~17% floor.
**Warning signs:** A batch of opt-ins that all arrive within hours of a single Reddit post and never reappear.

### Pitfall 4: Self-promotion rules vary by community and can get a post removed or an account restricted
**What goes wrong:** Reddit's Content Policy requires "authentic" participation and penalizes content manipulation; independent surveys of subreddit rules found 61% either ban self-promotion outright or only allow it under a 9:1 ratio (90% non-promotional activity to 10% promotional) [CITED: MEDIUM confidence, multiple marketing-blog sources converging on the same figure — see Sources]. Facebook groups commonly disallow self-promotion even via direct message to members [CITED, MEDIUM confidence].
**Why it happens:** Communities police for spam/growth-hacking because it degrades the community for existing members.
**How to avoid:** Check each specific subreddit's/group's current rules before posting (they change), post as a real ask ("I built this for myself, looking for testers") rather than an ad, and prefer channels where Joost already has standing (a club he's part of, a group he's a genuine member of) over cold posting into unfamiliar communities.
**Warning signs:** A post removed within minutes, or a moderator message about self-promotion — treat as a signal to stop, not to retry immediately.

### Pitfall 5: Assuming the LinkedIn "vacature" mechanism fits a volunteer-tester ask
**What goes wrong:** WERV-01 explicitly names this as a candidate channel worth checking, and the check reveals it does not fit: free job posts require a verified Company Page [VERIFIED: linkedin.com/help/a517777], cap at roughly 10-30 applications, auto-pause after 14 days, and surface to job-seekers searching by role/keyword — not to a personal network of cyclists.
**Why it happens:** "Vacature" reads like a plausible high-visibility LinkedIn mechanism, but LinkedIn Jobs is built for actual hiring, and Joost has no Company Page to attach it to.
**How to avoid:** Use a personal LinkedIn post/status update instead — same audience reach, zero setup cost, no application cap, no Company Page dependency.
**Warning signs:** N/A — this is a design-time decision, not a runtime failure; the recommendation above already resolves it.

## State of the Art

| Old requirement | Current requirement | When changed | Impact |
|---|---|---|---|
| 20 testers opted in for 14 days | 12 testers opted in for 14 continuous days | December 2024 [CITED: multiple sources converging, MEDIUM confidence] | Lower headcount bar, but... |
| Opt-in count alone was effectively sufficient | Google evaluates actual usage/session behavior during the 14 days via the production-access questionnaire and telemetry | Documented rejection wave from ~April 2026 onward [CITED: appconsolelab.com, testerscommunity.com, MEDIUM confidence — matches `REQUIREMENTS.md`'s own independently-recorded claim] | Raw opt-in count is no longer the binding constraint; genuine engagement is |

**Deprecated/outdated:** treating "12 opted-in testers" as the finish line. As of 2026, that number without matching usage is a documented rejection trigger, not a pass condition.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Personal LinkedIn post has a high activation rate among Joost's network | Summary, Channel Comparison Matrix | If overestimated, the "high-fit low-effort" channel underdelivers and the gap has to be covered by the weaker r/AndroidClosedTesting channel instead |
| A2 | Fiets-Facebookgroepen and Strava-clubs have "middel-hoog" activation rates | Channel Comparison Matrix | No direct evidence found for cycling-specific channels specifically (only general personal-contact-improves-retention research); if these channels underperform, volume planning needs r/AndroidClosedTesting to carry more weight than recommended |
| A3 | Colleagues largely overlap with the "9" already counted in TESTERS.md's own-circle estimate | Channel Comparison Matrix, Recommended Channel Mix | If colleagues are actually incremental (not already counted), this channel was dropped unnecessarily and could have added easy volume |
| A4 | TestersCommunity-app's "50,000+ developers" and general effectiveness claims are accurate | Channel Comparison Matrix | Source is the vendor's own marketing; if inflated, this channel offers less volume than it appears to, though it was already deprioritized as a backstop-only option |
| A5 | The reciprocal-testing ~17% activation floor from TESTERS.md's cited developer generalizes to r/AndroidClosedTesting broadly, not just that one developer's specific experience | Recommended Channel Mix, Pitfall 3 | If RideWindow's actual conversion is meaningfully higher (e.g., due to genuine reciprocity discipline), the channel could be weighted more heavily than recommended here |

## Open Questions

1. **Exact size of Joost's own LinkedIn network, Strava following, and any Dutch cycling Facebook groups he is already a member of**
   - What we know: the mechanisms and rules for each platform.
   - What's unclear: the actual numbers, which determine whether "reach now matters" tips any single channel above the others.
   - Recommendation: Joost checks his own connection/follower/membership counts directly (not verifiable from this research environment) before the planner finalizes the channel mix; this is a 5-minute manual check, not a blocker to writing the plan.

2. **Whether a specific NTFU-affiliated club or Facebook group is already within reach (an existing contact, not a cold approach)**
   - What we know: the NTFU itself has no open recruitment channel; individual affiliated clubs do, but require going through a board/admin.
   - What's unclear: whether Joost already knows someone on a relevant club's board, which would turn this from a "traag, hoge inspanning" channel into a fast one.
   - Recommendation: ask Joost directly during planning/discuss rather than researching further — this is personal-network knowledge, not researchable.

3. **Current self-promotion rule text for r/AndroidClosedTesting and r/TestersCommunity specifically**
   - What we know: the general pattern (join Google Group, download, test, comment with proof screenshot; some subs restrict self-promo to weekly threads).
   - What's unclear: the exact current wording, because Reddit is not fetchable from this research environment (see Environment Availability).
   - Recommendation: the planner should insert a manual verification step (visit the subreddit sidebar/wiki, or checkpoint:human-verify) immediately before drafting/posting, since these rules are known to change.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Reddit (www.reddit.com, www.redditinc.com) | Verifying current r/AndroidClosedTesting / r/TestersCommunity rules directly | ✗ — WebFetch blocked from this environment for both domains | — | Rely on cross-verified secondary developer write-ups (used above, MEDIUM confidence); planner should have Joost do a direct manual check before posting |
| Facebook (group search/browsing) | Sizing and identifying specific Dutch fiets-Facebookgroepen | ✗ — not indexed/browsable via WebSearch in a way that yields group membership numbers | — | Joost identifies specific groups himself (Open Question 1) |
| Google Play Console Help, LinkedIn Help | Verifying official policy (12 testers/14 days, job-posting eligibility) | ✓ — both fetched directly | current (2026) | — |

**Missing dependencies with no fallback:** none — both gaps above have a working fallback (secondary sources / manual human check).

## Sources

### Primary (HIGH confidence)
- [support.google.com/googleplay/android-developer/answer/14151465](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en) — official closed-testing requirements for new personal developer accounts: 12 testers, 14 continuous days, opt-out-before-14-days doesn't count, production-access questionnaire asks about feature usage and production-matching behavior
- [support.google.com/googleplay/android-developer/answer/9845334](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en) — official mechanics of setting up closed testing, opt-in link, Google Group requirement (must join group before opting in)
- [linkedin.com/help/linkedin/answer/a517777](https://www.linkedin.com/help/linkedin/answer/a517777) — official free job posting eligibility: requires a Company Page, 1 active free post at a time, 14-day visibility before pause, 10-30 application cap
- [linkedin.com/help/linkedin/answer/a521792](https://www.linkedin.com/help/linkedin/answer/a521792) and [a529397](https://www.linkedin.com/help/linkedin/answer/a529397) — job posts must be for bona fide roles, unpaid/volunteer roles must be clearly disclosed
- [support.strava.com/en-us/articles/15401655](https://support.strava.com/en-us/articles/15401655-club-posts) — admin posts appear in all members' feeds; non-admin posts appear only in club feed
- [partners.strava.com/resources/how-to-connect-with-your-members](https://partners.strava.com/resources/how-to-connect-with-your-members) — must mutually follow to invite non-members directly

### Secondary (MEDIUM confidence)
- [dev.to/vmzavas — How to Actually Get 12 Testers for 14 Days](https://dev.to/vmzavas/how-to-actually-get-12-testers-for-14-days-on-google-play-without-your-count-resetting-3n19) — developer first-hand account: friends/family "works once," reciprocal testing partnerships work best, recommends 14-15 committed testers for buffer
- [appconsolelab.com — production access rejection causes](https://appconsolelab.com/blog/apply-for-production-in-google-play-console-common-production-access-rejection-reasons-every-developer-should-avoid) — describes 2026 shift to engagement-based (not just opt-in-count) evaluation
- Multiple independent sources on the 9:1 Reddit self-promotion convention and Content Policy Rule 2 (authentic engagement) — [redship.io](https://redship.io/blog/reddit-self-promotion-rules), [karmaguy.io](https://karmaguy.io/en/blog/reddit-self-promotion-rules), [oneup.today survey of 49 subreddits](https://oneup.today/blogs/reddit-selfpromo-rules-study-2026) (found 61% ban or restrict self-promo)
- [ntfu.nl](https://www.ntfu.nl/) news items on club communication tooling (Cyql app, AllUnited ClubApp) — confirms NTFU itself doesn't run a member-facing recruitment channel, individual clubs do
- [wielerflits.nl](https://www.wielerflits.nl/fietstoerisme/wielersport-in-nederland-bezig-aan-ongekende-groei-ruim-15-miljoen-fietsers/) — ~1.5 million cyclists in NL per NTFU-cited figures (context on market size, not RideWindow-specific reach)
- NCBI/PMC papers on recruitment/retention in internet-based randomized trials — personal contact improves retention vs. fully automated recruitment (different domain, reasonable generalization)

### Tertiary (LOW confidence — vendor/commercial content, used only where independently corroborated or explicitly flagged)
- [testerscommunity.com](https://www.testerscommunity.com/) — vendor's own description of its credit system and "50,000+ developers" claim; commercial bias noted inline wherever cited
- [dev.to — comparison of methods to gather 20 testers](https://Dev.to/zmsoft/comparison-of-5-methods-to-gather-20-testers-and-what-to-use-422i) — general pattern confirmation only, not independently verified numbers

## Metadata

**Confidence breakdown:**
- Google Play policy mechanics: HIGH — fetched directly from official support.google.com pages
- LinkedIn job-posting mechanics: HIGH — fetched directly from official linkedin.com/help pages
- Channel-specific reach/effort/experience (Strava, Reddit communities, Facebook groups, NTFU): MEDIUM — cross-verified secondary sources, but RideWindow-specific numbers are unverified (ASSUMED, see Assumptions Log)
- Activation-rate estimates: LOW-MEDIUM — only one concrete data point exists (TESTERS.md's cited ~17% for reciprocal testing); other channels' rates are reasoned estimates, explicitly flagged ASSUMED

**Research date:** 2026-09-17
**Valid until:** ~30 days — Google's closed-testing policy and LinkedIn's job-posting rules are both known to have changed within the past year and could change again; Reddit-specific subreddit rules should be re-checked at execution time regardless of this document's age, since they were not independently verifiable here.
