// lib/features/home/home_screen.dart
// HomeScreen: ConsumerStatefulWidget met week strip, ride cards per tier,
// skeleton loading state, lege staat en "Plan het" SnackBar.

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
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/services/calendar_service.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _showHints = false;

  /// null = toon alle slots; non-null = filter op dag.
  DateTime? _selectedDay;

  /// Dagdeel filter: ochtend (6-12), middag (12-17), avond (17-22).
  /// null in de set = die periode is actief. Lege set = alles uit (toon niets).
  /// Standaard: alle drie actief (geen filtering).
  final Set<_DayPeriod> _activePeriods = {
    _DayPeriod.morning,
    _DayPeriod.afternoon,
    _DayPeriod.evening,
  };

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Show screen hints on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await shouldShowHint('home') && mounted) {
        setState(() => _showHints = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Herlaad lastRefreshed timestamp bij terugkeer naar foreground (NOTIF-06)
      ref.read(lastRefreshedProvider.notifier).refresh();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final weatherState = ref.watch(weatherProvider);
    final slotsState = ref.watch(slotsProvider);
    final locationAsync = ref.watch(locationProvider);
    final cityName = locationAsync.value?.city ?? kDefaultCity;
    final lastRefreshedAsync = ref.watch(lastRefreshedProvider);
    final userName = ref.watch(profileProvider).value?.userName;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: rw.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(cityName, weatherState, lastRefreshedAsync, slotsState, userName),
                _buildWeekStrip(slotsState),
                _buildPeriodFilter(),
                Expanded(
                  child: RefreshIndicator(
                    color: rw.scorePerfect,
                    onRefresh: () => ref.refresh(weatherProvider.future),
                    child: _buildCardsSection(weatherState, slotsState),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showHints)
          ScreenHintOverlay(
            hints: homeHints(context),
            onDismiss: () {
              markHintSeen('home');
              setState(() => _showHints = false);
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    String city,
    AsyncValue<List<HourlyForecast>> weatherState,
    AsyncValue<DateTime?> lastRefreshedAsync,
    SlotsState slotsState,
    String? userName,
  ) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final slotCount = slotsState is SlotsLoaded ? slotsState.slots.length : 0;
    final greeting = _buildGreeting(context, userName);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: rw.borderDim, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: rw.textHint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 13,
                        color: rw.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      slotCount > 0
                          ? S.of(context).rideWindowCount(slotCount)
                          : lastRefreshedAsync.when(
                              data: (ts) => ts == null
                                  ? ''
                                  : S.of(context).updatedAt(_formatTime(ts)),
                              loading: () => '',
                              error: (_, __) => '',
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        color: rw.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (weatherState.hasError)
            IconButton(
              icon: Icon(Icons.refresh, color: rw.scorePerfect),
              tooltip: S.of(context).retryButton,
              onPressed: () => ref.invalidate(weatherProvider),
            ),
        ],
      ),
    );
  }

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
    } else if (hour < 21) {
      timeGreeting = s.greetingEvening;
    } else {
      timeGreeting = s.greetingEvening;
    }
    if (userName != null && userName.isNotEmpty) {
      return s.greetingWithName(timeGreeting, userName);
    }
    return timeGreeting;
  }

  // ---------------------------------------------------------------------------
  // Week strip
  // ---------------------------------------------------------------------------

  Widget _buildWeekStrip(SlotsState slotsState) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    // Vandaag + 6 dagen vooruit (altijd 7 dagen zichtbaar).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).thisWeek,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: rw.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days
                .map((day) => _buildDayChip(day, slotsState))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Period filter (ochtend / middag / avond)
  // ---------------------------------------------------------------------------

  Widget _buildPeriodFilter() {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final allActive = _activePeriods.length == 3;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _buildPeriodChip(_DayPeriod.morning, s.filterMorning, '06–12'),
          const SizedBox(width: 8),
          _buildPeriodChip(_DayPeriod.afternoon, s.filterAfternoon, '12–17'),
          const SizedBox(width: 8),
          _buildPeriodChip(_DayPeriod.evening, s.filterEvening, '17–22'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(_DayPeriod period, String label, String hours) {
    final rw = context.rw;
    final isActive = _activePeriods.contains(period);
    final allActive = _activePeriods.length == 3;
    // Als alles aan staat, toon alles als "niet gefilterd" (subtiel).
    final isHighlighted = isActive && !allActive;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (allActive) {
            // Alles staat aan → selecteer alleen deze.
            _activePeriods
              ..clear()
              ..add(period);
          } else if (isActive && _activePeriods.length == 1) {
            // Laatste actieve uitzetten → reset naar alles aan.
            _activePeriods.addAll(_DayPeriod.values);
          } else if (isActive) {
            _activePeriods.remove(period);
          } else {
            _activePeriods.add(period);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted ? rw.scorePerfect : rw.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? rw.scorePerfect : rw.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? Colors.white : rw.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              hours,
              style: TextStyle(
                fontSize: 10,
                color: isHighlighted ? Colors.white70 : rw.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _slotMatchesPeriod(RideSlot slot) {
    if (_activePeriods.length == 3) return true; // Geen filter actief.
    final hour = slot.start.hour;
    if (hour < 12 && _activePeriods.contains(_DayPeriod.morning)) return true;
    if (hour >= 12 && hour < 17 && _activePeriods.contains(_DayPeriod.afternoon)) return true;
    if (hour >= 17 && _activePeriods.contains(_DayPeriod.evening)) return true;
    return false;
  }

  Widget _buildDayChip(DateTime day, SlotsState slotsState) {
    final rw = context.rw;
    final s = S.of(context);
    final dayLabels = [s.dayMon, s.dayTue, s.dayWed, s.dayThu, s.dayFri, s.daySat, s.daySun];
    final label = dayLabels[day.weekday - 1];
    final isSelected = _selectedDay?.day == day.day &&
        _selectedDay?.month == day.month &&
        _selectedDay?.year == day.year;

    // Bepaal dot klasse en teken.
    _DayClass dotClass;
    String dotText;

    if (slotsState is SlotsLoaded && slotsState.slots.isNotEmpty) {
      final daySlots = slotsState.slots.where((s) {
        return s.start.year == day.year &&
            s.start.month == day.month &&
            s.start.day == day.day;
      }).toList();

      if (daySlots.isEmpty) {
        dotClass = _DayClass.bad;
        dotText = '\u2717';
      } else {
        final bestTier = _bestTier(daySlots);
        if (bestTier is Perfect || bestTier is Great) {
          dotClass = _DayClass.good;
          dotText = '\u2713';
        } else {
          dotClass = _DayClass.ok;
          dotText = '~';
        }
      }
    } else {
      // Nog aan het laden of geen slots.
      dotClass = _DayClass.bad;
      dotText = '?';
    }

    // Kleuren per klasse.
    final Color bgColor;
    final Color textColor;
    switch (dotClass) {
      case _DayClass.good:
        bgColor = rw.tiers.perfectBg;
        textColor = rw.scorePerfect;
      case _DayClass.ok:
        bgColor = rw.tiers.acceptableBg;
        textColor = rw.tiers.acceptableFg;
      case _DayClass.bad:
        bgColor = rw.tiers.poorBg;
        textColor = rw.errorDark;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selectedDay = null;
          } else {
            _selectedDay = day;
          }
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: rw.textHint,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? rw.scorePerfect : rw.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: rw.scorePerfect, width: 2.5)
                  : null,
            ),
            child: Center(
              child: Text(
                dotText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cards section
  // ---------------------------------------------------------------------------

  Widget _buildCardsSection(
    AsyncValue<List<HourlyForecast>> weatherState,
    SlotsState slotsState,
  ) {
    // Loading state: skeleton kaarten.
    if (weatherState.isLoading) {
      return _buildSkeletonCards();
    }

    // Error state: toon bericht.
    if (weatherState.hasError) {
      return _buildErrorState();
    }

    // Lege staat: reason of lege lijst.
    if (slotsState is SlotsLoaded) {
      final loaded = slotsState;

      String? emptyMessage;
      if (loaded.reason == SlotsEmptyReason.badWeather) {
        emptyMessage = S.of(context).emptyBadWeather;
      } else if (loaded.reason == SlotsEmptyReason.allBlocked) {
        emptyMessage = S.of(context).emptyAllBlocked;
      } else if (loaded.slots.isEmpty) {
        emptyMessage = S.of(context).emptyNoSlots;
      }

      if (emptyMessage != null) {
        return _buildEmptyState(emptyMessage);
      }

      // Filter op geselecteerde dag.
      var slots = loaded.slots;
      if (_selectedDay != null) {
        slots = slots.where((s) {
          return s.start.year == _selectedDay!.year &&
              s.start.month == _selectedDay!.month &&
              s.start.day == _selectedDay!.day;
        }).toList();
      }

      // Filter op dagdeel (ochtend/middag/avond).
      slots = slots.where(_slotMatchesPeriod).toList();

      if (slots.isEmpty && (_selectedDay != null || _activePeriods.length < 3)) {
        return _buildEmptyState(S.of(context).emptyNoSlotsDay);
      }

      // Sorteer: Perfect eerst, daarna Great, Acceptable.
      slots.sort((a, b) => _tierOrder(a.tier).compareTo(_tierOrder(b.tier)));

      return _buildRideCardList(slots);
    }

    return _buildSkeletonCards();
  }

  Widget _buildRideCardList(List<RideSlot> slots) {
    final rw = context.rw;
    return ListView.builder(
      key: const PageStorageKey('home_ride_cards'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: slots.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              S.of(context).rideTimes,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: rw.textHint,
                letterSpacing: 0.5,
              ),
            ),
          );
        }
        final isBest = index == 1 &&
            (slots.first.tier is Perfect || slots.first.tier is Great);
        return _AnimatedCardEntry(
          index: index,
          child: _buildRideCard(slots[index - 1], isBest: isBest),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    final rw = context.rw;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 64,
                      color: rw.scorePoor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: rw.textTertiary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final rw = context.rw;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: rw.scorePoor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).weatherLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: rw.textTertiary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(weatherProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(S.of(context).retryButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rw.scorePerfect,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ride card
  // ---------------------------------------------------------------------------

  Widget _buildRideCard(RideSlot slot, {bool isBest = false}) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final borderColor = _tierBorderColor(slot.tier);
    final weatherState = ref.watch(weatherProvider);

    // Bereken slot-gefilterde forecast-uren voor weather chips en tap-navigatie.
    // Filter op [slot.start, slot.end) — exclusief eindpunt (SLOT-02 conventie).
    final allForecasts = weatherState.hasValue ? weatherState.requireValue : <HourlyForecast>[];
    final slotForecasts = allForecasts
        .where((f) => !f.time.isBefore(slot.start) && f.time.isBefore(slot.end))
        .toList();

    // Bereken gemiddelde temperatuur, totale neerslag en gemiddelde windsnelheid.
    final temps = slotForecasts
        .map((f) => f.temperatureC)
        .where((v) => v != null)
        .cast<double>()
        .toList();
    final precips = slotForecasts
        .map((f) => f.precipitationMm)
        .where((v) => v != null)
        .cast<double>()
        .toList();
    final winds = slotForecasts
        .map((f) => f.windspeedKmh)
        .where((v) => v != null)
        .cast<double>()
        .toList();

    final avgTemp = temps.isEmpty
        ? null
        : temps.reduce((a, b) => a + b) / temps.length;
    final totalPrecip =
        precips.isEmpty ? null : precips.reduce((a, b) => a + b);
    final avgWind = winds.isEmpty
        ? null
        : winds.reduce((a, b) => a + b) / winds.length;

    // Feels like temperature
    final apparents = slotForecasts
        .map((f) => f.apparentTemperatureC)
        .where((v) => v != null)
        .cast<double>()
        .toList();
    final avgApparent = apparents.isEmpty
        ? null
        : apparents.reduce((a, b) => a + b) / apparents.length;

    // Wind direction (circular mean)
    double? avgWindDir;
    {
      final dirs = slotForecasts
          .map((f) => f.winddirectionDeg)
          .whereType<double>()
          .toList();
      if (dirs.isNotEmpty) {
        double sinSum = 0, cosSum = 0;
        for (final d in dirs) {
          sinSum += _sin(d * _pi / 180);
          cosSum += _cos(d * _pi / 180);
        }
        avgWindDir = (_atan2(sinSum, cosSum) * 180 / _pi + 360) % 360;
      }
    }

    // Precipitation probability
    final precipProbs = slotForecasts
        .map((f) => f.precipitationProbability)
        .whereType<double>()
        .toList();
    final avgPrecipProb = precipProbs.isEmpty
        ? null
        : precipProbs.reduce((a, b) => a + b) / precipProbs.length;

    final tempLabel = avgTemp == null
        ? '\u2014'
        : avgApparent != null && (avgApparent - avgTemp).abs() >= 2
            ? '${avgTemp.round()}\u00B0 (${avgApparent.round()}\u00B0)'
            : '${avgTemp.toStringAsFixed(1)}\u00B0C';
    final precipLabel = totalPrecip == null
        ? '\u2014'
        : avgPrecipProb != null && avgPrecipProb > 0
            ? '${totalPrecip.toStringAsFixed(1)}mm (${avgPrecipProb.round()}%)'
            : '${totalPrecip.toStringAsFixed(1)}mm';
    final windLabel = avgWind == null
        ? '\u2014'
        : avgWind < 5
            ? S.of(context).windCalm
            : avgWindDir != null
                ? '${_windArrow(avgWindDir)} ${avgWind.toStringAsFixed(0)}km/h'
                : '${avgWind.toStringAsFixed(0)}km/h';

    return Dismissible(
      key: ValueKey('slot_${slot.start.millisecondsSinceEpoch}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        await _addToCalendar(slot, slotForecasts);
        return false; // Don't actually dismiss the card
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: rw.scorePerfect,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              S.of(context).addToCalendar,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(
          '/detail',
          extra: DetailArgs(
            slot: slot,
            forecasts: slotForecasts,
            heroTag: 'score_${slot.start.millisecondsSinceEpoch}',
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isBest
              ? LinearGradient(
                  colors: [rw.greenGradientStart, cs.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isBest ? null : cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: isBest ? rw.bestHighlight : rw.normalHighlight,
              blurRadius: isBest ? 12 : 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Beste keuze" label
              if (isBest)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: rw.scorePerfect,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      S.of(context).bestChoice,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              // Card top: dag + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WeatherIcon(tier: slot.tier, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        _formatDayName(slot.start),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rw.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  ScoreBadge(
                    tier: slot.tier,
                    heroTag: 'score_${slot.start.millisecondsSinceEpoch}',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Tijdreeks
              Text(
                '${_formatTime(slot.start)} \u2013 ${_formatTime(slot.end)} \u00B7 ${_durationHours(slot)}u',
                style: TextStyle(
                  fontSize: 14,
                  color: rw.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              // Weather indicator bars
              if (avgTemp != null || totalPrecip != null || avgWind != null)
                _buildWeatherBars(
                  avgTemp: avgTemp,
                  totalPrecip: totalPrecip,
                  avgWind: avgWind,
                ),
              const SizedBox(height: 12),
              // Footer: Plan het knop
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addToCalendar(slot, slotForecasts),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slot.tier is Acceptable
                          ? rw.scoreAcceptable
                          : rw.scorePerfect,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      S.of(context).schedule,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),  // close Dismissible
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
  // Skeleton loading
  // ---------------------------------------------------------------------------

  Widget _buildSkeletonCards() {
    final rw = context.rw;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: rw.border,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      }),
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
          SnackBar(
            content: Text(S.of(context).addedToGoogleCalendar),
          ),
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
    // Wind direction is where wind comes FROM, arrow shows direction
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
// Internal enum for day chip colour class
// ---------------------------------------------------------------------------

enum _DayClass { good, ok, bad }

enum _DayPeriod {
  morning,   // 6:00 – 11:59
  afternoon, // 12:00 – 16:59
  evening,   // 17:00 – 21:59
}

// ---------------------------------------------------------------------------
// Staggered fade+slide animation wrapper for ride cards
// ---------------------------------------------------------------------------

class _AnimatedCardEntry extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedCardEntry({required this.child, required this.index});

  @override
  State<_AnimatedCardEntry> createState() => _AnimatedCardEntryState();
}

class _AnimatedCardEntryState extends State<_AnimatedCardEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );
  }
}
