/// Welke meldingen er bij een profiel en het eerstvolgende venster horen.
///
/// **Waarom dit apart staat en puur is.** De drie schakelaars in Profiel deden
/// tot 2026-09-19 niets: ze sloegen een voorkeur op, vroegen permissie, en
/// niemand las die voorkeur ooit om iets te plannen. In `profile_screen.dart`
/// stond het met zoveel woorden -- *"Verdere scheduling vindt plaats via
/// SlotsNotifier data in de toekomst (Phase 8 scope: permissie-flow)"*. Die
/// toekomst is nooit gekomen en de schakelaars zijn sindsdien decoratie.
///
/// De beslissing staat hier los van `NotificationService` zodat ze te toetsen
/// is zonder plugin, zonder platformkanaal en zonder klok van het systeem --
/// precies de drie dingen die de oude opzet ontoetsbaar maakten.
library;

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/user_profile.dart';

/// Eén geplande melding.
sealed class NotificationPlan {
  const NotificationPlan();
}

/// "Morgen ligt er een fietsmoment klaar", de avond ervoor om 19:00.
class EveningBeforePlan extends NotificationPlan {
  const EveningBeforePlan({required this.slotDay, required this.slotTitle});

  final DateTime slotDay;
  final String slotTitle;
}

/// "Over 2 uur stap je op", twee uur voor de start.
class MorningOfPlan extends NotificationPlan {
  const MorningOfPlan({required this.slotStart, required this.slotTitle});

  final DateTime slotStart;
  final String slotTitle;
}

/// Het weekoverzicht, zondagavond 19:00.
class WeeklyDigestPlan extends NotificationPlan {
  const WeeklyDigestPlan();
}

/// Wat er gepland moet worden voor [profile] en [nextSlot].
///
/// Een lege lijst betekent "niets plannen", en dat is óók het signaal om
/// bestaande meldingen te annuleren -- zie de aanroeper.
///
/// [nextSlot] is het eerstvolgende beste venster, of null als er geen
/// acceptabel venster is. Zonder venster blijft alleen het weekoverzicht over:
/// dat hangt aan de kalender en niet aan het weer.
List<NotificationPlan> planNotifications({
  required UserProfile profile,
  required RideSlot? nextSlot,
  required DateTime now,
}) {
  final plans = <NotificationPlan>[];

  if (nextSlot != null) {
    final title = formatSlotTitle(nextSlot);

    // De avond ervoor om 19:00. Ligt dat moment al achter ons -- het venster is
    // vandaag, of het is al na zevenen op de vooravond -- dan heeft plannen
    // geen zin. NotificationService slaat het dan zelf ook over, maar de
    // beslissing hoort hier zodat ze te zien en te toetsen is.
    if (profile.notifEveningBefore) {
      final evening = DateTime(
        nextSlot.start.year,
        nextSlot.start.month,
        nextSlot.start.day - 1,
        19,
      );
      if (evening.isAfter(now)) {
        plans.add(
          EveningBeforePlan(slotDay: nextSlot.start, slotTitle: title),
        );
      }
    }

    // Twee uur van tevoren.
    if (profile.notifMorningOf) {
      final twoHoursBefore = nextSlot.start.subtract(const Duration(hours: 2));
      if (twoHoursBefore.isAfter(now)) {
        plans.add(
          MorningOfPlan(slotStart: nextSlot.start, slotTitle: title),
        );
      }
    }
  }

  if (profile.notifWeeklyDigest) {
    plans.add(const WeeklyDigestPlan());
  }

  return plans;
}

/// "09:00–11:00" -- dezelfde vorm als de knop op het ritdetail gebruikt.
///
/// Bewust hier en niet in de UI: de achtergrondtaak heeft geen scherm en moet
/// dezelfde tekst kunnen maken.
String formatSlotTitle(RideSlot slot) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(slot.start.hour)}:${two(slot.start.minute)}'
      '–${two(slot.end.hour)}:${two(slot.end.minute)}';
}
