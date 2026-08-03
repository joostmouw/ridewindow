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

  group('recurringSlotKey', () {
    test('matcht dezelfde formule als BlockedHours interne _slotOf', () {
      // maandag 2026-07-27, 9u: weekday=1, hour=9 -> 1*24+9 = 33
      expect(recurringSlotKey(DateTime(2026, 7, 27, 9)), 33);
    });
  });

  group('toRecurringRow — SYNC-10: calendar-entries gaan nooit mee', () {
    test('bevat alleen work/custom als "weekdag-uur": "blocktype" paren', () {
      final hours = {
        DateTime(2026, 7, 27, 9): BlockType.work, // maandag
        DateTime(2026, 7, 28, 17): BlockType.custom, // dinsdag
        DateTime(2026, 7, 29, 14): BlockType.calendar, // woensdag
      };
      final row = toRecurringRow(hours);

      expect(row.length, 2);
      expect(row['1-9'], 'work');
      expect(row['2-17'], 'custom');
      expect(row.values.contains('calendar'), isFalse);
    });

    test('een uitsluitend-calendar map levert een lege recurring-rij op', () {
      final row = toRecurringRow({
        DateTime(2026, 7, 27, 9): BlockType.calendar,
      });
      expect(row, isEmpty);
    });
  });

  group('fromRecurringJson', () {
    test('materialiseert weekdag-uur sleutels op de huidige week', () {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      final result = fromRecurringJson({'2-9': 'work', '2-17': 'custom'});

      expect(result.length, 2);
      final tuesday9 = monday.add(const Duration(days: 1, hours: 9));
      final tuesday17 = monday.add(const Duration(days: 1, hours: 17));
      expect(result[tuesday9], BlockType.work);
      expect(result[tuesday17], BlockType.custom);
      expect(tuesday9.weekday, DateTime.tuesday);
    });

    test('negeert misvormde sleutels stilzwijgend', () {
      final result = fromRecurringJson({'onzin': 'work', '2-9': 'work'});
      expect(result.length, 1);
    });
  });

  group('toRecurringRow / fromRecurringJson — round-trip (SYNC-10)', () {
    test('(weekdag, uur, BlockType) triples overleven de heenreis-terugreis', () {
      final hours = {
        DateTime(2026, 7, 27, 9): BlockType.work, // maandag
        DateTime(2026, 7, 28, 17): BlockType.custom, // dinsdag
      };

      final roundTripped = fromRecurringJson(toRecurringRow(hours));

      final originalTriples = hours.entries
          .map((e) => (recurringSlotKey(e.key), e.value))
          .toSet();
      final roundTrippedTriples = roundTripped.entries
          .map((e) => (recurringSlotKey(e.key), e.value))
          .toSet();

      expect(roundTrippedTriples, originalTriples);
    });
  });
}
