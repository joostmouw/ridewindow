// lib/features/peloton/group_name_sheet.dart
// De sheet met één naamveld, voor een groep maken (CLUB-01) en, in plan 06,
// voor hernoemen.

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

/// Vraagt een groepsnaam en geeft hem getrimd terug, of null bij wegtikken.
///
/// De database trimt en toetst zelf ook (`create_group`, `group_name_invalid`);
/// de grens van [kGroupNameMaxLength] hier is voor de rust in de lijst, niet
/// de verdediging.
Future<String?> showGroupNameSheet(
  BuildContext context, {
  String? initialName,
  required String title,
  String? hint,
  required String actionLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => _GroupNameSheet(
      initialName: initialName,
      title: title,
      hint: hint,
      actionLabel: actionLabel,
    ),
  );
}

class _GroupNameSheet extends StatefulWidget {
  const _GroupNameSheet({
    required this.initialName,
    required this.title,
    required this.hint,
    required this.actionLabel,
  });

  final String? initialName;
  final String title;
  final String? hint;
  final String actionLabel;

  @override
  State<_GroupNameSheet> createState() => _GroupNameSheetState();
}

class _GroupNameSheetState extends State<_GroupNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  // Pop met de context van de sheet zelf: die van het aanroepende scherm kan
  // binnen go_router naar de shell-navigator wijzen en dan haalt de pop het
  // scherm onder de sheet weg (zie de noot bij `_infoButton` in Profiel).
  void _submit() {
    if (_name.isEmpty) return;
    Navigator.of(context).pop(_name);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Padding(
      // Het toetsenbord schuift de sheet omhoog in plaats van het veld te
      // bedekken.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            if (widget.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.hint!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: kGroupNameMaxLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: s.groupNameLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _name.isEmpty ? null : _submit,
              child: Text(widget.actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
