# Een release naar Play, in één commando

De plek van dit script in de hele release-route (lokale APK, PWA, internal,
closed) staat in `docs/RELEASE-ROUTE.md`; hieronder staat alleen wat het
script doet.

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
5. Twee vinkjes, niet één. Bovenaan in dat venster, onder **App access**:
   **View app information and download bulk reports (read-only)** — zonder een
   app-toegangsrecht blijft **Apply** grijs, met onderaan de uitleg "To apply
   permissions, select an app access permission". Daaronder, onder **Releases**:
   **Release apps to testing tracks**, genoeg voor internal, alpha en beta en
   expliciet géén productie. Staat dat vinkje grijs in plaats van wit, dan heeft
   het account het recht al via het tabblad **Account permissions** (admin), en
   moet dat er eerst af. Niet aanzetten: *Release to production,
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

## Promoveren zonder opnieuw te uploaden

Een build die op internal getest is, hoort naar de gesloten test te gaan als
*dezelfde bytes*. Opnieuw uploaden kan niet (Play weigert een bestaande
versionCode) en zou die garantie ook weggooien. Daarom:

```bash
dart run tool/play_upload.dart --list-tracks
dart run tool/play_upload.dart --promote 46 --track alpha \
  --notes en-US:release-notes/en-US.txt \
  --notes nl-NL:release-notes/nl-NL.txt
```

`--list-tracks` bestaat omdat de naam van een gesloten track niet te raden is:
"Alpha" in de Console heet `alpha` in de API, maar een zelfgemaakte track
krijgt een gegenereerde naam. Zonder die lijst is de Console de enige plek waar
je het kunt zien. De uitvoer toont meteen welke build op welke track staat:

```
  production   (leeg)
  beta         (leeg)
  alpha        1.0.35 (46) [46] completed
  internal     1.0.35 (46) [46] completed
```

Let op: een promotie naar een gesloten of open track gaat langs de review van
Google; internal niet. De testers zien de build dus niet meteen.

## Notities achteraf rechtzetten

Staat er een build al op een track en voldoet de tekst niet (bijv. de winkel
kapt een zin af), vervang dan alleen de notities — de bundel blijft liggen:

```bash
dart run tool/play_upload.dart --set-notes 48 --track internal \
  --notes en-US:release-notes/en-US.txt \
  --notes nl-NL:release-notes/nl-NL.txt
```

## Notitielengte — waarom 400 en niet 500

Play staat 500 tekens per taal toe, maar de winkel kapt zichtbaar af ver onder
die grens: notities van 475 en 486 tekens stonden op 2026-09-21 in de store
midden in een zin afgekapt. De tool weigert daarom notities boven 400 tekens.
Houd notities kort en volledig: complete zinnen, geen halve mededeling die in
de winkel als "…" eindigt.

## Opties

| Optie | Standaard | |
|---|---|---|
| `--track` | `internal` | `internal`, `alpha`, `beta`, `production` |
| `--status` | `completed` | `draft` als je in de console nog wilt kijken vóór uitrol |
| `--aab` | `build/app/outputs/bundle/release/app-release.aab` | |
| `--key` | `~/.config/ridewindow/play-service-account.json` | |
| `--notes` | — | `taal:pad`, herhaalbaar. Het script stopt boven 400 tekens (zie de paragraaf over notitielengte) |
| `--promote` | — | `--promote <versionCode>`: zet een bestaande build op `--track`, mét `--notes` |
| `--set-notes` | — | `--set-notes <versionCode>`: vervangt alleen de notities van een bestaande release op `--track` |
| `--list-testers` | — | Toont per track welke Google Group als testerlijst dient. Leest alleen |
| `--set-testers` | — | Zet de testerlijst van `--track` op de groepen uit `--group`. Vervangt wat er staat |
| `--group` | — | Een Google Group als testerlijst, herhaalbaar |
| `--dry-run` | — | Controleert alles en logt in, schrijft niets |
| `--force` | — | Negeert de staleness-vangrail |

## Naar productie: het recht dat er eerst ontbrak (opgelost 2026-10-11)

**Opgelost:** sinds vanavond staat 1.0.59 (70) ter review op productie
(volledige uitrol, alle landen). Het verhaal hieronder blijft staan: het
verklaart de 403, de vangrail die de edit opruimt, en de middenweg (het recht
er na de release weer afhalen).

Een promotie van 68 naar `production --status draft` faalde met:

```
✓ Track "production" wijst nu naar 68
✗ Mislukt: DetailedApiRequestError(status: 403, message: The caller does not
  have permission)
  Edit 07786028926852601464 is opgeruimd.
```

De edit is weggegooid, dus er staat niets half in de Console. **Wat dit wel en
niet betekent:**

