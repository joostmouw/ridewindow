import 'package:shared_preferences/shared_preferences.dart';

/// Voor welke build de update-melding is weggeklikt.
///
/// Per build en niet voorgoed: wie "later" zegt tegen 61, wil 62 nog wel
/// horen. Zonder dit kwam dezelfde balk bij elke start terug, en een balk
/// bovenaan die nooit weggaat, dekt een strook van elk scherm af (dezelfde les
/// als de iOS-balk van 2026-09-19).
class UpdateBannerStore {
  UpdateBannerStore(this._prefs);

  final SharedPreferences _prefs;

  static const kDismissedBuildKey = 'update.dismissedBuild';

  int? get dismissedBuild => _prefs.getInt(kDismissedBuildKey);

  Future<void> dismiss(int build) => _prefs.setInt(kDismissedBuildKey, build);
}

/// Of de balk voor [available] moet staan. Los van opslag, zodat het zonder
/// SharedPreferences te toetsen is.
bool showUpdateBanner({required int? available, required int? dismissed}) =>
    available != null && (dismissed == null || available > dismissed);
