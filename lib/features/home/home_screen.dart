// lib/features/home/home_screen.dart
// HomeScreen: M3 Expressive redesign — SliverAppBar.medium, SegmentedButton,
// tonal ride cards, lightweight loading.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_verdict.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/features/shared/score_badge.dart';
import 'package:ridewindow/features/shared/score_display.dart';
import 'package:ridewindow/features/shared/unplan_confirm_dialog.dart';
import 'package:ridewindow/features/shared/weather_icon.dart';
import 'package:ridewindow/features/shared/weather_indicator_bar.dart';
import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/providers/last_refreshed_provider.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Vorm van een ride-kaart. De Dismissible-clip, de kaartrand en de
/// InkWell-ripple gebruiken dezelfde waarden, zodat je precies het blokje
/// wegveegt dat de gebruiker ziet.
const _rideCardMargin = EdgeInsets.symmetric(horizontal: 20, vertical: 6);
const double _rideCardRadius = 24;

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

  /// Ritkaarten die de gebruiker zélf open of dicht heeft gezet, op begintijd.
  ///
  /// Bewust een `Map` en geen `Set`, want er zijn drie toestanden en geen twee:
  /// niet aangeraakt (volg de standaard), expliciet open, expliciet dicht. De
  /// standaard is de beste kaart open en de rest dicht — de compacte regel is
  /// de rusttoestand, want drie volle balken op élke kaart is precies waarom de
  /// lijst als één massa las.
  ///
  /// **Élke kaart kan open én dicht, ook de beste.** In de eerste versie stond
  /// de beste permanent open; Joost merkte terecht op dat één kaart die als
  /// enige niet gehoorzaamt aan een interactie die alle andere wél hebben, geen
  /// keuze is maar een half afgemaakte feature.
  ///
  /// `slot.start` is de sleutel omdat een `RideSlot` geen id heeft en de lijst
  /// bij elke weerverversing opnieuw wordt opgebouwd; de begintijd overleeft
  /// dat en een index niet — anders staat na een refresh een ándere kaart open
  /// dan die je hebt aangetikt.
  final Map<DateTime, bool> _cardExpanded = {};

  /// Toont RIDE TIMES de volledige lijst in plaats van alleen de beste
  /// [_kVisibleSlotCount]?
  ///
  /// Home rendert zonder plafond élk gevonden tijdvak — bij Joost waren dat er
  /// 64, ruim 11.000 pixels scrollen (waargenomen 2026-09-07). Dat botst met
  /// waar dit scherm voor is: *at a glance* de béste momenten van je week. Bij
  /// 64 kaarten is er geen glance meer, en juist het woord "beste" verdwijnt in
  /// de massa.
  ///
  /// Bewust ter plekke uitklappen en niet een eigen scherm: de dagstrip en het
  /// periodefilter blijven dan gewoon staan, er komt geen derde plek bij waar
  /// een ritkaart getekend wordt, en wie alles wil zien heeft dat op dat moment
  /// zelf gevraagd.
  bool _showAllSlots = false;

  /// Hoeveel tijdvakken RIDE TIMES standaard toont. De lijst is gesorteerd op
  /// tier met de beste vooraan, dus dit zijn ook echt de vijf beste — en bij een
  /// actief filter de vijf beste bínnen die selectie.
  static const _kVisibleSlotCount = 5;

  /// Hoeveel geplande ritten PLANNED standaard toont. Lager dan bij de
  /// tijdvakken omdat dit geen keuzelijst is maar een geheugensteun: wat komt
  /// er nu aan. De rest staat compleet op het tabblad Rides.
  static const _kVisiblePlannedCount = 3;

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
    // Backlog #61: fire-and-forget opstart-reconcile. Zonder deze aanroep hing
    // de pull uit de cloud uitsluitend aan didChangeAppLifecycleState hieronder,
    // en die vuurt niet bij het opstarten -- een verse installatie met een
    // geldige sessie toonde daardoor een lege PLANNED-lijst tot de gebruiker de
    // app eenmaal wegzette. Bewust niet geawait en zonder setState: §4's grens
    // van 2 seconden tot het eerste ride slot mag hier niet aan hangen. De
    // methode is one-shot per account, dus opnieuw naar Home navigeren kost
    // geen tweede reconcile.
    ref.read(cloudSyncReconcilerProvider).reconcileOnStartup();
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
      // SYNC-04: fire-and-forget, never awaited in the UI path -- silently
      // pulls a newer cloud row for a signed-in user on both platforms.
      // Unlike the weatherProvider invalidate below, this is NOT gated on
      // isWebPlatform: AppLifecycleState.resumed fires on native too.
      ref.read(cloudSyncReconcilerProvider).reconcileOnForeground();
      // REFRESH-01: on web there is no WorkManager background task, so
      // regaining tab/app focus must itself trigger the cache-then-network
      // fetch. This is intentionally a no-op on native (isWebPlatform false)
      // to avoid a redundant/duplicate fetch on every app switch there --
      // native keeps relying on its existing WorkManager periodic task.
      if (isWebPlatform) {
        ref.invalidate(weatherProvider);
      }
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
    // REFRESH-03: keeps lastRefreshedProvider in sync with every successful
    // weather resolution (initial load, pull-to-refresh, and the resume-
    // triggered invalidate above) -- not just the lifecycle-resume moment
    // that previously drove lastRefreshedProvider's own re-read.
    ref.listen<AsyncValue<List<HourlyForecast>>>(weatherProvider,
        (previous, next) {
      if (next.hasValue) {
        ref.read(lastRefreshedProvider.notifier).refresh();
      }
    });
    final slotsState = ref.watch(slotsProvider);
    final locationAsync = ref.watch(locationProvider);
    final cityName = locationAsync.value?.city ?? kDefaultCity;
    final lastRefreshedAsync = ref.watch(lastRefreshedProvider);
    final userName = ref.watch(profileProvider).value?.userName;
    final slotCount = slotsState is SlotsLoaded ? slotsState.slots.length : 0;
    final greeting = _buildGreeting(context, userName);

    // Subtitle: last-updated label is appended whenever known, regardless of
    // slot count (REFRESH-03), while preserving the existing priority of
    // showing ride-count vs. city name as the primary segment.
    final lastUpdatedLabel = lastRefreshedAsync.when(
      data: (ts) =>
          ts == null ? null : S.of(context).updatedAt(_formatTime(ts)),
      loading: () => null,
      error: (_, __) => null,
    );
    final primary =
        slotCount > 0 ? S.of(context).rideWindowCount(slotCount) : cityName;
    final subtitle =
        lastUpdatedLabel != null ? '$primary · $lastUpdatedLabel' : primary;

    return Stack(
      children: [
        Scaffold(
          body: RefreshIndicator(
            color: cs.primary,
            onRefresh: () => ref.refresh(weatherProvider.future),
            edgeOffset:
                kToolbarHeight + MediaQuery.of(context).padding.top + 60,
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
                          baseStyle:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          showNameHint: userName == null || userName.isEmpty,
                          hintColor: cs.primary.withAlpha(120),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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

                // ── Stale/offline banner (REFRESH-04) ──
                if (weatherState.hasError && weatherState.hasValue)
                  SliverToBoxAdapter(
                    child: _buildStaleBanner(context, lastRefreshedAsync.value),
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
        children: days
            .map((day) => Expanded(child: _buildDayChip(day, slotsState)))
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Period filter — SegmentedButton
  // ---------------------------------------------------------------------------

  /// Was een `SegmentedButton` met drie omrande vakken en een icoon per vak.
  /// Dat is een zware vorm voor een licht filter: het stond als een volledige
  /// knoppenbalk pal boven de ritkaarten en trok evenveel aandacht als het
  /// antwoord eronder. Nu drie woorden met een onderstreping -- dezelfde
  /// gedachte als de dagstrip hierboven, waar de kwaliteit ook een streepje
  /// werd in plaats van een vlak.
  ///
  /// De iconen (zon, wolk, maan) zijn met de vakken meegegaan. Ze waren
  /// decoratie: "Morning" zegt al wat er staat, en drie iconen op een rij die
  /// niets toevoegen is precies het soort ruis dat deze stap moet wegnemen.
  Widget _buildPeriodFilter() {
    final s = S.of(context);
    // Alle drie actief betekent "geen filter", en dan hoort er niets
    // onderstreept te zijn -- anders leest een ongefilterde lijst als een
    // gefilterde. Dit is dezelfde afspraak als de `selected: allActive ? {}`
    // die de `SegmentedButton` hier had.
    final allActive = _activePeriods.length == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _buildPeriodItem(_DayPeriod.morning, s.filterMorning, allActive),
          _buildPeriodItem(_DayPeriod.afternoon, s.filterAfternoon, allActive),
          _buildPeriodItem(_DayPeriod.evening, s.filterEvening, allActive),
        ],
      ),
    );
  }

  Widget _buildPeriodItem(_DayPeriod period, String label, bool allActive) {
    final cs = Theme.of(context).colorScheme;
    final isOn = !allActive && _activePeriods.contains(period);

    return Expanded(
      child: Semantics(
        selected: isOn,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              // Vanuit "alles aan" is een tik een keuze vóór dat dagdeel, niet
              // het uitzetten ervan -- anders moet je twee keer tikken om te
              // krijgen wat je bedoelde. De `SegmentedButton` deed dit vanzelf
              // omdat hij in die staat niets geselecteerd toonde.
              if (allActive) {
                _activePeriods
                  ..clear()
                  ..add(period);
              } else if (_activePeriods.contains(period)) {
                _activePeriods.remove(period);
                // Alles uit betekent niets te zien. Terug naar alles aan, wat
                // ook was wat `emptySelectionAllowed` hier opving.
                if (_activePeriods.isEmpty) {
                  _activePeriods.addAll(_DayPeriod.values);
                }
              } else {
                _activePeriods.add(period);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isOn ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 5),
                // Uit is een haarlijn, niet niets. Met alle drie de dagdelen
                // aan — de standaard, en dus wat je het vaakst ziet — was er
                // anders geen enkele onderstreping, en dan leest deze rij als
                // een bijschrift in plaats van als een filter dat je kunt
                // bedienen. Drie streepjes op een rij zeggen "hier valt te
                // kiezen"; welke aan staat zegt de dikte en de kleur.
                AnimatedContainer(
                  duration: AppMotion.effectsDuration,
                  curve: AppMotion.effectsCurve,
                  height: isOn ? 3 : 1,
                  width: 28,
                  decoration: BoxDecoration(
                    color: isOn ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _slotMatchesPeriod(RideSlot slot) {
    if (_activePeriods.length == 3) return true;
    final hour = slot.start.hour;
    if (hour < 12 && _activePeriods.contains(_DayPeriod.morning)) return true;
    if (hour >= 12 &&
        hour < 17 &&
        _activePeriods.contains(_DayPeriod.afternoon)) return true;
    if (hour >= 17 && _activePeriods.contains(_DayPeriod.evening)) return true;
    return false;
  }

  Widget _buildDayChip(DateTime day, SlotsState slotsState) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final dayLabels = [
      s.dayMon,
      s.dayTue,
      s.dayWed,
      s.dayThu,
      s.dayFri,
      s.daySat,
      s.daySun
    ];
    final label = dayLabels[day.weekday - 1];
    final isToday = DateTime.now().day == day.day &&
        DateTime.now().month == day.month &&
        DateTime.now().year == day.year;
    final isSelected = _selectedDay?.day == day.day &&
        _selectedDay?.month == day.month &&
        _selectedDay?.year == day.year;

    // Bepaal dot klasse.
    // De béste rit van die dag bepaalt de kleur — dat is de vraag die je aan
    // een weekstrip stelt ("valt er die dag iets te rijden"), niet het
    // gemiddelde. `null` betekent: die dag heeft geen enkel venster.
    RideTier? bestTier;
    if (slotsState is SlotsLoaded && slotsState.slots.isNotEmpty) {
      final daySlots = slotsState.slots.where((s) {
        return s.start.year == day.year &&
            s.start.month == day.month &&
            s.start.day == day.day;
      }).toList();
      if (daySlots.isNotEmpty) bestTier = _bestTier(daySlots);
    }

    // Twee dingen, twee kanalen -- en dat was precies het probleem.
    //
    // Tot fase 23 droeg de achtergrondkleur van een dagchip zowel de kwaliteit
    // van die dag (groen/oranje/grijs) als of hij geselecteerd was
    // (primaryContainer/tertiaryContainer/wit). Twee betekenissen op één eigen-
    // schap, en het resultaat was een rij van zeven gekleurde blokjes die met de
    // ritkaarten eronder concurreerde in plaats van ze te dienen.
    //
    // Nu: **kwaliteit is de onderstreping**, **selectie is de vulling**. De
    // vulling is bewust een neutrale tonale trap en geen tierkleur, zodat je de
    // twee nooit meer met elkaar kunt verwarren.
    // Alle vier de niveaus, in exact de kleuren die de score op de ritkaart
    // eronder ook gebruikt (`ScoreDisplay` leest uit dezelfde `tiers`).
    //
    // Dit stond tot 2026-09-07 op drie niveaus, waarbij Perfect en Great samen
    // "goed" waren. Daardoor zag een dag met 99 er hetzelfde uit als een dag
    // met 71 -- en groen dekte de hele band van 70 tot 100, dus in een
    // redelijke week was de héle strip groen en zei hij niets. Precies het
    // onderscheid dat de kaarten eronder wél maken, gooide de strip weg.
    // Joost zag dat meteen ("deze zijn nu allemaal groen").
    //
    // `Poor` is in de praktijk onbereikbaar: `removeHiddenPoor` (SLOT-04)
    // haalt alles onder de 50 eruit vóórdat deze strip het ziet. Hij staat er
    // toch, want een `switch` op een sealed class hoort compleet te zijn en
    // niet te leunen op een filter twee lagen verderop.
    final Color qualityColor = switch (bestTier) {
      Perfect() => rw.tiers.perfectFg,
      Great() => rw.tiers.greatFg,
      Acceptable() => rw.tiers.acceptableFg,
      Poor() => rw.tiers.poorFg,
      null => rw.tiers.poorFg,
    };

    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedDay = isSelected ? null : day;
          });
        },
        // De `AnimatedScale` van 1.08 is vervallen. Een chip die opspringt trekt
        // aandacht naar het filter terwijl het antwoord eronder staat -- en
        // "rustiger" is de hele opdracht van deze stap. De haptische tik blijft,
        // dus de bevestiging bij het aanraken is niet weg.
        child: AnimatedContainer(
          duration: AppMotion.effectsDuration,
          curve: AppMotion.effectsCurve,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
          decoration: BoxDecoration(
            color: isSelected ? cs.surfaceContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                // Vandaag was een randje van 1px om de chip. Zonder vulling
                // heeft zo'n randje niets meer om omheen te liggen, en het
                // botste bovendien met de rand die selectie aangaf. Nu draagt
                // het weekdaglabel het: vandaag in de merkkleur, de rest grijs.
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isToday ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              // Het dagnummer draagt dezelfde kleur als het streepje eronder:
              // de dag néémt de kleur van zijn beste rit over in plaats van
              // hem alleen als randje mee te krijgen. Joost's keuze
              // (2026-09-07) toen bleek dat één streepje van 3px te weinig was
              // om het verschil tussen een perfecte en een goede dag te zien.
              //
              // Dit blijft één kanaal, geen twee: kleur is kwaliteit, en
              // selectie is nog steeds uitsluitend de vulling. Alle vier de
              // tierkleuren zijn donker (#1B5E20, #006457, #A42E0A, #585858),
              // dus dit kost geen leesbaarheid op papier.
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: qualityColor,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 5),
              // De kwaliteit van de dag, als balk over de volle breedte van de
              // dag in plaats van een streepje van 18px.
              //
              // Op 3×18 was de kleur niet af te lezen: de vier tierkleuren zijn
              // allemaal donker, en op zo'n oppervlak zien #1B5E20 (perfect) en
              // #006457 (great) er allebei uit als zwart. Kleur heeft oppervlak
              // nodig om kleur te zíjn. Vier px over de volle dagbreedte is nog
              // steeds geen gevuld blok — de reden dat de gekleurde chips
              // moesten verdwijnen blijft staan — maar wel genoeg om groen van
              // teal te onderscheiden zonder erop te turen.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedContainer(
                  duration: AppMotion.effectsDuration,
                  curve: AppMotion.effectsCurve,
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: qualityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
    final plannedRides =
        ref.watch(plannedRidesProvider).value ?? const <PlannedRide>[];
    // Gedeelde ritten van een maatje waar je ja op hebt gezegd horen hier
    // net zo goed te staan als je eigen ritten -- dat is het hele punt van
    // accepteren. Ze krijgen geen rij in `planned_rides` (die blijft strikt
    // persoonlijk), dus dit is een weergavelaag: twee bronnen, één lijst,
    // gesorteerd op begintijd zodat je week klopt in plaats van dat de
    // gedeelde ritten er als blok onder hangen.
    final joinedRides =
        ref.watch(joinedGroupRidesProvider).value ?? const <GroupRide>[];
    if (plannedRides.isEmpty && joinedRides.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    final entries = <_PlannedEntry>[
      for (final r in plannedRides) _PlannedEntry(ride: r),
      for (final g in joinedRides)
        _PlannedEntry(
          // Een wegwerp-`PlannedRide` puur om te tonen en om het detailscherm
          // te kunnen openen -- hij wordt nooit opgeslagen. `planned_rides`
          // blijft strikt persoonlijk (keuze 2 van epic #62); een gedeelde rit
          // hoort in `group_rides` en nergens anders.
          ride: PlannedRide(
            start: g.start,
            end: g.end,
            plannedScore: g.plannedScore,
          ),
          ownerName: g.ownerName,
        ),
    ]..sort((a, b) => a.ride.start.compareTo(b.ride.start));

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
            // Afgetopt op de eerstvolgende drie. PLANNED is geen keuzelijst
            // maar een geheugensteun -- wat komt er nu aan -- en twintig
            // geplande ritten zouden de tijdvakken waar dit scherm voor bestaat
            // van het scherm duwen.
            ...entries.take(_kVisiblePlannedCount).map(_buildPlannedRideCard),
            if (entries.length > _kVisiblePlannedCount)
              _buildMorePlannedRow(entries.length - _kVisiblePlannedCount),
          ],
        ),
      ),
    );
  }

  /// De rij onder PLANNED die naar de rest verwijst.
  ///
  /// Navigeert bewust naar het tabblad Rides in plaats van hier uit te klappen:
  /// dat tabblad ís al de volledige lijst met geplande ritten. Een tweede
  /// volledige lijst bouwen op Home zou hetzelfde scherm twee keer maken --
  /// en de app hoort geen huiswerk achter te laten, dus je gaat naar de plek
  /// die er al voor is.
  Widget _buildMorePlannedRow(int hidden) {
    final s = S.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.go('/rides');
        },
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text(s.morePlannedRides(hidden)),
        style: TextButton.styleFrom(
          foregroundColor: context.rw.plannedRide,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  /// Eén kaart onder PLANNED. Twee soorten, bewust in dezelfde vorm: je eigen
  /// geplande rit, en een gedeelde rit van een maatje waar je ja op hebt
  /// gezegd. Het verschil zit in twee dingen en verder niets — de gedeelde rit
  /// draagt de naam van de organisator, en hij heeft geen prullenbak, want je
  /// kunt de rit van een ander niet weggooien. Afzeggen gebeurt op de
  /// Peloton-tab, waar ook de rest van de gedeelde ritten staat.
  Widget _buildPlannedRideCard(_PlannedEntry entry) {
    final ride = entry.ride;
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final owner = entry.ownerName?.trim();
    final isShared = entry.isShared;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: rw.plannedRide.withAlpha(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Op volle sterkte, en 2px, precies zoals de agendacel (zie
          // `week_agenda_screen.dart`: een geplande cel houdt zijn scorekleur en
          // krijgt er een volle `plannedRide`-rand omheen). De rand stond hier
          // op alpha 60 en las daardoor als grijsblauw: zelfde token, ander
          // ding — terwijl het in beide schermen letterlijk dezelfde geplande
          // rit is. Joost zag dat direct (2026-09-07). De vulling blijft licht;
          // die draagt het blauw niet, de rand doet dat.
          side: BorderSide(color: rw.plannedRide, width: 2),
        ),
        // `Material.clipBehavior` staat standaard op `Clip.none`, en dan volgt
        // de inkt van de `InkWell` de rechthoek in plaats van de afgeronde
        // vorm. In rust zie je daar niets van; zodra je indrukt of sleept komt
        // er een vierkant vlak onder je vinger vandaan op een rij die rond
        // hoort te zijn. Dat is wat Joost zag (2026-09-07) en het is precies
        // wat Material Design hier niet voorschrijft.
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openPlannedRideDetail(ride),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(isShared ? Icons.groups : Icons.event_available,
                    size: 20, color: rw.plannedRide),
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
                      if (isShared)
                        Text(
                          s.pelotonWithOwner(
                            owner == null || owner.isEmpty
                                ? s.pelotonUnnamedFriend
                                : owner,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: rw.plannedRide,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                    ],
                  ),
                ),
                ScoreBadge(tier: rideTierFromScore(ride.plannedScore)),
                if (!isShared) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: s.removePlannedRideTooltip,
                    color: cs.error,
                    onPressed: () async {
                      final confirmed = await showUnplanConfirmDialog(context);
                      if (!confirmed) return;
                      ref.read(plannedRidesProvider.notifier).remove(ride);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(S.of(context).rideRemoved)),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPlannedRideDetail(PlannedRide ride) {
    final slotsState = ref.read(slotsProvider);
    final weatherState = ref.read(weatherProvider);
    final allForecasts =
        weatherState.hasValue ? weatherState.requireValue : <HourlyForecast>[];
    final slotForecasts = allForecasts
        .where((f) => !f.time.isBefore(ride.start) && f.time.isBefore(ride.end))
        .toList();

    // Try to find the matching RideSlot from current slots
    RideSlot? matchingSlot;
    if (slotsState is SlotsLoaded) {
      for (final slot in slotsState.slots) {
        if (slot.start == ride.start && slot.end == ride.end) {
          matchingSlot = slot;
          break;
        }
      }
    }

    // Fallback: construct a minimal RideSlot from the planned ride data
    matchingSlot ??= RideSlot(
      start: ride.start,
      end: ride.end,
      overallScore: ride.plannedScore,
      tier: rideTierFromScore(ride.plannedScore),
      hours: const [],
    );

    HapticFeedback.selectionClick();
    context.push(
      '/detail',
      extra: DetailArgs(
        slot: matchingSlot,
        forecasts: slotForecasts,
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
    // REFRESH-04: Riverpod 3.x auto-retry keeps AsyncValue.isLoading true
    // (with hasError also true) while a failed fetch is being retried in the
    // background -- so isLoading alone can no longer gate the spinner, or a
    // retry loop after a prior success would hide the stale cards/banner
    // behind an infinite spinner. Only show the spinner when there is truly
    // no previous data to fall back on yet.
    if (weatherState.isLoading && !weatherState.hasValue) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Only show the blank full-screen error when there is truly no previous
    // data to fall back on. When hasError && hasValue (a refresh failed
    // after an earlier success, or is being auto-retried), fall through to
    // the SlotsLoaded branch below, which renders the stale slots
    // SlotsNotifier preserves, alongside the stale banner added above the
    // week strip.
    if (weatherState.hasError && !weatherState.hasValue) {
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

      // Filter out already-planned rides
      final planned =
          ref.watch(plannedRidesProvider).value ?? const <PlannedRide>[];
      var slots = slotsState.slots.where((s) {
        return !planned.any((r) => r.start == s.start && r.end == s.end);
      }).toList();

      if (_selectedDay != null) {
        slots = slots.where((s) {
          return s.start.year == _selectedDay!.year &&
              s.start.month == _selectedDay!.month &&
              s.start.day == _selectedDay!.day;
        }).toList();
      }

      slots = slots.where(_slotMatchesPeriod).toList();

      if (slots.isEmpty &&
          (_selectedDay != null || _activePeriods.length < 3)) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(S.of(context).emptyNoSlotsDay),
        );
      }

      // Dart's List.sort is niet stabiel, dus binnen een tier moet de tiebreak
      // expliciet; anders wisselt de kaartvolgorde per rebuild. Binnen een tier
      // blijft de lijst chronologisch — dat leest als een agenda, en dat is wat
      // je van een lijst tijdvakken verwacht.
      slots.sort((a, b) {
        final byTier = _tierOrder(a.tier).compareTo(_tierOrder(b.tier));
        return byTier != 0 ? byTier : a.start.compareTo(b.start);
      });

      // ...met één uitzondering: het best scorende slot wordt naar voren
      // gehaald. Zonder dit droeg de kaart op plek 0 het "Best choice"-label
      // terwijl dat de vroegste van de beste tier was en niet de beste — een
      // rit van 99 boven een 100. Zolang die kaart nauwelijks opviel bleef dat
      // onopgemerkt; sinds hij met schaduw en accentrand domineert, wijst het
      // scherm met nadruk de verkeerde aan. Zie [indexOfBestSlot].
      final bestIndex = indexOfBestSlot(slots);
      if (bestIndex > 0) {
        slots.insert(0, slots.removeAt(bestIndex));
      }

      // Afgetopt op de beste vijf, met een rij eronder die de rest erbij haalt.
      // Zie [_showAllSlots] voor waarom.
      final total = slots.length;
      final hidden = total - _kVisibleSlotCount;
      final visible = _showAllSlots || hidden <= 0 ? total : _kVisibleSlotCount;

      return SliverList.builder(
        // +1 voor de "toon alles"-rij, maar alleen als er iets te tonen valt.
        itemCount: hidden > 0 ? visible + 1 : visible,
        itemBuilder: (context, index) {
          if (index == visible) return _buildShowAllSlotsRow(total);
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

  // ---------------------------------------------------------------------------
  // Stale/offline banner (REFRESH-04)
  // ---------------------------------------------------------------------------

  Widget _buildStaleBanner(BuildContext context, DateTime? staleTs) {
    final cs = Theme.of(context).colorScheme;
    final message = staleTs != null
        ? S.of(context).staleDataBannerWithTime(_formatTime(staleTs))
        : S.of(context).staleDataBannerNoTime;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message,
      {IconData icon = Icons.cloud_off_outlined, Widget? action}) {
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

    final allForecasts =
        weatherState.hasValue ? weatherState.requireValue : <HourlyForecast>[];
    final slotForecasts = allForecasts
        .where((f) => !f.time.isBefore(slot.start) && f.time.isBefore(slot.end))
        .toList();

    // Bereken gemiddelde weer-waarden
    final temps =
        slotForecasts.map((f) => f.temperatureC).whereType<double>().toList();
    final precips = slotForecasts
        .map((f) => f.precipitationMm)
        .whereType<double>()
        .toList();
    final winds =
        slotForecasts.map((f) => f.windspeedKmh).whereType<double>().toList();

    final avgTemp =
        temps.isEmpty ? null : temps.reduce((a, b) => a + b) / temps.length;
    final totalPrecip =
        precips.isEmpty ? null : precips.reduce((a, b) => a + b);
    final avgWind =
        winds.isEmpty ? null : winds.reduce((a, b) => a + b) / winds.length;

    // De echte deelscores uit de motor, gemiddeld over de uren van dit venster
    // — niet nagerekend uit de gemiddelde waarde hierboven. Dat scheelt: de
    // regenscore is de laagste van hoeveelheid én kans, en die kans zit niet in
    // `totalPrecip`. Zou de uitleg zelf gaan rekenen, dan noemt hij een ander
    // getal dan de score die ernaast staat.
    double? avgOf(double Function(HourlyScore) pick) {
      if (slot.hours.isEmpty) return null;
      return slot.hours.map(pick).reduce((a, b) => a + b) / slot.hours.length;
    }

    final tempScore = avgOf((h) => h.temperatureScore);
    final rainScore = avgOf((h) => h.rainScore);
    final windScore = avgOf((h) => h.windScore);

    // Alle kaarten dezelfde volle radius, ook de beste.
    //
    // Dat was even anders: de beste kaart had links 8px, zodat de accentrand
    // als rechte streep zou lezen in plaats van als sikkel. Die redenering
    // klopte voor de rand en niet voor de kaart -- bij het slepen kwam er een
    // vrijwel vierkant blok tevoorschijn op een scherm waar verder alles radius
    // 24 heeft, en dat viel Joost meteen op (2026-09-07). De rand is opgelost
    // door hem naar binnen te halen (zie hieronder), zodat de vorm van de kaart
    // niet langer een compromis met een detail hoeft te sluiten.
    final radius = BorderRadius.circular(_rideCardRadius);

    // Standaard: de beste open, de rest dicht. Zodra de gebruiker zelf een
    // kaart heeft aangetikt wint die keuze — ook op de beste kaart.
    final isExpanded = _cardExpanded[slot.start] ?? isBest;

    // Alle kaarten dezelfde marge. De beste kaart had er onderaan extra, omdat
    // zijn slagschaduw anders over de kaart eronder viel; die schaduw is er
    // niet meer (zie hieronder), dus die uitzondering ook niet.
    const margin = _rideCardMargin;

    // Zelfde constructie als op Rides: de hele Dismissible in een afgeronde clip,
    // met de marge erbuiten. Alleen de achtergrond afronden volstaat niet — dan
    // schuift de kaart nog steeds als rechthoek weg.
    //
    // Hier zat tot 2026-09-07 een `DecoratedBox` met een slagschaduw omheen: een
    // `ClipRRect` snijdt alles weg wat buiten zijn rechthoek valt en een schaduw
    // valt daar per definitie buiten, dus die moest van de ouder komen. Hij is
    // weg omdat de beste kaart nu alleen nog door zijn pil wordt aangewezen —
    // zie de noot bij `isBest` verderop. De constructie eromheen blijft nodig
    // voor de swipe, alleen zonder schaduw.
    return SpringPressEffect(
      child: Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: radius,
          child: Dismissible(
            key: ValueKey('slot_${slot.start.millisecondsSinceEpoch}'),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              _planRide(slot);
              return false;
            },
            // Geen gekleurd vlak achter de kaart, alleen een icoon en een
            // woord op de gewone achtergrond.
            //
            // Er heeft hier een groen blok gezeten, en dat was niet rond te
            // krijgen. `Dismissible` knipt zijn achtergrond zélf af tot het
            // onthulde stuk, en die knip loopt kaarsrecht langs de rand van
            // de kaart. Een `borderRadius` op dat blok deed daar niets tegen:
            // links werd hij netjes rond, rechts hield hij een hoek van 90°,
            // met een wig achtergrond ertussen omdat de kaart daar juist wél
            // rond is. Op een echt toestel met een echte vinger was dat het
            // eerste wat opviel (Joost, 2026-09-07, na drie rondes waarin ik
            // steeds naar de kaart keek in plaats van naar het vlak erachter).
            //
            // Wat niet bestaat kan ook niet vierkant afgeknipt worden. De
            // knip valt nu op de achtergrond zelf en is daarmee onzichtbaar.
            background: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  // Groen op papier in plaats van op een groen vlak, dus de
                  // kleur moet nu zelf het contrast dragen.
                  Icon(Icons.event_available, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).schedule,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            // Deze `ClipRRect` maakt van de meeschuivende kaart een écht
            // afgerond blok. Zonder hem kreeg je bij het slepen een kaars-
            // rechte voorrand met een harde naad tussen het groene vlak en de
            // kaart — precies wat je op een scherm vol radius-24 niet wilt
            // zien (waargenomen door Joost, 2026-09-07). De `shape` op de
            // `Card` hieronder rondt alleen zijn eigen rustpositie af; zodra
            // hij binnen de clip van de ouder verschuift, is het de ouder die
            // de vorm bepaalt. Vandaar een clip die mét de kaart meebeweegt.
            //
            // De buitenste `ClipRRect` blijft ook staan: die houdt het groene
            // onthulvlak binnen dezelfde ronding en voorkomt dat de kaart aan
            // de rechterkant buiten zijn plek schuift.
            //
            // Alle kaarten zijn volledig gelijk: hetzelfde wit, dezelfde
            // haarlijn, geen schaduw. De beste wordt aangewezen door zijn pil
            // "Beste keuze" en verder door niets — Joost's keuze op
            // 2026-09-07, nadat de kaart drie markeringen tegelijk droeg (pil,
            // staaf én schaduw) voor één en hetzelfde feit.
            //
            // Wat hier weg is en waarom het niet terug moet sluipen: een 5px
            // `brandDark`-staaf links ín de kaart. Als `Border(left:)` liep
            // hij tot in de hoeken en werd hij daar een sikkel, en de
            // omweg daaromheen (links maar 8px radius) maakte de kaart bij
            // het slepen tot een bijna vierkant blok op een scherm waar
            // alles radius 24 heeft.
            child: ClipRRect(
              borderRadius: radius,
              child: Card(
                // `elevation` binnen een `ClipRRect` is weggegooid werk — de
                // clip snijdt de schaduw weg. Niet ongedaan maken zonder de
                // schaduw óók buiten de clip te zetten; zo stond het tot
                // vandaag en dat is bewust vervallen.
                elevation: 0,
                margin: EdgeInsets.zero,
                color: cs.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(color: cs.surfaceContainerHigh),
                ),
                child: Stack(
                  children: [
                    InkWell(
                      borderRadius: radius,
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
                      // Een dichte kaart krijgt minder lucht dan een open.
                      //
                      // Ingeklapt draagt een kaart drie regels informatie maar
                      // besloeg hij ~230px: 20px rondom, twee tussenruimtes van
                      // 14, een eigen regel voor de chevron en nog een voor de
                      // Schedule-knop. Dat is de maat van een open kaart voor
                      // de inhoud van een dichte, en met vijf kaarten onder
                      // elkaar telt dat op tot een scherm vol lucht.
                      //
                      // Open blijft ruim: daar staan drie weerbalken met assen
                      // en die hebben die lucht nodig om leesbaar te zijn.
                      child: Padding(
                        padding: EdgeInsets.all(isExpanded ? 20 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Beste keuze" label
                            if (isBest)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          size: 14,
                                          color: cs.onPrimaryContainer),
                                      const SizedBox(width: 4),
                                      Text(
                                        S.of(context).bestChoice,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // De typografische stap uit schets
                                            // 001: 24 op de beste kaart, 16 op
                                            // de rest. Stond allebei op 16, en
                                            // dat is de helft van de vlakheid
                                            // die deze epic moet wegnemen.
                                            Text(
                                              _formatDayName(slot.start),
                                              style: (isBest
                                                      ? Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .titleMedium)
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${_formatTime(slot.start)} – ${_formatTime(slot.end)} · ${_durationHours(slot)}u',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
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
                                ScoreDisplay(
                                  score: slot.overallScore,
                                  tier: slot.tier,
                                  emphasis: isBest
                                      ? ScoreEmphasis.hero
                                      : ScoreEmphasis.normal,
                                ),
                              ],
                            ),
                            SizedBox(height: isExpanded ? 14 : 8),
                            // Open toont de volle balken, dicht één compacte
                            // regel. De beste kaart begint open en de rest
                            // dicht, maar dat is een startwaarde en geen wet:
                            // elke kaart kan beide kanten op.
                            //
                            // `AnimatedCrossFade` en niet `AnimatedSize` met
                            // een omgewisseld kind: die laatste liet de inhoud
                            // hard verspringen terwijl alleen de hoogte
                            // meebewoog. Hier vervagen de twee in elkaar
                            // terwijl de hoogte meeloopt — één beweging in
                            // plaats van twee die langs elkaar heen lopen.
                            //
                            // De tik op de kaart zelf gaat nog steeds naar het
                            // detailscherm; de `InkWell` van de chevron wint de
                            // hit-test, dus die twee bijten elkaar niet.
                            if (avgTemp != null ||
                                totalPrecip != null ||
                                avgWind != null) ...[
                              AnimatedCrossFade(
                                duration: AppMotion.emphasizedDuration,
                                sizeCurve: AppMotion.emphasizedCurve,
                                firstCurve: AppMotion.emphasizedCurve,
                                secondCurve: AppMotion.emphasizedCurve,
                                alignment: Alignment.topCenter,
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                // De dichtklap-chevron staat búiten deze
                                // `AnimatedCrossFade`, de uitklap-chevron erín.
                                // Dat is geen symmetrie maar ervaring: toen
                                // béide in de kinderen zaten, tekende de
                                // chevron van `firstChild` niets meer — de
                                // ruimte werd gereserveerd, het icoon bleef
                                // weg, en de kaart was daarmee niet meer dicht
                                // te klikken (Joost, 2026-09-07).
                                //
                                // Het lag níét aan `--tree-shake-icons`; beide
                                // glyphs zitten aantoonbaar in de gesubsette
                                // `MaterialIcons-Regular.otf` (0xe245 en
                                // 0xe246, nagemeten in de cmap van de build).
                                // De cross-fade zelf is de oorzaak. Verplaats
                                // de open-chevron dus niet terug naar binnen
                                // zonder op een toestel te controleren dat hij
                                // nog tekent.
                                firstChild: _buildWeatherBars(
                                  avgTemp: avgTemp,
                                  totalPrecip: totalPrecip,
                                  avgWind: avgWind,
                                  tempScore: tempScore,
                                  rainScore: rainScore,
                                  windScore: windScore,
                                ),
                                // Dicht deelt de chevron zijn regel met de
                                // weersamenvatting — die is kort
                                // (`20° · Dry · 16 km/h`), dus daar was ruimte,
                                // en een eigen regel van 28px voor één icoon
                                // was pure hoogte.
                                secondChild: Row(
                                  children: [
                                    Expanded(
                                      child: _buildWeatherSummary(
                                        avgTemp: avgTemp,
                                        totalPrecip: totalPrecip,
                                        avgWind: avgWind,
                                      ),
                                    ),
                                    _buildExpandToggle(slot, expanded: false),
                                  ],
                                ),
                              ),
                              if (isExpanded)
                                _buildExpandToggle(slot, expanded: true),
                            ],
                            SizedBox(height: isExpanded ? 14 : 6),
                            // Footer: Plan het knop
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _planRide(slot),
                                icon:
                                    const Icon(Icons.event_available, size: 16),
                                label: Text(S.of(context).schedule),
                                // Dicht een slag dichter op elkaar. Dezelfde
                                // knop met dezelfde tekst, alleen minder lucht
                                // eromheen -- de kaart is hier een regel in een
                                // lijst en geen scherm op zichzelf.
                                style: isExpanded
                                    ? null
                                    : FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
    double? tempScore,
    double? rainScore,
    double? windScore,
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
            metric: WeatherMetric.temperature,
            icon: Icons.thermostat,
            label: s.weatherTemperature,
            value: avgTemp,
            unit: '\u00B0',
            idealMin: tempMin,
            idealMax: tempMax,
            infoText: s.infoTemp,
            score: tempScore,
          ),
        if (totalPrecip != null)
          WeatherIndicatorBar(
            metric: WeatherMetric.rain,
            icon: Icons.water_drop,
            label: s.weatherRain,
            value: totalPrecip,
            unit: ' mm',
            idealMax: rainMax,
            infoText: s.infoRain,
            score: rainScore,
          ),
        if (avgWind != null)
          WeatherIndicatorBar(
            metric: WeatherMetric.wind,
            icon: Icons.air,
            label: s.weatherWind,
            value: avgWind,
            unit: ' km/h',
            idealMax: windMax,
            infoText: s.infoWind,
            score: windScore,
          ),
      ],
    );
  }

  /// De compacte weerregel voor de kaarten die n\u00ED\u00E9t de beste zijn.
  ///
  /// Bewust geen balken: die zijn er om af te lezen h\u00F3e ver iets van je ideaal
  /// af zit, en dat is een vraag die je alleen stelt over de rit die je
  /// overweegt. Voor de rest volstaat het oordeel \u2014 dat is precies het woord
  /// dat de balk hierboven ook al draagt.
  /// De rij onder RIDE TIMES die de rest van de tijdvakken erbij haalt, of ze
  /// weer wegvouwt. Draagt het totaal in de tekst, zodat je wéét hoeveel je
  /// opvraagt in plaats van in het duister te tikken.
  Widget _buildShowAllSlotsRow(int total) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _showAllSlots = !_showAllSlots);
          },
          icon: AnimatedRotation(
            turns: _showAllSlots ? 0.5 : 0.0,
            duration: AppMotion.emphasizedDuration,
            curve: AppMotion.emphasizedCurve,
            child: const Icon(Icons.expand_more, size: 20),
          ),
          label: Text(
            _showAllSlots ? s.showFewerWindows : s.showAllWindows(total),
          ),
          style: TextButton.styleFrom(foregroundColor: cs.primary),
        ),
      ),
    );
  }

  /// De open-/dichtklapknop van een ritkaart, op élke kaart hetzelfde — ook op
  /// de beste.
  ///
  /// Twee vormen, want hij leeft in twee verschillende regels. Dicht is hij een
  /// smal vlakje aan het eind van de weersamenvatting; open een volle regel met
  /// de chevron in het midden, onder de balken.
  ///
  /// Hier stond een `AnimatedRotation` die de chevron omdraaide in plaats van
  /// twee iconen te wisselen. Die is vervallen toen de knop ín de twee
  /// kruisvervagende kinderen werd gezet: elk kind heeft nu zijn eigen vaste
  /// stand, dus er valt niets meer te draaien. De vervaging draagt de overgang,
  /// en de kaart is er ~28px korter door — dat was de afweging, en compactheid
  /// won.
  Widget _buildExpandToggle(RideSlot slot, {required bool expanded}) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    // Eén glyph, gedraaid — nooit twee verschillende iconen.
    //
    // Dit stond op `expanded ? Icons.expand_less : Icons.expand_more` en toen
    // was de kaart niet meer dicht te klikken: de knop werkte, de ruimte werd
    // gereserveerd, maar er tekende niets (Joost, 2026-09-07).
    //
    // `Icons.expand_more` staat elders in dit bestand in een `const Icon` en
    // wordt daarom door `--tree-shake-icons` in de gesubsette
    // `MaterialIcons-Regular.otf` gehouden. `Icons.expand_less` stond alleen
    // in de ternaire hierboven — geen constante instantie, dus de shaker zag
    // hem niet en sneed de glyph eruit. Je merkt dat pas in een release-build
    // op een toestel: in debug is het lettertype compleet en lijkt alles goed.
    //
    // Vandaar één glyph die 180° draait. Wil je hier tóch een tweede icoon,
    // zet het dan ergens als `const Icon(...)` neer én controleer het in een
    // release-build.
    final icon = Transform.rotate(
      angle: expanded ? math.pi : 0,
      child: Icon(
        Icons.expand_more,
        size: 20,
        color: cs.onSurfaceVariant,
      ),
    );

    return Semantics(
      button: true,
      expanded: expanded,
      label: expanded ? s.hideWeatherDetails : s.showWeatherDetails,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _cardExpanded[slot.start] = !expanded);
        },
        child: expanded
            ? SizedBox(height: 28, child: Center(child: icon))
            // Dicht: 40×32 is klein op het scherm maar blijft met de
            // omliggende regelhoogte ruim boven de 48dp die Material voor een
            // raakdoel vraagt -- de rij eromheen telt mee.
            : SizedBox(width: 40, height: 32, child: Center(child: icon)),
      ),
    );
  }

  Widget _buildWeatherSummary({
    double? avgTemp,
    double? totalPrecip,
    double? avgWind,
  }) {
    final s = S.of(context);
    final rw = context.rw;
    final profile = ref.watch(profileProvider).value;
    final tol = profile?.tolerances;
    // Alleen regen krijgt hier een oordeel in plaats van een getal: "Dry" zegt
    // meteen alles, terwijl "0 mm" je nog laat nadenken. Temperatuur en wind
    // zijn als getal juist directer.
    final rainMax = tol?.rainMaxIdealMm ?? 0.5;

    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: rw.textTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget item(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: rw.textHint),
            const SizedBox(width: 5),
            Text(text, style: style),
          ],
        );

    return Row(
      children: [
        if (avgTemp != null) ...[
          item(Icons.thermostat, '${avgTemp.round()}\u00B0'),
          const SizedBox(width: 16),
        ],
        if (totalPrecip != null) ...[
          item(
            Icons.water_drop,
            _verdictText(
              s,
              weatherVerdictFor(
                WeatherMetric.rain,
                totalPrecip,
                idealMax: rainMax,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (avgWind != null) item(Icons.air, '${avgWind.round()} km/h'),
      ],
    );
  }

  String _verdictText(S s, WeatherVerdict verdict) => switch (verdict) {
        WeatherVerdict.dry => s.verdictDry,
        WeatherVerdict.light => s.verdictLight,
        WeatherVerdict.showers => s.verdictShowers,
        WeatherVerdict.wet => s.verdictWet,
        WeatherVerdict.calm => s.verdictCalm,
        WeatherVerdict.breezy => s.verdictBreezy,
        WeatherVerdict.gusty => s.verdictGusty,
        WeatherVerdict.chilly => s.verdictChilly,
        WeatherVerdict.ideal => s.verdictIdeal,
        WeatherVerdict.warm => s.verdictWarm,
      };

  // ---------------------------------------------------------------------------
  // Plan ride (in-app)
  // ---------------------------------------------------------------------------

  void _planRide(RideSlot slot) {
    final notifier = ref.read(plannedRidesProvider.notifier);
    final already =
        (ref.read(plannedRidesProvider).value ?? const <PlannedRide>[]).any(
      (r) => r.start == slot.start && r.end == slot.end,
    );
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).ridePlanned)),
      );
      return;
    }
    notifier.add(PlannedRide(
      start: slot.start,
      end: slot.end,
      plannedScore: slot.overallScore,
    ));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).ridePlanned)),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int _durationHours(RideSlot slot) => slot.end.difference(slot.start).inHours;

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
    return slots
        .reduce(
          (a, b) => _tierOrder(a.tier) <= _tierOrder(b.tier) ? a : b,
        )
        .tier;
  }

  int _tierOrder(RideTier tier) => switch (tier) {
        Perfect() => 0,
        Great() => 1,
        Acceptable() => 2,
        Poor() => 3,
      };

  String _windArrow(double degrees) {
    const arrows = [
      '\u2193',
      '\u2199',
      '\u2190',
      '\u2196',
      '\u2191',
      '\u2197',
      '\u2192',
      '\u2198'
    ];
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

// `_DayClass { good, ok, bad }` stond hier tot 2026-09-07. De dagstrip gebruikt
// nu `RideTier` zelf, zodat hij dezelfde vier niveaus en dezelfde kleuren toont
// als de ritkaarten eronder — zie de noot bij `qualityColor` in `_buildDayChip`.

enum _DayPeriod {
  morning, // 6:00 – 11:59
  afternoon, // 12:00 – 16:59
  evening, // 17:00 – 21:59
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

/// Eén regel onder PLANNED op Home, ongeacht waar hij vandaan komt.
///
/// [ownerName] is `null` voor je eigen geplande rit en gevuld voor een gedeelde
/// rit van een maatje. Dat ene veld is het hele verschil: het bepaalt of de
/// kaart een naam toont en of er een prullenbak op staat. Bewust geen twee
/// aparte widgets — de rit is voor de gebruiker hetzelfde ding, alleen met een
/// andere herkomst, en dat hoort de kaart ook uit te stralen.
class _PlannedEntry {
  const _PlannedEntry({required this.ride, this.ownerName});

  final PlannedRide ride;
  final String? ownerName;

  bool get isShared => ownerName != null;
}
