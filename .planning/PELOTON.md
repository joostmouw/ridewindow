# Epic "Peloton" — stand van zaken

> Bijgewerkt 2026-09-06. Epic staat als **#62** in `BACKLOG.md`. Dit bestand is de werkstand;
> begin hier als je de draad oppakt.

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

## Wat NIET bewezen is, en het enige dat er nog toe doet

**Een echte vriendschap tussen twee accounts.** Daar zijn twee accounts voor nodig. Twee routes:

- Joost stuurt YRG4GD6X naar iemand met de app; die vult hem in onder Rides → Peloton.
- Of Joost geeft toestemming om `joost.oppo@gmail.com` te gebruiken (staat op het toestel).
  **Niet ongevraagd doen** — inloggen met zijn tweede account is zijn keuze.

Daarna in één keer doortesten: uitnodigen vanaf de zaterdagrit → accepteren → rit verschijnt bij de
ander → uitnodiger ziet "1 fietser doet mee".

## Vallen waar ik in ben gelopen — niet opnieuw

**De PWA serveert een oudere build via zijn service worker.** Op 3 september gaf de app
`no routes for location: /invite/YRG4GD6X` terwijl `grep '/invite/:code'` op de live `main.dart.js`
gewoon een treffer gaf. Drie herlaadpogingen verder was het nog steeds de cache. **Controleer bij
een "werkt niet op de PWA" eerst of de code in de live bundel zit**, vóór je in de broncode zoekt.
Routes en andere pure-clientlogica horen in een lokale test, niet in een toestelsessie — daar meet
je de cache net zo hard als de code. Cache wissen: Chrome → Site-instellingen → `my-project-joost.web.app`
→ Clear & reset (wist wel de sessie).

**Play loopt achter en dat is opzet.** De Play-build op het toestel is 1.0.23+24 en heeft geen
Peloton. Elke Play-release is handwerk (versie bumpen in `pubspec.yaml` **én**
`lib/core/app_version.dart`, AAB bouwen, uploaden, uitrollen) en kost 20+ minuten per iteratie
tegen ~3 voor de PWA. Batch een Play-release pas als de epic een testbare mijlpaal heeft.

**De deel-link opent de PWA, niet de native app.** Daarvoor zijn Android App Links nodig:
`assetlinks.json` op het domein met de SHA-256 van de Play-signing-sleutel plus intent filters. Half
uur werk, zinvol pas als Peloton in een Play-build zit.

## Openstaande punten

- **`CLAUDE.md` klopt niet meer:** daar staat "één server-side functie". Het zijn er nu vijf
  (`migrate_account_data`, `delete_own_account`, `is_ride_member`, `redeem_friend_invite`,
  `friend_profiles`). Elke toevoeging is verantwoord in `0002_peloton.sql`, maar de constraint-tekst
  moet bijgewerkt worden zodat hij geen onwaarheid meer beweert.
- **Privacybeleid**: een maatje ziet nu je naam en de ritten waarvoor je uitgenodigd bent. Dat staat
  nog niet in het gepubliceerde beleid.
- Namen worden gedenormaliseerd gekopieerd bij accepteren; wie later zijn naam wijzigt, blijft bij
  bestaande uitnodigingen onder de oude naam staan. Bewust, maar het wordt zichtbaar zodra iemand
  het opmerkt.
- **Volgende feature-slice**: het snijvlak van beider beschikbaarheid ("wanneer kunnen wij allebei"),
  met de weerscore eroverheen. Dat vereist dat A B's rooster mag lezen — de zwaarste RLS-vraag van
  de epic, en de reden dat hij bewust nog niet gebouwd is.
