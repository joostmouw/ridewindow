// lib/features/home/home_screen.dart
// HomeScreen: M3 Expressive redesign — SliverAppBar.medium, SegmentedButton,
// tonal ride cards, lightweight loading.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/features/shared/score_badge.dart';
import 'package:ridewindow/features/shared/weather_icon.dart';
import 'package:ridewindow/features/shared/weather_indicator_bar.dart';
import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/providers/last_refreshed_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/theme/app_theme.dart';

const _pi = math.pi;
final _sin = math.sin;
final _cos = math.cos;
final _atan2 = math.atan2;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _showHints = false;

  // GlobalKeys for spotlight coach marks
  final _weekStripKey = GlobalKey();
  final _firstCardKey = GlobalKey();
  final _periodFilterKey = GlobalKey();

  /// null = toon alle slots; non-null = filter op dag.
  DateTime? _selectedDay;

  /// Dagdeel filter: ochtend (6-12), middag (12-17), avond (17-22).
  /// Standaard: alle drie actief (geen filtering).
  final Set<_DayPeriod> _activePeriods = {
    _DayPeriod.morning,
    _DayPeriod.afternoon,
    _DayPeriod.evening,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Delay to ensure all widgets have completed layout for spotlight measurement
      await Future.delayed(const Duration(milliseconds: 500));
      if (await shouldShowHint('home') && mounted) {
        setState(() => _showHints = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(lastRefreshedProvider.notifier).refresh();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final weatherState = ref.watch(weatherProvider);
    final slotsState = ref.watch(slotsProvider);
    final locationAsync = ref.watch(locationProvider);
    final cityName = locationAsync.value?.city ?? kDefaultCity;
    final lastRefreshedAsync = ref.watch(lastRefreshedProvider);
    final userName = ref.watch(profileProvider).value?.userName;
    final slotCount = slotsState is SlotsLoaded ? slotsState.slots.length : 0;
    final greeting = _buildGreeting(context, userName);

    // Subtitle: slot count or last refreshed
    final subtitle = slotCount > 0
        ? S.of(context).rideWindowCount(slotCount)
        : lastRefreshedAsync.when(
            data: (ts) =>
                ts == null ? cityName : '${S.of(context).updatedAt(_formatTime(ts))} · $cityName',
            loading: () => cityName,
            error: (_, __) => cityName,
          );

    return Stack(
      children: [
        Scaffold(
          body: RefreshIndicator(
            color: cs.primary,
            onRefresh: () => ref.refresh(weatherProvider.future),
            edgeOffset: kToolbarHeight + MediaQuery.of(context).padding.top + 60,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Collapsing header ──
                SliverAppBar(
                  pinned: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: userName == null || userName.isEmpty
                            ? () => _showNameDialog(context)
                            : null,
                        child: _GreetingWithWhisperName(
                          greeting: _buildTimeGreeting(context),
                          name: userName,
                          baseStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          showNameHint: userName == null || userName.isEmpty,
                          hintColor: cs.primary.withAlpha(120),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  backgroundColor: cs.surface,
                  surfaceTintColor: cs.surfaceTint,
                  actions: [
                    if (weatherState.hasError)
                      IconButton(
                        icon: Icon(Icons.refresh, color: cs.primary),
                        tooltip: S.of(context).retryButton,
                        onPressed: () => ref.invalidate(weatherProvider),
                      ),
                  ],
                ),

                // ── Week strip ──
                SliverToBoxAdapter(
                  child: KeyedSubtree(
                    key: _weekStripKey,
                    child: _buildWeekStrip(slotsState),
                  ),
                ),

                // ── Period filter ──
                SliverToBoxAdapter(
                  child: KeyedSubtree(
                    key: _periodFilterKey,
                    child: _buildPeriodFilter(),
                  ),
                ),

                // ── Planned rides ──
                _buildPlannedRidesSliver(),

                // ── Section label ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      S.of(context).rideTimes,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // ── Cards ──
                _buildCardsSliver(weatherState, slotsState),

                // Bottom padding
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          ),
        ),
        if (_showHints)
          ScreenHintOverlay(
            hints: _homeHints(context),
            onDismiss: () {
              markHintSeen('home');
              setState(() => _showHints = false);
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Name dialog (when greeting is tapped without a name set)
  // ---------------------------------------------------------------------------

  Future<void> _showNameDialog(BuildContext context) async {
    final s = S.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.yourName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: s.enterYourName),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(profileProvider.notifier).setUserName(name);
    }
  }

  // ---------------------------------------------------------------------------
  // Coach mark hints
  // ---------------------------------------------------------------------------

  List<HintItem> _homeHints(BuildContext context) {
    final s = S.of(context);
    return [
      HintItem(
        targetKey: _weekStripKey,
        gestureIcon: Icons.touch_app,
        title: s.hintFilterDay,
        description: s.hintFilterDayDesc,
      ),
      HintItem(
        targetKey: _firstCardKey,
        gestureIcon: Icons.touch_app,
        title: s.hintTapRideWindow,
        description: s.hintTapRideWindowDesc,
        spotlightPadding: 4,
      ),
      HintItem(
        targetKey: _periodFilterKey,
        gestureIcon: Icons.swipe,
        title: s.hintFilterPeriod,
        description: s.hintFilterPeriodDesc,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Greeting
  // ---------------------------------------------------------------------------

  String _buildGreeting(BuildContext context, String? userName) {
    final s = S.of(context);
    final hour = DateTime.now().hour;
    final String timeGreeting;
    if (hour < 6) {
      timeGreeting = s.greetingNightOwl;
    } else if (hour < 12) {
      timeGreeting = s.greetingMorning;
    } else if (hour < 17) {
      timeGreeting = s.greetingAfternoon;
    } else {
      timeGreeting = s.greetingEvening;
    }
    if (userName != null && userName.isNotEmpty) {
      return s.greetingWithName(timeGreeting, userName);
    }
    return timeGreeting;
  }

  String _buildTimeGreeting(BuildContext context) {
    final s = S.of(context);
    final hour = DateTime.now().hour;
    if (hour < 6) return s.greetingNightOwl;
    if (hour < 12) return s.greetingMorning;
    if (hour < 17) return s.greetingAfternoon;
    return s.greetingEvening;
  }

  // ---------------------------------------------------------------------------
  // Week strip
  // ---------------------------------------------------------------------------

  Widget _buildWeekStrip(SlotsState slotsState) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days.map((day) => Expanded(child: _buildDayChip(day, slotsState))).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Period filter — SegmentedButton
  // ---------------------------------------------------------------------------

  Widget _buildPeriodFilter() {
    final s = S.of(context);
    final allActive = _activePeriods.length == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: SegmentedButton<_DayPeriod>(
        segments: [
          ButtonSegment(value: _DayPeriod.morning, label: Text(s.filterMorning), icon: const Icon(Icons.wb_sunny_outlined, size: 16)),
          ButtonSegment(value: _DayPeriod.afternoon, label: Text(s.filterAfternoon), icon: const Icon(Icons.wb_cloudy_outlined, size: 16)),
          ButtonSegment(value: _DayPeriod.evening, label: Text(s.filterEvening), icon: const Icon(Icons.nights_stay_outlined, size: 16)),
        ],
        selected: allActive ? {} : _activePeriods,
        onSelectionChanged: (selected) {
          HapticFeedback.lightImpact();
          setState(() {
            _activePeriods
              ..clear()
              ..addAll(selected);
            if (_activePeriods.isEmpty) {
              _activePeriods.addAll(_DayPeriod.values);
            }
          });
        },
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }

  bool _slotMatchesPeriod(RideSlot slot) {
    if (_activePeriods.length == 3) return true;
    final hour = slot.start.hour;
    if (hour < 12 && _activePeriods.contains(_DayPeriod.morning)) return true;
    if (hour >= 12 && hour < 17 && _activePeriods.contains(_DayPeriod.afternoon)) return true;
    if (hour >= 17 && _activePeriods.contains(_DayPeriod.evening)) return true;
    return false;
  }

  Widget _buildDayChip(DateTime day, SlotsState slotsState) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final dayLabels = [s.dayMon, s.dayTue, s.dayWed, s.dayThu, s.dayFri, s.daySat, s.daySun];
    final label = dayLabels[day.weekday - 1];
    final isToday = DateTime.now().day == day.day &&
        DateTime.now().month == day.month &&
        DateTime.now().year == day.year;
    final isSelected = _selectedDay?.day == day.day &&
        _selectedDay?.month == day.month &&
        _selectedDay?.year == day.year;

    // Bepaal dot klasse.
    _DayClass dotClass;
    if (slotsState is SlotsLoaded && slotsState.slots.isNotEmpty) {
      final daySlots = slotsState.slots.where((s) {
        return s.start.year == day.year &&
            s.start.month == day.month &&
            s.start.day == day.day;
      }).toList();

      if (daySlots.isEmpty) {
        dotClass = _DayClass.bad;
      } else {
        final bestTier = _bestTier(daySlots);
        dotClass = (bestTier is Perfect || bestTier is Great)
            ? _DayClass.good
            : _DayClass.ok;
      }
    } else {
      dotClass = _DayClass.bad;
    }

    // Kleuren
    final Color chipBg;
    final Color chipFg;
    switch (dotClass) {
      case _DayClass.good:
        chipBg = isSelected ? cs.primaryContainer : rw.tiers.perfectBg;
        chipFg = isSelected ? cs.onPrimaryContainer : rw.scorePerfect;
      case _DayClass.ok:
        chipBg = isSelected ? cs.tertiaryContainer : rw.tiers.acceptableBg;
        chipFg = isSelected ? cs.onTertiaryContainer : rw.tiers.acceptableFg;
      case _DayClass.bad:
        chipBg = isSelected ? cs.surfaceContainerHighest : rw.tiers.poorBg;
        chipFg = isSelected ? cs.onSurface : rw.tiers.poorFg;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedDay = isSelected ? null : day;
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: AppMotion.spatialDuration,
        curve: AppMotion.spatialCurve,
        child: AnimatedContainer(
        duration: AppMotion.effectsDuration,
        curve: AppMotion.effectsCurve,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: chipFg, width: 2)
              : isToday
                  ? Border.all(color: cs.outline, width: 1)
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? chipFg : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: chipFg,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Planned rides section
  // ---------------------------------------------------------------------------

  Widget _buildPlannedRidesSliver() {
    final plannedRides = ref.watch(plannedRidesProvider);
    if (plannedRides.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.plannedRidesLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...plannedRides.map((ride) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: rw.plannedRide.withAlpha(18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: rw.plannedRide.withAlpha(60)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/rides'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.event_available, size: 20, color: rw.plannedRide),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDayName(ride.start),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: rw.plannedRide,
                                ),
                              ),
                              Text(
                                '${_formatTime(ride.start)} – ${_formatTime(ride.end)} · ${ride.durationHours}u',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ScoreBadge(tier: rideTierFromScore(ride.plannedScore)),
                      ],
                    ),
                  ),
                ),
              ),
            ),),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cards section (as sliver)
  // ---------------------------------------------------------------------------

  Widget _buildCardsSliver(
    AsyncValue<List<HourlyForecast>> weatherState,
    SlotsState slotsState,
  ) {
    if (weatherState.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (weatherState.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(
          S.of(context).weatherLoadError,
          icon: Icons.error_outline,
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(weatherProvider),
            icon: const Icon(Icons.refresh),
            label: Text(S.of(context).retryButton),
          ),
        ),
      );
    }

    if (slotsState is SlotsLoaded) {
      String? emptyMessage;
      if (slotsState.reason == SlotsEmptyReason.badWeather) {
        emptyMessage = S.of(context).emptyBadWeather;
      } else if (slotsState.reason == SlotsEmptyReason.allBlocked) {
        emptyMessage = S.of(context).emptyAllBlocked;
      } else if (slotsState.slots.isEmpty) {
        emptyMessage = S.of(context).emptyNoSlots;
      }

      if (emptyMessage != null) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(emptyMessage),
        );
      }

      var slots = slotsState.slots;
      if (_selectedDay != null) {
        slots = slots.where((s) {
          return s.start.year == _selectedDay!.year &&
              s.start.month == _selectedDay!.month &&
              s.start.day == _selectedDay!.day;
        }).toList();
      }

      slots = slots.where(_slotMatchesPeriod).toList();

      if (slots.isEmpty && (_selectedDay != null || _activePeriods.length < 3)) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(S.of(context).emptyNoSlotsDay),
        );
      }

      slots.sort((a, b) => _tierOrder(a.tier).compareTo(_tierOrder(b.tier)));

      return SliverList.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final isBest = index == 0 &&
              (slots.first.tier is Perfect || slots.first.tier is Great);
          final staggerIndex = index.clamp(0, AppMotion.maxStaggerItems);
          Widget card = _buildRideCard(slots[index], isBest: isBest);
          if (index == 0) {
            card = KeyedSubtree(key: _firstCardKey, child: card);
          }
          return SpringEntrance(
            delay: AppMotion.staggerDelay * staggerIndex,
            child: card,
          );
        },
      );
    }

    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.cloud_off_outlined, Widget? action}) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ride card — M3 Expressive
  // ---------------------------------------------------------------------------

  Widget _buildRideCard(RideSlot slot, {bool isBest = false}) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final weatherState = ref.watch(weatherProvider);

    final allForecasts = weatherState.hasValue ? weatherState.requireValue : <HourlyForecast>[];
    final slotForecasts = allForecasts
        .where((f) => !f.time.isBefore(slot.start) && f.time.isBefore(slot.end))
        .toList();

    // Bereken gemiddelde weer-waarden
    final temps = slotForecasts.map((f) => f.temperatureC).whereType<double>().toList();
    final precips = slotForecasts.map((f) => f.precipitationMm).whereType<double>().toList();
    final winds = slotForecasts.map((f) => f.windspeedKmh).whereType<double>().toList();

    final avgTemp = temps.isEmpty ? null : temps.reduce((a, b) => a + b) / temps.length;
    final totalPrecip = precips.isEmpty ? null : precips.reduce((a, b) => a + b);
    final avgWind = winds.isEmpty ? null : winds.reduce((a, b) => a + b) / winds.length;

    return SpringPressEffect(
      child: Dismissible(
      key: ValueKey('slot_${slot.start.millisecondsSinceEpoch}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        await _addToCalendar(slot, slotForecasts);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: cs.onPrimaryContainer, size: 22),
            const SizedBox(width: 8),
            Text(
              S.of(context).addToCalendar,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        elevation: isBest ? 2 : 0,
        color: isBest ? cs.primaryContainer.withAlpha(50) : null,
        shape: isBest
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: cs.primary.withAlpha(80)),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push(
              '/detail',
              extra: DetailArgs(
                slot: slot,
                forecasts: slotForecasts,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Beste keuze" label
                if (isBest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: cs.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            S.of(context).bestChoice,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Card top: dag + badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          WeatherIcon(tier: slot.tier, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDayName(slot.start),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_formatTime(slot.start)} – ${_formatTime(slot.end)} · ${_durationHours(slot)}u',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScoreBadge(tier: slot.tier),
                  ],
                ),
                const SizedBox(height: 14),
                // Weather indicator bars
                if (avgTemp != null || totalPrecip != null || avgWind != null)
                  _buildWeatherBars(
                    avgTemp: avgTemp,
                    totalPrecip: totalPrecip,
                    avgWind: avgWind,
                  ),
                const SizedBox(height: 14),
                // Footer: Plan het knop
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _addToCalendar(slot, slotForecasts),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(S.of(context).schedule),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildWeatherBars({
    double? avgTemp,
    double? totalPrecip,
    double? avgWind,
  }) {
    final s = S.of(context);
    final profile = ref.watch(profileProvider).value;
    final tol = profile?.tolerances;
    final tempMin = tol?.tempMinIdealC ?? 12.0;
    final tempMax = tol?.tempMaxIdealC ?? 26.0;
    final windMax = tol?.windMaxIdealKmh ?? 15.0;
    final rainMax = tol?.rainMaxIdealMm ?? 0.5;

    return Column(
      children: [
        if (avgTemp != null)
          WeatherIndicatorBar(
            icon: Icons.thermostat,
            label: s.weatherTemperature,
            value: avgTemp,
            unit: '\u00B0',
            min: -10,
            max: 45,
            idealMin: tempMin,
            idealMax: tempMax,
            infoText: s.infoTemp,
          ),
        if (totalPrecip != null) ...[
          const SizedBox(height: 4),
          WeatherIndicatorBar(
            icon: Icons.water_drop,
            label: s.weatherRain,
            value: totalPrecip,
            unit: 'mm',
            min: 0,
            max: 10,
            idealMax: rainMax,
            infoText: s.infoRain,
          ),
        ],
        if (avgWind != null) ...[
          const SizedBox(height: 4),
          WeatherIndicatorBar(
            icon: Icons.air,
            label: s.weatherWind,
            value: avgWind,
            unit: 'km/h',
            min: 0,
            max: 60,
            idealMax: windMax,
            infoText: s.infoWind,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SnackBar
  // ---------------------------------------------------------------------------

  Future<void> _addToCalendar(RideSlot slot, List<HourlyForecast> forecasts) async {
    try {
      await CalendarService().addRideSlotToCalendar(slot, forecasts);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).addedToGoogleCalendar)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).couldNotAdd(e.toString()))),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int _durationHours(RideSlot slot) =>
      slot.end.difference(slot.start).inHours;

  String _formatDayName(DateTime dt) {
    final s = S.of(context);
    final names = [
      s.dayMonFull,
      s.dayTueFull,
      s.dayWedFull,
      s.dayThuFull,
      s.dayFriFull,
      s.daySatFull,
      s.daySunFull,
    ];
    return names[dt.weekday - 1];
  }

  RideTier _bestTier(List<RideSlot> slots) {
    return slots.reduce(
      (a, b) => _tierOrder(a.tier) <= _tierOrder(b.tier) ? a : b,
    ).tier;
  }

  int _tierOrder(RideTier tier) => switch (tier) {
        Perfect() => 0,
        Great() => 1,
        Acceptable() => 2,
        Poor() => 3,
      };

  String _windArrow(double degrees) {
    const arrows = ['\u2193', '\u2199', '\u2190', '\u2196', '\u2191', '\u2197', '\u2192', '\u2198'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return arrows[index];
  }

  Color _tierBorderColor(RideTier tier) {
    final rw = context.rw;
    return switch (tier) {
      Perfect() => rw.scorePerfect,
      Great() => rw.scoreGreat,
      Acceptable() => rw.scoreAcceptable,
      Poor() => rw.scorePoor,
    };
  }
}

// ---------------------------------------------------------------------------
// Internal enums
// ---------------------------------------------------------------------------

enum _DayClass { good, ok, bad }

enum _DayPeriod {
  morning,   // 6:00 – 11:59
  afternoon, // 12:00 – 16:59
  evening,   // 17:00 – 21:59
}

// ---------------------------------------------------------------------------
// Greeting with whisper name — greeting is static, name fades+slides in
// ---------------------------------------------------------------------------

class _GreetingWithWhisperName extends StatefulWidget {
  const _GreetingWithWhisperName({
    required this.greeting,
    this.name,
    this.baseStyle,
    this.showNameHint = false,
    this.hintColor,
  });

  final String greeting;
  final String? name;
  final TextStyle? baseStyle;
  final bool showNameHint;
  final Color? hintColor;

  @override
  State<_GreetingWithWhisperName> createState() =>
      _GreetingWithWhisperNameState();
}

class _GreetingWithWhisperNameState extends State<_GreetingWithWhisperName>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    // Start after a short delay so the user sees it
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(_GreetingWithWhisperName old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = widget.name != null && widget.name!.isNotEmpty;

    if (!hasName) {
      // No name: show greeting with dotted underline hint to set name
      return Text.rich(
        TextSpan(
          text: '${widget.greeting} ',
          style: widget.baseStyle,
          children: [
            if (widget.showNameHint)
              TextSpan(
                text: '...',
                style: widget.baseStyle?.copyWith(
                  color: widget.hintColor,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: widget.hintColor,
                ),
              ),
          ],
        ),
      );
    }

    // Has name: greeting static, name whispers in
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${widget.greeting}, ', style: widget.baseStyle),
        SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Text(widget.name!, style: widget.baseStyle),
          ),
        ),
      ],
    );
  }
}
