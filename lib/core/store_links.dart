// lib/core/store_links.dart
// De links naar de Android-app in Play, op één plek.

/// De Play-vermelding. Werkt voor iedereen pas na de publieke lancering;
/// tot dan geeft hij "niet gevonden" voor wie geen tester is.
const kPlayStoreListingUrl =
    'https://play.google.com/store/apps/details?id=ridewindow.joost.amsterdam';

/// Stap 1 van meedoen als tester: de Google-groep die Play als testerslijst
/// gebruikt (closed testing). Zonder lidmaatschap weigert stap 2.
const kTesterGroupUrl = 'https://groups.google.com/g/ridewindow-testers';

/// Stap 2: aanmelden als tester, met hetzelfde Google-account als de groep.
const kTesterOptInUrl =
    'https://play.google.com/apps/testing/ridewindow.joost.amsterdam';

/// Zet op `true` bij de publieke lancering: dan opent de store-balk op de
/// website direct de Play-vermelding in plaats van de drie teststappen.
const kStoreAppPublic = false;
