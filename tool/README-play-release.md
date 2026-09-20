# Een release naar Play, in één commando

```bash
flutter build appbundle --release
dart run tool/play_upload.dart --track internal \
  --notes en-US:release-notes/en-US.txt \
  --notes nl-NL:release-notes/nl-NL.txt
```

Dat is het, zodra de inrichting hieronder eenmalig is gedaan.

## Waarom dit script bestaat

De AAB is ~66 MB. Het uploadgereedschap van een Claude-sessie weigert alles
boven 10 MB, en een AAB is niet te splitsen — dat is op 2026-09-07 echt
geprobeerd, niet beredeneerd. Daardoor was elke release handwerk in de Play
Console. De Play Developer API kent die grens niet: hij uploadt *resumable*, in
brokken van 8 MB.

## De inrichting — twee stappen die jouw hand vragen

Beide zijn rechtenwijzigingen op jouw Google-account. Ik kan ze niet doen.

### 1. Service-account met een sleutel

1. Play Console → **Setup → API access**. Koppel het Google Cloud-project
   (`my-project-joost`) als dat er nog niet staat, en zet de
   *Google Play Android Developer API* aan.
2. Klik **Create new service account**. Je komt in Google Cloud IAM uit.
   Naam bijv. `play-release-uploader`. Een IAM-rol is hier **niet** nodig — de
   rechten komen uit stap 2, uit Play zelf.
3. Op het service-account: **Keys → Add key → Create new key → JSON**. Bewaar
   het gedownloade bestand als:

   ```
   ~/.config/ridewindow/play-service-account.json
   ```

   Buiten de repo, bewust. (`.gitignore` heeft een vangnetregel, maar de
   standaardplek zorgt dat het niet nodig is.) Een andere plek kan met `--key`
   of met `$PLAY_SERVICE_ACCOUNT_JSON`.

### 2. Het service-account rechten geven in Play

Google Cloud maakt de identiteit en de sleutel, maar Play Console kent ze nog
niet: zonder deze stap weigert de API elke aanroep met 401/403. Klik-voor-klik
(namen nagekeken tegen Google's eigen documentatie, 2026-09-20; in de
Nederlandse console heten ze ongeveer hetzelfde):

1. **Users and permissions** — direct:
   `https://play.google.com/console/users-and-permissions`
2. Rechtsboven: **Invite new users**.
3. Plak het `client_email` uit de JSON
   (`...@my-project-joost.iam.gserviceaccount.com`) in het e-mailveld.
   Vervaldatum leeg laten, anders stopt uploaden op een dag zomaar.
4. Tabblad **App permissions** — niet Account permissions, dat geldt voor alle
   apps — dan **Add app** → **Ridewindow** → **Apply**.
5. Alléén het vinkje bij **Release apps to testing tracks**: genoeg voor
   internal, alpha en beta, en expliciet géén productie. "View app information
   (read-only)" mag al aan staan. Niet aanzetten: *Release to production,
   exclude devices, and use Play App Signing* — lekt de sleutel, dan kan de
   houder niets verder dan test-tracks van deze ene app.
6. **Invite user**. Een service-account krijgt geen mail en accepteert niets;
   de machtiging staat meteen. (Naar productie uploaden kan later, met een
   bewuste tweede uitnodiging met het productierecht.)

Rechten hebben tot ~24 uur nodig om door te werken. Krijg je vlak na het
uitnodigen een 401 of 403, wacht dan even; dat is geen fout in het script.

### Als de 403 blijft: maak de uitnodiging opnieuw

Op 2026-09-20 hield `The caller does not have permission` aan, ook na wachten en
zelfs na admin-rechten. De oorzaak: het service-account was in Cloud verwijderd
en opnieuw aangemaakt (eerst met een typefout in de naam). Play bindt zo'n rij
aan de identiteit, niet aan de tekst van het adres. Een opnieuw aangemaakt
account met hetzelfde e-mailadres is een ándere identiteit, dus de rechten
landen op niemand en er is aan de rij niets bijzonders te zien. Rechten
bijstellen helpt niet: **haal de rij weg met *Remove access* en nodig hetzelfde
adres opnieuw uit.**

Scheelt veel gokwerk bij een 403: roep `edits.insert` aan op een package dat
zeker niet bestaat en vergelijk. Krijg je daar een 404 *Package not found* en op
`ridewindow.joost.amsterdam` een 403, dan bestaat de app en ligt het puur bij de
rechten van dit account. Twee keer dezelfde 403 wijst naar de sleutel of de API.

## Wat het script doet, en wat het weigert

Eén Play-*edit* van begin tot eind: `insert` → bundel uploaden → track
bijwerken → `commit`. Gaat er iets mis halverwege, dan wordt de edit
weggegooid, zodat er geen halve release in de console blijft staan.

Er zitten twee vangrails in, allebei omdat 66 MB uploaden en het pas achteraf
merken duur is:

- **Voor de upload** leest hij de `versionCode` die Gradle in de build heeft
  gezet en houdt die naast `pubspec.yaml`. Lopen ze uiteen, dan stopt hij. Staat
  dat gemergede manifest er niet (schone checkout), dan valt hij terug op:
  is er iets in `lib/` of `assets/` gewijzigd ná de build?
- **Na de upload** controleert hij wat Play zelf uit de bundel las. Wijkt dat
  af, dan wordt de edit weggegooid in plaats van doorgevoerd.

`--force` zet de eerste vangrail uit. De tweede niet — die is een feit, geen
vermoeden.

## Opties

| Optie | Standaard | |
|---|---|---|
| `--track` | `internal` | `internal`, `alpha`, `beta`, `production` |
| `--status` | `completed` | `draft` als je in de console nog wilt kijken vóór uitrol |
| `--aab` | `build/app/outputs/bundle/release/app-release.aab` | |
| `--key` | `~/.config/ridewindow/play-service-account.json` | |
| `--notes` | — | `taal:pad`, herhaalbaar. Play kapt af op 500 tekens; het script stopt eerder |
| `--dry-run` | — | Controleert alles en logt in, schrijft niets |
| `--force` | — | Negeert de staleness-vangrail |

## Wat er bewezen is

Op 2026-09-20 is 1.0.34+45 hiermee naar internal gegaan: de hele edit-cyclus
(`insert` → bundel van 66,2 MB resumable geüpload → track bijgewerkt →
`commit`), met release-notes in en-US en nl-NL. Daarmee is de route compleet
gedraaid en is handwerk in de console niet meer nodig.

Eerder waren alleen de argumenten, de staleness-vangrail (uitgelokt met een
afwijkende `versionCode`) en het inlezen van de release-notes gedraaid. Twijfel
je bij een release, dan blijft `--status draft` de veilige eerste stap: dan komt
hij in de console te staan en niet meteen bij testers.
