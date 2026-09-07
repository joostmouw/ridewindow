# Epic "Peloton" — stand van zaken

> Bijgewerkt 2026-09-07. Epic staat als **#62** in `BACKLOG.md`. Dit bestand is de werkstand;
> begin hier als je de draad oppakt.
>
> **Stand in één zin:** de hele lus werkt en een geaccepteerde rit is nu ook zichtbaar bij de
> genodigde (`3ff18ed`, gedeployd, nog niet visueel gecontroleerd op een toestel). Open: de
> eenzijdige maatjeslijst — zie punt 2 hieronder, één query beslist het.

## Wat Joost heeft gekozen (2026-09-03, niet opnieuw ter discussie stellen)

1. **Vrienden zijn de kern**, niet losse links. Uitnodigen voor een rit gaat vanuit je maatjeslijst.
2. **Eén gedeelde rit met deelnemers**, geen kopie per persoon. Verzet de eigenaar de tijd, dan
   schuift die bij iedereen mee. `planned_rides` blijft strikt persoonlijk en ongewijzigd.
3. **Peloton is een tab onder Rides**, naast "Mijn ritten" — geen eigen bottom-nav-ingang.
4. De Peloton-tab toont **verstuurde en ontvangen uitnodigingen**. "Wanneer kunnen wij allebei"
   (het snijvlak van roosters) komt later.

Afgeleide keuze van mij, met reden: **vriend worden gaat via een deellink/code, niet via zoeken op
e-mailadres.** Zoeken op adres laat je uitproberen welke adressen een account hebben, en dat lek is
achteraf niet te dichten.

## Wat er staat

| Onderdeel | Waar | Status |
|---|---|---|
| Schema, RLS, 4 functies | `supabase/migrations/0002_peloton.sql` | **toegepast op de live database** (2026-09-03) |
| Datalaag | `lib/services/peloton_gateway.dart`, `lib/domain/models/peloton.dart` | af |
| Codegenerator | `lib/domain/services/invite_code.dart` | af, 6 tests |
| Providers | `lib/providers/peloton_providers.dart` | af |
| Peloton-tab | `lib/features/peloton/peloton_tab.dart` | af |
| Uitnodigen vanaf een rit | `lib/features/peloton/invite_buddies_sheet.dart` | af |
| Deel-link `/invite/:code` | `lib/features/peloton/invite_landing_screen.dart` | af, routetest |

Commits `be63137` t/m `efa6f99`, alles op main en gepusht. Suite 470/470, analyze 0 errors.

## Wat op een toestel bewezen is (2026-09-03, live PWA, joostmouw@gmail.com)

- Peloton-tab uitgelogd toont de uitleg, geen fout — additief, zoals REQUIREMENTS.md regel 8 eist.
- `friend_profiles()` slaagt; grants en policies kloppen.
- Insert op `friend_invites` slaagt — code **YRG4GD6X** aangemaakt, geldig t/m ~17 september.
- `redeem_friend_invite()` draait en weigert je eigen code met de generieke melding.

## De tweeaccountstest — gedraaid op 2026-09-06, met toestemming voor `joost.oppo@gmail.com`

**Bewezen, en dit was het hele punt van de epic:**

- **Een echte vriendschap tussen twee accounts bestaat.** B (`joost.oppo@gmail.com`, "Joost Mouw")
  heeft code **YRG4GD6X** ingewisseld onder Rides → Peloton; B's maatjeslijst toont sindsdien A.
  `redeem_friend_invite()` doet dus werkelijk wat het belooft, tussen twee losse accounts.
- Inloggen met een tweede Google-account werkt vanaf de accountkiezer (chevron naast de
  GIS-knop); beide accounts staan op het toestel, er is geen wachtwoord aan te pas gekomen.
- Het "Different Google account"-dialoog verschijnt zoals `account_section.dart` het beschrijft.

**Nog niet bewezen, en geblokkeerd door een echte bug:** uitnodigen → accepteren → rit bij de ander
→ deelnemersteller. Zie de sectie hieronder.

