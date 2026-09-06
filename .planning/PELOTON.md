# Epic "Peloton" — stand van zaken

> Bijgewerkt 2026-09-06 (avond, na de tweeaccountstest). Epic staat als **#62** in `BACKLOG.md`.
> Dit bestand is de werkstand; begin hier als je de draad oppakt.
>
> **Stand in één zin:** vriendschap tussen twee accounts is bewezen; uitnodigen is geblokkeerd door
> een RLS-weigering op `group_rides`, en `supabase/migrations/0003_peloton_policy_repair.sql` staat
> klaar om in de Supabase SQL-editor gedraaid te worden.

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

**Hoe je veilig tussen de accounts wisselt.** Bij inloggen met een ander account vraagt de app
"Keep data" of "Start fresh". **Keep data** is de veilige keuze: die raakt Joosts lokale profiel en
beschikbaarheid niet aan. De prijs is dat het testaccount B Joosts profielnaam erft — B heet daarom
in de app ook "Joost", wat de maatjeslijst dubbelzinnig maakt. **Start fresh** wist lokaal profiel,
beschikbaarheid en geplande ritten; dat is herstelbaar zolang de cloud bij is (`save([])` schrijft
alleen SharedPreferences en enqueuet géén cloud-deletes, dus de rijen van het andere account
blijven staan), maar het leunt op een sync die compleet was. Niet doen zonder reden.

## De blokkade: RLS weigert de insert op `group_rides`

Uitnodigen faalt met:

```
PostgrestException(message: new row violates row-level security policy
for table "group_rides", code: 42501)
```

**Waarom dit lang onzichtbaar bleef.** De catch in `invite_buddies_sheet.dart` toonde
`pelotonCodeInvalid` — "die code werkt niet, hij kan verlopen zijn" — terwijl er in dit pad
helemaal geen code bestaat. Die melding wees naar de verkeerde oorzaak. Inmiddels vervangen door
een eigen string (`pelotonInviteFailed`, EN + NL).

**Wat het patroon zegt.** Alles wat wérkt loopt via `SECURITY DEFINER`-functies
(`friend_profiles()`, `redeem_friend_invite()`) en slaat RLS dus over. Dit is het eerste pad dat
echt op een policy leunt, en het is meteen raak. De policy in `0002_peloton.sql` klopt
(`with check (owner_id = auth.uid())`) en de app schrijft `owner_id` letterlijk uit
`auth.currentSession.user.id`. Postgres geeft deze fout in twee gevallen: de check is onwaar, óf er
geldt geen enkele insertpolicy. Het eerste kan hier niet — dus vermoedelijk staan de
`group_rides`-policies niet (volledig) op de live database, terwijl RLS er wél aan staat.

**Uitgesloten, dus niet opnieuw onderzoeken:** de tabellen bestáán (PostgREST geeft
`42501 permission denied`, niet `PGRST205 not found`), de tabelnamen in
`supabase_tables.dart` kloppen, de grants staan in de migratie, en `id` heeft
`default gen_random_uuid()`.

**De volgende stap is één ding:** `supabase/migrations/0003_peloton_policy_repair.sql` draaien in de
Supabase SQL-editor, met de controlequery onderaan dat bestand **vóór en ná**. Staan alle acht
policies er vooraf al, dan is de diagnose fout en moet de zoektocht verder — noteer dat hier.
Daarna de rest van de lus in één keer: uitnodigen → accepteren als A → rit verschijnt → teller.

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
- **Volgende feature-slice**: het snijvlak van beider beschikbaarheid ("wanneer kunnen wij allebei"),
  met de weerscore eroverheen. Dat vereist dat A B's rooster mag lezen — de zwaarste RLS-vraag van
  de epic, en de reden dat hij bewust nog niet gebouwd is.
