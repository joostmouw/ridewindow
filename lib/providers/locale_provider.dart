import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/providers/profile_notifier.dart';

part 'locale_provider.g.dart';

/// Zet profile.locale (String) om naar Locale.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
@riverpod
Locale appLocale(Ref ref) {
  final profileValue = ref.watch(profileProvider);
  final locale = profileValue.value?.locale ?? 'nl';
  return Locale(locale);
}
