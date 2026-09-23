// test/features/group_error_text_test.dart
//
// Elke databasefoutsleutel uit 0012 en 0013 wordt een gewone zin in NL en EN,
// met wat de gebruiker kan doen, en nooit een foutcode (CLUB-18).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

void main() {
  late S nl;
  late S en;

  setUpAll(() async {
    nl = await S.delegate.load(const Locale('nl'));
    en = await S.delegate.load(const Locale('en'));
  });

  test('elke fout geeft in beide talen een zin zonder sleutel', () {
    for (final s in [nl, en]) {
      for (final error in GroupError.values) {
        final text = groupErrorText(s, error);
        expect(text.trim(), isNotEmpty, reason: error.name);
        expect(text, isNot(contains('_')), reason: error.name);
        expect(text, isNot(contains(error.name)), reason: error.name);
        expect(text, isNot(contains('P0001')), reason: error.name);
      }
    }
  });

  test('groupFull noemt de groep en 30', () {
    for (final s in [nl, en]) {
      final named = groupErrorText(
        s,
        GroupError.groupFull,
        groupName: 'Dinsdagclub',
      );
      expect(named, contains('Dinsdagclub'));
      expect(named, contains('30'));
      expect(groupErrorText(s, GroupError.groupFull), contains('30'));
    }
  });

  test('tooManyGroups noemt de persoon en 10, of spreekt jou aan', () {
    expect(
      groupErrorText(nl, GroupError.tooManyGroups, personName: 'Jacco'),
      allOf(contains('Jacco'), contains('10')),
    );
    expect(
      groupErrorText(en, GroupError.tooManyGroups, personName: 'Jacco'),
      allOf(contains('Jacco'), contains('10')),
    );
    expect(
      groupErrorText(nl, GroupError.tooManyGroups),
      allOf(startsWith('Je '), contains('10')),
    );
    expect(
      groupErrorText(en, GroupError.tooManyGroups),
      allOf(startsWith("You're "), contains('10')),
    );
  });

  test('lastAdmin in het Nederlands', () {
    expect(
      groupErrorText(nl, GroupError.lastAdmin),
      'Je bent de enige beheerder. Maak eerst iemand anders beheerder, '
      'dan kun je dit afgeven.',
    );
  });

  test('groupErrorTextOf: GroupException wordt de eigen zin, de rest generiek',
      () {
    expect(
      groupErrorTextOf(nl, const GroupException(GroupError.inviteInvalid)),
      nl.groupErrorInviteInvalid,
    );
    expect(groupErrorTextOf(nl, Exception('x')), nl.groupErrorGeneric);
    expect(groupErrorTextOf(en, StateError('boom')), en.groupErrorGeneric);
    expect(
      groupErrorTextOf(
        en,
        const GroupException(GroupError.groupFull),
        groupName: 'Buren',
      ),
      contains('Buren'),
    );
  });
}
