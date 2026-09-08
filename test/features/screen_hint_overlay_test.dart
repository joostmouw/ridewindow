// test/features/screen_hint_overlay_test.dart
//
// De uitleg-overlays zijn op 2026-09-08 omgebouwd naar een Material 3 rich
// tooltip met stapbesturing (Joost's keuze uit schets 007). Ze hadden tot dat
// moment geen enkele test.
//
// Twee dingen zijn hier het bewaken waard, want ze zijn aan een screenshot
// niet te zien:
//
// 1. Een tik op het scherm springt níét meer vooruit. Dat gedrag was de
//    aanleiding voor de hele wijziging -- je wilde lezen en de app ging
//    verder -- en het is één weggelaten `onTap` van terugkomen.
// 2. De knoppen zijn vertaald. De rondleiding toonde Nederlands in de Engelse
//    app; als de ARB-sleutels wegvallen valt dat pas op in de winkel.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';

final _targetA = GlobalKey();
final _targetB = GlobalKey();

int _dismissed = 0;

Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('nl')}) async {
  _dismissed = 0;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 80),
                Container(key: _targetA, height: 60, color: Colors.grey),
                const SizedBox(height: 200),
                Container(key: _targetB, height: 60, color: Colors.grey),
              ],
            ),
            ScreenHintOverlay(
              onDismiss: () => _dismissed++,
              hints: [
                HintItem(
                  targetKey: _targetA,
                  gestureIcon: AppIcons.handPointing,
                  title: 'Eerste stap',
                  description: 'Uitleg bij de eerste stap.',
                ),
                HintItem(
                  targetKey: _targetB,
                  gestureIcon: AppIcons.handPointing,
                  title: 'Tweede stap',
                  description: 'Uitleg bij de tweede stap.',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('een tik naast de knoppen brengt je niet naar de volgende stap',
      (tester) async {
    await _pump(tester);
    expect(find.text('Eerste stap'), findsOneWidget);

    // Midden onderin, ver van elke knop: precies waar iemand tikt die alleen
    // het scherm aanraakt.
    await tester.tapAt(const Offset(200, 740));
    await tester.pumpAndSettle();

    expect(find.text('Eerste stap'), findsOneWidget);
    expect(find.text('Tweede stap'), findsNothing);
    expect(_dismissed, 0);
  });

  testWidgets('Volgende en Vorige lopen heen en weer', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Tweede stap'), findsOneWidget);

    await tester.tap(find.text('Vorige'));
    await tester.pumpAndSettle();
    expect(find.text('Eerste stap'), findsOneWidget);
  });

  testWidgets('Vorige staat uit op de eerste stap', (tester) async {
    await _pump(tester);
    final back = tester.widget<TextButton>(
      find.ancestor(of: find.text('Vorige'), matching: find.byType(TextButton)),
    );
    expect(back.onPressed, isNull);
  });

  testWidgets('de laatste stap sluit af met Klaar', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Volgende'), findsNothing);

    await tester.tap(find.text('Klaar'));
    await tester.pumpAndSettle();
    expect(_dismissed, 1);
  });

  testWidgets('Overslaan sluit meteen af, vanaf de eerste stap',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Overslaan'));
    await tester.pumpAndSettle();
    expect(_dismissed, 1);
  });

  testWidgets('de besturing is vertaald, niet hardgecodeerd Nederlands',
      (tester) async {
    await _pump(tester, locale: const Locale('en'));
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Volgende'), findsNothing);
  });

  testWidgets('de voortgangsbalk staat op nul bij de eerste stap en vol bij de laatste',
      (tester) async {
    await _pump(tester);
    LinearProgressIndicator bar() =>
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));

    expect(bar().value, 0);

    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(bar().value, 1);
  });

  testWidgets('een doel dat nergens hangt sluit je niet op', (tester) async {
    // De sleutel is aan geen enkele widget gekoppeld, dus er valt niets te
    // meten -- ooit de situatie waarin alleen de scrim verscheen. Zolang een
    // tik nog vooruit sprong was dat te overleven; sinds alleen de knoppen
    // iets doen zou het een donker scherm zonder uitweg zijn.
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: ScreenHintOverlay(
            onDismiss: () => dismissed++,
            hints: [
              HintItem(
                targetKey: GlobalKey(),
                gestureIcon: AppIcons.handPointing,
                title: 'Zwevende stap',
                description: 'Het doel bestaat niet.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zwevende stap'), findsOneWidget);
    await tester.tap(find.text('Overslaan'));
    await tester.pumpAndSettle();
    expect(dismissed, 1);
  });
}
