---
quick_id: 260908-i4m
slug: play-release-v4-0-klaarzetten-en-uploads
date: 2026-09-08
status: in-progress
---

# Play-release v4.0 klaarzetten, en het uploaden uit handwerk halen

## Waarom

Fase 23, 24 en 25 van v4.0 draaien op de Oppo en staan live op Firebase Hosting,
maar **niet één tester ziet er iets van**: `pubspec.yaml` staat nog op
`1.0.24+25` — exact de build die op 2026-09-07 naar internal testing ging. De
hele epic begon met "de app ziet er hetzelfde uit"; zolang die build daar staat
is die klacht nog steeds waar voor iedereen behalve Joost.

Tweede helft: STATE.md constateert op 2026-09-07 dat uploaden vanaf hier niet
kan (`file_upload` weigert 67 MB, grens is 10 MB; een AAB is niet te splitsen)
en noemt de Play Developer API als uitweg. Daar staat sindsdien "het script is
mijn deel en is nog niet geschreven". Dat lost deze taak op, zodat de volgende
release één commando is in plaats van een handmatige gang door de console.

## Taken

1. **Versie ophogen** — `pubspec.yaml` naar `1.0.25+26`. `versionCode` 26 moet
   hoger zijn dan de 25 die op Play staat, anders weigert Play de upload.
2. **`tool/play_upload.dart`** — Play Developer API v3 via `googleapis`
   (`androidpublisher/v3.dart`, al een dependency) plus `googleapis_auth` voor
   de service-account-credentials. Doet de hele edit-cyclus:
   `insert` → `uploads` (resumable, dus geen 10 MB-grens) → `tracks.update` →
   `commit`. Argumenten: `--track`, `--aab`, `--key`, `--notes`, `--dry-run`.
3. **`tool/README-play-release.md`** — de twee stappen die Joosts hand vragen
   (service-account in GCP, uitnodigen in Play Console) plus het commando.
4. **AAB bouwen** — `flutter build appbundle --release`, controleren dat hij
   ondertekend is en `versionCode=26` draagt.
5. **STATE.md** — het openstaande aanbod vervangen door wat er nu staat.

## Wat expliciet niet in deze taak zit

Het uploaden zelf. Stap 2 en 3 van de inrichting zijn rechtenwijzigingen op
Joosts Google-account; die kan ik niet doen en ga ik niet omzeilen. Het script
is getest tot aan de authenticatie — verder komt het pas met een sleutel.

## Verificatie

- `dart analyze tool/` schoon.
- `bundletool`/`unzip` bevestigt `versionCode=26` en een handtekening in de AAB.
- `dart run tool/play_upload.dart --help` en `--dry-run` draaien zonder sleutel.
