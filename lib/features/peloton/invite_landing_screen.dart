import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/services/pending_invite_store.dart';
import 'package:ridewindow/theme/app_icons.dart';

/// Waar een gedeelde uitnodigingslink op uitkomt: `/invite/:code` (epic #62).
///
/// De basis-URL van de gedeelde link. Bewust hier als constante en niet
/// verspreid over de plekken die hem nodig hebben.
///
/// **De `/#/` is geen slordigheid maar noodzaak:** deze app draait op
/// go_router's default hash-strategie (er staat nergens `usePathUrlStrategy`),
/// dus `https://…/invite/ABC` komt op de server terecht en geeft een 404,
/// terwijl `https://…/#/invite/ABC` door de app zelf wordt afgehandeld. Zet je
/// ooit padroutering aan, dan moet deze constante mee.
///
/// Verandert het domein (backlog #54 stelt `ridewindow.web.app` voor), dan is
/// dit de plek — en let erop dat oude, al verstuurde links dan doodlopen.
const kInviteLinkBase = 'https://my-project-joost.web.app/#/invite';

String inviteLinkFor(String code) => '$kInviteLinkBase/$code';

/// Verzilvert de code uit de link en vertelt wat er gebeurd is.
///
/// Verzilveren gebeurt automatisch bij het openen: wie op een uitnodigingslink
/// tikt, heeft zijn keuze al gemaakt. Een extra "weet je het zeker"-knop zou
/// alleen een stap toevoegen aan iets wat de gebruiker zelf in gang zette.
class InviteLandingScreen extends ConsumerStatefulWidget {
  const InviteLandingScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<InviteLandingScreen> createState() =>
      _InviteLandingScreenState();
}

class _InviteLandingScreenState extends ConsumerState<InviteLandingScreen> {
  Future<Friend>? _redeem;

  @override
  void initState() {
    super.initState();
    if (ref.read(currentUserIdProvider) != null) {
      _start();
    } else {
      // Uitgelogd kan er niets verzilverd worden -- de RPC eist auth.uid().
      // De code wordt bewaard zodat hij het inloggen overleeft en daarna
      // vanzelf verzilverd wordt. Zie PendingInviteStore voor waarom dit geen
      // luxe is maar het verschil tussen een werkende en een doodlopende link.
      PendingInviteStore.save(widget.code);
    }
  }

  void _start() {
    setState(() {
      _redeem = ref
          .read(pelotonGatewayProvider)
          .redeemFriendInvite(widget.code)
          .then((friend) {
        ref.invalidate(friendsProvider);
        return friend;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final signedIn = ref.watch(currentUserIdProvider) != null;

    // Logt iemand in terwijl dit scherm openstaat, dan moet de code meteen
    // verzilverd worden. `initState` keek maar één keer; zonder deze listener
    // bleef de gebruiker naar "log eerst in" kijken terwijl hij dat net gedaan
    // had.
    ref.listen(currentUserIdProvider, (previous, next) {
      if (previous == null && next != null && _redeem == null) {
        PendingInviteStore.clear();
        _start();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(s.pelotonJoinTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: !signedIn
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Message(
                      icon: AppIcons.lock,
                      title: s.pelotonSignInToJoin,
                      detail: s.pelotonYourCode(widget.code),
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    // Jacco's verzoek, en het vangnet voor het geval de
                    // automatische verzilvering ergens strandt: de code moet
                    // te kopiëren zijn zonder overtypen.
                    TextButton.icon(
                      icon: const Icon(AppIcons.copy),
                      label: Text(s.pelotonCopyCode),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.code),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.pelotonCodeCopied)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Hier liep het vast: het scherm zei "log eerst in" en bood
                    // vervolgens geen enkele manier om dat te doen. De
                    // gebruiker moest zelf Profiel zien te vinden.
                    FilledButton(
                      onPressed: () => context.go('/profile'),
                      child: Text(s.pelotonSignInAction),
                    ),
                  ],
                )
              : FutureBuilder<Friend>(
                  future: _redeem,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _Message(
                        icon: AppIcons.hourglass,
                        title: s.pelotonJoining,
                        theme: theme,
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Message(
                            icon: AppIcons.linkBreak,
                            title: s.pelotonCodeInvalid,
                            theme: theme,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _start,
                            child: Text(s.pelotonRetry),
                          ),
                        ],
                      );
                    }
                    final friend = snapshot.data;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Message(
                          icon: AppIcons.usersThree,
                          title: s.pelotonFriendAdded(
                            friend?.label(s.pelotonUnnamedFriend) ??
                                s.pelotonUnnamedFriend,
                          ),
                          theme: theme,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go('/rides'),
                          child: Text(s.pelotonGoToPeloton),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.theme,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (detail != null) ...[
          const SizedBox(height: 8),
          SelectableText(
            detail!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ],
    );
  }
}
