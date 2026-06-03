import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/providers/profile_notifier.dart';

part 'theme_mode_provider.g.dart';

/// Zet profile.theme (String) om naar ThemeMode.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
/// Valt terug op ThemeMode.system als de provider nog laadt of een fout heeft.
@riverpod
ThemeMode themeMode(Ref ref) {
  final profileValue = ref.watch(profileProvider);
  final theme = profileValue.value?.theme ?? 'system';
  return switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
