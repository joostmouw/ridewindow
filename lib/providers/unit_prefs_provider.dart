import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/unit_prefs_store.dart';
import 'package:ridewindow/domain/models/units.dart';

part 'unit_prefs_provider.g.dart';

/// De gekozen eenheden, en de enige plek die ze verandert.
///
/// Synchroon leesbaar na de eerste laadbeurt, want elk scherm dat een getal
/// toont heeft ze nodig: een `AsyncValue` zou betekenen dat elke weerbalk een
/// laadtoestand moet kunnen tekenen voor een instelling die in microseconden
/// van schijf komt. Vandaar dezelfde vorm als `profile_notifier.dart`:
/// `getInstance()` binnen `build`, en daarna gewone waarden.
@Riverpod(keepAlive: true)
class UnitPrefsNotifier extends _$UnitPrefsNotifier {
  UnitPrefsStore? _store;

  @override
  Future<UnitPrefs> build() async {
    final store = _store = UnitPrefsStore(await SharedPreferences.getInstance());
    return store.read();
  }

  Future<void> setTemp(TempUnit unit) async {
    final store = _store ?? UnitPrefsStore(await SharedPreferences.getInstance());
    await store.writeTemp(unit);
    state = AsyncData(store.read());
  }

  Future<void> setWind(WindUnit unit) async {
    final store = _store ?? UnitPrefsStore(await SharedPreferences.getInstance());
    await store.writeWind(unit);
    state = AsyncData(store.read());
  }
}

/// Wat een scherm werkelijk nodig heeft: de eenheden, of de standaard zolang
/// ze nog geladen worden. Een weerbalk die op een instelling wacht, is een
/// weerbalk die knippert.
@riverpod
UnitPrefs units(Ref ref) =>
    ref.watch(unitPrefsProvider).value ?? UnitPrefs.defaults;
