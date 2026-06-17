// lib/services/widget_update_service.dart
// Serializeert het volgende beste rijslot naar SharedPreferences via home_widget,
// zodat de Android RideWidgetProvider de RemoteViews kan updaten.
//
// Veilig aanroepbaar vanuit zowel de main isolate (via provider listener)
// als de WorkManager isolate (geen Riverpod aanwezig — geef null of RideSlot direct mee).

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

class WidgetUpdateService {
  /// Schrijft [nextSlot] naar de home_widget SharedPreferences brug en
  /// vraagt de Android RideWidgetProvider om zijn RemoteViews te vernieuwen.
  ///
  /// Als [nextSlot] null is, wordt het widget bijgewerkt met
  /// "Geen slot gevonden" staat.
  static Future<void> update(RideSlot? nextSlot) async {
    if (nextSlot != null) {
      final durationH = nextSlot.end.difference(nextSlot.start).inHours;

      // Korte Nederlandse weekdagnaam + dag + maandafkorting (b.v. "za 21 jun")
      final dateStr = DateFormat('EEE d MMM', 'nl_NL').format(nextSlot.start);

      // Tijdvenster in HH:mm–HH:mm formaat
      final timeFmt = DateFormat('HH:mm');
      final timeStr =
          '${timeFmt.format(nextSlot.start)}\u2013${timeFmt.format(nextSlot.end)}';

      // Tier label in het Nederlands
      final tierLabel = switch (nextSlot.tier) {
        Perfect() => 'Perfect',
        Great() => 'Geweldig',
        Acceptable() => 'Acceptabel',
        Poor() => 'Slecht',
      };

      await HomeWidget.saveWidgetData<String>('slot_date', dateStr);
      await HomeWidget.saveWidgetData<String>('slot_time', timeStr);
      await HomeWidget.saveWidgetData<String>('slot_duration', '${durationH}u');
      await HomeWidget.saveWidgetData<String>('slot_tier', tierLabel);
      await HomeWidget.saveWidgetData<bool>('slot_available', true);
    } else {
      await HomeWidget.saveWidgetData<bool>('slot_available', false);
    }

    // Vraag Android om de widget RemoteViews te verversen
    await HomeWidget.updateWidget(androidName: 'RideWidgetProvider');
  }
}