- **Niet** dat het script of de sleutel stuk is: dezelfde aanroep zette 68
  seconden eerder op internal, en `--list-tracks` en `--list-testers` werken.
- **Wel** dat dit specifiek het productierecht mist. Dat is de bewuste keuze
  uit stap 5 van de inrichting hierboven: het account kreeg alleen *"Release
  apps to testing tracks"*, zodat een gelekt sleutel geen publieke release kan
  publiceren.
- De 403 komt pas bij de **commit**, niet bij het openen van de edit of het
  bijwerken van de track. Een `--dry-run` voorspelt dit dus niet: die stopt
  vóór de eerste schrijfactie. Reken erop dat je het pas weet als je het echt
  probeert, en dat dat veilig is omdat het script de edit opruimt.

**Zo zet je het recht aan (Joosts hand, een rechtenwijziging op zijn account):**

1. Play Console → **Users and permissions**.
2. Open de rij van `play-release-uploader@my-project-joost.iam.gserviceaccount.com`.
3. Tabblad **App permissions** → **Ridewindow**.
4. Onder **Releases**: zet *Release to production, exclude devices, and use Play
   App Signing* aan, naast het bestaande *Release apps to testing tracks*.
5. Opslaan. Rechten kunnen tot ~24 uur nodig hebben; meestal is het sneller.
6. Verifiëren: `dart run tool/play_upload.dart --promote 68 --track production
   --status draft --notes en-US:release-notes/en-US.txt --notes
   nl-NL:release-notes/nl-NL.txt`. Lukt hij, dan staat 68 als concept op
   productie en kun je in de Console de eenmalige instellingen nalopen.

**Daarna het recht weer weghalen** is de middenweg die de inrichting zelf
aanraadt: één release naar productie vraagt het één keer, en daarna kan de
sleutel weer niets publiek maken.

## Testerlijsten: alleen Google Groups, en internal kan niet via de API

```bash
dart run tool/play_upload.dart --list-testers
dart run tool/play_upload.dart --set-testers --track alpha \
  --group ridewindow-testers@googlegroups.com
```

Twee dingen die de API zelf zegt, en die het gedrag verklaren:

1. **Losse adressen bestaan hier niet.** De API-documentatie op het
   testers-endpoint zegt letterlijk *"Testers resource does not support email
   lists"*. Alleen Google Groups. Dat is ook waarom de groep in de Console de
   testerlijst *is* en niet een lijst ernaast: wie lid van de groep is, kan
   meedoen, en er valt niets over te zetten. Adressen één voor één toevoegen
   kan alleen in de Console.
2. **De internal-track is gemigreerd en de API mag er niet meer bij.** Op
   2026-10-11 gaf een schrijfpoging op internal:

   ```
   403 The internal track has been upgraded to use open or closed testing;
   switch back to communities-based testing before using the API for this track.
   ```

   `--list-testers` toont internal dus als "(geen testerlijst)" en een
   `--set-testers` erop faalt. De poging laat geen halve edit achter: het script
   gooit de edit weg als de API weigert.

   **En internal kent sowieso geen Google Groups.** Google's hulppagina
   (answer 9845334) beschrijft internal testers als een **e-maillijst**:
   "Create email list", adressen met komma's of een CSV. De keuze tussen "Email"
   en "Google Groups" staat alleen bij **closed testing**. Een internal test kan
   **maximaal 100 testers** hebben (closed: 2.000 per lijst, 200 lijsten).

   Let ook op deze regel uit diezelfde pagina, want hij is niet omkeerbaar
   zonder actie van de tester: *"A user who opts into your app's internal test
   is no longer eligible to receive an open or closed test."* Wie meegaat naar
   internal valt dus van alpha af tot hij zich daar opnieuw voor aanmeldt.

`production` is geen testtrack en heeft dus nooit een testerlijst; `--list-testers`
toont dat als "(geen testtrack)" in plaats van te knallen op de 400 die de API
daarvoor teruggeeft.

## Wat er bewezen is

Op 2026-09-20 is 1.0.34+45 hiermee naar internal gegaan: de hele edit-cyclus
(`insert` → bundel van 66,2 MB resumable geüpload → track bijgewerkt →
`commit`), met release-notes in en-US en nl-NL. Daarmee is de route compleet
gedraaid en is handwerk in de console niet meer nodig.

Eerder waren alleen de argumenten, de staleness-vangrail (uitgelokt met een
afwijkende `versionCode`) en het inlezen van de release-notes gedraaid. Twijfel
je bij een release, dan blijft `--status draft` de veilige eerste stap: dan komt
hij in de console te staan en niet meteen bij testers.
