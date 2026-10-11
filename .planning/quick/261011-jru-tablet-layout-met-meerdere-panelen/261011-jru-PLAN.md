---
phase: quick-261011-jru
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/app/window_size.dart
  - lib/app/scaffold_with_nav.dart
  - lib/features/welcome/welcome_screen.dart
  - lib/features/onboarding/onboarding_screen.dart
  - lib/features/profile/profile_screen.dart
  - lib/features/home/home_screen.dart
  - lib/features/planned/planned_rides_screen.dart
  - test/app/adaptive_layout_test.dart
  - test/features/home_two_pane_test.dart
  - test/features/rides_two_pane_test.dart
autonomous: true
requirements: [QUICK-261011-jru]

must_haves:
  truths:
    - "On a phone (width < 600) every screen renders exactly as before: bottom NavigationBar, no NavigationRail, Home one column, Rides with TabBar"
    - "From 600 px wide the shell shows a NavigationRail on the left with the same four destinations, labels, icons and attention badge, and no bottom NavigationBar"
    - "From 840 px wide Home shows the ride-window list on the left and the selected window's expanded card on the right; the best window is selected by default; tapping a list card selects it instead of pushing /detail"
    - "From 840 px wide the Rides screen shows Rides and Peloton side by side, no TabBar"
    - "From 600 px wide Welcome, Onboarding and Profile content is at most 640 px wide and centered; Welcome/Onboarding green background still fills the window"
    - "flutter test fully green (existing ~1104 + new), flutter analyze 0 errors 0 warnings"
  artifacts:
    - path: "lib/app/window_size.dart"
      provides: "WindowSizeClass enum, windowSizeClassOf(context), breakpoints 600/840, ReadableWidth widget (max 640)"
      contains: "enum WindowSizeClass"
    - path: "lib/app/scaffold_with_nav.dart"
      provides: "NavigationBar at compact, NavigationRail from medium"
      contains: "NavigationRail"
    - path: "test/app/adaptive_layout_test.dart"
      provides: "size-class unit tests + shell rail/bar tests at 400x800, 700x1000, 1280x800"
    - path: "test/features/home_two_pane_test.dart"
      provides: "Home one pane at 400x800, two panes at 1280x800"
    - path: "test/features/rides_two_pane_test.dart"
      provides: "Rides TabBar at 400x800, both lists side by side at 1280x800"
  key_links:
    - from: "lib/app/scaffold_with_nav.dart"
      to: "lib/app/window_size.dart"
      via: "windowSizeClassOf(context)"
      pattern: "windowSizeClassOf"
    - from: "lib/features/home/home_screen.dart"
      to: "lib/app/window_size.dart"
      via: "WindowSizeClass.expanded decides two-pane"
      pattern: "WindowSizeClass.expanded"
    - from: "lib/features/planned/planned_rides_screen.dart"
      to: "lib/app/window_size.dart"
      via: "WindowSizeClass.expanded decides side-by-side"
      pattern: "WindowSizeClass.expanded"
---

<objective>
Laat Ridewindow op tabletbreedte meerdere informatiepanelen naast elkaar tonen, zoals Gmail en YouTube: een navigatierail vanaf medium, lijst-plus-detail op Home en Ritten naast Peloton vanaf expanded, en leesbare breedte op Welcome/Onboarding/Profiel. De telefoonweergave blijft exact gelijk.

Purpose: Joost wil dat de app op een tablet het scherm benut in plaats van een opgerekte telefoon te zijn (knoppen van 1500 px breed, één lange kolom). Ontwerp is afgestemd in artifact https://claude.ai/artifact/QConk1p3H6mMU8Vx4jv2Z7.
Output: één gedeeld breedtebestand, aangepaste shell/Home/Ritten/Welcome/Onboarding/Profiel, drie nieuwe testbestanden.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@lib/app/scaffold_with_nav.dart
@test/app/nav_unanswered_badge_test.dart

Grote bestanden: lees ze NIET in zijn geheel. Gebruik de regelnummers hieronder (stand commit d9072aa) en grep.

