---
quick_id: 260925-build-58-toestel-en-feedback
date: 2026-09-25
status: complete
---

# Build 58: toestel, web en nieuwe feedback

## Wat bewezen is

- Play internal serveert 1.0.47 (58). Op de Oppo stond eerst 57; de
  Play-update behield de installatie (`com.android.vending`) en de lokale
  gegevens. Er is niet gesideload en niets naar alpha gepromoveerd.
- Alleen een nieuw venster van zaterdag 26 september 08:00–10:00 is gebruikt:
  eerst lokaal gepland, daarna gedeeld met **een groep met alleen de eigenaar**.
  Op Home verscheen het als een georganiseerde groepsrit; de prullenbak
  vroeg om bevestiging. Na bevestiging was de kaart weg, kwam ook niet als
  solo-rit terug, en de drie bestaande ritten bleven staan. Geen rit van
  een ander, en niet Joosts oorspronkelijke probleemrit, is verwijderd.
- De PWA is pas hierna gedeployed vanaf main op 1.0.47+58. Het bestaande
  script bouwde `build/web`, uploadde hem, en mat lokaal en live dezelfde
  `main.dart.js`-MD5: `457908fe9d66949c15c4c13c95935521`.
- De #84-fix staat ook op `meldingen` (`4f525c7`), bovenop de bestaande
  #74/#77-commits. Gerichte widgettests **31/31** en de volledige
  `flutter test`-suite slagen. `flutter analyze` gaf **202 infos, nul errors
  en nul warnings** en verliet met code 1 vanwege die infos. De twee nieuwe
  `unnecessary_import`-infos zijn in de branch weggehaald; `dart analyze`
  op de twee nieuwe bestanden meldde daarna **geen issues**.

## Feedback die nu niet meer verdwijnt

- **#85:** een groepsrit met iemand delen die geen lid van de groep is.
- **#86:** voor precies één groepsrit meerijden zonder lid van de vaste
  groep te worden. Dit is niet simpelweg dezelfde knop als #85: de
  lidmaatschaps- en zichtbaarheidsrechten verschillen.
- **#87:** de groepsritkaart herhaalt deelnemersaantallen en zet
  persoonsstatussen zwaar in tekst; een tester vraagt om kortere labels
  en iconen. Niet blind tekst door kleur/iconen vervangen, want betekenis
  moet toegankelijk en in beide talen blijven.

De bron was de twee door Joost aangewezen screenshots van 25 september.
De gesprekken en persoonsnamen zijn niet aan git toegevoegd.

## Vondsten en grenzen

1. **Een groen testsuite-cijfer is niet hetzelfde als de toestelroute.**
   Home is op Play getest, inclusief het verwijderen van de cloudrit en
   de eigen planning. Ritdetail en vegen op Ritten zijn in widgettests
   gedekt, maar niet afzonderlijk op de Oppo gedaan. Een uitnodiging
   aan een werkelijk ander account is evenmin verstuurd.
2. **De app blokkeert #85 niet toevallig.** De kiezer laat groep óf losse
   maatjes toe. Een participant van buiten de groep krijgt door de huidige
   RLS geen toegang tot de groepsrit. #85/#86 vereisen dus eerst een
   productbeslissing over wat een gast precies mag zien; een extra
   clientknop alleen zou de belofte niet waarmaken.
3. **De branch mag build 58 niet opnieuw uitgeven.** Die code staat al op
   Play en web zonder de meldingenfeatures. Daarom is alleen de #84-fix
   overgenomen, niet de versie- en release-notitiecommit. Bij samenvoegen
   moet de volgende release een nieuw nummer en eigen notities krijgen.
4. **Play-updatebediening:** tijdens het zoeken is `Update all` per ongeluk
   geraakt en onmiddellijk geannuleerd. Daarna stonden nog 22 andere
   updates beschikbaar. Ridewindow was via Play al op 58. Gebruik een
   volgende keer de eigen Ridewindow-vermelding, geen bulkknop.

## Open

- #84 op de Oppo nog afzonderlijk via het ritdetail en Ritten bewijzen
  indien volledig end-to-end bewijs nodig is; nooit een bestaande
  gedeelde rit hiervoor verwijderen.
- `meldingen` is bijgewerkt maar **niet gemerged**; deze task bevat geen
  notificatie-release en geen versie 59.
