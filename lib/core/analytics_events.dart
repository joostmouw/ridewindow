// De volledige lijst gebeurtenissen die de app mag versturen.
//
// **Waarom een gesloten lijst.** Telemetrie groeit vanzelf uit tot "meet
// alles, kijk later wel", en dan is niet meer uit te leggen wat er van een
// gebruiker vertrekt. Elke naam hier hoort bij een vraag die tijdens de
// wervingsfase beantwoord moet worden; staat een naam niet in deze lijst, dan
// weigert `AnalyticsService` hem. `analytics_events_test.dart` bewaakt dat.
//
// **Waarom geen vrije tekst in de props.** Die hoort in `public.feedback`, waar
// de gebruiker zelf op verzenden drukt. Zie de migratie 0008 voor de `check`
// die het ook aan de databasekant afdwingt.

import 'package:ridewindow/app/window_size.dart';

/// De app is geopend (koude start of terug uit de achtergrond na >30 min).
/// Beantwoordt: hoeveel testers zijn er werkelijk actief, en hoe lang blijven ze?
/// Draagt `signed_in` en [kPropWindowClass]; zie [appOpenProps].
const kEvAppOpen = 'app_open';

/// De breedteklasse (compact|medium|expanded|large) bij app_open. Beantwoordt
/// of tablets het onderhoud waard zijn. Een klasse, nooit een schermmaat in
/// pixels: vier waarden zijn niet herleidbaar tot een toestel.
const kPropWindowClass = 'window_class';

/// De props van [kEvAppOpen]: of je bent ingelogd en, als de breedte bekend
/// is, de breedteklasse als korte code. Verder niets; een nieuwe sleutel hier
/// hoort ook in het privacybeleid.
Map<String, Object?> appOpenProps({
  required bool signedIn,
  double? windowWidth,
}) =>
    {
      'signed_in': signedIn,
      if (windowWidth != null)
        kPropWindowClass: windowSizeClassFor(windowWidth).name,
    };

/// De eerste start ooit op dit toestel. Beantwoordt: hoeveel van de aangemelde
/// testers komen voorbij het installeren?
const kEvFirstRun = 'first_run';

/// De onboarding is uitgelopen tot het einde. Beantwoordt: haken ze af in de
/// eerste minuut? Dit is de meting waar fase 29 op stuurt.
const kEvOnboardingDone = 'onboarding_done';

/// Een ritvenster is opengeklapt. Beantwoordt: kijken ze verder dan de kaart?
const kEvSlotOpened = 'slot_opened';

/// Een rit is ingepland. De kernhandeling van de app.
const kEvRidePlanned = 'ride_planned';

/// Een geplande rit is afgezegd. Samen met het vorige: blijft een plan staan?
const kEvRideUnplanned = 'ride_unplanned';

/// De beschikbaarheidskalender is gewijzigd. Beantwoordt: komen ze voorbij de
/// standaardweek, of laten ze hem staan?
const kEvAvailabilityEdited = 'availability_edited';

/// Een Peloton-uitnodiging is verstuurd of aangenomen.
const kEvPelotonInvite = 'peloton_invite';

/// De app moest terugvallen op een plek die hij niet gemeten heeft, of de klok
/// van het toestel hoort bij een ander werelddeel. Dit is de gebeurtenis die de
/// Aruba-melding van 2026-09-19 zichtbaar had gemaakt voordat een mens hem zag.
const kEvLocationWarning = 'location_warning';

/// Feedback is verstuurd. Beantwoordt: bereikt de feedbackstroom van fase 28
/// iemand anders dan de vier mensen die Joost persoonlijk kent?
const kEvFeedbackSent = 'feedback_sent';

/// Elke naam die de app mag versturen. `AnalyticsService` weigert de rest.
const Set<String> kKnownAnalyticsEvents = {
  kEvAppOpen,
  kEvFirstRun,
  kEvOnboardingDone,
  kEvSlotOpened,
  kEvRidePlanned,
  kEvRideUnplanned,
  kEvAvailabilityEdited,
  kEvPelotonInvite,
  kEvLocationWarning,
  kEvFeedbackSent,
};
