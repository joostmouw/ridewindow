# 1.0.54 (65) staat op Internal testing en de PWA

Datum: 2026-09-30. Releasebron: `adaf0c7`, gepusht naar origin/main.
Joost heeft zowel internal als PWA en GitHub-push goedgekeurd.

## Uitrol

- AAB gebouwd met 1.0.54+65; Play-dry-run controleerde versienummer,
  actuele build en beide release-notities.
- Upload via `tool/play_upload.dart` geslaagd, inclusief servercontrole
  van versionCode 65, bijwerken van internal en doorvoeren van de edit.
- De daaropvolgende `--list-tracks` bevestigt:
  **internal 1.0.54 (65), completed**; **alpha 1.0.53 (64), completed**.
  Beta en production zijn leeg. Geen promotie naar alpha.
- GitHub Actions `36774805008` heeft Firebase Hosting gepubliceerd vanaf
  `adaf0c76e2b6b0741be914ef4365243513c067e7`, status success.
  Geen lokale Hosting-deploy die met CI kon racen.
- Live `version.json` bevestigt version 1.0.54 / build_number 65.
  De live `main.dart.js` bevat 1.0.54 driemaal en nergens de oude 1.0.53.

## Test- en buildbewijs

- Volledige gecommitteerde testboom: **1087/1087 groen**.
  Uit `git archive HEAD test` naar een tijdelijke map, met de actuele
  versieconstanten in de repo. Tijdens het voorbereiden waren twee lokale
  testbestanden door ander werk gewijzigd; die zijn niet overschreven of
  meegenomen. Bij de latere statuscontrole waren die wijzigingen weer weg,
  zonder restore/stash door deze releasetaak.
- Analyze: **0 errors, 0 warnings, 214 infos**, dus niet geheel lint-schoon.
- `flutter build appbundle --release` en `flutter build web --release`:
  geslaagd. AAB 71,5 MB (68,2 MiB volgens de uploader).
- AAB SHA-256:
  `eeaf9f0850ddab45314917d121dc2ea3136a412104dcfd8eddb133172ca5df2d`.
- Beide release-notities bevatten volledige zinnen onder 400 tekens:
  Engels 293, Nederlands 294.
- De bekende Cupertino-font- en toekomstige Kotlin-pluginwaarschuwingen
  blijven zichtbaar in de builds, niet gerepareerd in deze releasetaak.
- Logs: `/tmp/ridewindow-release65-{tests,analyze,aab-build,web-build}.log`.
  PWA-bewijs: `/tmp/ridewindow-release65-pwa-verification.json`.

## Wat de webcontrole wel en niet bewees

De PWA-build uit CI heeft MD5 `3a232e3e59889f2f95e3ec4bb878fc80`; de lokale
webbuild heeft `f7b64a53388b266eec27dd86e99f717b`. Deze zijn niet bytegelijk.
Niet alsnog lokaal gedeployd om die vergelijking geforceerd groen te maken.
De oorzaak van het verschil is niet onderzocht. Het bewijs voor dezelfde
bron is de geslaagde CI-run op de releasecommit; metadata en de versie in de
daadwerkelijk geserveerde appbundel zijn apart gecontroleerd.

## Open controle en grenzen

`adb devices -l` gaf geen aangesloten toestel. Geen sideload, geen
accountrechten gewijzigd en geen handmatige Google-login overgenomen.
De laatst bewezen Oppo-versie blijft 64 totdat een nieuwe toestelmeting
anders zegt. Na de normale Play-update naar 65 moeten de permissievraag,
kleine profielweergave, achtergrondaflevering, tijdzone en melding openen
nog worden bewezen.

Meldingen staan standaard uit. Op Android kies je in Profiel 5/10/20
procentpunt; de controle volgt de lokale voorgrond- en achtergrondrefresh.
Geen directe serverpush en geen gesloten-webpush gebouwd of beloofd.

De ongetrackte foto's, active-workstream en remote-Droid-taak blijven
ongemoeid en buiten deze releasecommits. STATE is bijgewerkt omdat de
releaseprocedure de actuele kanalentabel daar verplicht stelt.
