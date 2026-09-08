import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Custom [ThemeExtension] that exposes semantic colour tokens and tier colours.
///
/// Usage: `Theme.of(context).extension<RideWindowTheme>()!`
/// Shorthand: `context.rw` via the extension below.
class RideWindowTheme extends ThemeExtension<RideWindowTheme> {
  const RideWindowTheme({
    required this.tiers,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textHint,
    required this.surface,
    required this.surfaceDim,
    required this.border,
    required this.gridBlocked,
    required this.borderLight,
    required this.borderDim,
    required this.scorePerfect,
    required this.scoreGreat,
    required this.scoreAcceptable,
    required this.scorePoor,
    required this.plannedRide,
    required this.rideOrganiser,
    required this.ridePending,
    required this.plannedRideLight,
    required this.calendarBusy,
    required this.warning,
    required this.error,
    required this.errorDark,
    required this.availWork,
    required this.availCustom,
    required this.availCalendar,
    required this.availCustomLight,
    required this.availWorkLight,
    required this.rowGreenTint,
    required this.rowOrangeTint,
    required this.rowRedTint,
    required this.shadow,
    required this.bestHighlight,
    required this.normalHighlight,
    required this.scoreGreenTint,
    required this.greenBg,
    required this.greenBorder,
    required this.greenGradientStart,
  });

  final TierColors tiers;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textHint;
  final Color surface;
  final Color surfaceDim;
  final Color border;

  /// De vulling van een geblokkeerd uur in de roosters (Agenda,
  /// Beschikbaarheid).
  ///
  /// Bewust neutraal en niet uit de merkfamilie. Tot v4.0 was dit
  /// `surfaceContainerHighest` -- een olijftint die wegviel tegen de toen nog
  /// groene achtergrond, en dat was precies de bedoeling: geblokkeerd betekent
  /// "hier is niets". Sinds de achtergrond papier is, werd diezelfde tint juist
  /// het zwaarste vlak van het scherm en schreeuwde hij harder dan de
  /// tier-kleuren die er wél toe doen. De betekenis was omgekeerd zonder dat er
  /// iets aan de code veranderde.
  ///
  /// Neutraal grijs herstelt de rangorde: kleur betekent in het rooster nog
  /// maar één ding, namelijk "hier kun je fietsen".
  final Color gridBlocked;
  final Color borderLight;
  final Color borderDim;
  final Color scorePerfect;
  final Color scoreGreat;
  final Color scoreAcceptable;
  final Color scorePoor;
  final Color plannedRide;

  /// De kleur van "jij organiseert" en van "wacht op jou" (schets 008).
  final Color rideOrganiser;
  final Color ridePending;
  final Color plannedRideLight;
  final Color calendarBusy;
  final Color warning;
  final Color error;
  final Color errorDark;
  final Color availWork;
  final Color availCustom;
  final Color availCalendar;
  final Color availCustomLight;
  final Color availWorkLight;
  final Color rowGreenTint;
  final Color rowOrangeTint;
  final Color rowRedTint;
  final Color shadow;
  final Color bestHighlight;
  final Color normalHighlight;
  final Color scoreGreenTint;
  final Color greenBg;
  final Color greenBorder;
  final Color greenGradientStart;

  static const light = RideWindowTheme(
    tiers: TierColors.light,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    textHint: AppColors.lightTextHint,
    surface: AppColors.lightSurface,
    surfaceDim: AppColors.lightSurfaceDim,
    border: AppColors.lightBorder,
    gridBlocked: AppColors.lightGridBlocked,
    borderLight: AppColors.lightBorderLight,
    borderDim: AppColors.lightBorderDim,
    scorePerfect: AppColors.lightScorePerfect,
    scoreGreat: AppColors.lightScoreGreat,
    scoreAcceptable: AppColors.lightScoreAcceptable,
    scorePoor: AppColors.lightScorePoor,
    plannedRide: AppColors.lightPlannedRide,
    rideOrganiser: AppColors.lightRideOrganiser,
    ridePending: AppColors.lightRidePending,
    plannedRideLight: AppColors.lightPlannedRideLight,
    calendarBusy: AppColors.lightCalendarBusy,
    warning: AppColors.lightWarning,
    error: AppColors.lightError,
    errorDark: AppColors.lightErrorDark,
    availWork: AppColors.lightAvailWork,
    availCustom: AppColors.lightAvailCustom,
    availCalendar: AppColors.lightAvailCalendar,
    availCustomLight: AppColors.lightAvailCustomLight,
    availWorkLight: AppColors.lightAvailWorkLight,
    rowGreenTint: AppColors.lightRowGreenTint,
    rowOrangeTint: AppColors.lightRowOrangeTint,
    rowRedTint: AppColors.lightRowRedTint,
    shadow: AppColors.lightShadow,
    bestHighlight: AppColors.lightBestHighlight,
    normalHighlight: AppColors.lightNormalHighlight,
    scoreGreenTint: AppColors.lightScoreGreenTint,
    greenBg: AppColors.lightGreenBg,
    greenBorder: AppColors.lightGreenBorder,
    greenGradientStart: AppColors.lightGreenGradientStart,
  );

