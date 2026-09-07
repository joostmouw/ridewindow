import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/shared/clothing_tip.dart';

/// De kledingbanden zijn sinds fase 24 twee dingen tegelijk: de drempels waarop
/// `recommendClothing` kiest, én de schaal die `FeelsLikeBar` tekent. Zodra die
/// uit elkaar lopen staat de markering in de ene band terwijl de tekst een
/// andere noemt, en dan liegt het scherm over zijn eigen redenering. Deze test
/// zet de grenzen vast.
void main() {
  group('ClothingCombo.forFeelsLike', () {
    test('de grens hoort bij de warmere band', () {
      // Ondergrenzen zijn inclusief: 20,0 is nog kort/kort, 19,9 niet meer.
      expect(ClothingCombo.forFeelsLike(20.0), ClothingCombo.shortShort);
      expect(ClothingCombo.forFeelsLike(19.9), ClothingCombo.longShort);
      expect(ClothingCombo.forFeelsLike(14.0), ClothingCombo.longShort);
      expect(ClothingCombo.forFeelsLike(13.9), ClothingCombo.longLong);
      expect(ClothingCombo.forFeelsLike(5.0), ClothingCombo.longLong);
      expect(ClothingCombo.forFeelsLike(4.9), ClothingCombo.longLongExtra);
    });

    test('extremen vallen in de buitenste banden', () {
      expect(ClothingCombo.forFeelsLike(45), ClothingCombo.shortShort);
      expect(ClothingCombo.forFeelsLike(-30), ClothingCombo.longLongExtra);
    });
  });

  group('de banden als schaal', () {
    test('sluiten op elkaar aan zonder gat of overlap', () {
      // De enum staat van warm naar koud; de ondergrens van elke band is de
      // bovengrens van de volgende. Een gat hier zou een stukje baan
      // ongekleurd laten, een overlap zou twee tinten over elkaar tekenen.
      final ordered = ClothingCombo.values;
      for (var i = 0; i < ordered.length - 1; i++) {
        expect(
          ordered[i].minFeelsC,
          ordered[i + 1].maxFeelsC,
          reason: '${ordered[i].name} begint niet waar '
              '${ordered[i + 1].name} eindigt',
        );
      }
    });

    test('alleen de buitenste banden hebben een open kant', () {
      expect(ClothingCombo.shortShort.maxFeelsC, isNull);
      expect(ClothingCombo.longLongExtra.minFeelsC, isNull);
      for (final combo in [ClothingCombo.longShort, ClothingCombo.longLong]) {
        expect(combo.minFeelsC, isNotNull);
        expect(combo.maxFeelsC, isNotNull);
      }
    });

    test('het getekende bereik omvat alle binnengrenzen', () {
      for (final combo in ClothingCombo.values) {
        for (final bound in [combo.minFeelsC, combo.maxFeelsC]) {
          if (bound == null) continue;
          expect(bound, greaterThan(feelsLikeZoomMinC));
          expect(bound, lessThan(feelsLikeZoomMaxC));
        }
      }
    });
  });

  group('recommendClothing', () {
    test('trekt de eigen snelheid van de temperatuur af', () {
      // 15° met 28 km/u wind: (28 + 15) x 0,05 = 2,15 eraf, dus 12,85 -- net
      // in lang/lang. Dit is het geval dat de balk moet uitleggen, want de
      // voorspelling zegt 15 en het advies zegt lange mouw én lange broek.
      final advice = recommendClothing(avgTempC: 15, avgWindKmh: 28);
      expect(advice.feelsLike, closeTo(12.85, 0.001));
      expect(advice.combo, ClothingCombo.longLong);
      expect(advice.windy, isTrue);
    });

    test('windstil kost nog steeds de eigen 15 km/u', () {
      final advice = recommendClothing(avgTempC: 20, avgWindKmh: 0);
      expect(advice.feelsLike, closeTo(19.25, 0.001));
      expect(advice.combo, ClothingCombo.longShort);
      expect(advice.windy, isFalse);
    });

    test('regen telt vanaf een halve millimeter', () {
      expect(recommendClothing(avgTempC: 18, totalPrecipMm: 0.5).raining,
          isFalse);
      expect(
          recommendClothing(avgTempC: 18, totalPrecipMm: 0.6).raining, isTrue);
    });
  });
}
