import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/services/invite_code.dart';

void main() {
  group('generateInviteCode', () {
    test('heeft de afgesproken lengte en gebruikt alleen het alfabet', () {
      for (var i = 0; i < 200; i++) {
        final code = generateInviteCode();
        expect(code, hasLength(kInviteCodeLength));
        for (final char in code.split('')) {
          expect(
            kInviteCodeAlphabet.contains(char),
            isTrue,
            reason: 'Onverwacht teken "$char". Het alfabet mist bewust 0/O en '
                '1/I/L omdat een code ook wordt voorgelezen en overgetypt.',
          );
        }
      }
    });

    test(
      'bevat geen dubbelzinnige tekens -- dit is de eigenlijke eis, het '
      'alfabet is er slechts de uitvoering van',
      () {
        for (final char in '01OILUV'.split('')) {
          expect(
            kInviteCodeAlphabet.contains(char),
            isFalse,
            reason: '"$char" is niet te onderscheiden van een ander teken als '
                'iemand de code voorleest of overtypt.',
          );
        }
      },
    );

    test('is met een vaste seed reproduceerbaar -- de injectie werkt', () {
      final a = generateInviteCode(random: Random(42));
      final b = generateInviteCode(random: Random(42));
      expect(a, b);
    });

    test('produceert praktisch geen botsingen over 5000 codes', () {
      final seen = <String>{};
      for (var i = 0; i < 5000; i++) {
        seen.add(generateInviteCode());
      }
      expect(
        seen,
        hasLength(5000),
        reason: 'De code is de enige beveiliging op een uitnodiging. Botst hij '
            'binnen vijfduizend trekkingen, dan is de sleutelruimte te klein.',
      );
    });
  });

  group('normalizeInviteCode', () {
    test('accepteert wat mensen werkelijk plakken en typen', () {
      const expected = 'ABCD2345';
      for (final input in <String>[
        'ABCD2345',
        '  abcd2345  ',
        'ABCD-2345',
        'abcd 2345',
        'https://my-project-joost.web.app/invite/ABCD2345',
        'https://example.test/join?code=abcd2345',
      ]) {
        expect(
          normalizeInviteCode(input),
          expected,
          reason: 'Een geplakte link of een streepje is geen gebruikersfout '
              'maar een veldfout -- "$input" hoort gewoon te werken.',
        );
      }
    });

    test('laat onzin onzin -- er wordt niets bijverzonnen', () {
      expect(normalizeInviteCode(''), '');
      expect(normalizeInviteCode('!!!'), '');
    });
  });
}
