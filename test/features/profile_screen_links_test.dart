// De twee externe links in Profiel: Privacy Policy en de weerbron.
//
// Waarom deze test bestaat
// ------------------------
// Tester Androidguju67 meldde op 1.0.35+46 dat "Privacy Policy" een pagina over
// een "free weather api" opende. Er was geen adres verwisseld. De privacy-rij
// stond achter `if (await canLaunchUrl(uri))` zonder `else`, en op Android 11+
// geeft `canLaunchUrl` false zolang het manifest geen `<queries>` voor
// `VIEW`/`https` declareert -- ook met Chrome op het toestel. De rij deed dus
// zichtbaar niets. De rij eronder is Open-Meteo, die had geen guard, opende
// wel, en heet op zijn homepage letterlijk "Free Weather API".
//
// Het manifest is aangevuld, maar dat is niet het hele verhaal: een link die
// stil niets doet is in elke situatie fout. Deze test bewaakt die tweede helft,
// want die is de enige van de twee die in Dart te bewijzen is.
//
// Wat de test doet
// ----------------
// Test 1 en 2: beide rijen openen hun eigen adres, extern, niet in een in-app
//              tab. Dat laatste is wat het verschil tussen de twee rijen was.
// Test 3:      lukt openen niet, dan zegt de app dat, met het adres te kopiëren
//              erbij. Deze faalt op de oude code, want daar gebeurde niets.
// Test 4:      gooit het platform, dan blijft het bij dezelfde melding en geen
//              uitzondering op het scherm.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

import 'profile_screen_test.dart'
    show FakeGpsPermissionNotifier, FakeProfileNotifier, testProfile;

const _kPrivacy = 'https://joostmouw.github.io/ridewindow/privacy-policy.html';
const _kOpenMeteo = 'https://open-meteo.com/';

/// Vangt op wat de app aan het platform vraagt, zonder een browser te openen.
class _NepLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  _NepLauncher({this.lukt = true, this.gooit = false});

  final bool lukt;
  final bool gooit;

  final aangeroepen = <String>[];
  LaunchOptions? laatsteOpties;

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) async => lukt;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    aangeroepen.add(url);
    laatsteOpties = options;
    if (gooit) throw PlatformException_('geen activiteit gevonden');
    return lukt;
  }
}

/// Eigen fout in plaats van `PlatformException`: de test hoeft alleen te weten
/// dát het platform stuk kan gaan, niet met welke klasse.
class PlatformException_ implements Exception {
  PlatformException_(this.message);
  final String message;
  @override
  String toString() => 'PlatformException_: $message';
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late UrlLauncherPlatform origineel;
  String? klembord;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    origineel = UrlLauncherPlatform.instance;
    klembord = null;
    // Zonder deze handler gooit `Clipboard.setData` een MissingPluginException
    // en komt de bevestiging er nooit.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          klembord = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
  });

  tearDown(() {
    UrlLauncherPlatform.instance = origineel;
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpProfiel(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(() => FakeProfileNotifier(testProfile)),
          gpsPermissionProvider.overrideWith(
            () => FakeGpsPermissionNotifier(LocationPermission.denied),
          ),
        ],
        child: MaterialApp(
          home: const ProfileScreen(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Bewust geen `pumpAndSettle`: zolang de Calendar-status nog onbekend is
  /// draait daar een `CircularProgressIndicator`, en die komt nooit tot stilte.
  /// Een vast aantal frames is hier genoeg om een SnackBar te laten verschijnen.
  Future<void> draaiFrames(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tikOp(WidgetTester tester, String label) async {
    final rij = find.text(label, skipOffstage: false);
    expect(rij, findsOneWidget, reason: 'rij "$label" hoort in Profiel te staan');
    await tester.ensureVisible(rij);
    await tester.pump();
    await tester.tap(rij);
    await draaiFrames(tester);
  }

  testWidgets('Test 1 - Privacy Policy opent het privacy-adres, extern',
      (tester) async {
    final launcher = _NepLauncher();
    UrlLauncherPlatform.instance = launcher;
    await pumpProfiel(tester);

    final s = S.of(tester.element(find.byType(ProfileScreen)));
    await tikOp(tester, s.privacyPolicy);

    expect(launcher.aangeroepen, [_kPrivacy]);
    expect(
      launcher.laatsteOpties?.mode,
      PreferredLaunchMode.externalApplication,
      reason: 'Een privacybeleid hoort in een echte browser, niet in een tab '
          'binnen de app die erover gaat.',
    );
  });

  testWidgets('Test 2 - de weerbron opent open-meteo, net zo extern',
      (tester) async {
    // Dit was het verschil dat de melding onleesbaar maakte: deze rij ging via
    // een kale `launchUrl` zonder mode en belandde dus in een in-app tab,
    // terwijl de rij erboven extern opende. Twee rijen met hetzelfde pijltje
    // horen zich hetzelfde te gedragen.
    final launcher = _NepLauncher();
    UrlLauncherPlatform.instance = launcher;
    await pumpProfiel(tester);

    final s = S.of(tester.element(find.byType(ProfileScreen)));
    await tikOp(tester, s.weatherDataAttribution);

    expect(launcher.aangeroepen, [_kOpenMeteo]);
    expect(
      launcher.laatsteOpties?.mode,
      PreferredLaunchMode.externalApplication,
    );
  });

  testWidgets('Test 3 - lukt openen niet, dan zegt de app dat',
      (tester) async {
    // De kern van de melding. Op de oude code gebeurde hier niets: geen
    // browser, geen melding, geen spoor. De gebruiker tikte door naar de rij
    // eronder en dacht dat díe pagina het antwoord was.
    final launcher = _NepLauncher(lukt: false);
    UrlLauncherPlatform.instance = launcher;
    await pumpProfiel(tester);

    final s = S.of(tester.element(find.byType(ProfileScreen)));
    await tikOp(tester, s.privacyPolicy);

    expect(find.text(s.linkOpenFailed), findsOneWidget);

    // En het adres moet mee te nemen zijn, anders staat de gebruiker nog steeds
    // met lege handen bij een document waar hij recht op heeft.
    expect(find.text(s.linkCopyAction), findsOneWidget);
    await tester.tap(find.text(s.linkCopyAction));
    await draaiFrames(tester);
    await draaiFrames(tester);
    expect(klembord, _kPrivacy);
    expect(find.text(s.linkCopied), findsOneWidget);
  });

  testWidgets('Test 4 - gooit het platform, dan nog steeds dezelfde melding',
      (tester) async {
    UrlLauncherPlatform.instance = _NepLauncher(gooit: true);
    await pumpProfiel(tester);

    final s = S.of(tester.element(find.byType(ProfileScreen)));
    await tikOp(tester, s.privacyPolicy);

    expect(tester.takeException(), isNull);
    expect(find.text(s.linkOpenFailed), findsOneWidget);
  });
}
