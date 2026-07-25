import 'package:test/test.dart';
import 'package:ridewindow/domain/services/availability_key.dart';
import 'package:ridewindow/providers/availability_notifier.dart';

void main() {
  group('canonicalHourKey', () {
    test('lokale DateTime blijft ongewijzigd', () {
      final t = DateTime(2026, 7, 27, 9, 34, 12);
      expect(canonicalHourKey(t), DateTime(2026, 7, 27, 9));
    });

    test('UTC-DateTime levert dezelfde sleutel als de lokale variant', () {
      // De oude grid-sleutels stempelden een lokale wandkloktijd als UTC; de
      // componenten zijn dus al de bedoelde lokale tijd en mogen niet omgerekend
      // worden.
      expect(
        canonicalHourKey(DateTime.utc(2026, 7, 27, 9)),
        canonicalHourKey(DateTime(2026, 7, 27, 9)),
      );
    });

    test('de sleutel is niet UTC, zodat lookups tegen forecast-tijden matchen', () {
      expect(canonicalHourKey(DateTime.utc(2026, 7, 27, 9)).isUtc, isFalse);
    });
  });

  group('normalizeBlockedHours — migratie van bestaande installs', () {
    test('gemengde UTC- en lokale sleutels vallen samen op één sleutel', () {
      final raw = {
        DateTime.utc(2026, 7, 27, 9): BlockType.custom,
        DateTime(2026, 7, 27, 10): BlockType.custom,
      };
      final result = normalizeBlockedHours(raw);
      expect(result.length, 2);
      expect(result[DateTime(2026, 7, 27, 9)], BlockType.custom);
      expect(result[DateTime(2026, 7, 27, 10)], BlockType.custom);
    });

    test('bij een botsing wint het sterkste bloktype', () {
      final raw = {
        DateTime.utc(2026, 7, 27, 9): BlockType.custom,
        DateTime(2026, 7, 27, 9): BlockType.work,
      };
      expect(normalizeBlockedHours(raw)[DateTime(2026, 7, 27, 9)],
          BlockType.work,);
    });
  });

  group('BlockedHours — work/custom herhalen wekelijks', () {
    // 2026-07-27 is een maandag.
    final maandag = DateTime(2026, 7, 27, 9);

    test('work blokkeert hetzelfde uur in een latere week', () {
      final blocked = BlockedHours({maandag: BlockType.work});
      expect(blocked.isBlocked(maandag.add(const Duration(days: 7))), isTrue);
      expect(blocked.isBlocked(maandag.add(const Duration(days: 14))), isTrue);
    });

    test('custom herhaalt ook — het grid is een weekpatroon', () {
      final blocked = BlockedHours({maandag: BlockType.custom});
      expect(blocked.isBlocked(maandag.add(const Duration(days: 7))), isTrue);
    });

    test('een ander uur op dezelfde weekdag blijft vrij', () {
      final blocked = BlockedHours({maandag: BlockType.work});
      expect(blocked.isBlocked(DateTime(2026, 7, 27, 10)), isFalse);
    });

    test('een andere weekdag blijft vrij', () {
      final blocked = BlockedHours({maandag: BlockType.work});
      expect(blocked.isBlocked(DateTime(2026, 7, 28, 9)), isFalse);
    });
  });

  group('BlockedHours — calendar is datum-specifiek', () {
    final dinsdag = DateTime(2026, 7, 28, 14);

    test('blokkeert de eigen datum', () {
      final blocked = BlockedHours({dinsdag: BlockType.calendar});
      expect(blocked.isBlocked(dinsdag), isTrue);
    });

    test('herhaalt NIET naar de volgende week', () {
      final blocked = BlockedHours({dinsdag: BlockType.calendar});
      expect(blocked.isBlocked(dinsdag.add(const Duration(days: 7))), isFalse);
    });
  });

  group('BlockedHours — sleutel-smaak maakt niet meer uit (audit A1)', () {
    test('een UTC-sleutel blokkeert een lokaal uur', () {
      final blocked = BlockedHours({DateTime.utc(2026, 7, 27, 9): BlockType.custom});
      expect(blocked.isBlocked(DateTime(2026, 7, 27, 9)), isTrue);
    });

    test('een lokale sleutel blokkeert een lokaal forecast-uur', () {
      final blocked = BlockedHours({DateTime(2026, 7, 27, 9): BlockType.custom});
      expect(blocked.isBlocked(DateTime(2026, 7, 27, 9)), isTrue);
    });
  });

  test('blockTypeAt geeft null voor een vrij uur', () {
    expect(blockTypeAt(DateTime(2026, 7, 27, 9), const {}), isNull);
    expect(isHourBlocked(DateTime(2026, 7, 27, 9), const {}), isFalse);
  });
}
