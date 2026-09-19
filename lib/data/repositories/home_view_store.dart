import 'package:shared_preferences/shared_preferences.dart';

/// Hoe de gebruiker Home wil zien.
///
/// Twee keuzes die tot 2026-09-19 vastlagen. De aanleiding is backlog #69 en
/// #70: een tester zag drie losse vensters op één ochtend en vroeg waarom er
/// geen groter blok werd aangeboden. Het antwoord is niet "de lijst is fout"
/// maar "er is meer dan één juiste manier om hiernaar te kijken" -- dus kiest
/// de gebruiker, en onthoudt de app die keuze.
enum HomeView {
  /// De losse vensters, zoals de app het altijd deed.
  windows,

  /// Eén kaart per aaneengesloten goed dagdeel, met het beste venster erin
  /// gemarkeerd. Zie `ride_block.dart`.
  blocks,
}

/// Op welke volgorde de vensterlijst staat.
enum SlotSort {
  /// Beste kwaliteit eerst, met het allerbeste venster bovenaan. De volgorde
  /// die de app altijd had.
  best,

  /// Gewoon op tijd, als een agenda. Wat je van een lijst tijdvakken verwacht
  /// zodra je niet op zoek bent naar "de beste" maar naar "wanneer".
  time,
}

/// Onthoudt beide keuzes. Eigen sleutelruimte `home.*`, buiten de
/// `profile.*`-synchronisatie: dit is een kijkvoorkeur op dit toestel, geen
/// profielinstelling die je op een ander toestel terug wilt zien.
class HomeViewStore {
  HomeViewStore(this._prefs);

  final SharedPreferences _prefs;

  static const kViewKey = 'home.view';
  static const kSortKey = 'home.slotSort';

  HomeView get view =>
      _prefs.getString(kViewKey) == HomeView.blocks.name
          ? HomeView.blocks
          : HomeView.windows;

  SlotSort get sort => _prefs.getString(kSortKey) == SlotSort.time.name
      ? SlotSort.time
      : SlotSort.best;

  Future<void> setView(HomeView value) =>
      _prefs.setString(kViewKey, value.name);

  Future<void> setSort(SlotSort value) =>
      _prefs.setString(kSortKey, value.name);
}
