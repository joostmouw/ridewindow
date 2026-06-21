// lib/features/shared/clothing_tip.dart
// Clothing recommendation based on "feels like" cycling temperature.
// Cycling logic: legs are the engine (stay warm), upper body catches wind.
// So mixing = lang boven, kort onder — never the reverse.

import 'package:flutter/material.dart';

enum _ClothingCombo {
  /// kort/kort — short sleeves + shorts
  shortShort,
  /// lang/kort — long sleeves + shorts (upper body cold, legs warm from pedaling)
  longShort,
  /// lang/lang — long sleeves + long pants
  longLong,
  /// lang/lang + jacket — full cover + wind/rain layer
  longLongJacket,
}

_ClothingCombo _recommend(double? avgTempC, double? avgWindKmh, double? totalPrecipMm) {
  if (avgTempC == null) return _ClothingCombo.longShort;

  // Wind chill for cycling: you ride at ~15-20 km/h into the wind.
  final wind = (avgWindKmh ?? 0) + 15;
  final feelsLike = avgTempC - (wind * 0.05);

  final raining = (totalPrecipMm ?? 0) > 0.5;

  if (raining) {
    if (feelsLike >= 18) return _ClothingCombo.longShort;
    return _ClothingCombo.longLongJacket;
  }

  if (feelsLike >= 22) return _ClothingCombo.shortShort;
  if (feelsLike >= 16) return _ClothingCombo.longShort;
  if (feelsLike >= 8) return _ClothingCombo.longLong;
  return _ClothingCombo.longLongJacket;
}

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
    final combo = _recommend(avgTempC, avgWindKmh, totalPrecipMm);
    final cs = Theme.of(context).colorScheme;

    final String emoji;
    final String label;
    switch (combo) {
      case _ClothingCombo.shortShort:
        emoji = '\u{1F455}\u{1FA73}'; // t-shirt + shorts
        label = 'Kort/kort';
      case _ClothingCombo.longShort:
        emoji = '\u{1F9E5}\u{1FA73}'; // sweater + shorts
        label = 'Lang/kort';
      case _ClothingCombo.longLong:
        emoji = '\u{1F9E5}\u{1F456}'; // sweater + jeans
        label = 'Lang/lang';
      case _ClothingCombo.longLongJacket:
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
