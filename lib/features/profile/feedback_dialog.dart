// lib/features/profile/feedback_dialog.dart
// Backlog #33: "Send feedback" dialog — 1-5 star rating + free-text comment,
// submitted via a mailto: URI (no backend, no new dependency, no network call).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

const _kFeedbackRecipient = 'joostmouw@gmail.com';
const _kFeedbackSubject = 'RideWindow feedback';

/// Pure function — builds the mailto: URI for the feedback email.
///
/// Uses the `Uri(queryParameters: {...})` constructor (not string
/// concatenation) so special characters in [comment] are automatically
/// percent-encoded and cannot break the URI or inject extra mailto fields
/// (e.g. `cc=`, `bcc=`).
Uri buildFeedbackMailtoUri({required int rating, required String comment}) {
  final stars = '★' * rating + '☆' * (5 - rating);
  final trimmedComment = comment.trim();
  final commentText = trimmedComment.isEmpty ? '(none)' : trimmedComment;
  final body = '$stars ($rating/5)\n\nComment:\n$commentText';

  return Uri(
    scheme: 'mailto',
    path: _kFeedbackRecipient,
    queryParameters: {
      'subject': _kFeedbackSubject,
      'body': body,
    },
  );
}

/// Opens the feedback dialog.
Future<void> showFeedbackDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _FeedbackDialog(),
  );
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  int _rating = 0;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uri = buildFeedbackMailtoUri(
      rating: _rating,
      comment: _controller.text,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.sendFeedback),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.feedbackRatingLabel),
          Row(
            children: List.generate(5, (i) {
              final n = i + 1;
              final selected = n <= _rating;
              return Semantics(
                selected: selected,
                button: true,
                child: IconButton(
                  key: ValueKey('feedback_star_$n'),
                  icon: Icon(selected ? Icons.star : Icons.star_border),
                  tooltip: s.feedbackStarRating(n),
                  color: selected
                      ? context.rw.scorePerfect
                      : Theme.of(context).colorScheme.outline,
                  onPressed: () => setState(() => _rating = n),
                ),
              );
            }),
          ),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: s.feedbackCommentLabel,
              hintText: s.feedbackCommentHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: _rating == 0 ? null : _submit,
          child: Text(s.feedbackSendButton),
        ),
      ],
    );
  }
}
