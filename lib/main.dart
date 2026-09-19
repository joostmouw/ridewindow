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
import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/core/supabase_config.dart';
import 'package:ridewindow/features/shared/add_to_home_screen_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/background_task.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/services/notification_plan.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/locale_provider.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/theme_mode_provider.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:ridewindow/services/widget_update_service.dart';
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

class RideWindowApp extends ConsumerStatefulWidget {
  const RideWindowApp({super.key});

  @override
  ConsumerState<RideWindowApp> createState() => _RideWindowAppState();
}

class _RideWindowAppState extends ConsumerState<RideWindowApp> {
  @override
  void initState() {
    super.initState();
    // Tel deze start mee en leg hem vast (v4.1). Hier en niet in HomeScreen:
    // een tester die op het welkomscherm afhaakt is juist de meting die fase 29
    // nodig heeft, en die zou Home nooit bereiken.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordAppOpen());
  }

  Future<void> _recordAppOpen() async {
    try {
      final consent = await ref.read(analyticsConsentProvider.future);
      final wasFirstRun = consent.isFirstRun;
      await consent.recordAppOpen();

      // De telling loopt altijd -- die staat lokaal en verlaat het toestel
      // niet. Of er iets vertrekt, beslist AnalyticsService zelf op grond van
      // de toestemming.
      final analytics = await ref.read(analyticsProvider.future);
      if (wasFirstRun) await analytics.track(kEvFirstRun);
      await analytics.track(
        kEvAppOpen,
        props: {'signed_in': ref.read(currentUserIdProvider) != null},
      );
    } catch (_) {
      // Statistiek mag nooit de reden zijn dat de app niet start.
    }
  }


  /// Plant de meldingen opnieuw voor het eerstvolgende venster.
  ///
  /// **Waarom vanuit de voorgrond en niet vanuit de achtergrondtaak.** Die
  /// draait in een eigen isolate zonder `tz.initializeTimeZones()` en zonder de
  /// tijdzone van het toestel. Daar plannen zou `tz.local` op UTC laten staan en
  /// elke melding uren verkeerd laten afgaan -- precies dezelfde klasse fout als
  /// de Aruba-melding van dezelfde dag. De prijs is dat de meldingen alleen
  /// bijwerken zolang iemand de app af en toe opent; dat is een bewuste keuze en
  /// staat als vervolg op de backlog.
  Future<void> _rescheduleNotifications(RideSlot? slot) async {
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;

      final service = NotificationService();
      final plans = planNotifications(
        profile: profile,
        nextSlot: slot,
        now: DateTime.now(),
      );

      final strings = await S.delegate.load(Locale(profile.locale));
      await service.applyPlans(
        plans,
        strings: strings,
        exact: await service.canScheduleExact(),
        weeklySlotTitle: slot == null ? null : formatSlotTitle(slot),
      );
    } catch (_) {
      // Meldingen mogen nooit de reden zijn dat de app hapert.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Luister op slotsProvider en update het Android home screen widget
    // telkens als de slots-staat verandert (b.v. na WeatherRefresh of profielwijziging).
    ref.listen<SlotsState>(slotsProvider, (_, next) {
      // home_widget heeft geen web-implementatie; sla deze stap over op web.
      if (!kIsWeb) {
        if (next is SlotsLoaded) {
          final slot = next.slots.firstOrNull;
          WidgetUpdateService.update(slot);
          // Dezelfde aanleiding, tweede gevolg: de drie meldingsschakelaars in
          // Profiel hangen aan datzelfde eerstvolgende venster. Tot 2026-09-19
          // las niemand die voorkeuren ooit om iets te plannen -- ze sloegen
          // alleen een waarde op. Hier gebeurt het wel.
          _rescheduleNotifications(slot);
        }
      }
    });

    // De Android-notificatiekanalen dragen hun naam in de taal van de app (#67).
    // Het kanaal zelf ontstaat bij de eerste melding, met de vertaalde naam die
    // meegaat in AndroidNotificationDetails -- daar is niets voor nodig. Android
    // bevriest die naam echter bij aanmaak, dus een latere taalwissel moet hem
    // bijwerken. Dat is wat deze listener doet. Het is ook het enige punt waar de
    // taal bekend is zonder BuildContext, vandaar S.delegate.load().
    if (!kIsWeb) {
      ref.listen<Locale>(appLocaleProvider, (previous, next) async {
        if (previous == next) return;
        await NotificationService().init(strings: await S.delegate.load(next));
      });
    }

    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'Ridewindow',
      locale: locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
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
