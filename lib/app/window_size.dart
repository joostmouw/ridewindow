// lib/app/window_size.dart
// Breedteklassen volgens Material 3 (compact / medium / expanded) en een
// leesbreedte voor schermen met één kolom tekst. Quick-plan 261011-jru.
//
// Eén regel voor de hele app: de klasse volgt uit de **vensterbreedte**, niet
// uit de breedte van het lichaam naast de navigatierail. Zo kiezen shell, Home
// en Ritten altijd dezelfde stand bij dezelfde breedte. De breakpoints staan
// alleen hier.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Vanaf deze breedte (dp) is het venster "medium": navigatierail in plaats
/// van onderbalk, leesbreedte op tekstschermen.
const double kMediumMinWidth = 600.0;

/// Vanaf deze breedte (dp) is het venster "expanded": lijst-plus-detail op
/// Home, Ritten en Peloton naast elkaar.
const double kExpandedMinWidth = 840.0;

/// Maximale breedte van een leeskolom (Welcome, Onboarding, Profiel, het
/// detailpaneel op Home).
const double kReadableMaxWidth = 640.0;

enum WindowSizeClass { compact, medium, expanded }

/// Pure functie, los te testen.
WindowSizeClass windowSizeClassFor(double width) {
  if (width >= kExpandedMinWidth) return WindowSizeClass.expanded;
  if (width >= kMediumMinWidth) return WindowSizeClass.medium;
  return WindowSizeClass.compact;
}

/// De breedteklasse van het huidige venster.
WindowSizeClass windowSizeClassOf(BuildContext context) =>
    windowSizeClassFor(MediaQuery.sizeOf(context).width);

/// Beperkt [child] vanaf medium tot [maxWidth] breed, horizontaal gecentreerd.
///
/// Op compact komt er **geen** extra widget in de boom: de telefoon blijft
/// precies zoals hij was. Bewust padding en geen `Center`/`Align`: die maken
/// de hoogte los, en Welcome's `Stack` en Onboarding's `Column` rekenen op een
/// strakke hoogte.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    required this.child,
    this.maxWidth = kReadableMaxWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (windowSizeClassOf(context) == WindowSizeClass.compact) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.hasBoundedWidth
            ? math.max(0.0, (constraints.maxWidth - maxWidth) / 2)
            : 0.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: child,
        );
      },
    );
  }
}