**Hoe je tussen de accounts wisselt.** Bij inloggen met een ander account vraagt de app "Keep data"
of "Start fresh". **Keep data** laat de lokale data van het vórige account meereizen naar het
nieuwe — dat vervuilt elke test (B erfde zo Joosts profielnaam en heet in de app ook "Joost").
**Start fresh** is sinds `89d0c7a` de juiste keuze: die wist lokaal en laat de cloud de rest
herstellen. Vóór die commit was het destructief — zie punt 3 hieronder.

## De blokkade die er was: RLS weigerde de insert op `group_rides` — OPGELOST

Uitnodigen faalde met `new row violates row-level security policy for table "group_rides" (42501)`.

**Waarom dit lang onzichtbaar bleef.** De catch in `invite_buddies_sheet.dart` toonde
`pelotonCodeInvalid` — "die code werkt niet, hij kan verlopen zijn" — terwijl er in dat pad
helemaal geen code bestaat. Die melding wees naar de verkeerde oorzaak. Vervangen door een eigen
string (`pelotonInviteFailed`, EN + NL).

**De eerste diagnose was fout en is weerlegd.** Ik vermoedde ontbrekende policies; `pg_policies`
liet zien dat alle acht er gewoon stonden. Het herstelscript dat daarop gebaseerd was is verwijderd
zonder ooit gedraaid te zijn.

**De echte oorzaak.** `createGroupRide` doet `.insert(...).select()`, dus `INSERT ... RETURNING`, en
bij RETURNING past Postgres óók de SELECT-policy toe op de nieuwe rij. Die policy was
`is_ride_member(id)`, en die functie is `stable` en zoekt de rit op in `group_rides` zelf — in de
snapshot van het begin van de statement, waarin die rij nog niet bestaat. Dus `false`, dus
geweigerd. De insert-check `owner_id = auth.uid()` slaagde altijd al; het *teruglezen* faalde.

**De fix** (`supabase/migrations/0003_group_rides_select_own_row.sql`, door Joost gedraaid op
2026-09-07): de SELECT-policy krijgt een snapshot-vrije tak `owner_id = auth.uid()` vóór de helper.
Die leest de kolom van de rij die voorligt, zonder tabellookup.

**Les die breder geldt:** een `stable` SECURITY DEFINER-functie in een SELECT-policy ziet de rij niet
die in dezelfde statement wordt aangemaakt. Elke `.insert().select()` op een tabel waarvan de
SELECT-policy zo'n functie gebruikt, loopt hier tegenaan. `group_ride_participants` ontsnapt er
alleen aan doordat `inviteToRide` géén `.select()` doet.

## De lus is rond — en wat er onderweg stukging (2026-09-07)

Na de policy-fix (`0003_group_rides_select_own_row.sql`, door Joost gedraaid) is de hele keten op
het toestel doorlopen: **uitnodigen slaagt** ("Invitation sent"), B ziet de rit onder "Rides you
organise" met "Nobody has joined yet", **A krijgt de uitnodiging** ("From Joost, 17:00 – 20:00") en
kan hem accepteren. Dat is het bewijs dat de epic zocht.

Drie dingen werken daarna níét, en twee ervan zijn nieuw gevonden.

### 1. ~~Een geaccepteerde rit is bij de genodigde nergens te zien~~ — OPGELOST (`3ff18ed`)

Na "Join" verdween de uitnodiging uit "Invitations for you" en kwam hij nergens terug. Geen
renderfout maar een ontbrekende categorie: niet meer `invited` (dus weg uit `pendingRideInvites`),
niet van jou (dus niet in `ownedGroupRides`), en accepteren maakt met opzet geen `planned_rides`-rij.

**De fix.** `joinedGroupRides` (accepted, niet-eigenaar) als derde categorie, plus twee plekken waar
hij landt: een sectie "Ritten waar je aan meedoet" op de Peloton-tab, en Home onder PLANNED, daar
samengevoegd met je eigen ritten en gesorteerd op begintijd. Gedeelde ritten dragen de naam van de
organisator en hebben geen prullenbak — je gooit de rit van een ander niet weg. **"My rides" blijft
bewust persoonlijk**; de Peloton-tab ernaast draagt het gedeelde deel.

