---
quick_id: 260908-i4m
slug: play-release-v4-0-klaarzetten-en-uploads
date: 2026-09-08
status: complete
---

# Play-release v4.0 klaarzetten, en het uploaden uit handwerk halen

## Wat er nu staat

`1.0.25+26` is gebouwd, ondertekend en gecontroleerd: het gemergede manifest
zegt `versionCode=26` / `versionName=1.0.25`, en de AAB draagt `META-INF/UPLOAD.RSA`.
66 MB, op `build/app/outputs/bundle/release/app-release.aab`.

Uploaden is nu één commando in plaats van een gang door de console:

```bash
dart run tool/play_upload.dart --track internal \
  --notes en-US:release-notes/en-US.txt --notes nl-NL:release-notes/nl-NL.txt
```

## De vondst die het script vorm gaf

De 10 MB-grens uit STATE.md is niet het echte probleem — resumable upload lost
dat op en `googleapis` doet dat zelf. Het echte risico is **de verkeerde 66 MB
uploaden**: een build van vóór de laatste wijziging, of met een `versionCode`
die niet meer bij `pubspec.yaml` hoort. Dat merk je pas als een tester klaagt,
en dan staat het al op Play.

Daar zijn twee vangrails voor, en de scherpste bleek gratis: **AGP laat het
gemergede manifest naast de build staan**, op
`build/app/intermediates/packaged_manifests/release/.../AndroidManifest.xml`,
als gewone XML met `android:versionCode`. Dat is exact bewijs, vóór de upload,
zonder de protobuf-manifest in de AAB te hoeven ontleden.

De eerste opzet vergeleek de AAB-tijdstempel met die van `pubspec.yaml`. Dat
was te grof en bewees zichzelf meteen: het toevoegen van `googleapis_auth` als
dev-dependency maakte een volstrekt gezonde build "oud". De terugvalcontrole
kijkt nu naar `lib/` en `assets/` — wat werkelijk in de bundel komt.

## De tweede vondst, en die kwam van de testsuite

**`pubspec.yaml` is niet de enige plek waar de versie staat.** De in-app versie
is een constante in `lib/core/app_version.dart` — een bewuste keuze om
`package_info_plus` te vermijden, met de prijs uitgeschreven in de kop van dat
bestand. Die prijs werd hier geïnd: de eerste AAB was `versionCode=26` maar zou
in Profiel "1.0.24 (25)" tonen.

`test/core/app_version_test.dart` ving het precies zoals bedoeld, met een
foutmelding die naar het juiste bestand wijst. Fase 21 heeft twee sessies
verloren aan "welke build draait hier eigenlijk?"; een build die daarover liegt
maakt elk testersrapport onbetrouwbaar.

Daarom is er een **derde vangrail** bijgekomen: het script leest
`lib/core/app_version.dart` en weigert te uploaden als die niet met
`pubspec.yaml` overeenkomt. Redundant met de test, en dat is de bedoeling — het
script is de laatste poort vóór Play, en niemand garandeert dat de test net
gedraaid heeft.

De AAB is daarna opnieuw gebouwd. Die van 13:04 is vervangen door die van 13:12.

## Bestanden

| Bestand | Wat |
|---|---|
| `tool/play_upload.dart` | De edit-cyclus insert → upload → track → commit, met opruimen bij een fout |
| `tool/README-play-release.md` | De twee stappen die Joosts hand vragen, plus wat er nog niet bewezen is |
| `release-notes/{en-US,nl-NL}.txt` | Wat er tussen 1.0.24 en 1.0.25 veranderde, in beide talen, onder de 500 tekens |
| `pubspec.yaml` | `1.0.24+25` → `1.0.25+26`; `googleapis_auth` expliciet gemaakt |
| `lib/core/app_version.dart` | De in-app versie mee opgehoogd naar `1.0.25 (26)` |
| `.gitignore` | Vangnetregel voor `play-service-account*.json` |

## Verificatie

- `dart analyze tool/` — schoon.
- `flutter test` — 509 tests groen (na de app_version-fix; daarvóór faalde er
  precies één, en dat was de juiste).
- `--help`, `--dry-run`, onbekende optie, ongeldige status: alle vier het juiste
  gedrag en de juiste exitcode (0 / 66 / 64 / 64).
- De staleness-vangrail is **uitgelokt**, niet beredeneerd: `pubspec.yaml`
  tijdelijk op `+27` gezet, script stopte met "de gebouwde bundel draagt
  versionCode 26, pubspec.yaml zegt 27", daarna hersteld.
- De versie-vangrail is óók uitgelokt: `app_version.dart` tijdelijk terug op
  1.0.24 (25), script stopte met "de app toont zichzelf als 1.0.24 (25)".
- Release-notes worden ingelezen en de lengtegrens wordt gehandhaafd (de eerste
  versies waren 507 en 517 tekens en zijn ingekort).

## Wat níét bewezen is, en waarom

De vier API-aanroepen zelf. Daarvoor is een service-account-sleutel nodig, en
die vraagt twee rechtenwijzigingen op Joosts Google-account: een service-account
aanmaken in `my-project-joost` met een JSON-sleutel, en dat account uitnodigen
in Play Console onder *Users and permissions* met *Release to testing tracks*.
Beide staan uitgeschreven in `tool/README-play-release.md`.

Advies voor de eerste keer: `--track internal --status draft`, zodat een fout in
de console blijft staan en niet bij testers terechtkomt.
