/// Phase 4: MaterialApp.router wired to routerProvider via ConsumerWidget.
/// Phase 6: darkTheme + themeMode added; reacts to themeModeProvider.
/// Phase 8: tz.initializeTimeZones() + WorkManager initialisatie.
/// Phase 19: Supabase.initialize() parallel aan tzFuture/prefsFuture, awaited
/// vóór runApp() zodat authStateProvider nooit voor init leest (ARCHITECTURE §7.3).
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/core/supabase_config.dart';
import 'package:ridewindow/features/shared/add_to_home_screen_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/background_task.dart';
import 'package:ridewindow/providers/locale_provider.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/theme_mode_provider.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:ridewindow/services/widget_update_service.dart';
import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Laad timezone-data synchroon in geheugen (vereist voor flutter_local_notifications).
  tz.initializeTimeZones();

  // Laad intl locale-data voor NL en EN.
  await initializeDateFormatting('nl_NL');
  await initializeDateFormatting('en_US');

  // Parallel laden: timezone + SharedPreferences + Supabase voor snelle cold start.
  final tzFuture = FlutterTimezone.getLocalTimezone();
  final prefsFuture = SharedPreferences.getInstance();
  final supabaseFuture = Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );
  final timezoneInfo = await tzFuture;
  final prefs = await prefsFuture;

  tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

  // Wacht Supabase-init af vóórdat de eerste widget bouwt — anders kan een
  // provider authStateProvider lezen terwijl Supabase.instance nog niet
  // bestaat (ARCHITECTURE.md §1/§7 stap 3).
  await supabaseFuture;

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
  // Web heeft geen WorkManager-implementatie; sla deze stap over op web.
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      kWeatherRefreshTaskTag,
      kWeatherRefreshTaskName,
      frequency: const Duration(hours: 3),
      flexInterval: const Duration(hours: 3),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // Web-only: warm up GoogleSignIn eagerly (CAL-06) so the "Add to calendar"
  // tap has no unresolved await before the OAuth popup call -- Safari's popup
  // blocker requires the tap-to-popup call chain to stay synchronous (see
  // RESEARCH.md Pitfall 1). Native keeps CAL-02's on-demand lazy init, unchanged.
  if (kIsWeb) {
    await CalendarService.warmUpForWeb();
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final seeded = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  );
  final isLight = brightness == Brightness.light;

  // In light mode dragen de oppervlakken de merkkleur in plaats van MD3's
  // bijna-witte standaard: brandLight is de achtergrond, containers zijn
  // lichter zodat kaarten er bovenop komen te liggen. Dark mode volgt het
  // afgeleide schema van de seed.
  final colorScheme = isLight
      ? seeded.copyWith(
          surface: AppColors.brandLight,
          surfaceContainerLowest: AppColors.lightSurfaceContainerLowest,
          surfaceContainerLow: AppColors.lightSurfaceContainerLow,
          surfaceContainer: AppColors.lightSurfaceContainer,
          surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
          surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
          onSurface: AppColors.lightOnSurface,
          onSurfaceVariant: AppColors.lightOnSurfaceVariant,
          outline: AppColors.lightOutline,
          outlineVariant: AppColors.lightOutlineVariant,
        )
      : seeded;

  return ThemeData(
    colorScheme: colorScheme,
    extensions: [isLight ? RideWindowTheme.light : RideWindowTheme.dark],

    // ── Scaffold ──
    scaffoldBackgroundColor: colorScheme.surface,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    // ── Cards (M3 Expressive: larger radii) ──
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
      ),
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    ),

    // ── Buttons (M3 Expressive: fully rounded) ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
      ),
    ),

    // ── Chips (M3 Expressive) ──
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),

    // ── Bottom Sheet (M3 Expressive: 28dp corners) ──
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
    ),

    // ── Divider ──
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // ── NavigationBar ──
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
    ),

    // ── Switch ──
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHighest;
      }),
    ),
  );
}

class RideWindowApp extends ConsumerWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Luister op slotsProvider en update het Android home screen widget
    // telkens als de slots-staat verandert (b.v. na WeatherRefresh of profielwijziging).
    ref.listen<SlotsState>(slotsProvider, (_, next) {
      // home_widget heeft geen web-implementatie; sla deze stap over op web.
      if (!kIsWeb) {
        if (next is SlotsLoaded) {
          final slot = next.slots.firstOrNull;
          WidgetUpdateService.update(slot);
        }
      }
    });

    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'RideWindow',
      locale: locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // Renders the iOS "Add to Home Screen" instructional banner above
      // every route from a single wiring point (PWA-03). Resolves to
      // nothing on native/Android since isWebPlatform is false there.
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const AddToHomeScreenOverlay(),
        ],
      ),
    );
  }
}
