import 'package:flutter/material.dart';

/// Centralised shape and spacing tokens.
abstract final class AppShapes {
  // ── Border radii ──
  static const radiusXs = 4.0;
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radiusFull = 999.0;

  static final roundedXs = BorderRadius.circular(radiusXs);
  static final roundedSm = BorderRadius.circular(radiusSm);
  static final roundedMd = BorderRadius.circular(radiusMd);
  static final roundedLg = BorderRadius.circular(radiusLg);
  static final roundedXl = BorderRadius.circular(radiusXl);
  static final roundedFull = BorderRadius.circular(radiusFull);

  // ── Common paddings ──
  static const paddingXs = 4.0;
  static const paddingSm = 8.0;
  static const paddingMd = 12.0;
  static const paddingLg = 16.0;
  static const paddingXl = 24.0;
}
