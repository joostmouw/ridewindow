// Tests for backlog #33 "Send feedback" dialog.
//
// Covers:
//   Test 1/2: buildFeedbackMailtoUri pure-function URI construction
//   Test 3: dialog shows title + 5 star IconButtons
//   Test 4: Send button disabled until a star is selected
//
// url_launcher is not mocked in this suite — Send is never tapped in these
// tests (would invoke the real platform channel and throw
// MissingPluginException).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/profile/feedback_dialog.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

Future<void> _pumpDialogTrigger(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      // RideWindowTheme extension required — the dialog's star row reads
      // context.rw.scorePerfect for the selected-star color.
      theme: ThemeData(extensions: const [RideWindowTheme.light]),
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showFeedbackDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('Test 1 — builds mailto URI with rating and comment', () {
    final uri = buildFeedbackMailtoUri(rating: 4, comment: 'Great app!');

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'joostmouw@gmail.com');
    expect(uri.queryParameters['subject'], 'RideWindow feedback');
    expect(uri.queryParameters['body'], contains('★★★★☆'));
    expect(uri.queryParameters['body'], contains('Great app!'));
  });

  test('Test 2 — whitespace-only comment becomes (none) after trimming', () {
    final uri = buildFeedbackMailtoUri(rating: 1, comment: '   ');

    expect(uri.queryParameters['body'], contains('(none)'));
  });

  testWidgets('Test 3 — dialog shows title and 5 star IconButtons',
      (tester) async {
    await _pumpDialogTrigger(tester);

    final context = tester.element(find.text('open'));
    final s = S.of(context);

    expect(find.text(s.sendFeedback), findsOneWidget);
    for (var n = 1; n <= 5; n++) {
      expect(find.byKey(ValueKey('feedback_star_$n')), findsOneWidget);
    }
  });

  testWidgets(
      'Test 4 — Send disabled until a star is selected, enabled after tap',
      (tester) async {
    await _pumpDialogTrigger(tester);

    final context = tester.element(find.text('open'));
    final s = S.of(context);

    TextButton sendButton() => tester.widget<TextButton>(
          find.widgetWithText(TextButton, s.feedbackSendButton),
        );

    expect(sendButton().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('feedback_star_3')));
    await tester.pump();

    expect(sendButton().onPressed, isNotNull);
  });
}