lib/features/home/home_screen.dart (2633 regels):
- 64 `class HomeScreen extends ConsumerStatefulWidget`, 71 state; 77 `_firstCardKey`; 81 `DateTime? _selectedDay` (dagfilter, NIET de paneelselectie)
- 250-400 `build`: `Stack[Scaffold(body: RefreshIndicator(child: CustomScrollView(slivers: [SliverAppBar, stale banner, location banner, week strip, period filter, _buildPlannedRidesSliver(), _buildViewRow(), _buildCardsSliver(weatherState, slotsState), bottom padding])))`, dan `ScreenHintOverlay` op ~403
- 1121 `_buildCardsSliver`: lege/laad-staten, dan op ~1178 `planned`, `applyFilters` (geplande ritten, `_selectedDay`, `_slotMatchesPeriod`), sorteren op `_sort` (SlotSort.best / SlotSort.time), aftoppen op `_kVisibleSlotCount`, `indexOfBestSlot(slots)`, `SliverList.builder` die `_buildRideCard(slots[index], isBest: isBest)` aanroept; blokweergave via `_buildBlocksSliver(buildRideDays(slots, candidates: candidates))`
- 1324 `_buildBlockCard(RideDay day)`: onTap op ~1347 pusht `/detail` met `day.best`
- 1590 `_buildRideCard(RideSlot slot, {bool isBest = false})`: rekent avgTemp/totalPrecip/avgWind en deelscores; 1644 `final isExpanded = _cardExpanded[slot.start] ?? isBest;`; `SpringPressEffect > Padding > ClipRRect > Dismissible(swipe = _planRide) > Card > Stack > InkWell(onTap ~1750: context.push('/detail', extra: DetailArgs(slot:, forecasts:)))`; `AnimatedCrossFade` met `_buildWeatherBars` (open) / `_buildWeatherSummary` + `_buildExpandToggle` (dicht); Schedule-knop `FilledButton.tonalIcon(onPressed: () => _planRide(slot))`
- 2079 `_buildExpandToggle`, 2216 `_planRide`

lib/features/planned/planned_rides_screen.dart (1562 regels):
- 113 `PlannedRidesScreen`, 123 `_tabController` (length 2), 168 `build`: `Stack[Scaffold(appBar: AppBar(title, actions:[info], bottom: TabBar(controller, tabs:[_BadgedTab(label: ridesTabRides, count: ridesAttention), _BadgedTab(label: ridesTabBuddies, count: pelotonAttention)])), body: TabBarView(children:[RidesTab(firstRideKey: _firstRideKey), const BuddiesTab()])), ScreenHintOverlay...]`
- 226 `class _BadgedTab` (label + bolletje)

Welcome (`welcome_screen.dart` ~245): `Scaffold(backgroundColor: AppColors.brandLight, body: GestureDetector(child: SafeArea(child: AnimatedBuilder(... Stack ...))))`.
Onboarding (`onboarding_screen.dart` ~127): `Scaffold(backgroundColor: AppColors.brandLight, body: SafeArea(child: Padding(... Column(stretch) ...)))`.
Profiel (`profile_screen.dart` ~583): `Scaffold(appBar: AppBar(title: Text(s.profileTitle)), body: ListView(key: PageStorageKey('profile_settings'), ...))`.

Testpatroon: `test/app/nav_unanswered_badge_test.dart` (`_pumpShell` met een GoRouter + StatefulShellRoute en `_pumpRidesScreen` met de provider-overrides voor PlannedRidesScreen). Schermmaat zetten met `tester.view.physicalSize = Size(w * 3, h * 3); tester.view.devicePixelRatio = 3; addTearDown(tester.view.reset);`. Voor Home: hergebruik de pump-opzet uit `test/features/home_screen_test.dart` (zie rond regel 588 en de `pumpWidget`-aanroepen) met geladen slots.
</context>

## Hoe goedlopende apps het doen (werkregel CLAUDE.md)