Vijf providertests leggen de afbakening vast (`test/providers/peloton_providers_test.dart`).
**Op het toestel bevestigd 2026-09-07 09:49**: Home toont de gedeelde rit onder PLANNED met "With
Joost", groeps-icoon en zonder prullenbak, boven de eigen zaterdagrit die zijn prullenbak wél heeft;
de Peloton-tab toont "RIDES YOU'RE JOINING". Daarmee is de belofte van de epic — "de rit verschijnt
bij de ander" — waargemaakt.

### 2. Maatjes zijn eenzijdig zichtbaar — SYMPTOOM OPGELOST (`ef391bf`), oorzaak deels open

**Wat de database zei** (query gedraaid 2026-09-07): vijf rijen in `public.profiles`, en
**joost.oppo staat er niet bij** — er is niets van 6 september, terwijl hij toen inlogde en het
scherm "Synced" toonde. Jacco (echte tester, ingelogd 07:59 diezelfde ochtend) staat er wél, mét
`user_name: 'Jacco'`.

**Dat verschil is de sleutel.** Jacco's rij ontstond doordat de app bij zijn eerste login zijn naam
wegschreef, en díé schrijving duwde de rij omhoog. Bij joost.oppo koos ik "Keep data", dus de lokale
naam stond al ingevuld, de naam-schrijfactie werd overgeslagen, en de rij ontstond nooit. **De
profielrij hing aan een toevallige bijwerking**, niet aan een pad dat ervoor bedoeld is.

**Uitgesloten:** de RPC. `migrate_account_data` is los getoetst tegen de live database met alle
veertien parameters en komt netjes tot zijn eigen `not authenticated`-controle (P0001) — de functie
bestaat, de handtekening klopt, en hij schrijft de profielrij onvoorwaardelijk. Ergens vóór dat punt
viel `onSignIn` uit, en `_runAccountSync` slikte dat in met alleen een `debugPrint`.

**Wat er nu staat.** `_ensureCloudProfileRow()` draait na elke sign-in: een blinde, idempotente
enqueue van de huidige profielstaat plus een drain. Dat repareert het symptoom ongeacht welke stap
faalde, en herstelt bestaande accounts bij hun eerstvolgende login — joost.oppo hoeft dus alleen
opnieuw in te loggen. Daarnaast toont de catch in `_runAccountSync` nu een melding, zodat een stille
mislukking niet meer als "Synced" wegkomt.

**Wat nog open is:** wélke stap in `onSignIn` faalde. Dat is nu wél waarneembaar geworden — bij een
volgende mislukking verschijnt er een melding in plaats van niets. Repareer de oorzaak pas als hij
zich laat zien; het vangnet maakt het niet urgent meer.

**Te bevestigen:** log opnieuw in als joost.oppo en controleer of hij daarna in Joosts maatjeslijst
verschijnt.

### 3. "Start fresh" wiste een echt weekrooster — opgelost (`89d0c7a`)

Bij het wisselen naar A koos ik "Start fresh" om te voorkomen dat B's lokale rit meereisde. Dat
wiste Joosts beschikbaarheid lokaal én in de cloud: `clearAll()` loopt via `save()`, die
`updatedAt` op nu stempelt en een upsert enqueuet. De reconcile haalt de cloud-rij daarna nooit
meer terug (lokaal lijkt nieuwer) en de outbox duwt de leegte omhoog. Free tier, dus geen backup.

Hersteld uit een uitgelogde kopie in de desktop-browser (`flutter.availability.blockedHours`, 120
uur, ma–vr `work`) — wat exact de preset "Weekends only" bleek. Gerepareerd in code met
`resetForAccountSwitch()`, dat de sleutel én de tijdstempel verwijdert en niets enqueuet, precies
zoals `ProfileRepository.resetToDefaults()` dat al deed. Met regressietest.

**Les voor de volgende accountwissel:** "Keep data" laat het vorige account zijn lokale data
meenemen naar het nieuwe (vervuilt de test), "Start fresh" was tot vandaag destructief. Sinds
`89d0c7a` is "Start fresh" de juiste keuze en herstelt de cloud de rest.

## Vallen waar ik in ben gelopen — niet opnieuw

