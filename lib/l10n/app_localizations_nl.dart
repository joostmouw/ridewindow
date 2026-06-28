// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class SNl extends S {
  SNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'RideWindow';

  @override
  String get navHome => 'Home';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navRides => 'Ritten';

  @override
  String get navProfile => 'Profiel';

  @override
  String get greetingNightOwl => 'Nachtuil';

  @override
  String get greetingMorning => 'Goedemorgen';

  @override
  String get greetingAfternoon => 'Goedemiddag';

  @override
  String get greetingEvening => 'Goedenavond';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String rideWindowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rijvensters',
      one: 'rijvenster',
    );
    return '$count $_temp0 deze week';
  }

  @override
  String updatedAt(String time) {
    return 'Bijgewerkt $time';
  }

  @override
  String get retryButton => 'Opnieuw proberen';

  @override
  String get thisWeek => 'KOMENDE DAGEN';

  @override
  String get rideTimes => 'RIJTIJDEN';

  @override
  String get plannedRidesLabel => 'GEPLAND';

  @override
  String get filterMorning => 'Ochtend';

  @override
  String get filterAfternoon => 'Middag';

  @override
  String get filterEvening => 'Avond';

  @override
  String get adjustTime => 'TIJD AANPASSEN';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'Eind';

  @override
  String get infoTemp =>
      'De groene zone toont je ideale temperatuurbereik. De stip toont de gemiddelde temperatuur voor dit rijvenster. Pas je bereik aan in Profiel.';

  @override
  String get infoRain =>
      'De groene zone toont je regentolerantie. De stip toont de verwachte totale neerslag. Minder regen = betere rit.';

  @override
  String get infoWind =>
      'De groene zone toont je windcomfortlimiet. De stip toont de gemiddelde windsnelheid. Harde wind maakt fietsen zwaarder en minder veilig.';

  @override
  String get dayMon => 'MA';

  @override
  String get dayTue => 'DI';

  @override
  String get dayWed => 'WO';

  @override
  String get dayThu => 'DO';

  @override
  String get dayFri => 'VR';

  @override
  String get daySat => 'ZA';

  @override
  String get daySun => 'ZO';

  @override
  String get dayMonFull => 'Maandag';

  @override
  String get dayTueFull => 'Dinsdag';

  @override
  String get dayWedFull => 'Woensdag';

  @override
  String get dayThuFull => 'Donderdag';

  @override
  String get dayFriFull => 'Vrijdag';

  @override
  String get daySatFull => 'Zaterdag';

  @override
  String get daySunFull => 'Zondag';

  @override
  String get dayMonLower => 'maandag';

  @override
  String get dayTueLower => 'dinsdag';

  @override
  String get dayWedLower => 'woensdag';

  @override
  String get dayThuLower => 'donderdag';

  @override
  String get dayFriLower => 'vrijdag';

  @override
  String get daySatLower => 'zaterdag';

  @override
  String get daySunLower => 'zondag';

  @override
  String get dayUnknown => 'onbekend';

  @override
  String get tierPerfect => 'Perfect';

  @override
  String get tierGreat => 'Goed';

  @override
  String get tierAcceptable => 'Acceptabel';

  @override
  String get tierPoor => 'Slecht';

  @override
  String get tierPerfectAgenda => 'Perfect';

  @override
  String get tierGreatAgenda => 'Geweldig';

  @override
  String get tierAcceptableAgenda => 'Oké';

  @override
  String get tierPoorAgenda => 'Slecht';

  @override
  String get legendPlanned => 'Gepland';

  @override
  String get bestChoice => 'Beste keuze';

  @override
  String get schedule => 'Inplannen';

  @override
  String get addToCalendar => 'Toevoegen aan agenda';

  @override
  String get addedToGoogleCalendar =>
      'Rijvenster toegevoegd aan Google Agenda!';

  @override
  String couldNotAdd(String error) {
    return 'Kon niet toevoegen: $error';
  }

  @override
  String get weatherLoadError => 'Weersdata kon niet worden geladen.';

  @override
  String get emptyBadWeather =>
      'Geen goede rijmomenten deze week. Slecht weer verwacht.';

  @override
  String get emptyAllBlocked =>
      'Alle goede momenten zijn geblokkeerd. Pas je schema aan.';

  @override
  String get emptyNoSlots => 'Geen rijmomenten gevonden.';

  @override
  String get emptyNoSlotsDay => 'Geen rijmomenten op deze dag.';

  @override
  String get windCalm => 'Windstil';

  @override
  String durationHours(int hours) {
    return '${hours}u';
  }

  @override
  String get welcomeTitle => 'Jouw perfecte rijmoment';

  @override
  String get welcomeSubtitle =>
      'Combineer het weerbericht met jouw agenda en ontdek de beste windows om te fietsen.';

  @override
  String get welcomeButton => 'Aan de slag →';

  @override
  String get onboardingTitle => 'Wanneer rijd jij het liefst?';

  @override
  String get onboardingSubtitle =>
      'Kies een schema om te beginnen. Je kunt dit later altijd aanpassen.';

  @override
  String get onboardingNext => 'Volgende →';

  @override
  String get presetEveningsWeekends => 'Avonden & weekenden';

  @override
  String get presetEveningsWeekendsSub => 'Ma–Vr na 17:00, Za/Zo de hele dag';

  @override
  String get presetMorningsWeekends => 'Ochtenden & weekenden';

  @override
  String get presetMorningsWeekendsSub =>
      'Ma–Vr 06:00–09:00, Za/Zo de hele dag';

  @override
  String get presetWeekendsOnly => 'Alleen weekenden';

  @override
  String get presetWeekendsOnlySub => 'Za/Zo de hele dag';

  @override
  String get presetCustom => 'Stel mijn eigen schema in';

  @override
  String get presetCustomSub => 'Ik pas mijn agenda zelf aan';

  @override
  String get profileTitle => 'Profiel';

  @override
  String get sectionLocation => 'LOCATIE';

  @override
  String get sectionNotifications => 'NOTIFICATIES';

  @override
  String get sectionTheme => 'THEMA';

  @override
  String get sectionTolerances => 'TOLERANTIES';

  @override
  String get sectionRideLength => 'RIJLENGTE';

  @override
  String get sectionName => 'NAAM';

  @override
  String get sectionAbout => 'OVER';

  @override
  String get sectionLanguage => 'TAAL';

  @override
  String get locationBlocked => 'Locatie-toegang geblokkeerd';

  @override
  String get locationBlockedHint =>
      'Kies een stad of open instellingen om GPS opnieuw in te schakelen.';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get useGpsLocation => 'GPS-locatie gebruiken';

  @override
  String get grantPermission => 'Toestemming geven';

  @override
  String get gpsAutomatic => 'GPS (automatisch)';

  @override
  String get tapToChooseCity => 'Tik om stad te kiezen';

  @override
  String get notifEveningBefore => 'Avond van tevoren';

  @override
  String get notifEveningBeforeSub =>
      '19:00 de vorige dag als er een top-slot is';

  @override
  String get notifMorningOf => 'Ochtend van de dag';

  @override
  String get notifMorningOfSub => '2 uur voor het slot begint';

  @override
  String get notifWeeklyDigest => 'Wekelijks overzicht';

  @override
  String get notifWeeklyDigestSub =>
      'Zondagavond 19:00 — beste momenten van de week';

  @override
  String get notifExactTimingWarning =>
      'Exacte timing niet gegarandeerd. Sta exacte alarmen toe in Instellingen voor betrouwbaarheid.';

  @override
  String get settingsLabel => 'Instellingen';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get toleranceTemperature => 'Temperatuur';

  @override
  String get toleranceMaxRain => 'Max. neerslag';

  @override
  String get toleranceMaxWind => 'Max. wind';

  @override
  String get toleranceTempInfoTitle => 'Temperatuurbereik';

  @override
  String get toleranceTempInfo =>
      'Stel je ideale fietstemperatuur in. Uren binnen dit bereik scoren 100 voor temperatuur. Buiten het bereik daalt de score geleidelijk — hoe verder van je bereik, hoe lager de score.\n\nEen breder bereik geeft meer rijvensters; een smaller bereik toont alleen je ideale omstandigheden.';

  @override
  String get toleranceRainInfoTitle => 'Regentolerantie';

  @override
  String get toleranceRainInfo =>
      'Stel de maximale neerslag per uur in waar je in wilt fietsen. Uren op of onder deze limiet scoren 100 voor regen. Boven de limiet daalt de score — meer regen betekent een lagere score.\n\nZet op 0 mm voor alleen droog weer, of hoger als je wat regen niet erg vindt.';

  @override
  String get toleranceWindInfoTitle => 'Windtolerantie';

  @override
  String get toleranceWindInfo =>
      'Stel de maximale windsnelheid in waar je comfortabel in fietst. Uren op of onder deze limiet scoren 100 voor wind. Boven de limiet daalt de score — hardere wind betekent een lagere score.\n\nEen hogere tolerantie geeft meer rijvensters, maar verwacht zwaarder fietsen.';

  @override
  String get tempDescAllWeather => 'Je fietst in bijna elk weer';

  @override
  String get tempDescComfortable => 'Comfortabel fietsbereik';

  @override
  String get tempDescNiceOnly => 'Alleen bij lekker weer';

  @override
  String get tempDescPerfectOnly => 'Alleen bij perfect weer';

  @override
  String get rainDescDryOnly => 'Alleen bij droog weer';

  @override
  String get rainDescDrizzleOk => 'Een beetje motregen is ok';

  @override
  String get rainDescLightRainOk => 'Lichte regen geen probleem';

  @override
  String get rainDescHeavyRainOk => 'Ook bij flinke buien';

  @override
  String get windDescCalmOnly => 'Alleen bij windstil weer';

  @override
  String get windDescBreezeOk => 'Rustig briesje is prima';

  @override
  String get windDescStrongOk => 'Stevige wind geen probleem';

  @override
  String get windDescHardWindOk => 'Zelfs bij harde wind';

  @override
  String get editMySchedule => 'Mijn schema bewerken';

  @override
  String get setYourName => 'Stel je naam in';

  @override
  String get nameHint =>
      'Tik om je naam in te voeren voor een persoonlijke begroeting';

  @override
  String get yourName => 'Jouw naam';

  @override
  String get enterYourName => 'Voer je naam in';

  @override
  String get cancel => 'Annuleer';

  @override
  String get save => 'Opslaan';

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get weatherDataAttribution => 'Weerdata door Open-Meteo.com';

  @override
  String get version => 'Versie';

  @override
  String get debugMenu => 'Debug Menu';

  @override
  String get debugResetOnboarding => 'Onboarding resetten';

  @override
  String get debugOnboardingReset => 'Onboarding gereset. Herstart de app.';

  @override
  String get debugClearWeather => 'Weerdata wissen';

  @override
  String get debugWeatherCleared => 'Weerdata gewist.';

  @override
  String get debugResetAvailability => 'Beschikbaarheid resetten';

  @override
  String get debugAvailabilityReset => 'Beschikbaarheid gereset.';

  @override
  String get debugRefreshWeather => 'Weer handmatig verversen';

  @override
  String get debugWeatherRefreshing => 'Weer wordt ververst.';

  @override
  String get detailTierPerfectDesc => 'Ideaal fietsweer';

  @override
  String get detailTierGreatDesc => 'Prettig fietsweer';

  @override
  String get detailTierAcceptableDesc => 'Te doen, pak een extra laag';

  @override
  String get detailTierPoorDesc => 'Niet ideaal, maar mogelijk';

  @override
  String get detailConditions => 'omstandigheden';

  @override
  String get weatherSection => 'WEER';

  @override
  String get weatherTemperature => 'Temperatuur';

  @override
  String get weatherRain => 'Neerslag';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherHourly => 'UURLIJKS';

  @override
  String feelsLike(String temp) {
    return 'voelt als $temp°C';
  }

  @override
  String get dry => 'Droog';

  @override
  String rainChance(String mm, String percent) {
    return '${mm}mm ($percent% kans)';
  }

  @override
  String windFrom(String speed, String direction) {
    return '${speed}km/u uit $direction';
  }

  @override
  String windPenalty(String pct) {
    return 'Wisselende windrichting (-$pct% op score)';
  }

  @override
  String get clothingTitle => 'Wat trek je aan';

  @override
  String get clothingWinterJacket => 'Winterjas';

  @override
  String get clothingThermalPants => 'Thermobroek';

  @override
  String get clothingGloves => 'Handschoenen';

  @override
  String get clothingOvershoes => 'Overschoenen';

  @override
  String get clothingLongSleeveJersey => 'Lange mouw jersey';

  @override
  String get clothingArmWarmers => 'Armwarmers';

  @override
  String get clothingLegWarmers => 'Beenwarmers';

  @override
  String get clothingKneeWarmers => 'Kniewarmers';

  @override
  String get clothingShortSleeveJersey => 'Korte mouw jersey';

  @override
  String get clothingArmWarmersJustInCase => 'Armwarmers voor de zekerheid';

  @override
  String get clothingLightShirt => 'Licht shirt';

  @override
  String get clothingSunscreen => 'Zonnebrand';

  @override
  String get clothingExtraWater => 'Extra water';

  @override
  String get clothingRainJacket => 'Regenjas';

  @override
  String get clothingWindVest => 'Windvest';

  @override
  String get planRide => 'Rit inplannen';

  @override
  String get ridePlanned => 'Rit ingepland!';

  @override
  String get addToGoogleCalendar => 'Toevoegen aan Google Agenda';

  @override
  String get remindEveningBefore => 'Herinner me de avond ervoor';

  @override
  String get reminderPlanned => 'Herinnering gepland voor de avond ervoor!';

  @override
  String get shareRideWindow => 'Deel dit rijvenster';

  @override
  String shareText(String day, String timeRange, String tier, String summary) {
    return 'Fietsrit $day $timeRange ($tier)\n$summary\n\nVia RideWindow';
  }

  @override
  String insightsTitle(String tier, String score) {
    return 'Waarom \'$tier\' — $score/100';
  }

  @override
  String get insightsTempIdeal => 'Ideaal';

  @override
  String get insightsTempAcceptable => 'Acceptabel';

  @override
  String get insightsTempExtreme => 'Koud/Warm';

  @override
  String get insightsRainDry => 'Droog';

  @override
  String get insightsRainLight => 'Licht';

  @override
  String get insightsRainWet => 'Nat';

  @override
  String get insightsWindCalm => 'Rustig';

  @override
  String get insightsWindModerate => 'Matig';

  @override
  String get insightsWindStrong => 'Sterk';

  @override
  String get insightsTempNoteIdeal => 'Ideale temperatuur — comfortabel rijden';

  @override
  String get insightsTempNoteAcceptable =>
      'Acceptabele temperatuur — pak een extra laag';

  @override
  String get insightsTempNoteExtreme =>
      'Buiten het ideale bereik — kleding aanpassen';

  @override
  String get insightsRainNoteDry => 'Droog — geen neerslag verwacht';

  @override
  String get insightsRainNoteLight =>
      'Lichte neerslag verwacht — spatborden handig';

  @override
  String get insightsRainNoteWet => 'Neerslag verwacht — overweeg een regenjas';

  @override
  String get insightsWindNoteCalm => 'Lichte wind — nauwelijks merkbaar';

  @override
  String get insightsWindNoteModerate => 'Matige wind — verwacht wat weerstand';

  @override
  String get insightsWindNoteStrong =>
      'Sterke wind — plan de route strategisch';

  @override
  String get totalScore => 'Totaalscore';

  @override
  String get understood => 'Begrijpen';

  @override
  String get availabilityTitle => 'Mijn schema';

  @override
  String get legendFree => 'Vrij';

  @override
  String get legendBusy => 'Bezet';

  @override
  String get legendWork => 'Werk';

  @override
  String get riderNoTime => 'Helemaal geen tijd?';

  @override
  String get riderNoTimeDesc =>
      'Maak wat uren vrij om je perfecte rijmomenten te vinden.';

  @override
  String get riderFulltime => 'Fulltime fietser';

  @override
  String get riderFulltimeDesc =>
      'Je schema staat wagenwijd open. Genoeg keuze uit de beste momenten.';

  @override
  String get riderWeekend => 'Weekendstrijder';

  @override
  String get riderWeekendDesc =>
      'Het weekend is jouw speeltuin. We vinden de beste zaterdag- en zondagvensters.';

  @override
  String get riderEarlyBird => 'Vroege vogel';

  @override
  String get riderEarlyBirdDesc =>
      'Je fietst voordat de wereld wakker wordt. Ochtendslots zijn jouw sweet spot.';

  @override
  String get riderAfterWork => 'Na-werk fietser';

  @override
  String get riderAfterWorkDesc =>
      'De avond is jouw ontsnapping. We zoeken de beste avondvensters met het mooiste weer.';

  @override
  String get riderAfternoon => 'Middagfietser';

  @override
  String get riderAfternoonDesc =>
      'Je pakt de beste uren van de dag. Middagslots worden jouw ideale momenten.';

  @override
  String get riderBusy => 'Druk maar doorzetter';

  @override
  String get riderBusyDesc =>
      'Krap schema, maar elke rit telt. We vinden de pareltjes in je vrije uren.';

  @override
  String get riderFlexible => 'Flexibele fietser';

  @override
  String get riderFlexibleDesc =>
      'Een mooie mix van vrije tijd door de week. Je hebt altijd opties.';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaCancel => 'Annuleer';

  @override
  String get agendaBusy => 'Bezet';

  @override
  String agendaHoursSelected(int count) {
    return '$count uur geselecteerd';
  }

  @override
  String agendaPlanRide(int count) {
    return 'Rit inplannen (${count}u)';
  }

  @override
  String agendaRidePlanned(int count) {
    return 'Rit ingepland (${count}u)!';
  }

  @override
  String get agendaNow => 'Nu';

  @override
  String get agendaScoreBreakdown => 'Score-opbouw';

  @override
  String get agendaRain => 'Regen';

  @override
  String get agendaViewDetails => 'Bekijk details';

  @override
  String get ridesTitle => 'Mijn Ritten';

  @override
  String get ridesEmpty => 'Nog geen ritten gepland';

  @override
  String get ridesEmptyHint =>
      'Plan een rit vanuit Home of selecteer uren in de Agenda.';

  @override
  String get rideRemoved => 'Rit verwijderd';

  @override
  String rideSincePlanning(String delta) {
    return '$delta sinds planning';
  }

  @override
  String get ridesPerHour => 'Per uur';

  @override
  String get ridesAvgScoreBreakdown => 'Gemiddelde score-opbouw';

  @override
  String get ridesDeleteRide => 'Rit verwijderen';

  @override
  String ridesWindFrom(String direction, String advice) {
    return 'Wind uit $direction. $advice.';
  }

  @override
  String get tailwindNorth => 'Fiets noordwaarts voor wind mee terug';

  @override
  String get tailwindNortheast => 'Fiets noordoostwaarts voor wind mee terug';

  @override
  String get tailwindEast => 'Fiets oostwaarts voor wind mee terug';

  @override
  String get tailwindSoutheast => 'Fiets zuidoostwaarts voor wind mee terug';

  @override
  String get tailwindSouth => 'Fiets zuidwaarts voor wind mee terug';

  @override
  String get tailwindSouthwest => 'Fiets zuidwestwaarts voor wind mee terug';

  @override
  String get tailwindWest => 'Fiets westwaarts voor wind mee terug';

  @override
  String get tailwindNorthwest => 'Fiets noordwestwaarts voor wind mee terug';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NO';

  @override
  String get compassE => 'O';

  @override
  String get compassSE => 'ZO';

  @override
  String get compassS => 'Z';

  @override
  String get compassSW => 'ZW';

  @override
  String get compassW => 'W';

  @override
  String get compassNW => 'NW';

  @override
  String get hintTapRideWindow => 'Tik op een rijvenster';

  @override
  String get hintTapRideWindowDesc =>
      'Bekijk weerdetails, plan de rit in of voeg toe aan Google Agenda.';

  @override
  String get hintFilterDay => 'Filter op dag';

  @override
  String get hintFilterDayDesc =>
      'Tik op een dag bovenaan om alleen die dag te zien.';

  @override
  String get hintFilterPeriod => 'Filter op dagdeel';

  @override
  String get hintFilterPeriodDesc =>
      'Kies ochtend, middag of avond om ritten voor dat dagdeel te tonen.';

  @override
  String get hintTapWeatherDetail => 'Tik voor weerdetails';

  @override
  String get hintTapWeatherDetailDesc =>
      'Tik op een gekleurd uurvak om temperatuur, regen en wind te bekijken.';

  @override
  String get hintDragSelect => 'Sleep om uren te selecteren';

  @override
  String get hintDragSelectDesc =>
      'Houd een vak ingedrukt en sleep verticaal om meerdere uren te selecteren. Tik daarna op \"Rit inplannen\" onderaan.';

  @override
  String get hintTapSummary => 'Tik voor weersamenvatting';

  @override
  String get hintTapSummaryDesc =>
      'Tik op een rit voor een uitgebreid weeroverzicht per uur, score-opbouw en windadvies.';

  @override
  String get hintSwipeDelete => 'Swipe om te verwijderen';

  @override
  String get hintSwipeDeleteDesc =>
      'Veeg een rit naar links om hem te verwijderen.';

  @override
  String get hintDismiss => 'Tik om te sluiten';

  @override
  String get hintNext => 'Tik voor volgende';

  @override
  String calendarEventTitle(String timeRange) {
    return 'Fietsrit $timeRange';
  }

  @override
  String get calendarNoWeatherData => 'Geen weerdata beschikbaar';

  @override
  String get calendarDry => 'droog';

  @override
  String calendarWind(String speed) {
    return '${speed}km/u wind';
  }

  @override
  String get calendarSignInCanceled => 'Aanmelden geannuleerd';

  @override
  String get notifEveningTitle => 'Top rijmoment morgen!';

  @override
  String notifEveningBody(String slot) {
    return '$slot — perfecte omstandigheden verwacht';
  }

  @override
  String get notifMorningTitle => 'Over 2 uur een top rijmoment!';

  @override
  String notifMorningBody(String slot) {
    return '$slot — maak je klaar om te rijden';
  }

  @override
  String get notifWeeklyTitle => 'Je rijoverzicht voor deze week';

  @override
  String get notifChannelRideAlerts => 'Rijmeldingen';

  @override
  String get notifChannelRideAlertsDesc =>
      'Avond-van-tevoren en ochtend-van-de-dag rijmeldingen';

  @override
  String get notifChannelWeeklyDigest => 'Wekelijks overzicht';

  @override
  String get notifChannelWeeklyDigestDesc =>
      'Zondagavond overzicht van de beste rijmomenten';

  @override
  String get widgetTierPerfect => 'Perfect';

  @override
  String get widgetTierGreat => 'Geweldig';

  @override
  String get widgetTierAcceptable => 'Acceptabel';

  @override
  String get widgetTierPoor => 'Slecht';

  @override
  String get hourlyDry => 'droog';

  @override
  String get hourlyWindstil => 'windstil';

  @override
  String hourlyFeelsLike(String temp) {
    return 'v.a. $temp°C';
  }

  @override
  String get dayShortMon => 'Ma';

  @override
  String get dayShortTue => 'Di';

  @override
  String get dayShortWed => 'Wo';

  @override
  String get dayShortThu => 'Do';

  @override
  String get dayShortFri => 'Vr';

  @override
  String get dayShortSat => 'Za';

  @override
  String get dayShortSun => 'Zo';

  @override
  String get importFromCalendar => 'Importeer uit Google Agenda';

  @override
  String get legendCalendar => 'Agenda';

  @override
  String get calendarImportSuccess => 'Agenda-afspraken geimporteerd!';

  @override
  String get calendarImportError => 'Kon agenda-afspraken niet importeren';
}
