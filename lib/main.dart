/// Phase 4: MaterialApp.router wired to routerProvider via ConsumerWidget.
/// Phase 6: darkTheme + themeMode added; reacts to themeModeProvider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/providers/theme_mode_provider.dart';

void main() {
  runApp(const ProviderScope(child: RideWindowApp()));
}

class RideWindowApp extends ConsumerWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'RideWindow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}
