// lib/features/shared/clothing_tip.dart
// Clothing recommendation for cyclists based on feels-like temperature.
//
// Cycling logic:
// - Legs are the engine → stay warm from pedaling → shorts until ~14°C
// - Upper body catches wind → needs protection sooner
// - So mixing = lang boven, kort onder — never the reverse
//
// Thresholds (feels-like, accounting for cycling wind chill):
//   ≥20°C  kort/kort   — t-shirt + korte broek
//   14-20°C lang/kort  — lange mouw + korte broek
//   5-14°C  lang/lang  — lange mouw + lange broek
//   <5°C    lang/lang+  — volledige bescherming + extra lagen

import 'package:flutter/material.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Shared recommendation logic — used by both the emoji widget and the
// detailed clothing list on the detail screen.
// ---------------------------------------------------------------------------

enum ClothingCombo {
  shortShort,
  longShort,
  longLong,
  longLongExtra,
}

class ClothingAdvice {
  final ClothingCombo combo;
  final double feelsLike;
  final bool raining;
  final bool windy;

  const ClothingAdvice({
    required this.combo,
    required this.feelsLike,
    required this.raining,
    required this.windy,
  });
}

ClothingAdvice recommendClothing({
  required double? avgTempC,
  double? avgWindKmh,
  double? totalPrecipMm,
}) {
  // Cycling adds ~15 km/h effective headwind.
  final wind = (avgWindKmh ?? 0) + 15;
  final feelsLike = (avgTempC ?? 15) - (wind * 0.05);
  final raining = (totalPrecipMm ?? 0) > 0.5;
  final windy = (avgWindKmh ?? 0) > 25;

  final ClothingCombo combo;
  if (feelsLike >= 20) {
    combo = ClothingCombo.shortShort;
  } else if (feelsLike >= 14) {
    combo = ClothingCombo.longShort;
  } else if (feelsLike >= 5) {
    combo = ClothingCombo.longLong;
  } else {
    combo = ClothingCombo.longLongExtra;
  }

  return ClothingAdvice(
    combo: combo,
    feelsLike: feelsLike,
    raining: raining,
    windy: windy,
  );
}

/// Returns the detailed clothing items list for the detail screen.
List<String> clothingItems(ClothingAdvice advice, S s) {
  final items = <String>[];

  switch (advice.combo) {
    case ClothingCombo.shortShort:
      items.add(s.clothingShortSleeveJersey);
      if (advice.feelsLike >= 25) {
        items.add(s.clothingSunscreen);
      }
      if (advice.feelsLike >= 30) {
        items.add(s.clothingExtraWater);
      }
    case ClothingCombo.longShort:
      items.add(s.clothingLongSleeveJersey);
      if (advice.feelsLike < 17) {
        items.add(s.clothingArmWarmersJustInCase);
      }
    case ClothingCombo.longLong:
      items.add(s.clothingLongSleeveJersey);
      if (advice.feelsLike < 10) {
        items.addAll([s.clothingArmWarmers, s.clothingLegWarmers]);
      } else {
        items.add(s.clothingKneeWarmers);
      }
    case ClothingCombo.longLongExtra:
      items.addAll([
        s.clothingWinterJacket,
        s.clothingThermalPants,
        s.clothingGloves,
        s.clothingOvershoes,
      ]);
  }

  if (advice.raining) items.add(s.clothingRainJacket);
  if (advice.windy) items.add(s.clothingWindVest);

  return items;
}

// ---------------------------------------------------------------------------
// Emoji widget — compact visual summary
// ---------------------------------------------------------------------------

class ClothingTip extends StatelessWidget {
  final double? avgTempC;
  final double? avgWindKmh;
  final double? totalPrecipMm;

  const ClothingTip({
    super.key,
    this.avgTempC,
    this.avgWindKmh,
    this.totalPrecipMm,
  });

  @override
  Widget build(BuildContext context) {
    final advice = recommendClothing(
      avgTempC: avgTempC,
      avgWindKmh: avgWindKmh,
      totalPrecipMm: totalPrecipMm,
    );
    final cs = Theme.of(context).colorScheme;

    final String emoji;
    final String label;
    switch (advice.combo) {
      case ClothingCombo.shortShort:
        emoji = '\u{1F455}\u{1FA73}'; // t-shirt + shorts
        label = 'Kort/kort';
      case ClothingCombo.longShort:
        emoji = '\u{1F9E5}\u{1FA73}'; // long sleeve + shorts
        label = 'Lang/kort';
      case ClothingCombo.longLong:
        emoji = '\u{1F9E5}\u{1F456}'; // long sleeve + pants
        label = 'Lang/lang';
      case ClothingCombo.longLongExtra:
        emoji = '\u{1F9E5}\u{1F9E5}'; // double layer
        label = 'Lang/lang +';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
