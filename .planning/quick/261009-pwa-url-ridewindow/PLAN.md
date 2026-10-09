# PWA-URL naar ridewindow.web.app

## Doel

De Flutter PWA krijgt `https://ridewindow.web.app` als vaste URL, zonder al
gedeelde links, bestaande PWA-installaties of de Google/Supabase-loginroute
te breken.

## Aanpak

1. Claim Firebase Hosting-site `ridewindow` in project `my-project-joost`.
2. Richt `firebase.json` op die site en laat de oude default-site bestaan met
   een 301-redirect naar hetzelfde pad op het nieuwe domein.
3. Zet App Links en gedeelde uitnodigings-/groepslinks om naar het nieuwe
   domein. Laat de oude Android-host nog als legacy host doorverwijzen; de
   nieuwe host krijgt eigen `assetlinks.json`.
4. Werk GitHub Actions, deployscript, OAuth/Supabase/documentatie en
   regressietests bij. Een OAuth- of Supabase-consolewijziging wordt alleen
   gedaan als daarvoor een aparte, expliciete consolehandeling nodig is.
5. Deploy eerst de nieuwe site en controleer HTTP-routing, App Links,
   versie-informatie en redirectgedrag. Verwijder de oude site niet.

## Hoe goedlopende apps dit doen

Google Maps en WhatsApp laten gedeelde links stabiel blijven werken nadat een
productnaam of domein verandert. Dat nemen we over: de oude URL blijft een
doorstuuradres. Anders dan een losse marketingredirect behouden we elk pad,
omdat `/invite/<code>` en `/group/<code>` echte deep links zijn.

## Open consolehandelingen

- Google Cloud OAuth: `https://ridewindow.web.app` als Authorized JavaScript
  origin toevoegen; de bestaande origin niet meteen verwijderen.
- Supabase Auth: nieuwe Site URL en Redirect URL toevoegen of omzetten,
  afhankelijk van de bestaande configuratie.
- OAuth-consentscherm: alleen de zichtbare projectnaam controleren; dit is
  geen automatisch gevolg van de Hosting-URL.

## Uitkomst

Firebase-site `ridewindow` is op 2026-10-09 aangemaakt en live gedeployed.
`my-project-joost` blijft als legacy-site bestaan met een padbehoudende 301.
De Android App Link-configuratie, gedeelde linkbases, CI-deploy en
release-documentatie wijzen nu naar `ridewindow.web.app`.

De Google OAuth-origin en Supabase URL-configuratie zijn bewust niet vanuit
deze sessie aangepast. Zonder die consolewijzigingen moet web-Google-login op
het nieuwe domein nog als open controle worden beschouwd.
