// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RideWindow';

  @override
  String get navHome => 'Home';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navRides => 'Rides';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingNightOwl => 'Night owl';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String rideWindowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'windows',
      one: 'window',
    );
    return '$count ride $_temp0 this week';
  }

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get retryButton => 'Try again';

  @override
  String get thisWeek => 'COMING DAYS';

  @override
  String get rideTimes => 'RIDE TIMES';

  @override
  String get filterMorning => 'Morning';

  @override
  String get filterAfternoon => 'Afternoon';

  @override
  String get filterEvening => 'Evening';

  @override
  String get adjustTime => 'ADJUST TIME';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get infoTemp =>
      'The green zone shows your ideal temperature range. The dot shows the average temperature for this ride window. Adjust your range in Profile.';

  @override
  String get infoRain =>
      'The green zone shows your rain tolerance. The dot shows the total expected precipitation. Less rain = better ride.';

  @override
  String get infoWind =>
      'The green zone shows your wind comfort limit. The dot shows the average wind speed. Strong wind makes cycling harder and less safe.';

  @override
  String get dayMon => 'MON';

  @override
  String get dayTue => 'TUE';

  @override
  String get dayWed => 'WED';

  @override
  String get dayThu => 'THU';

  @override
  String get dayFri => 'FRI';

  @override
  String get daySat => 'SAT';

  @override
  String get daySun => 'SUN';

  @override
  String get dayMonFull => 'Monday';

  @override
  String get dayTueFull => 'Tuesday';

  @override
  String get dayWedFull => 'Wednesday';

  @override
  String get dayThuFull => 'Thursday';

  @override
  String get dayFriFull => 'Friday';

  @override
  String get daySatFull => 'Saturday';

  @override
  String get daySunFull => 'Sunday';

  @override
  String get dayMonLower => 'monday';

  @override
  String get dayTueLower => 'tuesday';

  @override
  String get dayWedLower => 'wednesday';

  @override
  String get dayThuLower => 'thursday';

  @override
  String get dayFriLower => 'friday';

  @override
  String get daySatLower => 'saturday';

  @override
  String get daySunLower => 'sunday';

  @override
  String get dayUnknown => 'unknown';

  @override
  String get tierPerfect => 'Perfect';

  @override
  String get tierGreat => 'Great';

  @override
  String get tierAcceptable => 'Acceptable';

  @override
  String get tierPoor => 'Poor';

  @override
  String get tierPerfectAgenda => 'Perfect';

  @override
  String get tierGreatAgenda => 'Great';

  @override
  String get tierAcceptableAgenda => 'OK';

  @override
  String get tierPoorAgenda => 'Poor';

  @override
  String get legendPlanned => 'Planned';

  @override
  String get bestChoice => 'Best choice';

  @override
  String get schedule => 'Schedule';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get addedToGoogleCalendar => 'Ride window added to Google Calendar!';

  @override
  String couldNotAdd(String error) {
    return 'Could not add: $error';
  }

  @override
  String get weatherLoadError => 'Weather data could not be loaded.';

  @override
  String get emptyBadWeather =>
      'No good ride windows this week. Bad weather expected.';

  @override
  String get emptyAllBlocked =>
      'All good windows are blocked. Adjust your schedule.';

  @override
  String get emptyNoSlots => 'No ride windows found.';

  @override
  String get emptyNoSlotsDay => 'No ride windows on this day.';

  @override
  String get windCalm => 'Calm';

  @override
  String durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String get welcomeTitle => 'Your perfect ride moment';

  @override
  String get welcomeSubtitle =>
      'Combine the weather forecast with your calendar and discover the best windows to ride.';

  @override
  String get welcomeButton => 'Get started →';

  @override
  String get onboardingTitle => 'When do you prefer to ride?';

  @override
  String get onboardingSubtitle =>
      'Pick a schedule to start. You can always change this later.';

  @override
  String get onboardingNext => 'Next →';

  @override
  String get presetEveningsWeekends => 'Evenings & weekends';

  @override
  String get presetEveningsWeekendsSub =>
      'Mon–Fri after 17:00, Sat/Sun all day';

  @override
  String get presetMorningsWeekends => 'Mornings & weekends';

  @override
  String get presetMorningsWeekendsSub =>
      'Mon–Fri 06:00–09:00, Sat/Sun all day';

  @override
  String get presetWeekendsOnly => 'Weekends only';

  @override
  String get presetWeekendsOnlySub => 'Sat/Sun all day';

  @override
  String get presetCustom => 'Set my own schedule';

  @override
  String get presetCustomSub => 'I\'ll adjust my calendar myself';

  @override
  String get profileTitle => 'Profile';

  @override
  String get sectionLocation => 'LOCATION';

  @override
  String get sectionNotifications => 'NOTIFICATIONS';

  @override
  String get sectionTheme => 'THEME';

  @override
  String get sectionTolerances => 'TOLERANCES';

  @override
  String get sectionRideLength => 'RIDE LENGTH';

  @override
  String get sectionName => 'NAME';

  @override
  String get sectionAbout => 'ABOUT';

  @override
  String get sectionLanguage => 'LANGUAGE';

  @override
  String get locationBlocked => 'Location access blocked';

  @override
  String get locationBlockedHint =>
      'Choose a city or open settings to re-enable GPS.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get useGpsLocation => 'Use GPS location';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get gpsAutomatic => 'GPS (automatic)';

  @override
  String get tapToChooseCity => 'Tap to choose city';

  @override
  String get notifEveningBefore => 'Evening before';

  @override
  String get notifEveningBeforeSub =>
      '19:00 the day before if there\'s a top slot';

  @override
  String get notifMorningOf => 'Morning of';

  @override
  String get notifMorningOfSub => '2 hours before the slot starts';

  @override
  String get notifWeeklyDigest => 'Weekly overview';

  @override
  String get notifWeeklyDigestSub =>
      'Sunday evening 19:00 — best moments of the week';

  @override
  String get notifExactTimingWarning =>
      'Exact timing not guaranteed. Allow exact alarms in Settings for reliability.';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get toleranceTemperature => 'Temperature';

  @override
  String get toleranceMaxRain => 'Max. rain';

  @override
  String get toleranceMaxWind => 'Max. wind';

  @override
  String get tempDescAllWeather => 'You ride in almost any weather';

  @override
  String get tempDescComfortable => 'Comfortable cycling range';

  @override
  String get tempDescNiceOnly => 'Only in nice weather';

  @override
  String get tempDescPerfectOnly => 'Only in perfect weather';

  @override
  String get rainDescDryOnly => 'Only in dry weather';

  @override
  String get rainDescDrizzleOk => 'A little drizzle is OK';

  @override
  String get rainDescLightRainOk => 'Light rain no problem';

  @override
  String get rainDescHeavyRainOk => 'Even in heavy showers';

  @override
  String get windDescCalmOnly => 'Only in calm weather';

  @override
  String get windDescBreezeOk => 'A gentle breeze is fine';

  @override
  String get windDescStrongOk => 'Strong wind no problem';

  @override
  String get windDescHardWindOk => 'Even in hard wind';

  @override
  String get editMySchedule => 'Edit my schedule';

  @override
  String get setYourName => 'Set your name';

  @override
  String get nameHint => 'Tap to enter your name for a personal greeting';

  @override
  String get yourName => 'Your name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get version => 'Version';

  @override
  String get debugMenu => 'Debug Menu';

  @override
  String get debugResetOnboarding => 'Reset onboarding';

  @override
  String get debugOnboardingReset => 'Onboarding reset. Restart the app.';

  @override
  String get debugClearWeather => 'Clear weather data';

  @override
  String get debugWeatherCleared => 'Weather data cleared.';

  @override
  String get debugResetAvailability => 'Reset availability';

  @override
  String get debugAvailabilityReset => 'Availability reset.';

  @override
  String get debugRefreshWeather => 'Manually refresh weather';

  @override
  String get debugWeatherRefreshing => 'Weather is refreshing.';

  @override
  String get detailTierPerfectDesc => 'Perfect — the best window this week';

  @override
  String get detailTierGreatDesc => 'Great — pleasant riding conditions';

  @override
  String get detailTierAcceptableDesc =>
      'Acceptable — doable, grab an extra layer';

  @override
  String get detailTierPoorDesc => 'Poor — not ideal, but possible';

  @override
  String get detailConditions => 'conditions';

  @override
  String get weatherSection => 'WEATHER';

  @override
  String get weatherTemperature => 'Temperature';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherHourly => 'HOURLY';

  @override
  String feelsLike(String temp) {
    return 'feels like $temp°C';
  }

  @override
  String get dry => 'Dry';

  @override
  String rainChance(String mm, String percent) {
    return '${mm}mm ($percent% chance)';
  }

  @override
  String windFrom(String speed, String direction) {
    return '${speed}km/h from $direction';
  }

  @override
  String windPenalty(String pct) {
    return 'Variable wind direction (-$pct% on score)';
  }

  @override
  String get clothingTitle => 'What to wear';

  @override
  String get clothingWinterJacket => 'Winter jacket';

  @override
  String get clothingThermalPants => 'Thermal pants';

  @override
  String get clothingGloves => 'Gloves';

  @override
  String get clothingOvershoes => 'Overshoes';

  @override
  String get clothingLongSleeveJersey => 'Long sleeve jersey';

  @override
  String get clothingArmWarmers => 'Arm warmers';

  @override
  String get clothingLegWarmers => 'Leg warmers';

  @override
  String get clothingKneeWarmers => 'Knee warmers';

  @override
  String get clothingShortSleeveJersey => 'Short sleeve jersey';

  @override
  String get clothingArmWarmersJustInCase => 'Arm warmers just in case';

  @override
  String get clothingLightShirt => 'Light shirt';

  @override
  String get clothingSunscreen => 'Sunscreen';

  @override
  String get clothingExtraWater => 'Extra water';

  @override
  String get clothingRainJacket => 'Rain jacket';

  @override
  String get clothingWindVest => 'Wind vest';

  @override
  String get planRide => 'Plan ride';

  @override
  String get ridePlanned => 'Ride planned!';

  @override
  String get addToGoogleCalendar => 'Add to Google Calendar';

  @override
  String get remindEveningBefore => 'Remind me the evening before';

  @override
  String get reminderPlanned => 'Reminder planned for the evening before!';

  @override
  String get shareRideWindow => 'Share this ride window';

  @override
  String shareText(String day, String timeRange, String tier, String summary) {
    return 'Bike ride $day $timeRange ($tier)\n$summary\n\nVia RideWindow';
  }

  @override
  String insightsTitle(String tier, String score) {
    return 'Why \'$tier\' — $score/100';
  }

  @override
  String get insightsTempIdeal => 'Ideal';

  @override
  String get insightsTempAcceptable => 'Acceptable';

  @override
  String get insightsTempExtreme => 'Cold/Hot';

  @override
  String get insightsRainDry => 'Dry';

  @override
  String get insightsRainLight => 'Light';

  @override
  String get insightsRainWet => 'Wet';

  @override
  String get insightsWindCalm => 'Calm';

  @override
  String get insightsWindModerate => 'Moderate';

  @override
  String get insightsWindStrong => 'Strong';

  @override
  String get insightsTempNoteIdeal => 'Ideal temperature — comfortable riding';

  @override
  String get insightsTempNoteAcceptable =>
      'Acceptable temperature — grab an extra layer';

  @override
  String get insightsTempNoteExtreme => 'Outside ideal range — adjust clothing';

  @override
  String get insightsRainNoteDry => 'Dry — no rain expected';

  @override
  String get insightsRainNoteLight => 'Light rain expected — fenders handy';

  @override
  String get insightsRainNoteWet => 'Rain expected — consider a rain jacket';

  @override
  String get insightsWindNoteCalm => 'Light wind — barely noticeable';

  @override
  String get insightsWindNoteModerate =>
      'Moderate wind — expect some resistance';

  @override
  String get insightsWindNoteStrong =>
      'Strong wind — plan your route strategically';

  @override
  String get totalScore => 'Total score';

  @override
  String get understood => 'Got it';

  @override
  String get availabilityTitle => 'My schedule';

  @override
  String get legendFree => 'Free';

  @override
  String get legendBusy => 'Busy';

  @override
  String get legendWork => 'Work';

  @override
  String get riderNoTime => 'No time at all?';

  @override
  String get riderNoTimeDesc =>
      'Free up some hours to find your perfect ride moments.';

  @override
  String get riderFulltime => 'Full-time cyclist';

  @override
  String get riderFulltimeDesc =>
      'Your schedule is wide open. Plenty of choice from the best moments.';

  @override
  String get riderWeekend => 'Weekend warrior';

  @override
  String get riderWeekendDesc =>
      'The weekend is your playground. We\'ll find the best Saturday and Sunday windows.';

  @override
  String get riderEarlyBird => 'Early bird';

  @override
  String get riderEarlyBirdDesc =>
      'You ride before the world wakes up. Morning slots are your sweet spot.';

  @override
  String get riderAfterWork => 'After-work rider';

  @override
  String get riderAfterWorkDesc =>
      'The evening is your escape. We\'ll find the best evening windows with the nicest weather.';

  @override
  String get riderAfternoon => 'Afternoon rider';

  @override
  String get riderAfternoonDesc =>
      'You pick the best hours of the day. Afternoon slots will be your ideal moments.';

  @override
  String get riderBusy => 'Busy but determined';

  @override
  String get riderBusyDesc =>
      'Tight schedule, but every ride counts. We\'ll find the gems in your free hours.';

  @override
  String get riderFlexible => 'Flexible rider';

  @override
  String get riderFlexibleDesc =>
      'A nice mix of free time throughout the week. You always have options.';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaCancel => 'Cancel';

  @override
  String get agendaBusy => 'Busy';

  @override
  String agendaHoursSelected(int count) {
    return '$count hours selected';
  }

  @override
  String agendaPlanRide(int count) {
    return 'Plan ride (${count}h)';
  }

  @override
  String agendaRidePlanned(int count) {
    return 'Ride planned (${count}h)!';
  }

  @override
  String get agendaNow => 'Now';

  @override
  String get agendaScoreBreakdown => 'Score breakdown';

  @override
  String get agendaRain => 'Rain';

  @override
  String get agendaViewDetails => 'View details';

  @override
  String get ridesTitle => 'My Rides';

  @override
  String get ridesEmpty => 'No rides planned yet';

  @override
  String get ridesEmptyHint =>
      'Plan a ride from Home or select hours in the Agenda.';

  @override
  String get rideRemoved => 'Ride removed';

  @override
  String rideSincePlanning(String delta) {
    return '$delta since planning';
  }

  @override
  String get ridesPerHour => 'Per hour';

  @override
  String get ridesAvgScoreBreakdown => 'Average score breakdown';

  @override
  String get ridesDeleteRide => 'Delete ride';

  @override
  String ridesWindFrom(String direction, String advice) {
    return 'Wind from $direction. $advice.';
  }

  @override
  String get tailwindNorth => 'Ride north for tailwind on the way back';

  @override
  String get tailwindNortheast => 'Ride northeast for tailwind on the way back';

  @override
  String get tailwindEast => 'Ride east for tailwind on the way back';

  @override
  String get tailwindSoutheast => 'Ride southeast for tailwind on the way back';

  @override
  String get tailwindSouth => 'Ride south for tailwind on the way back';

  @override
  String get tailwindSouthwest => 'Ride southwest for tailwind on the way back';

  @override
  String get tailwindWest => 'Ride west for tailwind on the way back';

  @override
  String get tailwindNorthwest => 'Ride northwest for tailwind on the way back';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NE';

  @override
  String get compassE => 'E';

  @override
  String get compassSE => 'SE';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SW';

  @override
  String get compassW => 'W';

  @override
  String get compassNW => 'NW';

  @override
  String get hintTapRideWindow => 'Tap a ride window';

  @override
  String get hintTapRideWindowDesc =>
      'View weather details, plan the ride or add to Google Calendar.';

  @override
  String get hintFilterDay => 'Filter by day';

  @override
  String get hintFilterDayDesc => 'Tap a day at the top to show only that day.';

  @override
  String get hintTapWeatherDetail => 'Tap for weather details';

  @override
  String get hintTapWeatherDetailDesc =>
      'Tap a colored hour cell to view temperature, rain and wind.';

  @override
  String get hintDragSelect => 'Drag to select hours';

  @override
  String get hintDragSelectDesc =>
      'Long press a cell and drag vertically to select multiple hours. Then tap \"Plan ride\" at the bottom.';

  @override
  String get hintTapSummary => 'Tap for weather summary';

  @override
  String get hintTapSummaryDesc =>
      'Tap a ride for a detailed hourly weather overview, score breakdown and wind advice.';

  @override
  String get hintSwipeDelete => 'Swipe to delete';

  @override
  String get hintSwipeDeleteDesc => 'Swipe a ride to the left to delete it.';

  @override
  String get hintDismiss => 'Tap to continue';

  @override
  String calendarEventTitle(String timeRange) {
    return 'Bike ride $timeRange';
  }

  @override
  String get calendarNoWeatherData => 'No weather data available';

  @override
  String get calendarDry => 'dry';

  @override
  String calendarWind(String speed) {
    return '${speed}km/h wind';
  }

  @override
  String get calendarSignInCanceled => 'Sign-in cancelled';

  @override
  String get notifEveningTitle => 'Great ride window tomorrow!';

  @override
  String notifEveningBody(String slot) {
    return '$slot — perfect conditions expected';
  }

  @override
  String get notifMorningTitle => 'Great ride window in 2 hours!';

  @override
  String notifMorningBody(String slot) {
    return '$slot — get ready to ride';
  }

  @override
  String get notifWeeklyTitle => 'Your ride overview for this week';

  @override
  String get notifChannelRideAlerts => 'Ride alerts';

  @override
  String get notifChannelRideAlertsDesc =>
      'Evening before and morning of ride alerts';

  @override
  String get notifChannelWeeklyDigest => 'Weekly overview';

  @override
  String get notifChannelWeeklyDigestDesc =>
      'Sunday evening overview of the best ride moments';

  @override
  String get widgetTierPerfect => 'Perfect';

  @override
  String get widgetTierGreat => 'Great';

  @override
  String get widgetTierAcceptable => 'Acceptable';

  @override
  String get widgetTierPoor => 'Poor';

  @override
  String get hourlyDry => 'dry';

  @override
  String get hourlyWindstil => 'calm';

  @override
  String hourlyFeelsLike(String temp) {
    return 'feels $temp°C';
  }

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String get importFromCalendar => 'Import from Google Calendar';

  @override
  String get legendCalendar => 'Calendar';

  @override
  String get calendarImportSuccess => 'Calendar events imported!';

  @override
  String get calendarImportError => 'Could not import calendar events';
}
