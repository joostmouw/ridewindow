import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridewindow/data/repositories/ride_score_alert_store.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/platform/ride_score_alerts.dart';
import 'package:ridewindow/providers/ride_score_alerts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideScoreAlertSettings extends ConsumerStatefulWidget {
  const RideScoreAlertSettings({super.key, this.notifications});
  final NotificationService? notifications;

  @override
  ConsumerState<RideScoreAlertSettings> createState() =>
      _RideScoreAlertSettingsState();
}

class _RideScoreAlertSettingsState
    extends ConsumerState<RideScoreAlertSettings> {
  bool _busy = false;
  late final _notifications = widget.notifications ?? NotificationService();

  Future<void> _setThreshold(int threshold) async {
    if (_busy) return;
    setState(() => _busy = true);
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (threshold > 0) {
        await _notifications.init(strings: s);
        final permitted =
            await _notifications.requestPostNotificationsPermission();
        if (!mounted) return;
        if (!permitted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(s.notifPermissionDenied),
              action: SnackBarAction(
                label: s.settingsLabel,
                onPressed: () => _notifications.openSystemSettings(),
              ),
            ),
          );
          return;
        }
      }
      await ref
          .read(scoreDropThresholdProvider.notifier)
          .setThreshold(threshold);
      if (threshold == 0) {
        await RideScoreAlerts(
          await SharedPreferences.getInstance(),
          notifications: _notifications,
        ).disable(locale: s.localeName);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(s.notifSettingsFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final value = ref.watch(scoreDropThresholdProvider);
    final threshold = value.value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(s.notifScoreDropSetting),
          subtitle: Text(s.notifScoreDropSettingSub),
          value: threshold > 0,
          onChanged: _busy || !value.hasValue
              ? null
              : (on) => _setThreshold(on ? 10 : 0),
        ),
        if (threshold > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<int>(
              initialValue: threshold,
              decoration: InputDecoration(labelText: s.notifScoreDropThreshold),
              items: [
                for (final points in kScoreDropThresholds)
                  DropdownMenuItem(
                    value: points,
                    child: Text(s.notifScoreDropPoints(points)),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) _setThreshold(value);
                    },
            ),
          ),
      ],
    );
  }
}
