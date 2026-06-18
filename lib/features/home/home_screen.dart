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
import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/providers/last_refreshed_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/services/calendar_service.dart';

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
    final weatherState = ref.watch(weatherProvider);
    final slotsState = ref.watch(slotsProvider);
    final locationAsync = ref.watch(locationProvider);
    final cityName = locationAsync.value?.city ?? kDefaultCity;
    final lastRefreshedAsync = ref.watch(lastRefreshedProvider);
    final userName = ref.watch(profileProvider).value?.userName;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(cityName, weatherState, lastRefreshedAsync, slotsState, userName),
                _buildWeekStrip(slotsState),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF2E7D32),
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
            hints: homeHints,
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
    final slotCount = slotsState is SlotsLoaded ? slotsState.slots.length : 0;
    final greeting = _buildGreeting(userName);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
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
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF999999),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      slotCount > 0
                          ? '$slotCount ride${slotCount == 1 ? '' : 's'} this week'
                          : lastRefreshedAsync.when(
                              data: (ts) => ts == null
                                  ? ''
                                  : 'Updated ${_formatTime(ts)}',
                              loading: () => '',
                              error: (_, __) => '',
                            ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (weatherState.hasError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
              tooltip: 'Retry',
              onPressed: () => ref.invalidate(weatherProvider),
            ),
        ],
      ),
    );
  }

  String _buildGreeting(String? userName) {
    final hour = DateTime.now().hour;
    final String timeGreeting;
    if (hour < 6) {
      timeGreeting = 'Night owl';
    } else if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else if (hour < 21) {
      timeGreeting = 'Good evening';
    } else {
      timeGreeting = 'Good evening';
    }
    if (userName != null && userName.isNotEmpty) {
      return '$timeGreeting, $userName';
    }
    return timeGreeting;
  }

  // ---------------------------------------------------------------------------
  // Week strip
  // ---------------------------------------------------------------------------

  Widget _buildWeekStrip(SlotsState slotsState) {
    // Bereken maandag van de huidige week.
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - DateTime.monday));
    final days = List.generate(
      7,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEZE WEEK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF999999),
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

  Widget _buildDayChip(DateTime day, SlotsState slotsState) {
    const dayLabels = ['MA', 'DI', 'WO', 'DO', 'VR', 'ZA', 'ZO'];
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
        dotText = '✗';
      } else {
        final bestTier = _bestTier(daySlots);
        if (bestTier is Perfect || bestTier is Great) {
          dotClass = _DayClass.good;
          dotText = '✓';
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
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
      case _DayClass.ok:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
      case _DayClass.bad:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF666666),
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
                  ? Border.all(color: const Color(0xFF2E7D32), width: 2.5)
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
        emptyMessage =
            'Geen goede rijmomenten deze week. Slecht weer verwacht.';
      } else if (loaded.reason == SlotsEmptyReason.allBlocked) {
        emptyMessage =
            'Alle goede momenten zijn geblokkeerd. Pas je schema aan.';
      } else if (loaded.slots.isEmpty) {
        emptyMessage = 'Geen rijmomenten gevonden.';
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

      if (slots.isEmpty && _selectedDay != null) {
        return _buildEmptyState('Geen rijmomenten op deze dag.');
      }

      // Sorteer: Perfect eerst, daarna Great, Acceptable.
      slots.sort((a, b) => _tierOrder(a.tier).compareTo(_tierOrder(b.tier)));

      return _buildRideCardList(slots);
    }

    return _buildSkeletonCards();
  }

  Widget _buildRideCardList(List<RideSlot> slots) {
    return ListView.builder(
      key: const PageStorageKey('home_ride_cards'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: slots.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'RIJTIJDEN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF999999),
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
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 64,
                      color: Color(0xFFBDBDBD),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF666666),
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFBDBDBD),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Weersdata kon niet worden geladen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(weatherProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Opnieuw proberen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
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
        ? '—'
        : avgApparent != null && (avgApparent - avgTemp).abs() >= 2
            ? '${avgTemp.round()}° (${avgApparent.round()}°)'
            : '${avgTemp.toStringAsFixed(1)}°C';
    final precipLabel = totalPrecip == null
        ? '—'
        : avgPrecipProb != null && avgPrecipProb > 0
            ? '${totalPrecip.toStringAsFixed(1)}mm (${avgPrecipProb.round()}%)'
            : '${totalPrecip.toStringAsFixed(1)}mm';
    final windLabel = avgWind == null
        ? '—'
        : avgWind < 5
            ? 'Windstil'
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
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Toevoegen aan agenda',
              style: TextStyle(
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
              ? const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isBest ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: isBest ? const Color(0x292E7D32) : const Color(0x12000000),
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
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Beste keuze',
                      style: TextStyle(
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
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
                '${_formatTime(slot.start)} – ${_formatTime(slot.end)} · ${_durationHours(slot)}u',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF444444),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              // Weather chips met echte gemiddelde weersdata
              Row(
                children: [
                  _buildWeatherChip('🌡', tempLabel),
                  const SizedBox(width: 6),
                  _buildWeatherChip('🌧', precipLabel),
                  const SizedBox(width: 6),
                  _buildWeatherChip('💨', windLabel),
                ],
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
                          ? const Color(0xFFFFA726)
                          : const Color(0xFF2E7D32),
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
                    label: const Text(
                      'Inplannen',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildWeatherChip(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $value',
        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Skeleton loading
  // ---------------------------------------------------------------------------

  Widget _buildSkeletonCards() {
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
              color: const Color(0xFFE0E0E0),
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
          const SnackBar(
            content: Text('Rijvenster toegevoegd aan Google Agenda!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kon niet toevoegen: $e')),
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
    const names = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrijdag',
      'Zaterdag',
      'Zondag',
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
    const arrows = ['↓', '↙', '←', '↖', '↑', '↗', '→', '↘'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return arrows[index];
  }

  Color _tierBorderColor(RideTier tier) => switch (tier) {
        Perfect() => const Color(0xFF2E7D32),
        Great() => const Color(0xFF66BB6A),
        Acceptable() => const Color(0xFFFFA726),
        Poor() => const Color(0xFFBDBDBD),
      };

}

// ---------------------------------------------------------------------------
// Internal enum for day chip colour class
// ---------------------------------------------------------------------------

enum _DayClass { good, ok, bad }

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