- **Gmail (tablet):** navigatierail links, lijst met vaste breedte, leespaneel rechts; het geopende item is in de lijst gemarkeerd; het eerste/meest relevante item staat al open zodat het rechterpaneel nooit leeg begint. **Overgenomen:** vaste lijstbreedte, markering van het geselecteerde item, standaard het beste venster geselecteerd.
- **YouTube / Google Play (tablet):** vanaf middelbreed een rail met icoon + label in plaats van een onderbalk; bolletjes blijven op het icoon staan. **Overgenomen:** `NavigationRail` met `labelType: all`, zelfde badge.
- **Google Maps / Strava (tablet):** de kopregel en filters horen bij de lijst, niet over het hele scherm. **Overgenomen:** Home-kop, dagstrook en filters blijven in het linkerpaneel (scheelt ook de meeste wijziging in Home's boom).
- **Instellingen-schermen (Android Settings, WhatsApp-instellingen op tablet):** inhoud gecentreerd met een maximale leesbreedte. **Overgenomen:** max 640 px voor Welcome, Onboarding en Profiel.
- **Bewuste afwijking:** Gmail toont in het rechterpaneel een compleet scherm; wij tonen de uitgeklapte ritkaart (score, balken, Schedule) en laten de tik op die kaart doorgaan naar het bestaande `/detail`. Zo is er geen tweede detailweergave om te onderhouden. De telefoonweergave verandert nergens: op compact wordt geen enkele nieuwe widget in de boom gezet.

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Breedteklassen, navigatierail en leesbreedte voor Welcome/Onboarding/Profiel</name>
  <files>lib/app/window_size.dart, lib/app/scaffold_with_nav.dart, lib/features/welcome/welcome_screen.dart, lib/features/onboarding/onboarding_screen.dart, lib/features/profile/profile_screen.dart, test/app/adaptive_layout_test.dart</files>
  <behavior>
    - windowSizeClassFor(599) == compact, (600) == medium, (839) == medium, (840) == expanded
    - Shell op 400x800: find.byType(NavigationBar) één, find.byType(NavigationRail) niets
    - Shell op 700x1000 en 1280x800: NavigationRail één, NavigationBar niets; vier bestemmingen met de NL-labels (Home, Agenda, Ritten, Profiel zoals in S); tik op de rail-bestemming Ritten toont de /rides-pagina
    - Rail toont het attention-bolletje met hetzelfde label als de onderbalk (unansweredBadgeLabel, bv. "9+" bij 12)
    - Profiel op 1280x800: breedte van de ListView (tester.getSize) is <= 640; op 400x800 gelijk aan schermbreedte
  </behavior>
  <action>
Maak `lib/app/window_size.dart` (header-commentaar in het Nederlands, zelfde stijl als de andere bestanden in lib/app): constanten `kMediumMinWidth = 600.0`, `kExpandedMinWidth = 840.0`, `kReadableMaxWidth = 640.0` (Material 3 window size classes); `enum WindowSizeClass { compact, medium, expanded }`; pure functie `WindowSizeClass windowSizeClassFor(double width)`; `WindowSizeClass windowSizeClassOf(BuildContext context)` op basis van `MediaQuery.sizeOf(context).width` (vensterbreedte, niet de breedte van het lichaam naast de rail -- één regel voor de hele app). Plus een widget `ReadableWidth({required Widget child, double maxWidth = kReadableMaxWidth})`: op compact retourneert hij `child` ongewijzigd (geen extra widget in de boom -- harde eis: telefoon onveranderd); vanaf medium gebruikt hij een `LayoutBuilder` en zet `Padding(horizontal: max(0, (constraints.maxWidth - maxWidth) / 2))` om het kind. Bewust padding en geen `Center`/`Align`: die maken de hoogte los, en Welcome's `Stack` en Onboarding's `Column` rekenen op een strakke hoogte.

`scaffold_with_nav.dart`: haal de vier bestemmingen één keer op als lokale lijst van records (icon, selectedIcon, label) zodat bar en rail dezelfde iconen/labels/badge gebruiken (Bicycle krijgt in beide `_AttentionBadge(count: attention, ...)`). Bij compact: exact de huidige `Scaffold(body: navigationShell, bottomNavigationBar: NavigationBar(...))`. Vanaf medium: `Scaffold(body: Row(children: [SafeArea(right: false, child: NavigationRail(selectedIndex, onDestinationSelected: dezelfde goBranch-aanroep inclusief initialLocation-regel, labelType: NavigationRailLabelType.all, destinations: NavigationRailDestination(icon, selectedIcon, label: Text(label))...)), Expanded(child: navigationShell)]))`, geen bottomNavigationBar. De PopScope (#80) blijft om beide heen, ongewijzigd. Werk de kopregel-comment bij ("NavigationBar of NavigationRail").

Welcome: wikkel het kind van `SafeArea` (de `AnimatedBuilder`) in `ReadableWidth`; Scaffold-achtergrond en GestureDetector blijven op volle breedte. Onboarding: wikkel het kind van `SafeArea` (de `Padding`) in `ReadableWidth`. Profiel: wikkel de `body: ListView(...)` in `ReadableWidth` (PageStorageKey blijft op de ListView). Geen nieuwe strings.

Test `test/app/adaptive_layout_test.dart`: unit-tests voor `windowSizeClassFor` en shell-tests met een kopie van het `_pumpShell`-patroon uit nav_unanswered_badge_test.dart, maar met parameter voor de schermmaat. Profiel-breedtetest: als het pompen van ProfileScreen te veel providers vraagt, test `ReadableWidth` los (een `ListView` erin op 400 en 1280 breed) en kijk in `profile_screen_test.dart` hoe ProfileScreen gepompt wordt -- voeg daar één test op 1280x800 toe als de bestaande helper een schermmaat toelaat.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter test test/app/ test/features/welcome_screen_test.dart test/features/onboarding_screen_test.dart test/features/profile_screen_test.dart && flutter analyze lib/app lib/features/welcome lib/features/onboarding lib/features/profile test/app</automated>
  </verify>
  <done>Rail vanaf 600 px, onderbalk daaronder; leesbreedte 640 op de drie schermen vanaf medium; bestaande nav-badge-, welcome-, onboarding- en profieltests groen; nieuwe tests groen; analyze zonder errors/warnings.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Home als lijst-plus-detail vanaf expanded</name>
  <files>lib/features/home/home_screen.dart, test/features/home_two_pane_test.dart</files>
  <behavior>
    - 400x800 met geladen slots: geen widget met key `ValueKey('home_detail_pane')`; tik op een kaart pusht nog steeds /detail (bestaande tests dekken dat, die moeten groen blijven)
    - 1280x800 met geladen slots: `home_detail_pane` bestaat; daarin staat de Schedule-knop en de weerbalken van het beste venster (score/tijdlabel van het slot met de hoogste score)
    - 1280x800: tik op een andere kaart in de lijst -> het detailpaneel toont dat venster (tijdlabel wisselt), er wordt geen /detail gepusht
    - 1280x800 zonder slots (lege staat): geen crash, detailpaneel leeg
  </behavior>
  <action>
Kleinste ingreep in de bestaande boom. (1) Haal de filter+sorteerlogica uit `_buildCardsSliver` (`planned`, `applyFilters`, de `switch (_sort)`) naar één methode, bv. `({List<RideSlot> slots, List<RideSlot> candidates}) _listedSlots(SlotsLoaded state)`, en laat `_buildCardsSliver` die aanroepen -- gedrag identiek, alleen verplaatst, zodat het detailpaneel exact dezelfde lijst en hetzelfde `indexOfBestSlot` gebruikt (geen tweede kopie van filter- of scorelogica). (2) Nieuw state-veld `DateTime? _paneSlotStart` (de selectie; los van `_selectedDay`). Geselecteerd slot = het slot in `_listedSlots(...).slots` met `start == _paneSlotStart`, anders het slot op `indexOfBestSlot(slots)`; valt de keuze door filters weg, dan valt hij terug op het beste. (3) In `build`: `final twoPane = windowSizeClassOf(context) == WindowSizeClass.expanded;`. Bij `!twoPane` blijft `body:` exact de huidige `RefreshIndicator(...)`. Bij `twoPane` wordt `body: Row(crossAxisAlignment: stretch, children: [SizedBox(width: 400, child: <dezelfde RefreshIndicator>), const VerticalDivider(width: 1), Expanded(child: KeyedSubtree(key: const ValueKey('home_detail_pane'), child: _buildDetailPane(...)))])` -- haal de RefreshIndicator in een lokale variabele zodat hij niet gedupliceerd wordt. Kop, banners, dagstrook, filters en geplande ritten blijven in het linkerpaneel. (4) `_buildDetailPane`: als er een geselecteerd slot is, `SingleChildScrollView(padding: 16) > Align(topCenter) > ConstrainedBox(maxWidth: kReadableMaxWidth) > _buildRideCard(slot, isBest: <is het beste venster en tier Perfect/Great, zelfde regel als in de lijst>, inPane: true)`; anders `const SizedBox.shrink()` (geen nieuwe string). (5) `_buildRideCard` krijgt `{bool inPane = false, bool selected = false}`: bij `inPane` is `isExpanded` altijd true en worden beide `_buildExpandToggle`-aanroepen weggelaten (het paneel is het uitgeklapte venster); de tik op de kaart in het paneel blijft `/detail` pushen. In de lijst, alleen als twoPane: de standaard `isExpanded` wordt `_cardExpanded[slot.start] ?? false` (detail staat al rechts), de InkWell-onTap zet `setState(() => _paneSlotStart = slot.start)` met `HapticFeedback.selectionClick()` in plaats van te pushen, en de geselecteerde kaart krijgt `side: BorderSide(color: cs.primary, width: 2)` in plaats van `cs.surfaceContainerHigh` (Gmail-markering, kleur uit het thema). (6) `_buildBlockCard` onTap: bij twoPane `_paneSlotStart = day.best.start` in plaats van pushen. Op compact is elke tak gelijk aan nu. Import `package:ridewindow/app/window_size.dart`. Comments in het Nederlands, in de stijl van het bestand, met verwijzing naar dit quick-plan.

Test `test/features/home_two_pane_test.dart`: kopieer de pump-opzet met geladen slots uit `test/features/home_screen_test.dart`, parametriseer de schermmaat, en dek de vier gedragingen hierboven. Voor de "geen push"-check: een GoRouter met een `/detail`-route die een herkenbare tekst toont, of tel dat die tekst niet verschijnt.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter test test/features/home_two_pane_test.dart test/features/home_screen_test.dart test/features/home_screen_location_test.dart test/features/home_screen_refresh_test.dart && flutter analyze lib/features/home test/features/home_two_pane_test.dart</automated>
  </verify>
  <done>Op 1280 px breed toont Home lijst (400 px) + detailpaneel met standaard het beste venster en selectie per tik; op telefoonbreedte geen detailpaneel en tikken pusht /detail als vanouds; alle bestaande Home-tests groen.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Ritten en Peloton naast elkaar vanaf expanded, plus volledige suite</name>
  <files>lib/features/planned/planned_rides_screen.dart, test/features/rides_two_pane_test.dart</files>
  <behavior>
    - 400x800: find.byType(TabBar) één, TabBarView aanwezig (gedrag identiek aan nu)
    - 1280x800: geen TabBar; RidesTab en BuddiesTab allebei in de boom en allebei zichtbaar (hitTestable), naast elkaar (x van BuddiesTab > x van RidesTab)
    - 1280x800: beide kolomkoppen tonen de bestaande labels ridesTabRides / ridesTabBuddies met hun bolletje (bv. pelotonTabAttentionCount 2 -> "2")
  </behavior>
  <action>
In `PlannedRidesScreen.build`: `final sideBySide = windowSizeClassOf(context) == WindowSizeClass.expanded;`. Bij `!sideBySide` alles exact zoals nu. Bij `sideBySide`: `AppBar` zonder `bottom`; `body: Row(crossAxisAlignment: stretch, children: [Expanded(child: _PaneColumn(header: _BadgedTab(label: ridesTabRides, count: ridesAttention), child: RidesTab(firstRideKey: _firstRideKey))), const VerticalDivider(width: 1), Expanded(child: _PaneColumn(header: _BadgedTab(label: ridesTabBuddies, count: pelotonAttention), child: const BuddiesTab()))])`. `_PaneColumn` is een kleine private widget: `Column[Padding(16,12,16,4) met de header in `titleSmall`-stijl links uitgelijnd, Expanded(child)]` -- hergebruik `_BadgedTab` voor label+bolletje zodat de tellers niet uiteen kunnen lopen (CLUB-25); als `_BadgedTab` afhankelijk is van een TabBar-context, maak er een gedeelde `_LabelWithBadge` van die beide gebruiken. Geen nieuwe strings. `_tabController` blijft bestaan (ongebruikt bij sideBySide, geen kwaad). Hint-overlay blijft werken: `_firstRideKey` zit nog in RidesTab. Import `package:ridewindow/app/window_size.dart`.

Test `test/features/rides_two_pane_test.dart`: kopieer `_pumpRidesScreen` uit `test/app/nav_unanswered_badge_test.dart` (zelfde overrides) met een schermmaatparameter en dek de drie gedragingen. Als BuddiesTab op 1280 extra providers vraagt die in de huidige helper ontbreken (bij compact werd hij lui gebouwd door TabBarView), voeg de nodige overrides toe in de nieuwe test -- niet in productiecode.

Draai daarna de volledige suite en analyze. Geen version bump, geen release-build, niet pushen. Commit de wijzigingen lokaal per taak (conventionele commit-berichten, Nederlands, met de attribution-regels uit de sessie).
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter test && flutter analyze 2>&1 | tail -3</automated>
  </verify>
  <done>Ritten en Peloton staan op 1280 px naast elkaar met hun bolletjes; op telefoonbreedte ongewijzigde tabs; volledige suite groen (~1104 bestaand + nieuw); analyze 0 errors, 0 warnings.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| geen | Puur presentatielaag; geen nieuwe invoer, netwerk, opslag of rechten |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-jru-01 | Information disclosure | Rides/Peloton naast elkaar | accept | Toont dezelfde gegevens als de bestaande tabs aan dezelfde gebruiker; geen nieuwe bron |
| T-jru-02 | Denial of service | Home detailpaneel bij lege lijst | mitigate | `_buildDetailPane` geeft `SizedBox.shrink()` zonder slot; getest op 1280x800 zonder slots |
</threat_model>

<verification>
- `flutter test` volledig groen; `flutter analyze` 0 errors, 0 warnings (infos mogen, ~214 bestaand).
- Op compact geen nieuwe widgets in de boom: `ReadableWidth` retourneert het kind, shell/Home/Ritten nemen de bestaande tak.
- `grep -n "windowSizeClassOf" lib/app/scaffold_with_nav.dart lib/features/home/home_screen.dart lib/features/planned/planned_rides_screen.dart` geeft drie treffers; breakpoints staan alleen in `lib/app/window_size.dart` (`grep -rn "840\|600" lib --include=*.dart | grep -i width` toont geen tweede plek met deze breakpoints).
- Optioneel visueel: `flutter run -d chrome` en het venster op ~700 en ~1300 px zetten (na `flutter build web` altijd Cmd+Shift+R).
</verification>

<success_criteria>
- Telefoon (<600): onderbalk, één kolom Home, tabs op Ritten -- identiek aan nu.
- Medium (600-839): rail links; Welcome/Onboarding/Profiel max 640 px gecentreerd.
- Expanded (>=840): rail + Home lijst/detail met beste venster voorgeselecteerd + Ritten en Peloton naast elkaar.
- Geen nieuwe strings, geen gedupliceerde score- of balkenlogica, geen versieverhoging, niet gepusht.
</success_criteria>

<output>
Create `.planning/quick/261011-jru-tablet-layout-met-meerdere-panelen/261011-jru-SUMMARY.md` when done
</output>
