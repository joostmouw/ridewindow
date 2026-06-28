import 'package:flutter/material.dart';

/// Tier colours used for ride-quality scoring.
/// Each tier has a foreground (text/icon) and background (container) variant.
class TierColors {
  const TierColors({
    required this.perfectFg,
    required this.perfectBg,
    required this.greatFg,
    required this.greatBg,
    required this.acceptableFg,
    required this.acceptableBg,
    required this.poorFg,
    required this.poorBg,
  });

  final Color perfectFg;
  final Color perfectBg;
  final Color greatFg;
  final Color greatBg;
  final Color acceptableFg;
  final Color acceptableBg;
  final Color poorFg;
  final Color poorBg;

  static const light = TierColors(
    perfectFg: Color(0xFF1B5E20),
    perfectBg: Color(0xFFE8F5E9),
    greatFg: Color(0xFF00695C),   // teal 800 — distinct from Perfect green
    greatBg: Color(0xFFE0F2F1),   // teal 50
    acceptableFg: Color(0xFFE65100),
    acceptableBg: Color(0xFFFFF3E0),
    poorFg: Color(0xFF757575),
    poorBg: Color(0xFFF5F5F5),
  );

  static const dark = TierColors(
    perfectFg: Color(0xFFA5D6A7),
    perfectBg: Color(0xFF1B3A1E),
    greatFg: Color(0xFF80CBC4),   // teal 200
    greatBg: Color(0xFF1A332F),   // dark teal
    acceptableFg: Color(0xFFFFCC80),
    acceptableBg: Color(0xFF3E2723),
    poorFg: Color(0xFF9E9E9E),
    poorBg: Color(0xFF2C2C2C),
  );
}

/// Semantic colour tokens used throughout the app.
abstract final class AppColors {
  // ── Brand ──
  static const seed = Color(0xFF2E7D32);

  // ── Light semantic ──
  static const lightTextPrimary = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF444444);
  static const lightTextTertiary = Color(0xFF666666);
  static const lightTextHint = Color(0xFF999999);

  static const lightSurface = Color(0xFFF5F5F5);
  static const lightSurfaceDim = Color(0xFFF0F0F0);
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightBorderLight = Color(0xFFE8E8E8);
  static const lightBorderDim = Color(0xFFF0F0F0);

  static const lightScorePerfect = Color(0xFF2E7D32);
  static const lightScoreGreat = Color(0xFF26A69A);  // teal 400
  static const lightScoreAcceptable = Color(0xFFFFA726);
  static const lightScorePoor = Color(0xFFBDBDBD);

  static const lightPlannedRide = Color(0xFF1565C0);
  static const lightPlannedRideLight = Color(0xFF64B5F6);
  static const lightCalendarBusy = Color(0xFF64B5F6);

  static const lightWarning = Color(0xFFFF9800);
  static const lightError = Color(0xFFE53935);
  static const lightErrorDark = Color(0xFFC62828);

  static const lightAvailWork = Color(0xFFB0BEC5);
  static const lightAvailCustom = Color(0xFFFF9800);
  static const lightAvailCalendar = Color(0xFF64B5F6);
  static const lightAvailCustomLight = Color(0xFFFFCC80);
  static const lightAvailWorkLight = Color(0xFFE0E0E0);

  static const lightRowGreenTint = Color(0x0A2E7D32);
  static const lightRowOrangeTint = Color(0x0AFF9800);
  static const lightRowRedTint = Color(0x08C62828);

  static const lightShadow = Color(0x14000000);
  static const lightBestHighlight = Color(0x292E7D32);
  static const lightNormalHighlight = Color(0x12000000);
  static const lightScoreGreenTint = Color(0x332E7D32);
  static const lightGreenBg = Color(0xFFF0F7F0);
  static const lightGreenBorder = Color(0xFFCCE5CC);
  static const lightGreenGradientStart = Color(0xFFE8F5E9);

  // ── Dark semantic ──
  static const darkTextPrimary = Color(0xFFE0E0E0);
  static const darkTextSecondary = Color(0xFFBDBDBD);
  static const darkTextTertiary = Color(0xFF9E9E9E);
  static const darkTextHint = Color(0xFF757575);

  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceDim = Color(0xFF2C2C2C);
  static const darkBorder = Color(0xFF424242);
  static const darkBorderLight = Color(0xFF383838);
  static const darkBorderDim = Color(0xFF333333);

  static const darkScorePerfect = Color(0xFF66BB6A);
  static const darkScoreGreat = Color(0xFF80CBC4);   // teal 200
  static const darkScoreAcceptable = Color(0xFFFFB74D);
  static const darkScorePoor = Color(0xFF757575);

  static const darkPlannedRide = Color(0xFF42A5F5);
  static const darkPlannedRideLight = Color(0xFF90CAF9);
  static const darkCalendarBusy = Color(0xFF90CAF9);

  static const darkWarning = Color(0xFFFFB74D);
  static const darkError = Color(0xFFEF5350);
  static const darkErrorDark = Color(0xFFE53935);

  static const darkAvailWork = Color(0xFF78909C);
  static const darkAvailCustom = Color(0xFFFFB74D);
  static const darkAvailCalendar = Color(0xFF90CAF9);
  static const darkAvailCustomLight = Color(0xFF5D4037);
  static const darkAvailWorkLight = Color(0xFF37474F);

  static const darkRowGreenTint = Color(0x1A66BB6A);
  static const darkRowOrangeTint = Color(0x1AFFB74D);
  static const darkRowRedTint = Color(0x1AEF5350);

  static const darkShadow = Color(0x29000000);
  static const darkBestHighlight = Color(0x2966BB6A);
  static const darkNormalHighlight = Color(0x1FFFFFFF);
  static const darkScoreGreenTint = Color(0x3366BB6A);
  static const darkGreenBg = Color(0xFF1B3A1E);
  static const darkGreenBorder = Color(0xFF2E5B30);
  static const darkGreenGradientStart = Color(0xFF1B3A1E);
}