  static const dark = RideWindowTheme(
    tiers: TierColors.dark,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    textHint: AppColors.darkTextHint,
    surface: AppColors.darkSurface,
    surfaceDim: AppColors.darkSurfaceDim,
    border: AppColors.darkBorder,
    gridBlocked: AppColors.darkGridBlocked,
    borderLight: AppColors.darkBorderLight,
    borderDim: AppColors.darkBorderDim,
    scorePerfect: AppColors.darkScorePerfect,
    scoreGreat: AppColors.darkScoreGreat,
    scoreAcceptable: AppColors.darkScoreAcceptable,
    scorePoor: AppColors.darkScorePoor,
    plannedRide: AppColors.darkPlannedRide,
    rideOrganiser: AppColors.darkRideOrganiser,
    ridePending: AppColors.darkRidePending,
    plannedRideLight: AppColors.darkPlannedRideLight,
    calendarBusy: AppColors.darkCalendarBusy,
    warning: AppColors.darkWarning,
    error: AppColors.darkError,
    errorDark: AppColors.darkErrorDark,
    availWork: AppColors.darkAvailWork,
    availCustom: AppColors.darkAvailCustom,
    availCalendar: AppColors.darkAvailCalendar,
    availCustomLight: AppColors.darkAvailCustomLight,
    availWorkLight: AppColors.darkAvailWorkLight,
    rowGreenTint: AppColors.darkRowGreenTint,
    rowOrangeTint: AppColors.darkRowOrangeTint,
    rowRedTint: AppColors.darkRowRedTint,
    shadow: AppColors.darkShadow,
    bestHighlight: AppColors.darkBestHighlight,
    normalHighlight: AppColors.darkNormalHighlight,
    scoreGreenTint: AppColors.darkScoreGreenTint,
    greenBg: AppColors.darkGreenBg,
    greenBorder: AppColors.darkGreenBorder,
    greenGradientStart: AppColors.darkGreenGradientStart,
  );

