import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

/// De zin bij een groepsfout (CLUB-18): wat er aan de hand is en wat je kunt
/// doen, nooit een foutcode.
///
/// Exhaustieve switch zonder vangnet-tak: komt er een sleutel bij in [GroupError],
/// dan compileert dit niet tot hij hier een zin heeft.
///
/// [groupName] maakt `group_full` persoonlijker; [personName] maakt van
/// `too_many_groups` een zin over die persoon (bij voordragen of accepteren)
/// in plaats van over jou.
String groupErrorText(
  S s,
  GroupError error, {
  String? groupName,
  String? personName,
}) {
  return switch (error) {
    GroupError.groupFull => (groupName == null || groupName.trim().isEmpty)
        ? s.groupErrorFull
        : s.groupErrorFullNamed(groupName.trim()),
    GroupError.tooManyGroups =>
      (personName == null || personName.trim().isEmpty)
          ? s.groupErrorTooManyGroupsSelf
          : s.groupErrorTooManyGroupsOther(personName.trim()),
    GroupError.inviteInvalid => s.groupErrorInviteInvalid,
    GroupError.lastAdmin => s.groupErrorLastAdmin,
    GroupError.groupNameInvalid => s.groupErrorNameInvalid,
    GroupError.notAuthenticated => s.groupErrorSignedOut,
    GroupError.notMember => s.groupErrorNotMember,
    GroupError.notFriend => s.groupErrorNotFriend,
    GroupError.notAllowed => s.groupErrorNotAllowed,
    GroupError.tooManyRequests => s.groupErrorTooManyRequests,
    GroupError.unknown => s.groupErrorGeneric,
  };
}

/// Voor een catch-tak: een [GroupException] krijgt zijn eigen zin, al het
/// andere (netwerk, onbekende databasefout) de generieke. Elke catch-tak in de
/// groeps-UI gebruikt deze functie, zodat er geen stille tak overblijft en er
/// nooit ruwe servertekst op het scherm komt.
String groupErrorTextOf(
  S s,
  Object error, {
  String? groupName,
  String? personName,
}) {
  if (error is GroupException) {
    return groupErrorText(
      s,
      error.error,
      groupName: groupName,
      personName: personName,
    );
  }
  return s.groupErrorGeneric;
}
