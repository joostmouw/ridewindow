# PWA-URL naar ridewindow.web.app

Datum: 2026-10-09.

## Resultaat

- Firebase Hosting-site `ridewindow` aangemaakt in project
  `my-project-joost`.
- `https://ridewindow.web.app` serveert de Flutter PWA.
- `https://my-project-joost.web.app` blijft bestaan en geeft een 301 naar
  hetzelfde pad op de nieuwe site:
  - `/` → `https://ridewindow.web.app/`
  - `/invite/ABCD2345` → `https://ridewindow.web.app/invite/ABCD2345`
  - `/group/ABCD2345` → `https://ridewindow.web.app/group/ABCD2345`
- `assetlinks.json` is live op het nieuwe domein en valideert als JSON.
- De live PWA serveert `version.json` voor 1.0.54 / build 65.

## Code en documentatie

- Firebase multisite-configuratie met targets `ridewindow` en `legacy`.
- CI deployt beide hosting-sites.
- App Links, Android `asset_statements` en gedeelde maatjes-/groepslinks
  gebruiken de nieuwe host.
- Regressietests, release-route, OAuth-runbook en WebAPK-meettool bijgewerkt.
- Oude links blijven werken door de legacy-redirect; de oude site is niet
  verwijderd.

## Verificatie

- `flutter test`: **1087 tests groen**.
- Gerichte URL-/App-Link-tests groen.
- `flutter build apk --release`: geslaagd.
- `flutter build web --release`: geslaagd.
- Firebase dry-runs voor beide targets geslaagd.
- Live HTTP-controle voor oude redirects, nieuwe routes en `assetlinks.json`
  geslaagd.
- `flutter analyze`: geen errors of warnings; de bestaande 214 infos blijven
  de baseline.
- Workflow YAML parseert correct.

## Open

- Voeg in Google Cloud Console `https://ridewindow.web.app` toe als
  Authorized JavaScript origin. Houd de oude origin tijdens de migratie.
- Controleer/zet in Supabase Auth de Site URL en Redirect URLs voor het nieuwe
  domein.
- De nieuwe Android App Link-host zit in de bron en de release-APK, maar wordt
  pas door testers herkend na een volgende Play-release. De huidige Play-build
  herkent de oude host nog; die blijft werken via de bestaande App Link en
  redirect.