**~~De PWA serveert een oudere build via zijn service worker.~~ Fout gediagnosticeerd — het was de
HTTP-cache, en dat is op 2026-09-06 opgelost (`d99b3bd`).** Firebase Hosting gaf `index.html`,
`flutter_bootstrap.js` en `main.dart.js` standaard `cache-control: max-age=3600`. Geen van die drie
draagt een hash in zijn naam, dus een toestel dat de app al geopend had bleef **een uur lang** de
oude code draaien — herladen, herstarten en zelfs Chrome's cache wissen hielpen niet. De service
worker trof geen blaam: Flutter serveert hier zijn *zelf-uitschrijvende* worker (784 bytes, hij
doet `registration.unregister()`), die cachet niets. Deze verkeerde verdenking heeft twee keer een
halve sessie gekost. `firebase.json` zet die drie nu op `no-cache, must-revalidate`; de ETag zorgt
dat een ongewijzigde bundel een 304 kost en geen 5,7 MB.

Blijft staan: **controleer bij een "werkt niet op de PWA" eerst of de code in de live bundel zit**
(`curl .../main.dart.js | grep ...`), vóór je in de broncode zoekt. Zit hij er wel in en zie je hem
niet, dan draait het toestel iets ouders — sinds de headerfix hoort dat niet meer voor te komen,
en als het tóch gebeurt is dát het signaal, niet een raadsel.

**Als je tijdens het debuggen een verse bundel moet forceren**, werkt dit deterministisch en in één
keer: geef de bestanden een nieuwe URL in plaats van tegen caches te vechten. Na `flutter build web`
in `build/web` de verwijzingen omschrijven naar `flutter_bootstrap.js?v=<ts>` (in `index.html`) en
`main.dart.js?v=<ts>` (in `flutter_bootstrap.js`), deployen, en de app openen op
`https://my-project-joost.web.app/?cb=<ts>`. Andere URL is een andere cachesleutel — geen wissen,
geen wachten, geen sessieverlies.

**Play loopt achter en dat is opzet.** De Play-build op het toestel is 1.0.23+24 en heeft geen
Peloton. Elke Play-release is handwerk (versie bumpen in `pubspec.yaml` **én**
`lib/core/app_version.dart`, AAB bouwen, uploaden, uitrollen) en kost 20+ minuten per iteratie
tegen ~3 voor de PWA. Batch een Play-release pas als de epic een testbare mijlpaal heeft.

**De deel-link opent de PWA, niet de native app.** Daarvoor zijn Android App Links nodig:
`assetlinks.json` op het domein met de SHA-256 van de Play-signing-sleutel plus intent filters. Half
uur werk, zinvol pas als Peloton in een Play-build zit.

## Openstaande punten

- ~~**`CLAUDE.md` klopt niet meer**~~ — **opgelost 2026-09-06.** De constraint noemt nu zes functies
  en waarom elk er staat. Het waren er zes, niet vijf: naast de vier `rpc()`-functies
  (`migrate_account_data`, `delete_own_account`, `friend_profiles`, `redeem_friend_invite`) telt ook
  de RLS-helper `is_ride_member` mee én de trigger-functie `set_updated_at` uit `0001`.
- **Privacybeleid**: een maatje ziet nu je naam en de ritten waarvoor je uitgenodigd bent. Dat staat
  nog niet in het gepubliceerde beleid.
- Namen worden gedenormaliseerd gekopieerd bij accepteren; wie later zijn naam wijzigt, blijft bij
  bestaande uitnodigingen onder de oude naam staan. Bewust, maar het wordt zichtbaar zodra iemand
  het opmerkt.
- **Volgende feature-slices staan nu uitgewerkt als epic #65 in `BACKLOG.md`** ("Peloton v2"),
  afgeleid uit een vergelijking met Partiful, Komoot, Howbout en Strava. Kern: nodig niet uit voor
  één rit maar voor de best scorende vensters van de week, en laat iemand meekijken zónder account.
  De volgorde begint bij de twee gaten hierboven — een geaccepteerde rit die nergens zichtbaar is,
  en de eenzijdige maatjeslijst. Het snijvlak van beider beschikbaarheid ("wanneer kunnen wij
  allebei") is daar slice 3; dat vereist dat A B's rooster mag lezen, de zwaarste RLS-vraag van het
  geheel, en is de reden dat het bewust nog niet gebouwd is.
