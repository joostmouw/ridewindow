// lib/features/profile/account_section.dart
// AccountSection: D-01 t/m D-07 -- de account-sectie bovenaan Profiel.
// Signed-out: platformafhankelijke inlogknop (Android ListTile of web
// renderButton, D-05/D-06). Signed-in: avatar + naam + e-mail + Uitloggen
// (D-02). Uitloggen beeindigt alleen de Supabase-sessie (D-12).
//
// AUTH-05: initialisatie loopt via CalendarService.ensureGoogleSignInReady(),
// hetzelfde gememoizede hek als het bestaande Calendar-pad -- er mag maar op
// een plek in de codebase GoogleSignIn.instance.initialize() worden
// aangeroepen (zie calendar_service.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/remote/supabase_tables.dart';
import 'package:ridewindow/domain/services/account_switch_resolver.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/services/account_sync_service.dart';
import 'package:ridewindow/services/calendar_service.dart';

// package:google_sign_in/web_only.dart does not exist in google_sign_in
// 7.2.0 -- renderButton() lives in the federated google_sign_in_web package,
// which pulls in dart:js_interop-based code that fails to compile for the
// Dart VM (`flutter test`'s target). Routed through the conditional-import
// seam below instead of importing google_sign_in_web directly (Rule 1 fix,
// see google_signin_button.dart's header comment).
import 'google_signin_button.dart';

/// SharedPreferences-sleutel voor de laatst gesynchroniseerde Supabase-uid op
/// dit toestel (AUTH-08, ARCHITECTURE.md §5). Bewust *niet* toegevoegd aan
/// ProfileRepository of een gedeeld sleutel-bestand -- die extractie is
/// Fase 20's werk, niet dit plan's.
const _kLastSyncedUidKey = 'account.lastSyncedUid';

class AccountSection extends ConsumerStatefulWidget {
  const AccountSection({super.key});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  // Vastgesteld eenmalig in initState (zie <interfaces> in het plan): een
  // gooiende supportsAuthenticate()-aanroep (geen platform-channel in tests)
  // degradeert naar `true` (Android/native-tak) zodat widget-tests veilig
  // blijven zonder de SDK te mocken.
  bool _supportsNativeAuthenticate = true;

  // Dubbeltik-guard voor de Android-inlogknop.
  bool _busy = false;

  // AUTH-08: welke uid al gecontroleerd is op een accountwissel, zodat de
  // check niet dubbel draait wanneer zowel de interactieve inlogflow
  // (_handleSignInSuccess) als de reactieve authStateProvider-listener
  // (build(), voor een herstelde sessie bij koude start) voor dezelfde
  // sign-in vuren -- "dezelfde code-pad" die het plan bedoelt.
  String? _lastCheckedUid;

  @override
  void initState() {
    super.initState();
    _detectPlatformBranch();
  }

