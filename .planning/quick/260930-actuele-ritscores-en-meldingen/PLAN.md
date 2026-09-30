# Actuele ritscores en meldingen bij verslechtering

Datum: 2026-09-30. GSD quick-werkwijze via de Droid-ingang in AGENTS.md:
eerst dit plan, dan samenhangende wijzigingen met tests, daarna SUMMARY.

## Vraag en bevindingen

Joost ziet dat geplande ritten op Home hun oude score houden, ook bij andere
temperatuurvoorkeuren of nieuw weer. Hij wil een instelbare melding bij een
daling van bijvoorbeeld vijf of tien procentpunt.

- Home leest uitsluitend `RideEntry.plannedScore`.
- Ritten en detail nemen het gemiddelde van de uren, zonder trend-, wind- en
  daglichtcorrectie. Detail leest de providers bovendien zonder ze te volgen.
- `plannedScore` blijft de historische planscore, niet de actuele score.
- Tak `meldingen` heeft onafgerond werk voor #74 en #77. Hergebruik #74
  (tijdzone in de isolate en opnieuw plannen), niet ongevraagd de
  uitnodigingspoller van #77 of diens wijzigingen aan de authenticatie.

## Hoe goedlopende apps dit oplossen

- WhatsApp en Strava bieden meldingscategorieën in instellingen. Neem een
  expliciete opt-in over en vraag systeemtoestemming pas bij inschakelen,
  niet bij het openen van de app.
- Google Maps koppelt een waarschuwing aan een concrete gewijzigde reis:
  benoem datum/tijd en oude/nieuwe score, niet alleen "het weer is slechter".
- Neem geen herhaalde waarschuwingen voor dezelfde wijziging over. Bewaar een
  lokale vergelijkingsscore en meld pas bij een volgende volledige daling.
- Bewuste afwijking: geen directe serverpush. Android controleert bij het
  openen en via de bestaande achtergrondtaak (circa drie uur; Android kan
  uitstellen). Web krijgt een eerlijke uitleg, geen schakelaar die niets doet.
- Bestaande vormgeving (Outfit, Phosphor, SectionCard, themakleuren) blijft
  leidend. UX-skill geraadpleegd voor toestemming, feedback en toegankelijkheid,
  niet voor een nieuw uiterlijk.

## Uitvoering

1. Pure berekening voor een vast ritvenster: dezelfde scoremotor,
   trend/windcorrectie en daglicht als suggesties. Alleen een complete,
   aaneengesloten voorspelling levert een actuele score. Geen selectie op
   beschikbaarheid, favoriete duur of kwaliteit: een geboekte slechte rit
   moet zichtbaar blijven.
2. Reactieve provider delen tussen Home, Ritten en detail, ook voor gedeelde
   ritten en voorgelegde vensters. Historische planscore bewaren als referentie.
   Geen gedeeltelijke weersverwachting als volledige score voorstellen.
3. Lokale meldingsvoorkeur per toestel: uit of 5/10/20 procentpunt. Geen
   Supabase-migratie: systeempermissie en aflevergeschiedenis zijn lokaal.
   Alleen toekomstige eigen/geaccepteerde ritten, niet uitnodigingen of
   afzeggingen. Profiel/locatiewijziging stelt de vergelijking opnieuw in
   zodat de melding geen weersverslechtering claimt door een eigen instelling.
4. Achtergrondtijdzone en scheduling uit #74 integreren. Scoredaling ook
   controleren met de lokaal bewaarde lijst van eigen/geaccepteerde ritten.
   Bestaande herinneringen mogen getoonde scoredalingsmeldingen niet wissen.
5. Nieuwe tekst NL+EN. Gerichte regressies, volledige `flutter test`,
   `flutter analyze`, web- en Android-build. Oppo alleen zonder de
   Play-installatie/data te vervangen; geen push, upload of deploy zonder
   expliciete opdracht.

## Acceptatie

- Nieuw weer en nieuwe tolerantie werken op alle drie schermen door.
- Dezelfde rit heeft overal dezelfde actuele score, ook onder 50.
- Ontbrekende uren: historische score als terugval, geen dalingsmelding.
- Instelbare daling is in procentpunten, opt-in en zonder meldingsspam.
- Nieuwe voorkeuren/baselines wijzigen geen planscore of cloudrij.
- Platformgrenzen en niet uitgevoerde toestelcontroles staan in SUMMARY.
