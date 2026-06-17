/// Phase 4: MaterialApp.router wired to routerProvider via ConsumerWidget.
/// Phase 6: darkTheme + themeMode added; reacts to themeModeProvider.
/// Phase 8: tz.initializeTimeZones() + WorkManager initialisatie.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/platform/background_task.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/theme_mode_provider.dart';
import 'package:ridewindow/services/widget_update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Laad timezone-data synchroon in geheugen (vereist voor flutter_local_notifications).
  tz.initializeTimeZones();

  // Parallel laden: timezone + SharedPreferences voor snelle cold start.
  final tzFuture = FlutterTimezone.getLocalTimezone();
  final prefsFuture = SharedPreferences.getInstance();
  final timezoneInfo = await tzFuture;
  final prefs = await prefsFuture;

  tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

  // Start de app snel — WorkManager init daarna (niet blocking voor UI).
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const RideWindowApp(),
    ),
  );

  // WorkManager init na runApp() — UI is al zichtbaar.
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kWeatherRefreshTaskTag,
    kWeatherRefreshTaskName,
    frequency: const Duration(hours: 3),
    flexInterval: const Duration(hours: 3),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

class RideWindowApp extends ConsumerWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Luister op slotsProvider en update het Android home screen widget
    // telkens als de slots-staat verandert (b.v. na WeatherRefresh of profielwijziging).
    ref.listen<SlotsState>(slotsProvider, (_, next) {
      if (next is SlotsLoaded) {
        final slot = next.slots.firstOrNull;
        WidgetUpdateService.update(slot);
      }
    });

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
