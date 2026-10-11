# 38-02 — App: toestel-id, weigering herkennen, bewaren, melden

Status: af (golf 1). Bewijs tegen de echte grens staat in 38-03, zodra
Joost de plafonds bevestigt en 0016 live zet. Tot die dag is er in productie
gewoon nog nooit een weigering en verandert er niets merkbaars.

## Wat er staat

- **FeedbackDeviceStore** (`lib/data/repositories/feedback_device_store.dart`):
  eigen uuid v4 per toestel onder `feedback.deviceId`, aangemaakt bij de
  eerste versturing, injecteerbare Random. Bewust los van
  `analytics.deviceId`: dat verdwijnt bij intrekken van de
  statistiek-toestemming, en juist daarna moet het toestelplafond het
  toestel nog herkennen (D-08). De dialoog leest hem in `_submit` en stuurt
  hem mee; lukt het niet, dan vertrekt de rij zonder id en valt hij onder
  de afzendertelling: feedback strandt nooit op zijn eigen id.
- **buildFeedbackRow** neemt `deviceId` aan; de sleutel staat er alleen als
  hij bestaat (geen lege string, want dat is in de database iets anders dan
  afwezig). FeedbackService en de dialoog geven hem door.
- **RateLimitedRefusal** (`lib/services/sync_outbox_service.dart`):
  herkent `rw_rate_limited:<tabel>:<soort>` in willekeurige foutvorm via
  `tryFrom` (getypt, of ingebed in een PostgrestException-tekst). De drain
  behandelt hem als eigen soort: géén `markFailed`, géén `dropRow`,
  `attempts` ongemoeid, en doorgaan naar de volgende rij.
- **De reconciler** wikkelt de insertRow-fouten van feedback én analytics
  om naar de getypte weigering en bumped `feedbackRateLimitedProvider`
  (keepAlive) één keer per drain; app_events is stil (D-10). De app-root
  (`main.dart` builder, naast `TopBanners`) heeft
  `FeedbackRateLimitedListener`: één NL/EN snackbar per stijging ("bewaard,
  later opnieuw, daglimiet bereikt"), daarna de teller terug op nul.
- ARB-sleutel `feedbackRateLimited` in beide talen, geen em-dash.

## Vondsten tijdens het bouwen

1. **De val zat al in huis: `kMaxSendAttempts` dropt na vijf pogingen.**
   Een weigering per ongeluk als gewone fout tellen, betekent dat de
   feedback van een tester binnen een handvol voorgrondovergangen verdwijnt:
   precies het stille verlies dat RATE-05 uitsluit. Daarom is de
   weigeringstak in de drain geen speciaal geval van "mislukt", maar een
   derde uitkomst naast verzonden en mislukt. Bewijs in
   `sync_outbox_service_test.dart`: zeven drains later bestaat de rij nog,
   `attempts = 0`; een gewone fout dropt na vijf keer nog steeds (contratest).
2. **Eén telling per drain, niet per rij.** De eerste versie bumped met het
   aantal geweigerde rijen, maar "drie rijen geweigerd" is geen nieuws bovenop
   "je feedback is bewaard". De teller betekent nu: drains met een weigering
   sinds de app-root laatst keek.
3. **Dubbele drains vragen om onderdrukking.** Eén voorgrondcyclus draint
   twee keer (vóór en na de merge, plan 21-14) en de dialoog draint bij
   versturen ook meteen: dezelfde geweigerde rij zou twee, drie keer
   achtereen dezelfde snackbar geven. De listener onderdrukt daarom een
   tweede melding binnen 10 seconden (muurklok). Het venster is injecteerbaar
   (`kFeedbackRefusalSuppressWindow`), want `pump` zet in tests alleen de
   timerklok vooruit, nooit `DateTime.now()`.
4. **Widgettest-les: `SharedPreferences.getInstance()` zonder mock lost
   nooit op.** Zodra de dialoog het toestel-id ging halen, bleef de hele
   `_submit`-keten in Test 7 hangen vóór de enqueue: het platformkanaal
   antwoordt in een testomgeving niet en de future voltooit nooit. Mock
   values horen er dus bij elke test die versturen aanraakt; in productie
   bestaat dit pad niet (echte plugin).
5. **Fake-klok-les: een snackbar verdwijnt niet onder één grote
   `pump`.** Bij een klok-sprong voltooit de entree-animatie ín dat ene
   frame en start de 4-seconden display-timer pas ná de sprong; hij schiet
   dus nooit binnen het pompte venster. Snackbars in tests weglaten kost
   per-frame oprekken (50 x 200 ms), niet één `pump(seconds: 5)`. Drie
   rondes kostte dat, terwijl de listener zelf de hele tijd gewoon werkte:
   de faalassertie stond vóór de tweede bump.
6. **Vier bestaande `drain()`-overrides werden ongeldig door de nieuwe
   optionele parameter.** Blijft de sweep-regel gelden: wie de signatuur
   van `drain` aanraakt, checkt de fakes in
   `outbox_drain_wiring_test.dart`,
   `cloud_sync_reconciler_gateway_test.dart`,
   `startup_reconcile_wiring_test.dart` en `feedback_dialog_test.dart`.

## Verificatie

- `flutter analyze`: 215 issues, exact de nulmeting van vóór deze wijziging
  (bekende backlog van `require_trailing_commas` elders; mijn code voegt er
  nul toe).
- `flutter test`: 1212 tests, alles groen, inclusief 18 nieuwe/uitgebreide
  tests rond de weigering, het toestel-id en de melding.

## Wat er nog niet is

- Het echte bewijs (RATE-04: productiebuild zonder update valt onder
  dezelfde grenzen) staat in 38-03 en wacht op Joost: plafondbevestiging,
  0016 + `rate_limits_test.sql` in de SQL Editor, de PostgREST-probe, en
  opruim-SQL daarna.
