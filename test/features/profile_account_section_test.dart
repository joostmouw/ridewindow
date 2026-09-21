/// Widget-tests voor AccountSection (Plan 19-03) in de uitgelogde en
/// ingelogde toestand, gepumpt via ProfileScreen zodat Task 2's inbedding
/// ook wordt bewezen.
///
/// Zelfde Fake*Notifier + ProviderScope-overridepatroon als
/// profile_screen_calendar_test.dart. `authStateProvider` is een gewone
/// `@Riverpod`-functieprovider (`Stream&lt;User?&gt;`), geen class-based
/// Notifier -- daarom gebruikt de override hier
/// `.overrideWith((ref) =&gt; stream)` in plaats van de
/// `Fake*Notifier.overrideWith(() =&gt; Fake...())`-vorm die de andere
/// providers in dit bestand gebruiken.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/services/account_sync_service.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers (zelfde patroon als profile_screen_calendar_test.dart)
// ---------------------------------------------------------------------------

class FakeProfileNotifier extends ProfileNotifier {
  final UserProfile fakeProfile;
  FakeProfileNotifier(this.fakeProfile);

  @override
  Future<UserProfile> build() async => fakeProfile;
}

class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  final LocationPermission fakePermission;
  FakeGpsPermissionNotifier(this.fakePermission);

  @override
  Future<LocationPermission> build() async => fakePermission;
}

class FakeLocationNotifier extends LocationNotifier {
  final LocationData fakeLocation;
  FakeLocationNotifier(this.fakeLocation);

  @override
  Future<LocationData> build() async => fakeLocation;
}

class FakeWeatherNotifier extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

/// Fake seam for `accountSyncServiceProvider` (plan 21-07's testability
/// hook, see `cloud_sync_reconciler_provider.dart`'s doc comment on that
/// provider) -- overrides `onSignIn`/`resolvePrompt`/`markSynced` directly
/// so widget tests never touch a live `SupabaseClient`. The repo/closure
/// constructor arguments are never exercised by the overridden methods, so
/// plain real repositories (backed by the test's own SharedPreferences) are
/// enough -- no separate mock needed.
class FakeAccountSyncService extends AccountSyncService {
  FakeAccountSyncService(
    this.promptsToReturn, {
    required SharedPreferences prefs,
  }) : super(
          profileRepo: ProfileRepository(prefs),
          availabilityRepo: AvailabilityRepository(prefs),
          plannedRidesRepo: PlannedRidesRepository(prefs),
          readCloudProfile: (_) async => null,
          readCloudAvailability: (_) async => null,
          migrateFn: (_) async {},
          writeLastSyncedUid: (_) async {},
        );

  final List<PendingSyncPrompt> promptsToReturn;
  final List<SyncDomain> resolvedDomains = [];

  @override
  Future<List<PendingSyncPrompt>> onSignIn(
    String userId, {
    required String? lastSyncedUid,
  }) async =>
      promptsToReturn;

  @override
  Future<void> resolvePrompt(
    PendingSyncPrompt prompt,
    String userId, {
    required bool keepLocal,
  }) async {
    resolvedDomains.add(prompt.domain);
  }

  @override
  Future<void> markSynced(String userId) async {}
}

UserProfile _baseProfile() => const UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: 12.0,
        tempMaxIdealC: 26.0,
        windMaxIdealKmh: 15.0,
        rainMaxIdealMm: 0.5,
      ),
      allowedDurations: [2, 3, 5],
      theme: 'system',
      locationOverride: null,
      notifEveningBefore: false,
      notifMorningOf: false,
      notifWeeklyDigest: false,
    );

const _defaultLocation =
    LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam', source: LocationSource.override);