  @override
  RideWindowTheme copyWith({
    TierColors? tiers,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textHint,
    Color? surface,
    Color? surfaceDim,
    Color? border,
    Color? gridBlocked,
    Color? borderLight,
    Color? borderDim,
    Color? scorePerfect,
    Color? scoreGreat,
    Color? scoreAcceptable,
    Color? scorePoor,
    Color? plannedRide,
    Color? rideOrganiser,
    Color? ridePending,
    Color? plannedRideLight,
    Color? calendarBusy,
    Color? warning,
    Color? error,
    Color? errorDark,
    Color? availWork,
    Color? availCustom,
    Color? availCalendar,
    Color? availCustomLight,
    Color? availWorkLight,
    Color? rowGreenTint,
    Color? rowOrangeTint,
    Color? rowRedTint,
    Color? shadow,
    Color? bestHighlight,
    Color? normalHighlight,
    Color? scoreGreenTint,
    Color? greenBg,
    Color? greenBorder,
    Color? greenGradientStart,
  }) {
    return RideWindowTheme(
      tiers: tiers ?? this.tiers,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textHint: textHint ?? this.textHint,
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      border: border ?? this.border,
      gridBlocked: gridBlocked ?? this.gridBlocked,
      borderLight: borderLight ?? this.borderLight,
      borderDim: borderDim ?? this.borderDim,
      scorePerfect: scorePerfect ?? this.scorePerfect,
      scoreGreat: scoreGreat ?? this.scoreGreat,
      scoreAcceptable: scoreAcceptable ?? this.scoreAcceptable,
      scorePoor: scorePoor ?? this.scorePoor,
      plannedRide: plannedRide ?? this.plannedRide,
      rideOrganiser: rideOrganiser ?? this.rideOrganiser,
      ridePending: ridePending ?? this.ridePending,
      plannedRideLight: plannedRideLight ?? this.plannedRideLight,
      calendarBusy: calendarBusy ?? this.calendarBusy,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      errorDark: errorDark ?? this.errorDark,
      availWork: availWork ?? this.availWork,
      availCustom: availCustom ?? this.availCustom,
      availCalendar: availCalendar ?? this.availCalendar,
      availCustomLight: availCustomLight ?? this.availCustomLight,
      availWorkLight: availWorkLight ?? this.availWorkLight,
      rowGreenTint: rowGreenTint ?? this.rowGreenTint,
      rowOrangeTint: rowOrangeTint ?? this.rowOrangeTint,
      rowRedTint: rowRedTint ?? this.rowRedTint,
      shadow: shadow ?? this.shadow,
      bestHighlight: bestHighlight ?? this.bestHighlight,
      normalHighlight: normalHighlight ?? this.normalHighlight,
      scoreGreenTint: scoreGreenTint ?? this.scoreGreenTint,
      greenBg: greenBg ?? this.greenBg,
      greenBorder: greenBorder ?? this.greenBorder,
      greenGradientStart: greenGradientStart ?? this.greenGradientStart,
    );
  }

