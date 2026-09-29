// test/features/peloton_unseen_friends_test.dart
//
// Een nieuw maatje telt in het rode bolletje tot je de tab Peloton echt ziet.
// "Echt" is het subtiele deel: StatefulShellRoute houdt de tak Ritten in een
// IndexedStack, dus de tab kan gebouwd zijn terwijl je op Home staat. Dan
// staat TickerMode uit, en mag het bolletje niet stil verdwijnen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/seen_friends_store.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/features/peloton/buddies_tab.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required bool visible,
}) async {
  SharedPreferences.setMockInitialValues({
    SeenFriendsStore.keyFor(_me): <String>[],
  });
  final container = ProviderContainer(
    retry: (_, __) => null,
    overrides: [
      pelotonGatewayProvider.overrideWithValue(
        FakeGroupGateway(
          me: _me,
          friends: const [Friend(userId: 'uid-a', displayName: 'Anna')],
        ),
      ),
      currentUserIdProvider.overrideWithValue(_me),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        home: Scaffold(
          body: TickerMode(enabled: visible, child: const BuddiesTab()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('zichtbaar: het nieuwe maatje is daarna gezien', (tester) async {
    final c = await _pump(tester, visible: true);
    expect(find.text('Anna'), findsOneWidget);
    expect(c.read(unseenFriendsProvider).value, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(SeenFriendsStore(prefs).seenFor(_me), {'uid-a'});
    // Het bolletje is weg, maar je ziet nog wie erbij kwam.
    expect(find.text('Nieuw maatje'), findsOneWidget);
  });

  testWidgets('gebouwd maar niet zichtbaar: het bolletje blijft',
      (tester) async {
    final c = await _pump(tester, visible: false);
    expect(c.read(unseenFriendsProvider).value, {'uid-a'});
    expect(find.text('Nieuw maatje'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(SeenFriendsStore(prefs).seenFor(_me), isEmpty);
  });
}