final _fakeUser = User(
  id: 'test-uid-123',
  appMetadata: const {},
  userMetadata: const {'full_name': 'Rider Test'},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
  email: 'rider@example.com',
);

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required Stream<User?> authStream,
  AccountSyncService? fakeSyncService,
  Stream<int>? outboxPendingCountStream,
}) async {
  // Vergroot het test-viewport zodat de nieuwe Account-sectie (bovenaan) en
  // de bestaande secties allemaal binnen de sliver-viewport vallen en dus
  // gemount worden.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // De accountwissel-"start fresh"-tak (Plan 19-04) leest plannedRidesProvider,
  // dat op zijn beurt sharedPrefsProvider vereist -- zonder deze override
  // gooit PlannedRidesNotifier.build() een UnimplementedError zodra die tak
  // wordt geraakt.
  final prefs = await SharedPreferences.getInstance();

  // Plan 21-07: elke ingelogde flow raakt nu _runAccountSync() aan het einde
  // van _checkAccountSwitch(), wat accountSyncServiceProvider (dat anders een
  // live Supabase-client zou aanroepen) nodig heeft -- krijgt hier altijd een
  // testbare fake, tenzij een test zelf iets anders opgeeft.
  final syncService = fakeSyncService ?? FakeAccountSyncService(const [], prefs: prefs);

  // outboxPendingCountProvider default: overschreven met een direct-emitting
  // Stream in plaats van de echte appDatabaseProvider/Drift-keten -- een
  // live `.watchSingle()`-stream schedulet bij widget-teardown een
  // zero-duration Timer die flutter_test's eind-van-test invariant-check
  // ("A Timer is still pending...") laat falen, en geen van de bestaande
  // tests in dit bestand heeft de echte database nodig.
  final overrides = <Override>[
    profileProvider.overrideWith(() => FakeProfileNotifier(_baseProfile())),
    gpsPermissionProvider.overrideWith(
      () => FakeGpsPermissionNotifier(LocationPermission.whileInUse),
    ),
    locationProvider.overrideWith(
      () => FakeLocationNotifier(_defaultLocation),
    ),
    weatherProvider.overrideWith(() => FakeWeatherNotifier()),
    authStateProvider.overrideWith((ref) => authStream),
    sharedPrefsProvider.overrideWithValue(prefs),
    accountSyncServiceProvider.overrideWith((ref) async => syncService),
    outboxPendingCountProvider.overrideWith(
      (ref) => outboxPendingCountStream ?? Stream<int>.value(0),
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        locale: Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ProfileScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Test 1 — uitgelogd toont Inloggen met Google + belofteregel, geen Uitloggen',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.signInWithGoogle, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSyncPromise, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSignOut, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 2 — ingelogd toont naam + e-mail + Uitloggen, geen Inloggen met Google',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text('Rider Test', skipOffstage: false), findsOneWidget);
    expect(find.text('rider@example.com', skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSignOut, skipOffstage: false), findsOneWidget);
    expect(find.text(s.signInWithGoogle, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 3 — tik op Uitloggen opent bevestigingsdialoog (D-12)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    // Geen pumpAndSettle: ProfileScreen's animated rain/wind widgets gebruiken
    // AnimationController.repeat(), wat pumpAndSettle laat timeouten (zelfde
    // patroon als home_screen_test.dart, zie STATE.md 04-05).
    await tester.tap(find.text(s.accountSignOut, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountSignOutConfirmTitle), findsOneWidget);
    expect(find.text(s.accountSignOutConfirmBody), findsOneWidget);
  });

  testWidgets(
      'Test 4 — andere Google-account dan voorheen toont de accountwissel-dialoog (AUTH-08)',
      (tester) async {
    // Overschrijft de lege setUp-default: dit toestel heeft eerder al
    // gesynchroniseerd met een ander account dan de nieuw ingelogde
    // gebruiker hieronder.
    SharedPreferences.setMockInitialValues({
      'account.lastSyncedUid': 'previous-uid',
    });

    final newAccountUser = User(
      id: 'new-uid',
      appMetadata: const {},
      userMetadata: const {'full_name': 'New Rider'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: 'new-rider@example.com',
    );

    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(newAccountUser),
    );
    // De ref.listen-callback in AccountSection.build() vuurt asynchroon
    // (na de authStateProvider state-transitie) -- extra pumps geven de
    // SharedPreferences-lezing en de showDialog-aanroep tijd om te lopen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.accountSwitchDialogTitle), findsOneWidget);
    expect(find.text(s.accountSwitchDialogBody), findsOneWidget);
  });

  testWidgets(
      'Test 5 — tik op "Opnieuw beginnen" sluit de accountwissel-dialoog',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'account.lastSyncedUid': 'previous-uid',
    });

    final newAccountUser = User(
      id: 'new-uid',
      appMetadata: const {},
      userMetadata: const {'full_name': 'New Rider'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: 'new-rider@example.com',
    );

    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(newAccountUser),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.accountSwitchDialogTitle), findsOneWidget);

    await tester.tap(find.text(s.accountSwitchRestartAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountSwitchDialogTitle), findsNothing);
  });

  testWidgets(
      'Test 6 — divergente profile + availability toont twee sequentiële '
      'conflictdialogen, profiel eerst, nooit tegelijk (D-04/D-05)',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final fakeService = FakeAccountSyncService(
      const [
        PendingSyncPrompt(SyncDomain.profile),
        PendingSyncPrompt(SyncDomain.availability),
      ],
      prefs: prefs,
    );

    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
      fakeSyncService: fakeService,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    // Alleen de profiel-dialoog is zichtbaar -- de beschikbaarheid-dialoog
    // verschijnt pas nadat deze is afgehandeld, nooit tegelijk.
    expect(find.text(s.accountConflictProfileTitle), findsOneWidget);
    expect(find.text(s.accountConflictAvailabilityTitle), findsNothing);

    await tester.tap(find.text(s.accountConflictKeepLocalAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountConflictProfileTitle), findsNothing);
    expect(find.text(s.accountConflictAvailabilityTitle), findsOneWidget);

    await tester.tap(find.text(s.accountConflictKeepLocalAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountConflictAvailabilityTitle), findsNothing);
    expect(fakeService.resolvedDomains, [SyncDomain.profile, SyncDomain.availability]);
  });

  testWidgets(
      'Test 7 — 0 openstaande outbox-rijen toont "Gesynchroniseerd", niet '
      '"Wordt gesynchroniseerd..." (D-06/D-07)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
      outboxPendingCountStream: Stream<int>.value(0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.accountSyncStatusSynced, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSyncStatusPending, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 8 — 3 openstaande outbox-rijen toont "Wordt gesynchroniseerd...", '
      'niet "Gesynchroniseerd" (D-06/D-07)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
      outboxPendingCountStream: Stream<int>.value(3),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.accountSyncStatusPending, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSyncStatusSynced, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 9 — uitgelogde rij toont nooit een sync-statustekst (D-06/D-07 '
      'gelden alleen voor de ingelogde staat)',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.accountSyncStatusSynced, skipOffstage: false), findsNothing);
    expect(find.text(s.accountSyncStatusPending, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 10 — tik op "Account verwijderen" opent bevestigingsdialoog met '
      'expliciete onomkeerbaarheids-waarschuwing (AUTH-09, D-01)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.accountDeleteAction, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountDeleteConfirmTitle), findsOneWidget);
    // Letterlijk vindbaar, niet alleen "een dialoog is open" -- de tekst
    // moet de onomkeerbaarheid expliciet noemen (plan's <behavior>-eis).
    expect(find.text(s.accountDeleteConfirmBody), findsOneWidget);
  });

  testWidgets(
      'Test 11 — tik op Annuleren sluit de verwijder-dialoog zonder RPC-'
      'aanroep of afmelding -- de ingelogde rij blijft ongewijzigd zichtbaar '
      '(AUTH-09, D-03)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.accountDeleteAction, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountDeleteConfirmTitle), findsOneWidget);

    await tester.tap(find.text(s.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountDeleteConfirmTitle), findsNothing);
    // De ingelogde rij is nog steeds intact -- geen afmelding is gebeurd.
    expect(find.text('Rider Test', skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSignOut, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 12 — tik op "Verwijderen" zonder geinitialiseerde Supabase-client '
      'toont de foutmelding-snackbar, nooit de succes-snackbar (compenserende '
      'dekking voor de RPC->signOut-volgorde: een gooiende RPC-aanroep mag '
      'signOut() nooit bereiken -- zie SUMMARY voor waarom het succespad zelf '
      'niet los te faken is zonder zware SupabaseClient-mocking)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.accountDeleteAction, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(s.accountDeleteConfirmAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountDeleteError, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountDeletedSnackbar, skipOffstage: false), findsNothing);
    // signOut() is nooit bereikt: de ingelogde rij toont nog steeds de
    // gebruiker (een echte signOut zou -- als de call uberhaupt zou slagen op
    // een ongeinitialiseerde client, wat hij niet doet -- de auth-stream niet
    // veranderen in deze test-harness, dus dit is een zwakke maar nuttige
    // extra check dat de widget-boom niet is gecrasht).
    expect(find.text('Rider Test', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 13 — een mislukte afmelding zegt het nu, in plaats van stil niets '
      'te doen (sweep "stille takken", 2026-09-21)',
      (tester) async {
    // Zelfde truc als Test 12: Supabase is niet geïnitialiseerd, dus
    // `auth.signOut()` gooit. Vóór de sweep gebeurde daar zichtbaar niets
    // mee; nu hoort er een snackbar te komen.
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.accountSignOut, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(s.accountSignOutConfirmTitle), findsOneWidget);

    // "Uitloggen" staat op twee plekken zolang de dialoog open is: de rij in
    // Profiel en de bevestigingsknop. De knop is de TextButton achteraan.
    await tester.tap(find.widgetWithText(TextButton, s.accountSignOut).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountSignOutFailed, skipOffstage: false),
        findsOneWidget);
    // De gebruiker is niet uitgelogd -- dat is de waarheid die de snackbar
    // vertelt, anders dan een stille mislukking.
    expect(find.text('Rider Test', skipOffstage: false), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // E-mail + wachtwoord login (OPEN.md punt 11, 2026-09-21)
  // ---------------------------------------------------------------------------

  testWidgets(
      'Test 14 — uitgelogd toont Inloggen met e-mail naast Inloggen met '
      'Google (OPEN.md punt 11)',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.signInWithGoogle, skipOffstage: false), findsOneWidget);
    expect(find.text(s.signInWithEmail, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 15 — tik op Inloggen met e-mail opent de dialoog met beide velden '
      'en de inlogknop',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.signInWithEmail, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "Inloggen met e-mail" staat op de rij én als dialoogtitel, dus de
    // titel-assertie wordt gescoped op de dialoog zelf.
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text(s.emailSignInTitle)),
      findsOneWidget,
    );
    expect(find.text(s.emailFieldLabel), findsOneWidget);
    expect(find.text(s.passwordFieldLabel), findsOneWidget);
    expect(find.text(s.emailSignInAction), findsOneWidget);
  });

  testWidgets(
      'Test 16 — ongeldige invoer toont een validatiefout in de dialoog, '
      'vóór elke netwerk-aanroep (geen crash op een ongeïnitialiseerde '
      'client; de fout is dus geen netwerkfout)',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.signInWithEmail, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Geen '@': de e-mail-validatie moet vangen, niet de netwerklaag.
    await tester.enterText(find.byType(TextField).at(0), 'geen@adres');
    await tester.enterText(find.byType(TextField).at(1), 'geheim123');
    await tester.tap(find.text(s.emailSignInAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.emailInvalidError), findsOneWidget);

    // Geldig adres, te kort wachtwoord: de wachtwoord-validatie vangt.
    await tester.enterText(
      find.byType(TextField).at(0),
      'fietser@example.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'kort');
    await tester.tap(find.text(s.emailSignInAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.passwordTooShortError), findsOneWidget);
  });

  testWidgets(
      'Test 17 — geldige invoer op een ongeïnitialiseerde Supabase-client '
      'toont de foutmelding in de dialoog en blijft open (zelfde truc als '
      'Test 12/13; het succespad is niet los te faken zonder zware '
      'SupabaseClient-mocking — zie Test 12)',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.signInWithEmail, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byType(TextField).at(0),
      'fietser@example.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'geheim123');
    await tester.tap(find.text(s.emailSignInAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountEmailSignInFailed), findsOneWidget);
    // De dialoog blijft open — geen crash, geen zogenaamd geslaagde login.
    // De titel-assertie is gescoped op de dialoog (dezelfde tekst staat op
    // de rij erachter zodra de dialoog open is).
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(s.emailSignInTitle),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Test 18 — wisselen naar Account aanmaken wisselt titel en knoptekst; '
      'een mislukte aanmelding toont de aanmaakfout, niet de inlogfout',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    await tester.tap(find.text(s.signInWithEmail, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text(s.emailSignInTitle)),
      findsOneWidget,
    );

    await tester.tap(find.text(s.emailSwitchToCreate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.descendant(of: dialog, matching: find.text(s.emailCreateTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text(s.emailCreateAction)),
      findsOneWidget,
    );

    // Success-informatie "controleer je e-mail" kan zonder netwerk getest
    // worden? Nee: signUp vereist Supabase. Het foutpad volstaat — zorg dat
    // de fout de aanmaak-variant is, niet de inlog-variant.
    await tester.enterText(
      find.byType(TextField).at(0),
      'nieuw@example.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'geheim123');
    await tester.tap(find.text(s.emailCreateAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountEmailCreateFailed), findsOneWidget);
    expect(find.text(s.accountEmailSignInFailed), findsNothing);
  });
}
