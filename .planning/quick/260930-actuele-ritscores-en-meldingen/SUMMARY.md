# Geplande scores volgen weer en voorkeuren; dalingsmeldingen zijn instelbaar

Datum: 2026-09-30. Lokaal op main, nog geen release, push of deploy.

## Wat er fout was

Home las alleen de historische `plannedScore`. Ritten en detail namen een
uur-gemiddelde zonder trend-, wind- en daglichtcorrectie. Detail las bovendien
de actuele gegevens zonder ze te volgen, en delen, agenda-export en de
weeruitleg bleven de route-argumenten van het openen gebruiken.

`RideWindowScorer` berekent nu een volledig bestaand tijdvak met dezelfde
correcties als suggesties. Beschikbaarheid, dedup, favoriete duur en de
ondergrens van 50 mogen een gepland tijdvak niet wegnemen. Ontbreekt één uur,
dan is er geen actuele score; de historische planscore blijft onaangeraakt.

Sweep: Home-plankaarten + openen detail, Ritten + voorgelegde vensters,
detail + gewijzigde start/eindtijd, uitleg, deeltekst en Google Agenda-export.
De uurkleuren in Agenda blijven terecht uur-scores, geen vensterscores.
Scorefix: `6ebf85d`.

## Meldingen

- Profiel biedt een expliciete lokale opt-in, standaard uit. Drempel:
  5, 10 of 20 procentpunt; bij inschakelen standaard 10.
- De eerste controle stelt de vergelijking in. Daarna tellen kleine dalingen
  cumulatief op. Bij aflevering wordt die score de nieuwe vergelijking;
  dezelfde voorspelling meldt niet nogmaals. Verbetering verhoogt de referentie.
- Eigen instelling, locatie, account, drempel of ritvenster veranderd:
  opnieuw vergelijken vanaf de nieuwe score, geen valse weerswaarschuwing.
- Alleen nog niet gestarte eigen, georganiseerde en geaccepteerde ritten.
  Geen open uitnodigingen of afzeggingen.
- Dezelfde controle loopt bij voorgrondwijzigingen en na de drie-uurs
  WorkManager-weerrefresh. De cache bevat alleen rit-id/tijdvak en vergelijking,
  geen deelnemersnamen. Geen nieuwe cloudrij, migratie of servercode.
- De lokale gedeelde ritten zijn de laatst bekende plannen. Als iemand een
  gedeelde rit op de server verzet/afzegt, weet de achtergrondcontrole dat pas
  na een volgende voorgrond-sync. Dit is niet dezelfde belofte als echte push.
- `340834a` uit de bestaande tak `meldingen` is als werk overgenomen:
  pluginregistratie + tijdzone in de isolate, terugval op de bewaarde IANA-zone,
  gedeelde scheduler voor de oude drie herinneringen. #77 (uitnodigingspoller
  en authenticatie-operaties) is bewust niet overgenomen; die tak blijft bestaan.
- Achtergrond-suggesties kregen ook de daglichtcorrectie, die daar ontbrak.
- Opnieuw plannen annuleert alleen de drie vaste herinnerings-id's; anders
  verdween een zojuist getoonde dalingsmelding meteen door `cancelAll()`.
- De meldingsdatum initialiseert ook in de isolate haar intl-locale-data.
- Uitzetten annuleert bestaande dalingsmeldingen ook zonder geladen weer.
- Web legt de grens uit in Profiel: actuele scores wel, meldingen bij een
  gesloten webapp nog niet. Geen decoratieve schakelaar.

## Twee extra stille meldingsfouten in de sweep

De herinneringsknop op detail vroeg geen toestemming, initialiseerde de plugin
niet en zei ook bij een al verstreken avond "ingesteld". Nu een expliciete
toestemmingsflow, foutmelding en tijdcontrole. Op web is die niet-werkende knop
weg. Profiel initialiseert de plugin ook vóór zijn oude herinneringsplanning.

Tests maakten twee eigen aannames zichtbaar:

- `makeSlot(start: ...)` hield zijn einde vast op juni 2026. Een datum in 2020
  maakte een rit van zes jaar en hing de daglichtberekening op; de fixture
  gebruikt nu vier uur vanaf zijn start. Geen aangetoonde productiebug.
- De linktests vonden de onderste sectie alleen zolang hij binnen de bouwcache
  van een 3000 px hoog Profiel stond. Meer instellingen duwden hem eruit.
  Ze scrollen nu vóór het zoeken/tikken, en toetsen nog dezelfde link/foutflow.

## Verificatie

- Volledige `flutter test`: **1087/1087 groen**.
- `flutter analyze --no-fatal-infos`: **0 errors, 0 warnings, 214 infos**.
  De standaard analyze blijft door de info-lints niet op exit 0; niet als
  volledig lint-schoon presenteren.
- `flutter build web --release`: groen, inclusief Wasm dry run.
- `flutter build apk --release`: groen, APK 74,2 MB.
- Builds melden de Cupertino-fontfamilie zonder meegeleverde asset en de
  toekomstige incompatibiliteit van plugins met Built-in Kotlin. Niet aangepakt
  als onderdeel van deze taak.
- Generators melden bestaande SDK/json_annotation-constraints en dat
  `--delete-conflicting-outputs` tegenwoordig wordt genegeerd.
- `adb devices -l`: geen toestel. Geen sideload, geen wisactie en geen
  menselijke Google-login overgenomen.

**Nog te bewijzen op de Oppo, na een normale Play-update:** permissievraag,
dalingsmelding ontvangen met de app dicht, tijdzonepeiling in WorkManager,
melding aanklikken en wijzigingen op de echte kleine profielweergave.
Android kan het drie-uurswerk verder uitstellen. Echte webpush vereist eerst
een bewuste herziening van de servercodegrens.

De versie blijft 1.0.53+64: dit zijn lokale builds voor validatie, geen nieuwe
uitgebrachte build. Voor een release beide versievelden samen ophogen en de
normale internal/web/toestel/alpha-route volgen.

## Overige instructies in deze sessie

- Komoot is als **toekomstig onderzoek** vastgelegd in backlog #89, gekoppeld
  aan #23/#24/#65. Zie de aparte taak `260930-komoot-groepsplanning`.
- Op Joosts exacte verzoek draait `droid daemon --remote-access`. Factory-docs
  en de CLI-help nagekeken: relayverbinding, geen openbare luisterpoort.
  Daemon-PID 78796 was bij de eindcontrole actief. Geen secrets vastgelegd.
- De al aanwezige foto's en `.planning/active-workstream` zijn ongemoeid.
  Tijdens de sessie verscheen ook de ongetrackte map
  `.planning/quick/260930-remote-droid-mac-mini/`; dat is ander werk en blijft
  buiten deze commits.
