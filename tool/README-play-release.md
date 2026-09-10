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

Play Console → **Users and permissions → Invite new user**. Plak het
`client_email` uit de JSON (`...@my-project-joost.iam.gserviceaccount.com`),
beperk tot **Ridewindow**, en vink aan:

- *Release to testing tracks* — genoeg voor internal, alpha en beta.
- *Release to production* — alleen als je ook naar productie wilt kunnen
  uploaden.

Rechten hebben tot ~24 uur nodig om door te werken. Krijg je vlak na het
uitnodigen een 401 of 403, wacht dan even; dat is geen fout in het script.

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

## Wat er nog niet bewezen is

Alles tot en met de authenticatie is gedraaid: argumenten, de staleness-vangrail
(uitgelokt met een afwijkende `versionCode`), het inlezen van de release-notes,
en `dart analyze` is schoon. De vier API-aanroepen zelf zijn nooit uitgevoerd —
daarvoor is de sleutel uit stap 1 nodig. Draai de eerste keer met
`--track internal --status draft`, zodat een fout in de console blijft staan en
niet bij testers terechtkomt.
