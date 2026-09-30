# Release 1.0.54 (65): actuele ritscores en dalingsmeldingen

Datum: 2026-09-30. GSD quick volgens de Droid-werkwijze in AGENTS.md.

## Opdracht en toestemming

Joost vraagt de huidige wijzigingen naar Google Play Internal testing te
brengen. Hij heeft daarna expliciet ingestemd met de gekoppelde PWA-uitrol
en GitHub-push. Geen alpha-/productiepromotie en geen sideload.

Play `--list-tracks` bevestigt vooraf internal 64 en alpha 64.
main bevat de scorefix `6ebf85d`, meldingen `16d476c` en twee
onderzoeksnotities. De release wordt 1.0.54+65.

## Stappen

1. Verhoog de versie in pubspec en app_version samen. Schrijf korte volledige
   releasezinnen in Nederlands en Engels, beide onder de 400 tekens.
2. Draai de volledige gecommitteerde tests en analyze op baseline. Twee
   testbestanden zijn na de eerdere commits lokaal gewijzigd door ander werk:
   niet overschrijven of meeliften in de commit. Gebruik een tijdelijke kopie
   van de gecommitteerde testboom voor deze controle.
3. Controleer staged diff/status en commit de releasevoorbereiding. Bouw AAB
   en web vanaf deze broncode. Controleer de upload zonder te publiceren.
4. Push main naar origin: de bestaande GitHub Actions-workflow publiceert
   de PWA. Geen tweede lokale Hosting-deploy die met CI kan racen.
5. Upload de AAB naar `internal` met beide release-notities. Controleer
   daarna de Play-tracks, CI-status en live `version.json` op build 65.
6. Leg de echte uitkomsten vast in SUMMARY en de verplichte release-tabel
   in STATE. Blijf expliciet over de ontbrekende Oppo-controle.

## Interacties en goede apps

Geen nieuwe interactie ontworpen in deze releasetaak. Het gedrag en de
vergelijking met goedlopende apps staan in het plan
`260930-actuele-ritscores-en-meldingen/PLAN.md`.

## Grenzen

- Alleen eerder gecommitteerde appwijzigingen en deze releasevoorbereiding.
  De ongetrackte foto's, active-workstream en remote-Droid-taak blijven buiten
  de releasecommits, net als de nieuwe lokale testwijzigingen.
- Gebruik de bestaande uploadidentiteit zonder sleutels te tonen of te
  wijzigen. Geen wijzigingen aan accountrechten.
- De dalingsmelding loopt lokaal bij voorgrondwijzigingen en de bestaande
  drie-uursachtergrondtaak; geen directe serverpush en geen gesloten-webpush.
- Geen claim dat installatie of achtergrondaflevering op de Oppo is bewezen.
