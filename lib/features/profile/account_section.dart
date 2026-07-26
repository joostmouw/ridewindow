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
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/services/calendar_service.dart';

// package:google_sign_in/web_only.dart does not exist in google_sign_in
// 7.2.0 -- renderButton() lives in the federated google_sign_in_web package,
// which pulls in dart:js_interop-based code that fails to compile for the
// Dart VM (`flutter test`'s target). Routed through the conditional-import
// seam below instead of importing google_sign_in_web directly (Rule 1 fix,
// see google_signin_button.dart's header comment).
import 'google_signin_button.dart';

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

    String? accessToken;
    try {
      var authorization = await account.authorizationClient
          .authorizationForScopes(['email']);
      authorization ??=
          await account.authorizationClient.authorizeScopes(['email']);
      accessToken = authorization.accessToken;
    } catch (e) {
      debugPrint('AccountSection: kon geen access token krijgen: $e');
    }

    try {
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('AccountSection: signInWithIdToken mislukt: $e');
      _showSignInError();
      return;
    }

    // D-04: vul profile.userName alleen in als het nog leeg is, nooit
    // overschrijven.
    if (!mounted) return;
    if (ref.read(profileProvider).value?.userName == null) {
      await ref
          .read(profileProvider.notifier)
          .setUserName(account.displayName);
    }
    // D-07: geen succesbevestiging -- de sectie verandert zichtbaar, dat is
    // het bewijs.
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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

    return ListTile(
      leading: Semantics(
        label: s.accountAvatarSemanticLabel,
        child: _AccountAvatar(avatarUrl: avatarUrl),
      ),
      title: Text(displayName),
      subtitle: user.email != null ? Text(user.email!) : null,
      trailing: TextButton(
        onPressed: () => _confirmAndSignOut(context),
        child: Text(s.accountSignOut),
      ),
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
