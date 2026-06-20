import 'package:flutter/material.dart';
import 'app_colors.dart';

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
    required this.borderLight,
    required this.borderDim,
    required this.scorePerfect,
    required this.scoreGreat,
    required this.scoreAcceptable,
    required this.scorePoor,
    required this.plannedRide,
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
  final Color borderLight;
  final Color borderDim;
  final Color scorePerfect;
  final Color scoreGreat;
  final Color scoreAcceptable;
  final Color scorePoor;
  final Color plannedRide;
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
    borderLight: AppColors.lightBorderLight,
    borderDim: AppColors.lightBorderDim,
    scorePerfect: AppColors.lightScorePerfect,
    scoreGreat: AppColors.lightScoreGreat,
    scoreAcceptable: AppColors.lightScoreAcceptable,
    scorePoor: AppColors.lightScorePoor,
    plannedRide: AppColors.lightPlannedRide,
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
    borderLight: AppColors.darkBorderLight,
    borderDim: AppColors.darkBorderDim,
    scorePerfect: AppColors.darkScorePerfect,
    scoreGreat: AppColors.darkScoreGreat,
    scoreAcceptable: AppColors.darkScoreAcceptable,
    scorePoor: AppColors.darkScorePoor,
    plannedRide: AppColors.darkPlannedRide,
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
    Color? borderLight,
    Color? borderDim,
    Color? scorePerfect,
    Color? scoreGreat,
    Color? scoreAcceptable,
    Color? scorePoor,
    Color? plannedRide,
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
      borderLight: borderLight ?? this.borderLight,
      borderDim: borderDim ?? this.borderDim,
      scorePerfect: scorePerfect ?? this.scorePerfect,
      scoreGreat: scoreGreat ?? this.scoreGreat,
      scoreAcceptable: scoreAcceptable ?? this.scoreAcceptable,
      scorePoor: scorePoor ?? this.scorePoor,
      plannedRide: plannedRide ?? this.plannedRide,
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
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderDim: Color.lerp(borderDim, other.borderDim, t)!,
      scorePerfect: Color.lerp(scorePerfect, other.scorePerfect, t)!,
      scoreGreat: Color.lerp(scoreGreat, other.scoreGreat, t)!,
      scoreAcceptable: Color.lerp(scoreAcceptable, other.scoreAcceptable, t)!,
      scorePoor: Color.lerp(scorePoor, other.scorePoor, t)!,
      plannedRide: Color.lerp(plannedRide, other.plannedRide, t)!,
      plannedRideLight: Color.lerp(plannedRideLight, other.plannedRideLight, t)!,
      calendarBusy: Color.lerp(calendarBusy, other.calendarBusy, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      availWork: Color.lerp(availWork, other.availWork, t)!,
      availCustom: Color.lerp(availCustom, other.availCustom, t)!,
      availCalendar: Color.lerp(availCalendar, other.availCalendar, t)!,
      availCustomLight: Color.lerp(availCustomLight, other.availCustomLight, t)!,
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
      greenGradientStart: Color.lerp(greenGradientStart, other.greenGradientStart, t)!,
    );
  }
}

/// Convenience getter so widgets can write `context.rw` instead of
/// `Theme.of(context).extension<RideWindowTheme>()!`.
extension RideWindowThemeX on BuildContext {
  RideWindowTheme get rw => Theme.of(this).extension<RideWindowTheme>()!;
}
