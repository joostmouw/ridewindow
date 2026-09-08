// lib/features/profile/profile_screen.dart
// ProfileScreen: Wave 2 — vier tolerantie-sliders, rijlengte-chips, thema-SegmentedButton.
// Wave 3 — LOCATIE sectie: stad-picker, GPS-banner (D-07-06).
// Wave 4 — NOTIFICATIES sectie: drie SwitchListTile widgets (NOTIF-01/02/03).
// D-06-02: onChangeEnd persisteert, onChanged update lokale state.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ridewindow/core/app_version.dart';
import 'package:ridewindow/core/nl_cities.dart';
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/features/profile/account_section.dart';
import 'package:ridewindow/features/profile/feedback_dialog.dart';
import 'package:ridewindow/features/shared/section_card.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/theme/app_icons.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

const _kPrivacyPolicyUrl = 'https://joostmouw.github.io/ridewindow-privacy/';

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Lokale state voor live slider-waarden (vóór onChangeEnd persistentie).
  late double _tempMin;
  late double _tempMax;
  late double _rainMax;
  late double _windMax;

  final _notifService = NotificationService();
  int _versionTapCount = 0;

  // Google Calendar-verbindingsstatus (backlog #36). null = nog aan het
  // controleren; true/false = resultaat van isCalendarConnected().
  bool? _calendarConnected;

  // AUTH-07: het Calendar-geautoriseerde e-mailadres wanneer dat afwijkt van
  // het ingelogde Supabase-account. null = geen mismatch (of nog niet
  // gecontroleerd, of Calendar niet verbonden) -- alleen gezet nadat zowel
  // het Calendar-account als het ingelogde account bekend zijn EN verschillen.
  String? _calendarMismatchEmail;

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse(_kPrivacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Vraag POST_NOTIFICATIONS op en toon SnackBar als SCHEDULE_EXACT_ALARM niet beschikbaar is.
  /// Aanroepen bij inschakelen van een notificatie-toggle (NOTIF-04, NOTIF-05).
  Future<void> _scheduleNotificationsIfPermitted(BuildContext context) async {
    // 1. Vraag POST_NOTIFICATIONS op
    final granted = await _notifService.requestPostNotificationsPermission();
    if (!granted) return;

    // 2. Controleer SCHEDULE_EXACT_ALARM
    final canExact = await _notifService.canScheduleExact();
    if (!canExact) {
      // Toon SnackBar met uitleg (per NOTIF-05 fallback, D-08-09)
      if (context.mounted) {
        final s = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.notifExactTimingWarning),
            action: SnackBarAction(
              label: s.settingsLabel,
              onPressed: () => _notifService.openExactAlarmSettings(),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
    // Verdere scheduling vindt plaats via SlotsNotifier data in de toekomst (Phase 8 scope: permissie-flow)
  }

  @override
  void initState() {
    super.initState();
    // Initialiseer uit profileProvider snapshot (synchrone read na eerste load).
    final profile = ref.read(profileProvider).value;
    _tempMin = profile?.tolerances.tempMinIdealC ?? 12.0;
    _tempMax = profile?.tolerances.tempMaxIdealC ?? 26.0;
    _rainMax = profile?.tolerances.rainMaxIdealMm ?? 0.5;
    _windMax = profile?.tolerances.windMaxIdealKmh ?? 15.0;

    // Backlog #36: check-only (niet-promptende) Google Calendar-status,
    // fire-and-forget zodat initState() synchroon blijft.
    _checkCalendarConnection();
  }

  /// Controleert de Google Calendar-verbindingsstatus zonder ooit te
  /// prompten (backlog #36). Bij een fout (bv. platform-channel niet
  /// beschikbaar) degradeert de UI gracieus naar "Not connected" in plaats
  /// van te crashen (T-quick260714nfk-02).
  Future<void> _checkCalendarConnection() async {
    try {
      final connected = await CalendarService().isCalendarConnected();
      if (mounted) setState(() => _calendarConnected = connected);
      if (connected) {
        await _checkCalendarMismatch();
      }
    } catch (_) {
      if (mounted) setState(() => _calendarConnected = false);
    }
  }

  /// AUTH-07: vergelijkt het Calendar-geautoriseerde Google-account met het
  /// ingelogde Supabase-account (D-11: non-prompting, dus alleen aangeroepen
  /// nadat [_calendarConnected] al `true` is via de eveneens niet-promptende
  /// [CalendarService.isCalendarConnected]). Een eenmalige read van
  /// `authStateProvider` op controlemoment is hier correct -- dit is een
  /// passieve check, net als de bestaande Calendar-statuscontrole, geen
  /// live-updatende vergelijking. Bij een fout (bv. geen platform-channel in
  /// tests) degradeert dit stil naar "geen mismatch" in plaats van te
  /// crashen -- dezelfde fail-safe stijl als [_checkCalendarConnection].
  Future<void> _checkCalendarMismatch() async {
    try {
      final calendarEmail = await CalendarService().currentGoogleEmail();
      final signedInEmail = ref.read(authStateProvider).value?.email;
      final mismatch = calendarEmail != null &&
          signedInEmail != null &&
          calendarEmail != signedInEmail;
      if (mounted) {
        setState(
          () => _calendarMismatchEmail = mismatch ? calendarEmail : null,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _calendarMismatchEmail = null);
    }
  }

  /// Trekt de Google Calendar-autorisatie in (backlog #36). Best-effort:
  /// als de aanroep zelf faalt, wordt toch doorgegaan met de UI-update omdat
  /// de gebruikersintentie (loskoppelen) duidelijk is (T-quick260714nfk-02).
  Future<void> _disconnectCalendar(BuildContext context) async {
    try {
      await CalendarService().disconnectCalendar();
    } catch (_) {
      // Best-effort: negeer fouten, ga toch door met UI-update.
    }
    if (mounted) {
      setState(() {
        _calendarConnected = false;
        _calendarMismatchEmail = null;
      });
    }
    if (context.mounted) {
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.calendarDisconnectedSnackbar)),
      );
    }
  }

  String _calendarStatusText(S s) {
    if (_calendarConnected == null) return s.calendarStatusChecking;
    return _calendarConnected!
        ? s.calendarStatusConnected
        : s.calendarStatusNotConnected;
  }

  void _showNameDialog(BuildContext context, String? currentName) {
    final controller = TextEditingController(text: currentName);
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.yourName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: s.enterYourName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(profileProvider.notifier).setUserName(controller.text);
              Navigator.of(ctx).pop();
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _showDebugMenu(BuildContext context) {
    final s = S.of(context);
    // `isScrollControlled` + een scrollende body (gevonden op toestel
    // 2026-08-06): zonder deze twee klapt de sheet dicht op de standaardhoogte
    // van een halve viewport en valt het laatste item — "Inspect sync outbox" —
    // buiten beeld, onbereikbaar. Uitgerekend het item dat een vastgelopen
    // outbox moet kunnen diagnosticeren was daardoor niet te openen.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.debugMenu,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(AppIcons.arrowCounterClockwise),
                title: Text(s.debugResetOnboarding),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('onboarding.completed');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.debugOnboardingReset)),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.trashSimple),
                title: Text(s.debugClearWeather),
                onTap: () {
                  ref.invalidate(weatherProvider);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.debugWeatherCleared)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.calendarBlank),
                title: Text(s.debugResetAvailability),
                onTap: () async {
                  await ref.read(availabilityProvider.notifier).clearAll();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.debugAvailabilityReset)),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.arrowsClockwise),
                title: Text(s.debugRefreshWeather),
                onTap: () {
                  ref.invalidate(weatherProvider);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.debugWeatherRefreshing)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.paperPlaneTilt),
                title: Text(s.debugOutbox),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showOutboxSheet(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Plan 21-12: makes the sync outbox readable on the device itself. Every
  /// failed send already writes its error to `sync_outbox_entries.lastError`,
  /// but until now nothing anywhere read that column, so diagnosing a stuck
  /// pending counter required adb. Deliberately lives in the hidden debug
  /// menu rather than the account section — it is a diagnostic, not a
  /// user-facing feature.
  void _showOutboxSheet(BuildContext context) {
    final s = S.of(context);
    final dao = ref.read(appDatabaseProvider).syncOutboxDao;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: FutureBuilder(
          future: dao.pendingRows(),
          builder: (ctx, snapshot) {
            final rows = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    s.debugOutboxTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (rows == null)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(s.debugOutboxEmpty),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        return ListTile(
                          dense: true,
                          title: Text('${row.entity} · ${row.operation}'),
                          subtitle: Text(
                            '${row.entityKey}\n'
                            '${s.debugOutboxRowSubtitle(
                              row.attempts,
                              row.lastError ?? s.debugOutboxNoError,
                            )}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                if (rows != null && rows.isNotEmpty)
                  ListTile(
                    leading: const Icon(AppIcons.trashSimple),
                    title: Text(s.debugOutboxClear),
                    onTap: () async {
                      final cleared = await dao.clearAll();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.debugOutboxCleared(cleared)),
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openCityPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            itemCount: kNlCities.length,
            itemBuilder: (_, i) {
              final city = kNlCities[i];
              return ListTile(
                title: Text(city.name),
                onTap: () {
                  ref
                      .read(profileProvider.notifier)
                      .setLocationOverride(city.name);
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final permissionAsync = ref.watch(gpsPermissionProvider);
    final permission = permissionAsync.value;

    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: ListView(
        key: const PageStorageKey('profile_settings'),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Sectie: ACCOUNT (D-01: bewust bovenaan, boven Naam en de
          // tolerantie-instellingen -- zie 19-CONTEXT.md).
          const AccountSection(),

          // Sectie: LOCATIE (D-07-06: stad-picker + GPS-banner, LOC-03, LOC-04)
          SectionCard(
            title: s.sectionLocation,
            children: [
              // ELEMENT 0 — Web-only promoted city picker CTA (LOC-07 primary path)
              if (isWebPlatform &&
                  (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever))
                SectionBanner(
                  // Tonaal, niet vol groen. Dit is een terugvalstaat -- er ging
                  // iets mis met je locatie -- en op de papieren achtergrond was
                  // `primaryContainer` het meest verzadigde vlak van het hele
                  // scherm geworden. Daarmee trok een foutmelding meer aandacht
                  // dan je account.
                  //
                  // De groene rand die die urgentie vasthield is vervallen: als
                  // strook bovenin de sectiekaart doet de kleur dat werk al, en
                  // een rand ín een omrande kaart geeft een dubbele lijn.
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.chooseCityPrimaryTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(s.chooseCityPrimaryHint),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _openCityPicker(context),
                        icon: const Icon(AppIcons.buildings),
                        label: Text(s.tapToChooseCity),
                      ),
                    ],
                  ),
                ),

              // ELEMENT 1 — GPS-geblokkeerd banner (deniedForever)
              if (permission == LocationPermission.deniedForever)
                SectionBanner(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.locationBlocked,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWebPlatform
                            ? s.locationBlockedWebHint
                            : s.locationBlockedHint,
                      ),
                      if (!isWebPlatform)
                        TextButton(
                          onPressed: () => ref
                              .read(gpsPermissionProvider.notifier)
                              .openSettings(),
                          child: Text(s.openSettings),
                        ),
                    ],
                  ),
                ),

              // ELEMENT 2 — GPS toestemming vragen (denied, niet deniedForever)
              if (permission == LocationPermission.denied)
                ListTile(
                  leading: const Icon(AppIcons.crosshair),
                  title: Text(s.useGpsLocation),
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(gpsPermissionProvider.notifier)
                        .requestPermission(),
                    child: Text(s.grantPermission),
                  ),
                ),

              // ELEMENT 3 — Actieve locatie + stad-picker
              ListTile(
                leading: const Icon(AppIcons.buildings),
                title: Text(profile.locationOverride ?? s.gpsAutomatic),
                subtitle: Text(s.tapToChooseCity),
                trailing: profile.locationOverride != null
                    ? IconButton(
                        icon: const Icon(AppIcons.x),
                        tooltip: s.clearLocationOverride,
                        onPressed: () => ref
                            .read(profileProvider.notifier)
                            .setLocationOverride(null),
                      )
                    : null,
                onTap: () => _openCityPicker(context),
              ),
            ],
          ),

          // Sectie: NOTIFICATIES (NOTIF-01, NOTIF-02, NOTIF-03)
          SectionCard(
            title: s.sectionNotifications,
            children: [
              SwitchListTile(
                title: Text(s.notifEveningBefore),
                subtitle: Text(s.notifEveningBeforeSub),
                value: profile.notifEveningBefore,
                onChanged: (v) async {
                  await ref
                      .read(profileProvider.notifier)
                      .setNotifEveningBefore(v);
                  if (v && context.mounted) {
                    await _scheduleNotificationsIfPermitted(context);
                  }
                },
              ),
              SwitchListTile(
                title: Text(s.notifMorningOf),
                subtitle: Text(s.notifMorningOfSub),
                value: profile.notifMorningOf,
                onChanged: (v) async {
                  await ref.read(profileProvider.notifier).setNotifMorningOf(v);
                  if (v && context.mounted) {
                    await _scheduleNotificationsIfPermitted(context);
                  }
                },
              ),
              SwitchListTile(
                title: Text(s.notifWeeklyDigest),
                subtitle: Text(s.notifWeeklyDigestSub),
                value: profile.notifWeeklyDigest,
                onChanged: (v) async {
                  await ref
                      .read(profileProvider.notifier)
                      .setNotifWeeklyDigest(v);
                  if (v && context.mounted) {
                    await _scheduleNotificationsIfPermitted(context);
                  }
                },
              ),
            ],
          ),

          // Sectie: TAAL
          SectionCard(
            title: s.sectionLanguage,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SegmentedButton<String>(
                  // Zie de noot bij de themakiezer hieronder: geen vinkje op een
                  // enkelvoudige keuze. Hier past het label ook mét vinkje, maar
                  // twee keuzeknoppen recht onder elkaar waarvan er één een
                  // vinkje draagt en de ander niet, oogt als een fout.
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'nl', label: Text('Nederlands')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {profile.locale},
                  onSelectionChanged: (s) =>
                      ref.read(profileProvider.notifier).setLocale(s.first),
                ),
              ),
            ],
          ),

          // Sectie: THEMA (D-06-09: SegmentedButton, PROF-04)
          SectionCard(
            title: s.sectionTheme,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                // D-06-09: SegmentedButton, PROF-04
                child: SegmentedButton<String>(
                  // Geen vinkje. In een sectiekaart is de knop 32px smaller —
                  // dat is spec-conform (16dp schermmarge plus 16dp
                  // list-item-inspringing), maar met drie segmenten brak
                  // "System" daardoor af tot "Syste / m" op de Oppo. Het vinkje
                  // is hier bovendien dubbelop: dit is een enkelvoudige keuze en
                  // het gevulde `secondaryContainer` zégt al welke aan staat.
                  //
                  // Niet overnemen op de periodefilter van Home: die is
                  // meervoudig, en daar draagt het vinkje wél informatie —
                  // welke van de drie aan staan is niet af te lezen aan één
                  // gevuld vlak.
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'system', label: Text(s.themeSystem)),
                    ButtonSegment(value: 'light', label: Text(s.themeLight)),
                    ButtonSegment(value: 'dark', label: Text(s.themeDark)),
                  ],
                  selected: {profile.theme},
                  onSelectionChanged: (s) =>
                      ref.read(profileProvider.notifier).setTheme(s.first),
                ),
              ),
            ],
          ),

          // Sectie: TOLERANTIES
          SectionCard(
            title: s.sectionTolerances,
            children: [
              // --- Temperatuurbereik (RangeSlider) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    // `Expanded` in plaats van een `Spacer` ná het label: in een
                    // sectiekaart is de rij 32px smaller dan in de oude platte
                    // lijst (kaartmarge plus binnenmarge), en met een label op
                    // zijn natuurlijke breedte liep hij over. Nu mag het label
                    // krimpen of afbreken; de waarde rechts houdt zijn maat.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.toleranceTemperature,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _infoButton(
                          context,
                          s.toleranceTempInfoTitle,
                          s.toleranceTempInfo,
                          _tempRangeDescription(context, _tempMin, _tempMax),
                        ),
                        Text(
                          '${_tempMin.round()}°C – ${_tempMax.round()}°C',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_tempMin, _tempMax),
                      min: 0,
                      max: 40,
                      divisions: 40,
                      labels: RangeLabels(
                        '${_tempMin.round()}°C',
                        '${_tempMax.round()}°C',
                      ),
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (v) => setState(() {
                        _tempMin = v.start;
                        _tempMax = v.end;
                      }),
                      onChangeEnd: (v) =>
                          ref.read(profileProvider.notifier).updateTolerances(
                                profile.tolerances.copyWith(
                                  tempMinIdealC: v.start,
                                  tempMaxIdealC: v.end,
                                ),
                              ),
                    ),
                    Text(
                      _tempRangeDescription(context, _tempMin, _tempMax),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // --- Max. neerslag + animated drops ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.toleranceMaxRain,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _infoButton(
                          context,
                          s.toleranceRainInfoTitle,
                          s.toleranceRainInfo,
                          _rainDescription(context, _rainMax),
                        ),
                        Text(
                          '${_rainMax.toStringAsFixed(1)}mm',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 40,
                      child: _AnimatedRainDrops(intensity: _rainMax / 5.0),
                    ),
                    Slider(
                      value: _rainMax,
                      min: 0,
                      max: 5,
                      divisions: 50,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (v) => setState(() => _rainMax = v),
                      onChangeEnd: (v) =>
                          ref.read(profileProvider.notifier).updateTolerances(
                                profile.tolerances.copyWith(rainMaxIdealMm: v),
                              ),
                    ),
                    Text(
                      _rainDescription(context, _rainMax),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // --- Max. wind + animated windsock ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.toleranceMaxWind,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _infoButton(
                          context,
                          s.toleranceWindInfoTitle,
                          s.toleranceWindInfo,
                          _windDescription(context, _windMax),
                        ),
                        Text(
                          '${_windMax.round()} ${s.unitKmh}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 40,
                      child: _AnimatedWindFlag(intensity: _windMax / 50.0),
                    ),
                    Slider(
                      value: _windMax,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (v) => setState(() => _windMax = v),
                      onChangeEnd: (v) =>
                          ref.read(profileProvider.notifier).updateTolerances(
                                profile.tolerances.copyWith(windMaxIdealKmh: v),
                              ),
                    ),
                    Text(
                      _windDescription(context, _windMax),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),

          // Sectie: RIJLENGTE
          SectionCard(
            title: s.sectionRideLength,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    // PROF-02: last-chip-guard zit in
                    // ProfileNotifier.toggleDuration()
                    FilterChip(
                      label: const Text('2u'),
                      selected: profile.allowedDurations.contains(2),
                      onSelected: (_) {
                        HapticFeedback.lightImpact();
                        ref.read(profileProvider.notifier).toggleDuration(2);
                      },
                    ),
                    FilterChip(
                      label: const Text('3u'),
                      selected: profile.allowedDurations.contains(3),
                      onSelected: (_) {
                        HapticFeedback.lightImpact();
                        ref.read(profileProvider.notifier).toggleDuration(3);
                      },
                    ),
                    FilterChip(
                      label: const Text('4-5u'),
                      selected: profile.allowedDurations.contains(5),
                      onSelected: (_) {
                        HapticFeedback.lightImpact();
                        ref.read(profileProvider.notifier).toggleDuration(5);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Beschikbaarheidskalender navigatie (D-06-08)
              ListTile(
                title: Text(s.editMySchedule),
                trailing: const Icon(AppIcons.caretRight),
                onTap: () => context.push('/availability'),
              ),
            ],
          ),

          // Sectie: NAAM
          SectionCard(
            title: s.sectionName,
            children: [
              ListTile(
                leading: const Icon(AppIcons.user),
                title: Text(profile.userName ?? s.setYourName),
                subtitle: profile.userName == null ? Text(s.nameHint) : null,
                onTap: () => _showNameDialog(context, profile.userName),
              ),
            ],
          ),

          // Sectie: OVER (REL-03: privacybeleid + versie)
          SectionCard(
            title: s.sectionAbout,
            children: [
              ListTile(
                leading: const Icon(AppIcons.chatCircleDots),
                title: Text(s.sendFeedback),
                trailing: const Icon(AppIcons.caretRight),
                onTap: () => showFeedbackDialog(context),
              ),
              ListTile(
                leading: const Icon(AppIcons.calendarBlank),
                title: Text(s.googleCalendarLabel),
                subtitle: _calendarMismatchEmail != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_calendarStatusText(s)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppIcons.warning,
                                size: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  s.calendarMismatchWarning(
                                    _calendarMismatchEmail!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(_calendarStatusText(s)),
                trailing: _calendarConnected == null
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (_calendarConnected!
                        ? TextButton(
                            onPressed: () => _disconnectCalendar(context),
                            child: Text(s.calendarDisconnectButton),
                          )
                        : null),
              ),
              ListTile(
                title: Text(s.privacyPolicy),
                trailing: const Icon(AppIcons.arrowSquareOut),
                onTap: _launchPrivacyPolicy,
              ),
              ListTile(
                title: Text(s.weatherDataAttribution),
                trailing: const Icon(AppIcons.arrowSquareOut),
                onTap: () => launchUrl(Uri.parse('https://open-meteo.com/')),
              ),
              ListTile(
                title: Text(s.version),
                trailing: const Text(kAppVersionDisplay),
                onTap: () {
                  _versionTapCount++;
                  if (_versionTapCount >= 5) {
                    _versionTapCount = 0;
                    _showDebugMenu(context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper methods for contextual info descriptions
// ---------------------------------------------------------------------------

Widget _infoButton(BuildContext context, String title, String explanation,
    String currentDesc) {
  return IconButton(
    icon: Icon(AppIcons.info,
        size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    tooltip: title,
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(explanation),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.slidersHorizontal,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentDesc,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}

String _tempRangeDescription(BuildContext context, double min, double max) {
  final s = S.of(context);
  final range = max - min;
  if (range >= 25) return s.tempDescAllWeather;
  if (range >= 15) return s.tempDescComfortable;
  if (range >= 8) return s.tempDescNiceOnly;
  return s.tempDescPerfectOnly;
}

String _rainDescription(BuildContext context, double mm) {
  final s = S.of(context);
  if (mm <= 0.3) return s.rainDescDryOnly;
  if (mm <= 1.0) return s.rainDescDrizzleOk;
  if (mm <= 3.0) return s.rainDescLightRainOk;
  return s.rainDescHeavyRainOk;
}

String _windDescription(BuildContext context, double kmh) {
  final s = S.of(context);
  if (kmh <= 10) return s.windDescCalmOnly;
  if (kmh <= 20) return s.windDescBreezeOk;
  if (kmh <= 30) return s.windDescStrongOk;
  return s.windDescHardWindOk;
}

// ---------------------------------------------------------------------------
// Animated rain drops — more drops at higher intensity
// ---------------------------------------------------------------------------

class _AnimatedRainDrops extends StatefulWidget {
  final double intensity; // 0.0–1.0

  const _AnimatedRainDrops({required this.intensity});

  @override
  State<_AnimatedRainDrops> createState() => _AnimatedRainDropsState();
}

class _AnimatedRainDropsState extends State<_AnimatedRainDrops>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropCount = (widget.intensity * 12).round().clamp(1, 12);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RainPainter(
            progress: _controller.value,
            dropCount: dropCount,
            intensity: widget.intensity,
          ),
          size: const Size(double.infinity, 40),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  final int dropCount;
  final double intensity;

  _RainPainter({
    required this.progress,
    required this.dropCount,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0x4042A5F5),
        const Color(0xCC1565C0),
        intensity,
      )!
      ..strokeWidth = 1.5 + intensity
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(42);
    for (var i = 0; i < dropCount; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 0.7 + rng.nextDouble() * 0.3;
      final y = ((progress * speed + rng.nextDouble()) % 1.0) * size.height;
      final length = 4 + intensity * 6;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1, y + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.progress != progress || old.dropCount != dropCount;
}

// ---------------------------------------------------------------------------
// Animated wind flag — oscillates faster/wider at higher intensity
// ---------------------------------------------------------------------------

class _AnimatedWindFlag extends StatefulWidget {
  final double intensity; // 0.0–1.0

  const _AnimatedWindFlag({required this.intensity});

  @override
  State<_AnimatedWindFlag> createState() => _AnimatedWindFlagState();
}

class _AnimatedWindFlagState extends State<_AnimatedWindFlag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Angle: 0 at rest, up to 35 degrees at max wind
        final maxAngle = widget.intensity * 0.6; // ~35 degrees
        final angle = math.sin(_controller.value * math.pi) * maxAngle;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: angle,
              alignment: Alignment.bottomCenter,
              child: Text(
                '🚩',
                style: TextStyle(fontSize: 20 + widget.intensity * 8),
              ),
            ),
            const SizedBox(width: 8),
            // Wind lines that stretch with intensity
            ...List.generate(
              (widget.intensity * 3).round().clamp(0, 3),
              (i) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 12 + widget.intensity * 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0x33999999),
                      const Color(0x99666666),
                      widget.intensity,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// `_SectionHeader` stond hier tot v4.0 fase 23. Hij is opgegaan in
// `SectionCard` (settings_section.dart), omdat een kop zonder het vlak
// eronder geen groep maakt -- en dat vlak is precies wat dit scherm miste.