  @override
  RideWindowTheme lerp(covariant RideWindowTheme? other, double t) {
    if (other == null) return this;
    return RideWindowTheme(
      tiers: t < 0.5 ? tiers : other.tiers,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      border: Color.lerp(border, other.border, t)!,
      gridBlocked: Color.lerp(gridBlocked, other.gridBlocked, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderDim: Color.lerp(borderDim, other.borderDim, t)!,
      scorePerfect: Color.lerp(scorePerfect, other.scorePerfect, t)!,
      scoreGreat: Color.lerp(scoreGreat, other.scoreGreat, t)!,
      scoreAcceptable: Color.lerp(scoreAcceptable, other.scoreAcceptable, t)!,
      scorePoor: Color.lerp(scorePoor, other.scorePoor, t)!,
      plannedRide: Color.lerp(plannedRide, other.plannedRide, t)!,
      rideOrganiser: Color.lerp(rideOrganiser, other.rideOrganiser, t)!,
      ridePending: Color.lerp(ridePending, other.ridePending, t)!,
      plannedRideLight:
          Color.lerp(plannedRideLight, other.plannedRideLight, t)!,
      calendarBusy: Color.lerp(calendarBusy, other.calendarBusy, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      availWork: Color.lerp(availWork, other.availWork, t)!,
      availCustom: Color.lerp(availCustom, other.availCustom, t)!,
      availCalendar: Color.lerp(availCalendar, other.availCalendar, t)!,
      availCustomLight:
          Color.lerp(availCustomLight, other.availCustomLight, t)!,
      availWorkLight: Color.lerp(availWorkLight, other.availWorkLight, t)!,
      rowGreenTint: Color.lerp(rowGreenTint, other.rowGreenTint, t)!,
      rowOrangeTint: Color.lerp(rowOrangeTint, other.rowOrangeTint, t)!,
      rowRedTint: Color.lerp(rowRedTint, other.rowRedTint, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      bestHighlight: Color.lerp(bestHighlight, other.bestHighlight, t)!,
      normalHighlight: Color.lerp(normalHighlight, other.normalHighlight, t)!,
      scoreGreenTint: Color.lerp(scoreGreenTint, other.scoreGreenTint, t)!,
      greenBg: Color.lerp(greenBg, other.greenBg, t)!,
      greenBorder: Color.lerp(greenBorder, other.greenBorder, t)!,
      greenGradientStart:
          Color.lerp(greenGradientStart, other.greenGradientStart, t)!,
    );
  }
}

/// Convenience getter so widgets can write `context.rw` instead of
/// `Theme.of(context).extension<RideWindowTheme>()!`.
extension RideWindowThemeX on BuildContext {
  RideWindowTheme get rw => Theme.of(this).extension<RideWindowTheme>()!;
}

/// Het lichte thema als één gedeelde instantie.
///
/// Voor de schermen die hun achtergrond hard vastzetten en dus ook hun
/// voorgrond moeten vastzetten -- zie `BrandCanvas`. Een top-level `final`
/// wordt in Dart lui en precies één keer geïnitialiseerd, en dat is hier het
/// punt: `ColorScheme.fromSeed` is geen goedkope aanroep om per frame te doen.
final ThemeData brandCanvasTheme = buildAppTheme(Brightness.light);

/// Het app-brede thema, per helderheid.
///
/// **Stond tot 2026-09-08 in `main.dart` en was daardoor onbereikbaar voor de
/// twee schermen die hem het hardst nodig hadden.** Welkom en Onboarding zetten
/// hun achtergrond bewust hard op [AppColors.brandLight] -- een merkmoment in
/// plaats van behang -- maar haalden hun tekstkleur uit het actieve schema. In
/// donkere modus is dat lichte tekst op een licht groen vlak: 1,21:1 voor de
/// titel en 1,09:1 voor de ondertitel, tegen 9,63:1 en 5,54:1 in lichte modus.
/// Een scherm dat zijn achtergrond vastzet, moet zijn voorgrond ook vastzetten,
/// en daarvoor moet dit thema van buiten main.dart te bouwen zijn.
ThemeData buildAppTheme(Brightness brightness) {
  final seeded = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  );
  final isLight = brightness == Brightness.light;

  // In light mode houden de oppervlakken een lichte groenzweem in plaats van
  // MD3's neutrale grijs, zodat het scherm papier is en geen steriel wit --
  // maar de achtergrond is sinds v4.0 wél licht (`lightSurface`), niet
  // brandLight. Zie de noot bij `AppColors.brandLight`: op een middentoon leest
  // een slagschaduw niet, en zonder schaduw is er geen manier om de beste rit
  // vóór de rest te zetten. Dark mode volgt het afgeleide schema van de seed.
  final colorScheme = isLight
      ? seeded.copyWith(
          surface: AppColors.lightSurface,
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

    // ── Huisletter (epic #64) ──
    // `fontFamily` dekt alles wat geen expliciete stijl uit `textTheme` pakt
    // (denk aan losse `TextStyle`s in schermen die nog niet zijn omgezet), zodat
    // er nergens Roboto doorheen lekt zolang die opruiming loopt.
    fontFamily: AppTypography.family,
    textTheme: AppTypography.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),

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
    //
    // Sinds v4.0 fase 23 hebben Home en Ride Detail hun kaarten lokaal op
    // papier-wit gezet: `surfaceContainerLowest` met een haarlijn in
    // `surfaceContainerHigh`. Dit thema bleef ondertussen op
    // `surfaceContainerLow` staan met een rand van `outlineVariant` op 120
    // alpha, en dus had de app twee soorten kaarten — welke je kreeg hing
    // ervan af of dat scherm in de sweep was meegenomen. Op "My rides" was dat
    // meteen te zien: groenige kaarten naast Home's witte.
    //
    // Nu is het thema de papierbehandeling en zijn de lokale overschrijvingen
    // op Home en Ride Detail de uitzondering die ze horen te zijn (die staan
    // er om andere redenen — een `ClipRRect` die geen `elevation` doorlaat, en
    // een `Container` die ook een `BoxShadow` droeg).
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.surfaceContainerHigh),
      ),
      color: colorScheme.surfaceContainerLowest,
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
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
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
      // Zonder deze rand is een uitgeschakelde schakelaar een randloze olijf-
      // vlek: op de papieren achtergrond van v4.0 leest hij dan niet als "uit"
      // maar als "kapot". Material 3 schrijft de omtrek voor en die ontbrak --
      // vandaar dat de notificatie-toggles in Profiel dood ogen. Aan verdwijnt
      // hij, want daar draagt de gevulde track de staat al.
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return colorScheme.outline;
      }),
    ),
  );
}