  Future<void> _detectPlatformBranch() async {
    bool supports = true;
    try {
      supports = GoogleSignIn.instance.supportsAuthenticate();
    } catch (_) {
      supports = true;
    }
    if (mounted) setState(() => _supportsNativeAuthenticate = supports);

    if (!supports) {
      // Web-tak: luister naar authenticationEvents voor de door Google
      // gerenderde knop (D-05/D-06, PITFALLS.md #2).
      try {
        GoogleSignIn.instance.authenticationEvents.listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _handleSignInSuccess(event.user);
          }
        });
      } catch (_) {
        // Geen platform-channel in tests -- geen abonnement, geen crash.
      }
    }
  }

  /// Gedeelde afrondingsstap na een succesvolle GoogleSignInAccount, gebruikt
  /// door zowel de Android-handler als de web authenticationEvents-listener.
  Future<void> _handleSignInSuccess(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      _showSignInError();
      return;
    }

    // O3M-02 (Bug 2): authorizationForScopes is niet-promptend en veilig op
    // beide platforms. De promptende authorizeScopes()-fallback mag alleen
    // op de native/Android-tak draaien (_supportsNativeAuthenticate == true,
    // D-06's signaal) -- op web wordt deze aanroep gedaan vanuit de
    // authenticationEvents-listener, buiten elke user-gesture call-stack, dus
    // de browser blokkeert het popup-venster altijd ("Failed to open popup
    // window"). Android's exacte twee-staps-volgorde blijft ongewijzigd.
    String? accessToken;
    try {
      var authorization = await account.authorizationClient
          .authorizationForScopes(['email']);
      if (authorization == null && _supportsNativeAuthenticate) {
        authorization =
            await account.authorizationClient.authorizeScopes(['email']);
      }
      accessToken = authorization?.accessToken;
    } catch (e) {
      debugPrint('AccountSection: kon geen access token krijgen: $e');
    }

    User? signedInUser;
    try {
      // O3M-01 (Bug 1): nonce: CalendarService.authNonce -- de RUWE nonce die
      // hoort bij de SHA-256-hash die CalendarService al naar Google's
      // initialize(nonce:) heeft gestuurd. Zonder deze regel weigert Supabase
      // met een 400 "Passed nonce and nonce in id_token should either both
      // exist or not", omdat het Google ID-token wel een nonce-claim draagt
      // maar hier voorheen niets werd meegestuurd.
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        nonce: CalendarService.authNonce,
      );
      signedInUser = response.user;
    } catch (e) {
      debugPrint('AccountSection: signInWithIdToken mislukt: $e');
      _showSignInError();
      return;
    }

    // AUTH-08: vergelijk de nieuw ingelogde uid met de laatst gesynchroniseerde
    // uid op dit toestel, voor de bestaande naam-invulstap -- nooit gissen bij
    // een accountwissel (D-08/D-09).
    if (signedInUser != null) {
      await _checkAccountSwitch(signedInUser.id);
    }

    // D-04: vul profile.userName alleen in als het nog leeg is, nooit
    // overschrijven.
    // D-07 (fase 20): deze invulling gaat via het niet-stempelende
    // schrijfpad hieronder -- de autofill komt van de app, niet van de
    // gebruiker, en mag profile.updatedAt dus niet bewegen. Zou hij wel
    // stempelen, dan leest fase 21 elk eerste inloggen op een nieuw toestel
    // als een echte wijziging en toont hij een conflictdialoog terwijl er
    // niets aan de hand is.
    if (!mounted) return;
    if (ref.read(profileProvider).value?.userName == null) {
      await ref
          .read(profileProvider.notifier)
          .setUserNameFromSignIn(account.displayName);
    }
    // D-07: geen succesbevestiging -- de sectie verandert zichtbaar, dat is
    // het bewijs.
  }

  /// AUTH-08: vergelijkt [signedInUid] met de lokaal opgeslagen
  /// `account.lastSyncedUid` via de pure [resolveAccountSwitch]. Dit is het
  /// gedeelde code-pad dat zowel de interactieve inlogflow
  /// (_handleSignInSuccess) als een herstelde sessie bij koude start
  /// (via de authStateProvider-listener in [build]) raakt -- geen van beide
  /// mag de gebruiker ooit gissen bij een accountwissel.
  Future<void> _checkAccountSwitch(String signedInUid) async {
    if (_lastCheckedUid == signedInUid) return;
    _lastCheckedUid = signedInUid;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncedUid = prefs.getString(_kLastSyncedUidKey);
    final decision = resolveAccountSwitch(
      signedInUid: signedInUid,
      lastSyncedUid: lastSyncedUid,
    );

    switch (decision) {
      case AccountSwitchDecision.firstSignIn:
      case AccountSwitchDecision.sameAccount:
        await prefs.setString(_kLastSyncedUidKey, signedInUid);
        break;
      case AccountSwitchDecision.differentAccount:
        if (!mounted) return;
        final s = S.of(context);
        final keepData = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(s.accountSwitchDialogTitle),
            content: Text(s.accountSwitchDialogBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(s.accountSwitchKeepAction),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(s.accountSwitchRestartAction),
              ),
            ],
          ),
        );

        if (keepData == false) {
          // D-09: wist uitsluitend profielinstellingen, beschikbaarheid en
          // geplande ritten -- de Drift forecast-cache is afgeleide data en
          // wordt hier nooit aangeraakt (zelfde redenering als SYNC-09).
          // Profiel eerst, want latere lezingen kunnen naar tolerances
          // verwijzen.
          //
          // availabilityProvider is niet keepAlive en wordt door deze sectie
          // niet gewatcht (in tegenstelling tot profileProvider, dat
          // ProfileScreen elders al watcht) -- zonder een tijdelijk manuele
          // listener kan de provider zichzelf tussen de awaits in disposen,
          // waarna clearAll()'s state-schrijving een UnmountedRefException
          // gooit.
          final availabilitySub = ref.listenManual(
            availabilityProvider,
            (_, __) {},
          );
          try {
            await ref.read(profileProvider.notifier).resetToDefaults();
            await ref.read(availabilityProvider.notifier).clearAll();
            await ref.read(plannedRidesProvider.notifier).clearAll();
          } finally {
            availabilitySub.close();
          }
        }
        await prefs.setString(_kLastSyncedUidKey, signedInUid);
        break;
    }

    // Plan 21-07: MIG-01/02/03 + D-04/D-05/D-06/D-07 -- appended as the
    // final step, after both switch-decision branches above have fully
    // settled local storage (see this method's own `lastSyncedUid` local,
    // captured BEFORE either `prefs.setString` call above -- AccountSyncService
    // needs that pre-write snapshot, never the already-overwritten value).
    await _runAccountSync(signedInUid, lastSyncedUid);
  }

  /// Wires plan 21-06's `AccountSyncService` into the sign-in flow (MIG-01/
  /// 02/03) and shows at most two sequential D-04/D-05 conflict dialogs,
  /// profile before availability. Wrapped in try/catch: a sync failure
  /// (network error, RLS denial, etc.) must never block the sign-in flow
  /// that already succeeded above -- same "never crash on a background sync
  /// problem" reasoning as `CloudSyncReconciler.reconcileOnForeground`.
  Future<void> _runAccountSync(
    String userId,
    String? preSwitchLastSyncedUid,
  ) async {
    try {
      final service = await ref.read(accountSyncServiceProvider.future);

      final prompts = await service.onSignIn(
        userId,
        lastSyncedUid: preSwitchLastSyncedUid,
      );

      for (final prompt in prompts) {
        if (!mounted) return;
        final s = S.of(context);
        final isProfile = prompt.domain == SyncDomain.profile;
        final keepLocal = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(
              isProfile
                  ? s.accountConflictProfileTitle
                  : s.accountConflictAvailabilityTitle,
            ),
            content: Text(
              isProfile
                  ? s.accountConflictProfileBody
                  : s.accountConflictAvailabilityBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(s.accountConflictKeepLocalAction),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(s.accountConflictKeepCloudAction),
              ),
            ],
          ),
        );
        await service.resolvePrompt(prompt, userId, keepLocal: keepLocal ?? true);
      }

      if (prompts.isNotEmpty) {
        await service.markSynced(userId);
      }

      // Plan 21-10 (SYNC-05 gap closure): drain the offline outbox right
      // here, once AccountSyncService has fully settled this sign-in
      // (including every prompt above). Without this, an enqueue made
      // during sign-in (e.g. `enqueueCurrentState()` from a
      // pushLocalToCloud decision) would sit until the next foreground
      // event instead of reaching the cloud immediately -- exactly the
      // "Wordt gesynchroniseerd..." symptom found on-device 2026-08-04
      // (see MANUAL-VERIFICATION-21.md). `drainOutbox()` never throws, so
      // this call cannot turn a background sync problem into a crash.
      await ref.read(cloudSyncReconcilerProvider).drainOutbox();

      if (mounted) {
        ref.invalidate(profileProvider);
        ref.invalidate(availabilityProvider);
      }
    } catch (e) {
      debugPrint('AccountSection: _runAccountSync mislukt: $e');
    }
  }

  void _showSignInError() {
    if (!mounted) return;
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.accountSignInError)),
    );
  }

  Future<void> _handleAndroidSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await CalendarService.ensureGoogleSignInReady();
      final account = await GoogleSignIn.instance.authenticate();
      await _handleSignInSuccess(account);
    } on GoogleSignInException catch (e) {
      // D-07: annuleren is een keuze, geen fout -- niets tonen.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        debugPrint('AccountSection: GoogleSignInException: ${e.code} ${e.description}');
        _showSignInError();
      }
    } catch (e) {
      debugPrint('AccountSection: onverwachte inlogfout: $e');
      _showSignInError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.accountSignOutConfirmTitle),
        content: Text(s.accountSignOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.accountSignOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // D-12: uitloggen beeindigt alleen de Supabase-sessie -- de Calendar-
      // autorisatie en lokale SharedPreferences blijven onaangeroerd.
      await Supabase.instance.client.auth.signOut();
    }
  }

  /// AUTH-09, D-01/D-02/D-03: verwijdert het account server-side via
  /// `delete_own_account()` (plan 21-02), meldt zich daarna af, en toont een
  /// korte snackbar. Geen apart bevestigingsscherm, geen type-to-confirm-veld,
  /// geen her-authenticatie -- bewust vastgestelde scope in 21-CONTEXT.md.
  ///
  /// D-03, niet-onderhandelbaar: raakt nooit lokale data (resetToDefaults/
  /// clearAll horen bij de aparte account-switch "opnieuw beginnen"-tak in
  /// _checkAccountSwitch hierboven en blijven daar).
  ///
  /// De try/catch-volgorde is de kern van deze methode: signOut() staat in
  /// dezelfde try als de RPC-aanroep en wordt dus nooit bereikt als de RPC
  /// gooit -- een mislukte server-side verwijdering mag zich nooit voordoen
  /// als een geslaagde (D-02's volgorde-eis).
  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(s.accountDeleteConfirmTitle),
        content: Text(s.accountDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(s.accountDeleteConfirmAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.rpc(kDeleteOwnAccountRpc);
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.accountDeletedSnackbar)),
      );
    } catch (e) {
      debugPrint('AccountSection: delete_own_account mislukt: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.accountDeleteError)),
      );
      // Doet bewust GEEN signOut() bij een fout -- een mislukte server-side
      // verwijdering mag nooit als geslaagd ogen (D-02's volgorde-eis).
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // AUTH-08: reageert op elke wijziging in authStateProvider -- niet
    // alleen op een expliciete inlogtik. Dit is het gedeelde pad dat zowel
    // de interactieve inlogflow (via _handleSignInSuccess hierboven) als een
    // herstelde sessie bij koude start (de seed in auth_notifier.dart's
    // authState()) raakt, zodat een accountwissel nooit ongemerkt blijft.
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        _checkAccountSwitch(user.id);
      }
    });
    final authAsync = ref.watch(authStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccountSectionHeader(s.sectionAccount),
        authAsync.when(
          loading: () => ListTile(
            leading: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(s.accountLoading),
          ),
          error: (_, __) => _buildSignedOutRow(context, s),
          data: (user) =>
              user == null ? _buildSignedOutRow(context, s) : _buildSignedInRow(context, s, user),
        ),
      ],
    );
  }

  Widget _buildSignedOutRow(BuildContext context, S s) {
    if (_supportsNativeAuthenticate) {
      return ListTile(
        leading: const Icon(Icons.login),
        title: Text(s.signInWithGoogle),
        subtitle: Text(s.accountSyncPromise),
        onTap: _busy ? null : _handleAndroidSignIn,
      );
    }

    // Web-tak: label + Google's eigen gerenderde knop (D-05/D-06).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.signInWithGoogle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(s.accountSyncPromise),
          const SizedBox(height: 8),
          renderGoogleSignInButton(),
        ],
      ),
    );
  }

  Widget _buildSignedInRow(BuildContext context, S s, User user) {
    final metadata = user.userMetadata;
    final avatarUrl = metadata?['avatar_url'] as String?;
    final displayName = (metadata?['full_name'] as String?) ??
        (metadata?['name'] as String?) ??
        user.email ??
        '';

    // D-06/D-07: exactly two visible sync-status strings, never a third.
    // loading/error render nothing (a transient blank frame is acceptable,
    // a fabricated third status string is not).
    final pendingCountAsync = ref.watch(outboxPendingCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ListTile(
          leading: Semantics(
            label: s.accountAvatarSemanticLabel,
            child: _AccountAvatar(avatarUrl: avatarUrl),
          ),
          title: Text(displayName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.email != null) Text(user.email!),
              pendingCountAsync.when(
                data: (count) => Text(
                  count == 0 ? s.accountSyncStatusSynced : s.accountSyncStatusPending,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          trailing: TextButton(
            onPressed: () => _confirmAndSignOut(context),
            child: Text(s.accountSignOut),
          ),
        ),
        // AUTH-09: destructive-styled, below the sign-out row so both
        // actions are visually distinguishable (sign-out non-destructive,
        // delete destructive) rather than two equal-weight buttons.
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 4),
          child: TextButton(
            onPressed: () => _confirmAndDeleteAccount(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(s.accountDeleteAction),
          ),
        ),
      ],
    );
  }
}

/// Avatar met graceful fallback: NetworkImage-laadfouten schakelen naar een
/// generiek account-icoon in plaats van een kapot-plaatje-glyph.
class _AccountAvatar extends StatefulWidget {
  const _AccountAvatar({this.avatarUrl});
  final String? avatarUrl;

  @override
  State<_AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<_AccountAvatar> {
  bool _loadFailed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.avatarUrl == null || _loadFailed) {
      return const CircleAvatar(child: Icon(Icons.account_circle));
    }
    return CircleAvatar(
      backgroundImage: NetworkImage(widget.avatarUrl!),
      onBackgroundImageError: (_, __) {
        if (mounted) setState(() => _loadFailed = true);
      },
    );
  }
}

/// Sectie-koptekst, dupliceert profile_screen.dart's private _SectionHeader
/// stijl (Dart-privacy is per-bestand -- zie de interfaces-sectie in het plan).
class _AccountSectionHeader extends StatelessWidget {
  const _AccountSectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
