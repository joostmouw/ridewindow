// test/features/welcome_dark_mode_test.dart
//
// De welkomtekst moet leesbaar zijn in *beide* helderheden (Joost, 2026-09-08,
// met een screenshot van bleke tekst -- de tweede keer).
//
// Waarom dit een eigen test verdient: het welkomscherm zet zijn achtergrond
// hard op `brandLight` maar haalde zijn tekstkleur uit het áctieve schema. In
// lichte modus klopt dat (9,63:1) en in donkere modus niet (1,21:1). Een test
// die alleen in lichte modus meet -- en dat deden ze alle drie -- ziet dat
// nooit. Dit meet de werkelijk gerenderde kleur tegen de werkelijke
// achtergrond, in allebei de standen.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/onboarding/onboarding_screen.dart';
import 'package:ridewindow/features/shared/brand_canvas.dart';
import 'package:ridewindow/features/welcome/welcome_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// WCAG relatieve luminantie.
double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  final hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

Widget _app({required Brightness brightness, required Widget screen}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => BrandCanvas(child: screen)),
      GoRoute(
        path: '/onboard',
        builder: (_, __) => const Scaffold(body: Text('Onboarding')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      // Het échte thema, niet een kaal `ThemeData` met alleen de extensie:
      // juist het samenspel tussen het geërfde schema en de vastgezette
      // achtergrond is wat hier misging.
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}

/// De kleur waarmee een `Text` daadwerkelijk gerenderd wordt, inclusief wat hij
/// van zijn `DefaultTextStyle` erft.
Color _renderedColor(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  final inherited = DefaultTextStyle.of(tester.element(finder)).style;
  return (text.style?.color) ??
      inherited.merge(text.style).color ??
      const Color(0xFF000000);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final brightness in Brightness.values) {
    testWidgets(
        'welkomtekst haalt AA op het groene vlak in ${brightness.name} modus',
        (tester) async {
      await tester.pumpWidget(
        _app(brightness: brightness, screen: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();

      final title = find.textContaining('perfecte fietsmoment');
      expect(title, findsOneWidget);

      final ratio = contrast(
        _renderedColor(tester, title),
        AppColors.brandLight,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'de titel staat op een hardgecodeerd $AppColors.brandLight-vlak; '
            'in donkere modus zonder BrandCanvas is dit 1,21:1',
      );
    });

    testWidgets(
        'de achtergrond blijft het merkgroen in ${brightness.name} modus',
        (tester) async {
      await tester.pumpWidget(
        _app(brightness: brightness, screen: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.brandLight,
          reason: 'het groene vlak is een merkmoment en hoort niet mee te '
              'schakelen met de helderheid');
    });

    testWidgets(
        'ook Onboarding staat op het lichte palet in ${brightness.name}',
        (tester) async {
      await tester.pumpWidget(
        _app(brightness: brightness, screen: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      // `BrandCanvas` levert één en hetzelfde thema, ongeacht de stand van de
      // app eromheen. Zonder wrapper zou dit het donkere schema zijn.
      final theme = Theme.of(tester.element(find.byType(OnboardingScreen)));
      expect(theme.brightness, Brightness.light);
    });
  }
}
