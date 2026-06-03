// lib/features/home/home_screen.dart
// HomeScreen: ConsumerStatefulWidget met week strip, ride cards per tier,
// skeleton loading state, lege staat en "Plan het" SnackBar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// null = toon alle slots; non-null = filter op dag.
  DateTime? _selectedDay;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final slotsState = ref.watch(slotsProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(location.city, weatherState),
            _buildWeekStrip(slotsState),
            Expanded(child: _buildCardsSection(weatherState, slotsState)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    String city,
    AsyncValue<List<HourlyForecast>> weatherState,
  ) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.watch_later_outlined,
                    size: 18,
                    color: Color(0xFF666666),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'This week',
                style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
            ],
          ),
          const Spacer(),
          if (weatherState.hasError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
              tooltip: 'Opnieuw proberen',
              onPressed: () => ref.invalidate(weatherProvider),
            ),
        ],
      ),
    );
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
          const SizedBox(height: 5),
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
        return _buildRideCard(slots[index - 1]);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
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
    );
  }

  Widget _buildErrorState() {
    return Center(
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
    );
  }

  // ---------------------------------------------------------------------------
  // Ride card
  // ---------------------------------------------------------------------------

  Widget _buildRideCard(RideSlot slot) {
    final borderColor = _tierBorderColor(slot.tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card top: dag + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDayName(slot.start),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                _buildBadge(slot.tier),
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
            // Weather chips placeholder (Phase 5 zal echte data vullen)
            Row(
              children: [
                _buildWeatherChip('🌡', '?°C'),
                const SizedBox(width: 6),
                _buildWeatherChip('🌧', '?mm'),
                const SizedBox(width: 6),
                _buildWeatherChip('💨', '?km/u'),
              ],
            ),
            const SizedBox(height: 12),
            // Footer: Plan het knop
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _showPlanItSnackBar,
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
                  child: const Text(
                    'Plan het',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(RideTier tier) {
    final Color bg;
    final Color fg;
    switch (tier) {
      case Perfect():
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
      case Great():
        bg = const Color(0xFFF1F8E9);
        fg = const Color(0xFF33691E);
      case Acceptable():
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
      case Poor():
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF757575);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _tierLabel(tier),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
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
  // Bottom navigation
  // ---------------------------------------------------------------------------

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        // Profiel-navigatie komt in Phase 6.
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profiel',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SnackBar
  // ---------------------------------------------------------------------------

  void _showPlanItSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Google Calendar integratie komt in een volgende update.',
        ),
      ),
    );
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

  Color _tierBorderColor(RideTier tier) => switch (tier) {
        Perfect() => const Color(0xFF2E7D32),
        Great() => const Color(0xFF66BB6A),
        Acceptable() => const Color(0xFFFFA726),
        Poor() => const Color(0xFFBDBDBD),
      };

  String _tierLabel(RideTier tier) => switch (tier) {
        Perfect() => 'Perfect',
        Great() => 'Goed',
        Acceptable() => 'Acceptabel',
        Poor() => 'Slecht',
      };
}

// ---------------------------------------------------------------------------
// Internal enum for day chip colour class
// ---------------------------------------------------------------------------

enum _DayClass { good, ok, bad }
