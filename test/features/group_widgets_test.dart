// test/features/group_widgets_test.dart
//
// De gedeelde bouwstenen van fase 34 (plan 04): de naamsheet voor maken en
// hernoemen, de sheet met de groepsregels (CLUB-28) en het kenteken.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/peloton/group_name_sheet.dart';
import 'package:ridewindow/features/peloton/group_rules_sheet.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_theme.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: buildAppTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    );

/// Een knop die de naamsheet opent en de uitkomst in [onResult] legt.
class _Opener extends StatelessWidget {
  const _Opener({required this.onResult, this.initialName});

  final void Function(String?) onResult;
  final String? initialName;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () async {
          final name = await showGroupNameSheet(
            context,
            initialName: initialName,
            title: 'Nieuwe groep',
            hint: 'Geef hem een naam',
            actionLabel: 'Groep maken',
          );
          onResult(name);
        },
        child: const Text('open'),
      );
}

Future<void> _open(WidgetTester tester, {String? initialName,
    required void Function(String?) onResult}) async {
  await tester.pumpWidget(
    _app(_Opener(onResult: onResult, initialName: initialName)),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

FilledButton _action(WidgetTester tester) => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Groep maken'),
    );

void main() {
  group('showGroupNameSheet', () {
    testWidgets('teller loopt mee en stopt bij 40', (tester) async {
      await _open(tester, onResult: (_) {});
      expect(find.text('0/40'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Dinsdagclub');
      await tester.pump();
      expect(find.text('11/40'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'x' * 50);
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, 40);
      expect(find.text('40/40'), findsOneWidget);
    });

    testWidgets('knop uit bij leeg of spaties, geeft getrimde naam terug',
        (tester) async {
      String? result = 'nog niets';
      await _open(tester, onResult: (v) => result = v);

      expect(_action(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(_action(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '  Dinsdagclub ');
      await tester.pump();
      expect(_action(tester).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Groep maken'));
      await tester.pumpAndSettle();

      expect(result, 'Dinsdagclub');
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('initialName staat al in het veld', (tester) async {
      await _open(tester, initialName: 'Buren', onResult: (_) {});
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Buren');
      expect(_action(tester).onPressed, isNotNull);
    });
  });

  group('groepsregels', () {
    testWidgets('GroupRulesButton opent de titel en zeven regels',
        (tester) async {
      await tester.pumpWidget(_app(const GroupRulesButton()));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Zo werken groepen'), findsOneWidget);
      expect(find.byKey(const ValueKey('group-rule')), findsNWidgets(7));
      final all = tester
          .widgetList<Text>(find.descendant(
            of: find.byKey(const ValueKey('group-rule')),
            matching: find.byType(Text),
          ))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(all, contains('30'));
      expect(all, contains('10'));
      expect(all, contains('beheerder'));
    });
  });

  group('GroupCrest', () {
    for (final (brightness, bg, fg) in [
      (Brightness.light, AppColors.brandLight, AppColors.brandDark),
      (Brightness.dark, AppColors.brandDark, AppColors.brandLight),
    ]) {
      testWidgets('vaste kleuren in ${brightness.name}', (tester) async {
        await tester.pumpWidget(
          _app(const GroupCrest(name: 'Dinsdag Club'), brightness: brightness),
        );
        expect(find.text('DC'), findsOneWidget);
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byType(GroupCrest),
            matching: find.byType(Container),
          ),
        );
        expect((box.decoration! as BoxDecoration).color, bg);
        expect(tester.widget<Text>(find.text('DC')).style!.color, fg);
      });
    }
  });
}
