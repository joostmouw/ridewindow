import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

/// Nodigt maatjes uit voor een concreet tijdvak (epic #62).
///
/// Maakt de gedeelde rit pas aan wanneer je werkelijk iemand uitnodigt — een
/// `group_rides`-rij zonder deelnemers is niets meer dan ruis in de database,
/// en zou ook in "ritten die jij organiseert" opduiken terwijl er niemand
/// gevraagd is.
///
/// Bestaat er al een gedeelde rit van jou op exact dit tijdvak, dan wordt die
/// hergebruikt. Zonder die controle levert twee keer uitnodigen twee
/// groepsritten op, en dat is precies de duplicatiefout die plan 21-13 al eens
/// heeft opgeleverd — in een andere gedaante, met dezelfde oorzaak: een sleutel
/// die uit tijd is afgeleid en niet consequent vergeleken wordt.
Future<void> showInviteBuddiesSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime start,
  required DateTime end,
  required double plannedScore,
}) async {
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final friends = await ref.read(friendsProvider.future);

  if (!context.mounted) return;

  if (friends.isEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.pelotonNeedFriendsFirst)),
    );
    return;
  }

  final selected = await showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    builder: (context) => _FriendPicker(friends: friends),
  );

  if (selected == null || selected.isEmpty) return;

  final gateway = ref.read(pelotonGatewayProvider);
  final myName = ref.read(profileProvider).value?.userName;

  try {
    final existing = await ref.read(groupRidesProvider.future);
    final mine = existing.where(
      (r) => r.start.isAtSameMomentAs(start) && r.end.isAtSameMomentAs(end),
    );

    final ride = mine.isNotEmpty
        ? mine.first
        : await gateway.createGroupRide(
            start: start,
            end: end,
            plannedScore: plannedScore,
            ownerName: myName,
          );

    for (final friend in friends.where((f) => selected.contains(f.userId))) {
      await gateway.inviteToRide(
        rideId: ride.id,
        friendId: friend.userId,
        displayName: friend.displayName,
      );
    }

    ref.invalidate(groupRidesProvider);
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonInviteSent)));
  } catch (error) {
    // Een uitnodiging die niet aankomt mag geen scherm laten crashen; de rit
    // zelf is niet veranderd, dus opnieuw proberen is veilig.
    debugPrint('Peloton: uitnodigen mislukt: $error');
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonCodeInvalid)));
  }
}

class _FriendPicker extends StatefulWidget {
  const _FriendPicker({required this.friends});

  final List<Friend> friends;

  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(s.pelotonPickFriends, style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final friend in widget.friends)
                  CheckboxListTile(
                    value: _selected.contains(friend.userId),
                    title: Text(friend.label(s.pelotonUnnamedFriend)),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _selected.add(friend.userId);
                      } else {
                        _selected.remove(friend.userId);
                      }
                    }),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: Text(s.pelotonInviteAction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
