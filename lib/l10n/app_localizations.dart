import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl')
  ];

  /// No description provided for @appTitle.
  ///
  /// In nl, this message translates to:
  /// **'RideWindow'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In nl, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAgenda.
  ///
  /// In nl, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navRides.
  ///
  /// In nl, this message translates to:
  /// **'Ritten'**
  String get navRides;

  /// No description provided for @navProfile.
  ///
  /// In nl, this message translates to:
  /// **'Profiel'**
  String get navProfile;

  /// No description provided for @greetingNightOwl.
  ///
  /// In nl, this message translates to:
  /// **'Nachtuil'**
  String get greetingNightOwl;

  /// No description provided for @greetingMorning.
  ///
  /// In nl, this message translates to:
  /// **'Goedemorgen'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In nl, this message translates to:
  /// **'Goedemiddag'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In nl, this message translates to:
  /// **'Goedenavond'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In nl, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @rideWindowCount.
  ///
  /// In nl, this message translates to:
  /// **'{count} {count, plural, =1{rijvenster} other{rijvensters}} deze week'**
  String rideWindowCount(int count);

  /// No description provided for @updatedAt.
  ///
  /// In nl, this message translates to:
  /// **'Bijgewerkt {time}'**
  String updatedAt(String time);

  /// No description provided for @retryButton.
  ///
  /// In nl, this message translates to:
  /// **'Opnieuw proberen'**
  String get retryButton;

  /// No description provided for @thisWeek.
  ///
  /// In nl, this message translates to:
  /// **'KOMENDE DAGEN'**
  String get thisWeek;

  /// No description provided for @rideTimes.
  ///
  /// In nl, this message translates to:
  /// **'RIJTIJDEN'**
  String get rideTimes;

  /// No description provided for @filterMorning.
  ///
  /// In nl, this message translates to:
  /// **'Ochtend'**
  String get filterMorning;

  /// No description provided for @filterAfternoon.
  ///
  /// In nl, this message translates to:
  /// **'Middag'**
  String get filterAfternoon;

  /// No description provided for @filterEvening.
  ///
  /// In nl, this message translates to:
  /// **'Avond'**
  String get filterEvening;

  /// No description provided for @adjustTime.
  ///
  /// In nl, this message translates to:
  /// **'TIJD AANPASSEN'**
  String get adjustTime;

  /// No description provided for @startLabel.
  ///
  /// In nl, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In nl, this message translates to:
  /// **'Eind'**
  String get endLabel;

  /// No description provided for @infoTemp.
  ///
  /// In nl, this message translates to:
  /// **'De groene zone toont je ideale temperatuurbereik. De stip toont de gemiddelde temperatuur voor dit rijvenster. Pas je bereik aan in Profiel.'**
  String get infoTemp;

  /// No description provided for @infoRain.
  ///
  /// In nl, this message translates to:
  /// **'De groene zone toont je regentolerantie. De stip toont de verwachte totale neerslag. Minder regen = betere rit.'**
  String get infoRain;

  /// No description provided for @infoWind.
  ///
  /// In nl, this message translates to:
  /// **'De groene zone toont je windcomfortlimiet. De stip toont de gemiddelde windsnelheid. Harde wind maakt fietsen zwaarder en minder veilig.'**
  String get infoWind;

  /// No description provided for @dayMon.
  ///
  /// In nl, this message translates to:
  /// **'MA'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In nl, this message translates to:
  /// **'DI'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In nl, this message translates to:
  /// **'WO'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In nl, this message translates to:
  /// **'DO'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In nl, this message translates to:
  /// **'VR'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In nl, this message translates to:
  /// **'ZA'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In nl, this message translates to:
  /// **'ZO'**
  String get daySun;

  /// No description provided for @dayMonFull.
  ///
  /// In nl, this message translates to:
  /// **'Maandag'**
  String get dayMonFull;

  /// No description provided for @dayTueFull.
  ///
  /// In nl, this message translates to:
  /// **'Dinsdag'**
  String get dayTueFull;

  /// No description provided for @dayWedFull.
  ///
  /// In nl, this message translates to:
  /// **'Woensdag'**
  String get dayWedFull;

  /// No description provided for @dayThuFull.
  ///
  /// In nl, this message translates to:
  /// **'Donderdag'**
  String get dayThuFull;

  /// No description provided for @dayFriFull.
  ///
  /// In nl, this message translates to:
  /// **'Vrijdag'**
  String get dayFriFull;

  /// No description provided for @daySatFull.
  ///
  /// In nl, this message translates to:
  /// **'Zaterdag'**
  String get daySatFull;

  /// No description provided for @daySunFull.
  ///
  /// In nl, this message translates to:
  /// **'Zondag'**
  String get daySunFull;

  /// No description provided for @dayMonLower.
  ///
  /// In nl, this message translates to:
  /// **'maandag'**
  String get dayMonLower;

  /// No description provided for @dayTueLower.
  ///
  /// In nl, this message translates to:
  /// **'dinsdag'**
  String get dayTueLower;

  /// No description provided for @dayWedLower.
  ///
  /// In nl, this message translates to:
  /// **'woensdag'**
  String get dayWedLower;

  /// No description provided for @dayThuLower.
  ///
  /// In nl, this message translates to:
  /// **'donderdag'**
  String get dayThuLower;

  /// No description provided for @dayFriLower.
  ///
  /// In nl, this message translates to:
  /// **'vrijdag'**
  String get dayFriLower;

  /// No description provided for @daySatLower.
  ///
  /// In nl, this message translates to:
  /// **'zaterdag'**
  String get daySatLower;

  /// No description provided for @daySunLower.
  ///
  /// In nl, this message translates to:
  /// **'zondag'**
  String get daySunLower;

  /// No description provided for @dayUnknown.
  ///
  /// In nl, this message translates to:
  /// **'onbekend'**
  String get dayUnknown;

  /// No description provided for @tierPerfect.
  ///
  /// In nl, this message translates to:
  /// **'Perfect'**
  String get tierPerfect;

  /// No description provided for @tierGreat.
  ///
  /// In nl, this message translates to:
  /// **'Goed'**
  String get tierGreat;

  /// No description provided for @tierAcceptable.
  ///
  /// In nl, this message translates to:
  /// **'Acceptabel'**
  String get tierAcceptable;

  /// No description provided for @tierPoor.
  ///
  /// In nl, this message translates to:
  /// **'Slecht'**
  String get tierPoor;

  /// No description provided for @tierPerfectAgenda.
  ///
  /// In nl, this message translates to:
  /// **'Perfect'**
  String get tierPerfectAgenda;

  /// No description provided for @tierGreatAgenda.
  ///
  /// In nl, this message translates to:
  /// **'Geweldig'**
  String get tierGreatAgenda;

  /// No description provided for @tierAcceptableAgenda.
  ///
  /// In nl, this message translates to:
  /// **'Oké'**
  String get tierAcceptableAgenda;

  /// No description provided for @tierPoorAgenda.
  ///
  /// In nl, this message translates to:
  /// **'Slecht'**
  String get tierPoorAgenda;

  /// No description provided for @legendPlanned.
  ///
  /// In nl, this message translates to:
  /// **'Gepland'**
  String get legendPlanned;

  /// No description provided for @bestChoice.
  ///
  /// In nl, this message translates to:
  /// **'Beste keuze'**
  String get bestChoice;

  /// No description provided for @schedule.
  ///
  /// In nl, this message translates to:
  /// **'Inplannen'**
  String get schedule;

  /// No description provided for @addToCalendar.
  ///
  /// In nl, this message translates to:
  /// **'Toevoegen aan agenda'**
  String get addToCalendar;

  /// No description provided for @addedToGoogleCalendar.
  ///
  /// In nl, this message translates to:
  /// **'Rijvenster toegevoegd aan Google Agenda!'**
  String get addedToGoogleCalendar;

  /// No description provided for @couldNotAdd.
  ///
  /// In nl, this message translates to:
  /// **'Kon niet toevoegen: {error}'**
  String couldNotAdd(String error);

  /// No description provided for @weatherLoadError.
  ///
  /// In nl, this message translates to:
  /// **'Weersdata kon niet worden geladen.'**
  String get weatherLoadError;

  /// No description provided for @emptyBadWeather.
  ///
  /// In nl, this message translates to:
  /// **'Geen goede rijmomenten deze week. Slecht weer verwacht.'**
  String get emptyBadWeather;

  /// No description provided for @emptyAllBlocked.
  ///
  /// In nl, this message translates to:
  /// **'Alle goede momenten zijn geblokkeerd. Pas je schema aan.'**
  String get emptyAllBlocked;

  /// No description provided for @emptyNoSlots.
  ///
  /// In nl, this message translates to:
  /// **'Geen rijmomenten gevonden.'**
  String get emptyNoSlots;

  /// No description provided for @emptyNoSlotsDay.
  ///
  /// In nl, this message translates to:
  /// **'Geen rijmomenten op deze dag.'**
  String get emptyNoSlotsDay;

  /// No description provided for @windCalm.
  ///
  /// In nl, this message translates to:
  /// **'Windstil'**
  String get windCalm;

  /// No description provided for @durationHours.
  ///
  /// In nl, this message translates to:
  /// **'{hours}u'**
  String durationHours(int hours);

  /// No description provided for @welcomeTitle.
  ///
  /// In nl, this message translates to:
  /// **'Jouw perfecte rijmoment'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In nl, this message translates to:
  /// **'Combineer het weerbericht met jouw agenda en ontdek de beste windows om te fietsen.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeButton.
  ///
  /// In nl, this message translates to:
  /// **'Aan de slag →'**
  String get welcomeButton;

  /// No description provided for @onboardingTitle.
  ///
  /// In nl, this message translates to:
  /// **'Wanneer rijd jij het liefst?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In nl, this message translates to:
  /// **'Kies een schema om te beginnen. Je kunt dit later altijd aanpassen.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingNext.
  ///
  /// In nl, this message translates to:
  /// **'Volgende →'**
  String get onboardingNext;

  /// No description provided for @presetEveningsWeekends.
  ///
  /// In nl, this message translates to:
  /// **'Avonden & weekenden'**
  String get presetEveningsWeekends;

  /// No description provided for @presetEveningsWeekendsSub.
  ///
  /// In nl, this message translates to:
  /// **'Ma–Vr na 17:00, Za/Zo de hele dag'**
  String get presetEveningsWeekendsSub;

  /// No description provided for @presetMorningsWeekends.
  ///
  /// In nl, this message translates to:
  /// **'Ochtenden & weekenden'**
  String get presetMorningsWeekends;

  /// No description provided for @presetMorningsWeekendsSub.
  ///
  /// In nl, this message translates to:
  /// **'Ma–Vr 06:00–09:00, Za/Zo de hele dag'**
  String get presetMorningsWeekendsSub;

  /// No description provided for @presetWeekendsOnly.
  ///
  /// In nl, this message translates to:
  /// **'Alleen weekenden'**
  String get presetWeekendsOnly;

  /// No description provided for @presetWeekendsOnlySub.
  ///
  /// In nl, this message translates to:
  /// **'Za/Zo de hele dag'**
  String get presetWeekendsOnlySub;

  /// No description provided for @presetCustom.
  ///
  /// In nl, this message translates to:
  /// **'Stel mijn eigen schema in'**
  String get presetCustom;

  /// No description provided for @presetCustomSub.
  ///
  /// In nl, this message translates to:
  /// **'Ik pas mijn agenda zelf aan'**
  String get presetCustomSub;

  /// No description provided for @profileTitle.
  ///
  /// In nl, this message translates to:
  /// **'Profiel'**
  String get profileTitle;

  /// No description provided for @sectionLocation.
  ///
  /// In nl, this message translates to:
  /// **'LOCATIE'**
  String get sectionLocation;

  /// No description provided for @sectionNotifications.
  ///
  /// In nl, this message translates to:
  /// **'NOTIFICATIES'**
  String get sectionNotifications;

  /// No description provided for @sectionTheme.
  ///
  /// In nl, this message translates to:
  /// **'THEMA'**
  String get sectionTheme;

  /// No description provided for @sectionTolerances.
  ///
  /// In nl, this message translates to:
  /// **'TOLERANTIES'**
  String get sectionTolerances;

  /// No description provided for @sectionRideLength.
  ///
  /// In nl, this message translates to:
  /// **'RIJLENGTE'**
  String get sectionRideLength;

  /// No description provided for @sectionName.
  ///
  /// In nl, this message translates to:
  /// **'NAAM'**
  String get sectionName;

  /// No description provided for @sectionAbout.
  ///
  /// In nl, this message translates to:
  /// **'OVER'**
  String get sectionAbout;

  /// No description provided for @sectionLanguage.
  ///
  /// In nl, this message translates to:
  /// **'TAAL'**
  String get sectionLanguage;

  /// No description provided for @locationBlocked.
  ///
  /// In nl, this message translates to:
  /// **'Locatie-toegang geblokkeerd'**
  String get locationBlocked;

  /// No description provided for @locationBlockedHint.
  ///
  /// In nl, this message translates to:
  /// **'Kies een stad of open instellingen om GPS opnieuw in te schakelen.'**
  String get locationBlockedHint;

  /// No description provided for @openSettings.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen openen'**
  String get openSettings;

  /// No description provided for @useGpsLocation.
  ///
  /// In nl, this message translates to:
  /// **'GPS-locatie gebruiken'**
  String get useGpsLocation;

  /// No description provided for @grantPermission.
  ///
  /// In nl, this message translates to:
  /// **'Toestemming geven'**
  String get grantPermission;

  /// No description provided for @gpsAutomatic.
  ///
  /// In nl, this message translates to:
  /// **'GPS (automatisch)'**
  String get gpsAutomatic;

  /// No description provided for @tapToChooseCity.
  ///
  /// In nl, this message translates to:
  /// **'Tik om stad te kiezen'**
  String get tapToChooseCity;

  /// No description provided for @notifEveningBefore.
  ///
  /// In nl, this message translates to:
  /// **'Avond van tevoren'**
  String get notifEveningBefore;

  /// No description provided for @notifEveningBeforeSub.
  ///
  /// In nl, this message translates to:
  /// **'19:00 de vorige dag als er een top-slot is'**
  String get notifEveningBeforeSub;

  /// No description provided for @notifMorningOf.
  ///
  /// In nl, this message translates to:
  /// **'Ochtend van de dag'**
  String get notifMorningOf;

  /// No description provided for @notifMorningOfSub.
  ///
  /// In nl, this message translates to:
  /// **'2 uur voor het slot begint'**
  String get notifMorningOfSub;

  /// No description provided for @notifWeeklyDigest.
  ///
  /// In nl, this message translates to:
  /// **'Wekelijks overzicht'**
  String get notifWeeklyDigest;

  /// No description provided for @notifWeeklyDigestSub.
  ///
  /// In nl, this message translates to:
  /// **'Zondagavond 19:00 — beste momenten van de week'**
  String get notifWeeklyDigestSub;

  /// No description provided for @notifExactTimingWarning.
  ///
  /// In nl, this message translates to:
  /// **'Exacte timing niet gegarandeerd. Sta exacte alarmen toe in Instellingen voor betrouwbaarheid.'**
  String get notifExactTimingWarning;

  /// No description provided for @settingsLabel.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get settingsLabel;

  /// No description provided for @themeSystem.
  ///
  /// In nl, this message translates to:
  /// **'Systeem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In nl, this message translates to:
  /// **'Licht'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In nl, this message translates to:
  /// **'Donker'**
  String get themeDark;

  /// No description provided for @toleranceTemperature.
  ///
  /// In nl, this message translates to:
  /// **'Temperatuur'**
  String get toleranceTemperature;

  /// No description provided for @toleranceMaxRain.
  ///
  /// In nl, this message translates to:
  /// **'Max. neerslag'**
  String get toleranceMaxRain;

  /// No description provided for @toleranceMaxWind.
  ///
  /// In nl, this message translates to:
  /// **'Max. wind'**
  String get toleranceMaxWind;

  /// No description provided for @tempDescAllWeather.
  ///
  /// In nl, this message translates to:
  /// **'Je fietst in bijna elk weer'**
  String get tempDescAllWeather;

  /// No description provided for @tempDescComfortable.
  ///
  /// In nl, this message translates to:
  /// **'Comfortabel fietsbereik'**
  String get tempDescComfortable;

  /// No description provided for @tempDescNiceOnly.
  ///
  /// In nl, this message translates to:
  /// **'Alleen bij lekker weer'**
  String get tempDescNiceOnly;

  /// No description provided for @tempDescPerfectOnly.
  ///
  /// In nl, this message translates to:
  /// **'Alleen bij perfect weer'**
  String get tempDescPerfectOnly;

  /// No description provided for @rainDescDryOnly.
  ///
  /// In nl, this message translates to:
  /// **'Alleen bij droog weer'**
  String get rainDescDryOnly;

  /// No description provided for @rainDescDrizzleOk.
  ///
  /// In nl, this message translates to:
  /// **'Een beetje motregen is ok'**
  String get rainDescDrizzleOk;

  /// No description provided for @rainDescLightRainOk.
  ///
  /// In nl, this message translates to:
  /// **'Lichte regen geen probleem'**
  String get rainDescLightRainOk;

  /// No description provided for @rainDescHeavyRainOk.
  ///
  /// In nl, this message translates to:
  /// **'Ook bij flinke buien'**
  String get rainDescHeavyRainOk;

  /// No description provided for @windDescCalmOnly.
  ///
  /// In nl, this message translates to:
  /// **'Alleen bij windstil weer'**
  String get windDescCalmOnly;

  /// No description provided for @windDescBreezeOk.
  ///
  /// In nl, this message translates to:
  /// **'Rustig briesje is prima'**
  String get windDescBreezeOk;

  /// No description provided for @windDescStrongOk.
  ///
  /// In nl, this message translates to:
  /// **'Stevige wind geen probleem'**
  String get windDescStrongOk;

  /// No description provided for @windDescHardWindOk.
  ///
  /// In nl, this message translates to:
  /// **'Zelfs bij harde wind'**
  String get windDescHardWindOk;

  /// No description provided for @editMySchedule.
  ///
  /// In nl, this message translates to:
  /// **'Mijn schema bewerken'**
  String get editMySchedule;

  /// No description provided for @setYourName.
  ///
  /// In nl, this message translates to:
  /// **'Stel je naam in'**
  String get setYourName;

  /// No description provided for @nameHint.
  ///
  /// In nl, this message translates to:
  /// **'Tik om je naam in te voeren voor een persoonlijke begroeting'**
  String get nameHint;

  /// No description provided for @yourName.
  ///
  /// In nl, this message translates to:
  /// **'Jouw naam'**
  String get yourName;

  /// No description provided for @enterYourName.
  ///
  /// In nl, this message translates to:
  /// **'Voer je naam in'**
  String get enterYourName;

  /// No description provided for @cancel.
  ///
  /// In nl, this message translates to:
  /// **'Annuleer'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get save;

  /// No description provided for @privacyPolicy.
  ///
  /// In nl, this message translates to:
  /// **'Privacybeleid'**
  String get privacyPolicy;

  /// No description provided for @version.
  ///
  /// In nl, this message translates to:
  /// **'Versie'**
  String get version;

  /// No description provided for @debugMenu.
  ///
  /// In nl, this message translates to:
  /// **'Debug Menu'**
  String get debugMenu;

  /// No description provided for @debugResetOnboarding.
  ///
  /// In nl, this message translates to:
  /// **'Onboarding resetten'**
  String get debugResetOnboarding;

  /// No description provided for @debugOnboardingReset.
  ///
  /// In nl, this message translates to:
  /// **'Onboarding gereset. Herstart de app.'**
  String get debugOnboardingReset;

  /// No description provided for @debugClearWeather.
  ///
  /// In nl, this message translates to:
  /// **'Weerdata wissen'**
  String get debugClearWeather;

  /// No description provided for @debugWeatherCleared.
  ///
  /// In nl, this message translates to:
  /// **'Weerdata gewist.'**
  String get debugWeatherCleared;

  /// No description provided for @debugResetAvailability.
  ///
  /// In nl, this message translates to:
  /// **'Beschikbaarheid resetten'**
  String get debugResetAvailability;

  /// No description provided for @debugAvailabilityReset.
  ///
  /// In nl, this message translates to:
  /// **'Beschikbaarheid gereset.'**
  String get debugAvailabilityReset;

  /// No description provided for @debugRefreshWeather.
  ///
  /// In nl, this message translates to:
  /// **'Weer handmatig verversen'**
  String get debugRefreshWeather;

  /// No description provided for @debugWeatherRefreshing.
  ///
  /// In nl, this message translates to:
  /// **'Weer wordt ververst.'**
  String get debugWeatherRefreshing;

  /// No description provided for @detailTierPerfectDesc.
  ///
  /// In nl, this message translates to:
  /// **'Ideaal fietsweer'**
  String get detailTierPerfectDesc;

  /// No description provided for @detailTierGreatDesc.
  ///
  /// In nl, this message translates to:
  /// **'Prettig fietsweer'**
  String get detailTierGreatDesc;

  /// No description provided for @detailTierAcceptableDesc.
  ///
  /// In nl, this message translates to:
  /// **'Te doen, pak een extra laag'**
  String get detailTierAcceptableDesc;

  /// No description provided for @detailTierPoorDesc.
  ///
  /// In nl, this message translates to:
  /// **'Niet ideaal, maar mogelijk'**
  String get detailTierPoorDesc;

  /// No description provided for @detailConditions.
  ///
  /// In nl, this message translates to:
  /// **'omstandigheden'**
  String get detailConditions;

  /// No description provided for @weatherSection.
  ///
  /// In nl, this message translates to:
  /// **'WEER'**
  String get weatherSection;

  /// No description provided for @weatherTemperature.
  ///
  /// In nl, this message translates to:
  /// **'Temperatuur'**
  String get weatherTemperature;

  /// No description provided for @weatherRain.
  ///
  /// In nl, this message translates to:
  /// **'Neerslag'**
  String get weatherRain;

  /// No description provided for @weatherWind.
  ///
  /// In nl, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherHourly.
  ///
  /// In nl, this message translates to:
  /// **'UURLIJKS'**
  String get weatherHourly;

  /// No description provided for @feelsLike.
  ///
  /// In nl, this message translates to:
  /// **'voelt als {temp}°C'**
  String feelsLike(String temp);

  /// No description provided for @dry.
  ///
  /// In nl, this message translates to:
  /// **'Droog'**
  String get dry;

  /// No description provided for @rainChance.
  ///
  /// In nl, this message translates to:
  /// **'{mm}mm ({percent}% kans)'**
  String rainChance(String mm, String percent);

  /// No description provided for @windFrom.
  ///
  /// In nl, this message translates to:
  /// **'{speed}km/u uit {direction}'**
  String windFrom(String speed, String direction);

  /// No description provided for @windPenalty.
  ///
  /// In nl, this message translates to:
  /// **'Wisselende windrichting (-{pct}% op score)'**
  String windPenalty(String pct);

  /// No description provided for @clothingTitle.
  ///
  /// In nl, this message translates to:
  /// **'Wat trek je aan'**
  String get clothingTitle;

  /// No description provided for @clothingWinterJacket.
  ///
  /// In nl, this message translates to:
  /// **'Winterjas'**
  String get clothingWinterJacket;

  /// No description provided for @clothingThermalPants.
  ///
  /// In nl, this message translates to:
  /// **'Thermobroek'**
  String get clothingThermalPants;

  /// No description provided for @clothingGloves.
  ///
  /// In nl, this message translates to:
  /// **'Handschoenen'**
  String get clothingGloves;

  /// No description provided for @clothingOvershoes.
  ///
  /// In nl, this message translates to:
  /// **'Overschoenen'**
  String get clothingOvershoes;

  /// No description provided for @clothingLongSleeveJersey.
  ///
  /// In nl, this message translates to:
  /// **'Lange mouw jersey'**
  String get clothingLongSleeveJersey;

  /// No description provided for @clothingArmWarmers.
  ///
  /// In nl, this message translates to:
  /// **'Armwarmers'**
  String get clothingArmWarmers;

  /// No description provided for @clothingLegWarmers.
  ///
  /// In nl, this message translates to:
  /// **'Beenwarmers'**
  String get clothingLegWarmers;

  /// No description provided for @clothingKneeWarmers.
  ///
  /// In nl, this message translates to:
  /// **'Kniewarmers'**
  String get clothingKneeWarmers;

  /// No description provided for @clothingShortSleeveJersey.
  ///
  /// In nl, this message translates to:
  /// **'Korte mouw jersey'**
  String get clothingShortSleeveJersey;

  /// No description provided for @clothingArmWarmersJustInCase.
  ///
  /// In nl, this message translates to:
  /// **'Armwarmers voor de zekerheid'**
  String get clothingArmWarmersJustInCase;

  /// No description provided for @clothingLightShirt.
  ///
  /// In nl, this message translates to:
  /// **'Licht shirt'**
  String get clothingLightShirt;

  /// No description provided for @clothingSunscreen.
  ///
  /// In nl, this message translates to:
  /// **'Zonnebrand'**
  String get clothingSunscreen;

  /// No description provided for @clothingExtraWater.
  ///
  /// In nl, this message translates to:
  /// **'Extra water'**
  String get clothingExtraWater;

  /// No description provided for @clothingRainJacket.
  ///
  /// In nl, this message translates to:
  /// **'Regenjas'**
  String get clothingRainJacket;

  /// No description provided for @clothingWindVest.
  ///
  /// In nl, this message translates to:
  /// **'Windvest'**
  String get clothingWindVest;

  /// No description provided for @planRide.
  ///
  /// In nl, this message translates to:
  /// **'Rit inplannen'**
  String get planRide;

  /// No description provided for @ridePlanned.
  ///
  /// In nl, this message translates to:
  /// **'Rit ingepland!'**
  String get ridePlanned;

  /// No description provided for @addToGoogleCalendar.
  ///
  /// In nl, this message translates to:
  /// **'Toevoegen aan Google Agenda'**
  String get addToGoogleCalendar;

  /// No description provided for @remindEveningBefore.
  ///
  /// In nl, this message translates to:
  /// **'Herinner me de avond ervoor'**
  String get remindEveningBefore;

  /// No description provided for @reminderPlanned.
  ///
  /// In nl, this message translates to:
  /// **'Herinnering gepland voor de avond ervoor!'**
  String get reminderPlanned;

  /// No description provided for @shareRideWindow.
  ///
  /// In nl, this message translates to:
  /// **'Deel dit rijvenster'**
  String get shareRideWindow;

  /// No description provided for @shareText.
  ///
  /// In nl, this message translates to:
  /// **'Fietsrit {day} {timeRange} ({tier})\n{summary}\n\nVia RideWindow'**
  String shareText(String day, String timeRange, String tier, String summary);

  /// No description provided for @insightsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Waarom \'{tier}\' — {score}/100'**
  String insightsTitle(String tier, String score);

  /// No description provided for @insightsTempIdeal.
  ///
  /// In nl, this message translates to:
  /// **'Ideaal'**
  String get insightsTempIdeal;

  /// No description provided for @insightsTempAcceptable.
  ///
  /// In nl, this message translates to:
  /// **'Acceptabel'**
  String get insightsTempAcceptable;

  /// No description provided for @insightsTempExtreme.
  ///
  /// In nl, this message translates to:
  /// **'Koud/Warm'**
  String get insightsTempExtreme;

  /// No description provided for @insightsRainDry.
  ///
  /// In nl, this message translates to:
  /// **'Droog'**
  String get insightsRainDry;

  /// No description provided for @insightsRainLight.
  ///
  /// In nl, this message translates to:
  /// **'Licht'**
  String get insightsRainLight;

  /// No description provided for @insightsRainWet.
  ///
  /// In nl, this message translates to:
  /// **'Nat'**
  String get insightsRainWet;

  /// No description provided for @insightsWindCalm.
  ///
  /// In nl, this message translates to:
  /// **'Rustig'**
  String get insightsWindCalm;

  /// No description provided for @insightsWindModerate.
  ///
  /// In nl, this message translates to:
  /// **'Matig'**
  String get insightsWindModerate;

  /// No description provided for @insightsWindStrong.
  ///
  /// In nl, this message translates to:
  /// **'Sterk'**
  String get insightsWindStrong;

  /// No description provided for @insightsTempNoteIdeal.
  ///
  /// In nl, this message translates to:
  /// **'Ideale temperatuur — comfortabel rijden'**
  String get insightsTempNoteIdeal;

  /// No description provided for @insightsTempNoteAcceptable.
  ///
  /// In nl, this message translates to:
  /// **'Acceptabele temperatuur — pak een extra laag'**
  String get insightsTempNoteAcceptable;

  /// No description provided for @insightsTempNoteExtreme.
  ///
  /// In nl, this message translates to:
  /// **'Buiten het ideale bereik — kleding aanpassen'**
  String get insightsTempNoteExtreme;

  /// No description provided for @insightsRainNoteDry.
  ///
  /// In nl, this message translates to:
  /// **'Droog — geen neerslag verwacht'**
  String get insightsRainNoteDry;

  /// No description provided for @insightsRainNoteLight.
  ///
  /// In nl, this message translates to:
  /// **'Lichte neerslag verwacht — spatborden handig'**
  String get insightsRainNoteLight;

  /// No description provided for @insightsRainNoteWet.
  ///
  /// In nl, this message translates to:
  /// **'Neerslag verwacht — overweeg een regenjas'**
  String get insightsRainNoteWet;

  /// No description provided for @insightsWindNoteCalm.
  ///
  /// In nl, this message translates to:
  /// **'Lichte wind — nauwelijks merkbaar'**
  String get insightsWindNoteCalm;

  /// No description provided for @insightsWindNoteModerate.
  ///
  /// In nl, this message translates to:
  /// **'Matige wind — verwacht wat weerstand'**
  String get insightsWindNoteModerate;

  /// No description provided for @insightsWindNoteStrong.
  ///
  /// In nl, this message translates to:
  /// **'Sterke wind — plan de route strategisch'**
  String get insightsWindNoteStrong;

  /// No description provided for @totalScore.
  ///
  /// In nl, this message translates to:
  /// **'Totaalscore'**
  String get totalScore;

  /// No description provided for @understood.
  ///
  /// In nl, this message translates to:
  /// **'Begrijpen'**
  String get understood;

  /// No description provided for @availabilityTitle.
  ///
  /// In nl, this message translates to:
  /// **'Mijn schema'**
  String get availabilityTitle;

  /// No description provided for @legendFree.
  ///
  /// In nl, this message translates to:
  /// **'Vrij'**
  String get legendFree;

  /// No description provided for @legendBusy.
  ///
  /// In nl, this message translates to:
  /// **'Bezet'**
  String get legendBusy;

  /// No description provided for @legendWork.
  ///
  /// In nl, this message translates to:
  /// **'Werk'**
  String get legendWork;

  /// No description provided for @riderNoTime.
  ///
  /// In nl, this message translates to:
  /// **'Helemaal geen tijd?'**
  String get riderNoTime;

  /// No description provided for @riderNoTimeDesc.
  ///
  /// In nl, this message translates to:
  /// **'Maak wat uren vrij om je perfecte rijmomenten te vinden.'**
  String get riderNoTimeDesc;

  /// No description provided for @riderFulltime.
  ///
  /// In nl, this message translates to:
  /// **'Fulltime fietser'**
  String get riderFulltime;

  /// No description provided for @riderFulltimeDesc.
  ///
  /// In nl, this message translates to:
  /// **'Je schema staat wagenwijd open. Genoeg keuze uit de beste momenten.'**
  String get riderFulltimeDesc;

  /// No description provided for @riderWeekend.
  ///
  /// In nl, this message translates to:
  /// **'Weekendstrijder'**
  String get riderWeekend;

  /// No description provided for @riderWeekendDesc.
  ///
  /// In nl, this message translates to:
  /// **'Het weekend is jouw speeltuin. We vinden de beste zaterdag- en zondagvensters.'**
  String get riderWeekendDesc;

  /// No description provided for @riderEarlyBird.
  ///
  /// In nl, this message translates to:
  /// **'Vroege vogel'**
  String get riderEarlyBird;

  /// No description provided for @riderEarlyBirdDesc.
  ///
  /// In nl, this message translates to:
  /// **'Je fietst voordat de wereld wakker wordt. Ochtendslots zijn jouw sweet spot.'**
  String get riderEarlyBirdDesc;

  /// No description provided for @riderAfterWork.
  ///
  /// In nl, this message translates to:
  /// **'Na-werk fietser'**
  String get riderAfterWork;

  /// No description provided for @riderAfterWorkDesc.
  ///
  /// In nl, this message translates to:
  /// **'De avond is jouw ontsnapping. We zoeken de beste avondvensters met het mooiste weer.'**
  String get riderAfterWorkDesc;

  /// No description provided for @riderAfternoon.
  ///
  /// In nl, this message translates to:
  /// **'Middagfietser'**
  String get riderAfternoon;

  /// No description provided for @riderAfternoonDesc.
  ///
  /// In nl, this message translates to:
  /// **'Je pakt de beste uren van de dag. Middagslots worden jouw ideale momenten.'**
  String get riderAfternoonDesc;

  /// No description provided for @riderBusy.
  ///
  /// In nl, this message translates to:
  /// **'Druk maar doorzetter'**
  String get riderBusy;

  /// No description provided for @riderBusyDesc.
  ///
  /// In nl, this message translates to:
  /// **'Krap schema, maar elke rit telt. We vinden de pareltjes in je vrije uren.'**
  String get riderBusyDesc;

  /// No description provided for @riderFlexible.
  ///
  /// In nl, this message translates to:
  /// **'Flexibele fietser'**
  String get riderFlexible;

  /// No description provided for @riderFlexibleDesc.
  ///
  /// In nl, this message translates to:
  /// **'Een mooie mix van vrije tijd door de week. Je hebt altijd opties.'**
  String get riderFlexibleDesc;

  /// No description provided for @agendaTitle.
  ///
  /// In nl, this message translates to:
  /// **'Agenda'**
  String get agendaTitle;

  /// No description provided for @agendaCancel.
  ///
  /// In nl, this message translates to:
  /// **'Annuleer'**
  String get agendaCancel;

  /// No description provided for @agendaBusy.
  ///
  /// In nl, this message translates to:
  /// **'Bezet'**
  String get agendaBusy;

  /// No description provided for @agendaHoursSelected.
  ///
  /// In nl, this message translates to:
  /// **'{count} uur geselecteerd'**
  String agendaHoursSelected(int count);

  /// No description provided for @agendaPlanRide.
  ///
  /// In nl, this message translates to:
  /// **'Rit inplannen ({count}u)'**
  String agendaPlanRide(int count);

  /// No description provided for @agendaRidePlanned.
  ///
  /// In nl, this message translates to:
  /// **'Rit ingepland ({count}u)!'**
  String agendaRidePlanned(int count);

  /// No description provided for @agendaNow.
  ///
  /// In nl, this message translates to:
  /// **'Nu'**
  String get agendaNow;

  /// No description provided for @agendaScoreBreakdown.
  ///
  /// In nl, this message translates to:
  /// **'Score-opbouw'**
  String get agendaScoreBreakdown;

  /// No description provided for @agendaRain.
  ///
  /// In nl, this message translates to:
  /// **'Regen'**
  String get agendaRain;

  /// No description provided for @agendaViewDetails.
  ///
  /// In nl, this message translates to:
  /// **'Bekijk details'**
  String get agendaViewDetails;

  /// No description provided for @ridesTitle.
  ///
  /// In nl, this message translates to:
  /// **'Mijn Ritten'**
  String get ridesTitle;

  /// No description provided for @ridesEmpty.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen ritten gepland'**
  String get ridesEmpty;

  /// No description provided for @ridesEmptyHint.
  ///
  /// In nl, this message translates to:
  /// **'Plan een rit vanuit Home of selecteer uren in de Agenda.'**
  String get ridesEmptyHint;

  /// No description provided for @rideRemoved.
  ///
  /// In nl, this message translates to:
  /// **'Rit verwijderd'**
  String get rideRemoved;

  /// No description provided for @rideSincePlanning.
  ///
  /// In nl, this message translates to:
  /// **'{delta} sinds planning'**
  String rideSincePlanning(String delta);

  /// No description provided for @ridesPerHour.
  ///
  /// In nl, this message translates to:
  /// **'Per uur'**
  String get ridesPerHour;

  /// No description provided for @ridesAvgScoreBreakdown.
  ///
  /// In nl, this message translates to:
  /// **'Gemiddelde score-opbouw'**
  String get ridesAvgScoreBreakdown;

  /// No description provided for @ridesDeleteRide.
  ///
  /// In nl, this message translates to:
  /// **'Rit verwijderen'**
  String get ridesDeleteRide;

  /// No description provided for @ridesWindFrom.
  ///
  /// In nl, this message translates to:
  /// **'Wind uit {direction}. {advice}.'**
  String ridesWindFrom(String direction, String advice);

  /// No description provided for @tailwindNorth.
  ///
  /// In nl, this message translates to:
  /// **'Fiets noordwaarts voor wind mee terug'**
  String get tailwindNorth;

  /// No description provided for @tailwindNortheast.
  ///
  /// In nl, this message translates to:
  /// **'Fiets noordoostwaarts voor wind mee terug'**
  String get tailwindNortheast;

  /// No description provided for @tailwindEast.
  ///
  /// In nl, this message translates to:
  /// **'Fiets oostwaarts voor wind mee terug'**
  String get tailwindEast;

  /// No description provided for @tailwindSoutheast.
  ///
  /// In nl, this message translates to:
  /// **'Fiets zuidoostwaarts voor wind mee terug'**
  String get tailwindSoutheast;

  /// No description provided for @tailwindSouth.
  ///
  /// In nl, this message translates to:
  /// **'Fiets zuidwaarts voor wind mee terug'**
  String get tailwindSouth;

  /// No description provided for @tailwindSouthwest.
  ///
  /// In nl, this message translates to:
  /// **'Fiets zuidwestwaarts voor wind mee terug'**
  String get tailwindSouthwest;

  /// No description provided for @tailwindWest.
  ///
  /// In nl, this message translates to:
  /// **'Fiets westwaarts voor wind mee terug'**
  String get tailwindWest;

  /// No description provided for @tailwindNorthwest.
  ///
  /// In nl, this message translates to:
  /// **'Fiets noordwestwaarts voor wind mee terug'**
  String get tailwindNorthwest;

  /// No description provided for @compassN.
  ///
  /// In nl, this message translates to:
  /// **'N'**
  String get compassN;

  /// No description provided for @compassNE.
  ///
  /// In nl, this message translates to:
  /// **'NO'**
  String get compassNE;

  /// No description provided for @compassE.
  ///
  /// In nl, this message translates to:
  /// **'O'**
  String get compassE;

  /// No description provided for @compassSE.
  ///
  /// In nl, this message translates to:
  /// **'ZO'**
  String get compassSE;

  /// No description provided for @compassS.
  ///
  /// In nl, this message translates to:
  /// **'Z'**
  String get compassS;

  /// No description provided for @compassSW.
  ///
  /// In nl, this message translates to:
  /// **'ZW'**
  String get compassSW;

  /// No description provided for @compassW.
  ///
  /// In nl, this message translates to:
  /// **'W'**
  String get compassW;

  /// No description provided for @compassNW.
  ///
  /// In nl, this message translates to:
  /// **'NW'**
  String get compassNW;

  /// No description provided for @hintTapRideWindow.
  ///
  /// In nl, this message translates to:
  /// **'Tik op een rijvenster'**
  String get hintTapRideWindow;

  /// No description provided for @hintTapRideWindowDesc.
  ///
  /// In nl, this message translates to:
  /// **'Bekijk weerdetails, plan de rit in of voeg toe aan Google Agenda.'**
  String get hintTapRideWindowDesc;

  /// No description provided for @hintFilterDay.
  ///
  /// In nl, this message translates to:
  /// **'Filter op dag'**
  String get hintFilterDay;

  /// No description provided for @hintFilterDayDesc.
  ///
  /// In nl, this message translates to:
  /// **'Tik op een dag bovenaan om alleen die dag te zien.'**
  String get hintFilterDayDesc;

  /// No description provided for @hintTapWeatherDetail.
  ///
  /// In nl, this message translates to:
  /// **'Tik voor weerdetails'**
  String get hintTapWeatherDetail;

  /// No description provided for @hintTapWeatherDetailDesc.
  ///
  /// In nl, this message translates to:
  /// **'Tik op een gekleurd uurvak om temperatuur, regen en wind te bekijken.'**
  String get hintTapWeatherDetailDesc;

  /// No description provided for @hintDragSelect.
  ///
  /// In nl, this message translates to:
  /// **'Sleep om uren te selecteren'**
  String get hintDragSelect;

  /// No description provided for @hintDragSelectDesc.
  ///
  /// In nl, this message translates to:
  /// **'Houd een vak ingedrukt en sleep verticaal om meerdere uren te selecteren. Tik daarna op \"Rit inplannen\" onderaan.'**
  String get hintDragSelectDesc;

  /// No description provided for @hintTapSummary.
  ///
  /// In nl, this message translates to:
  /// **'Tik voor weersamenvatting'**
  String get hintTapSummary;

  /// No description provided for @hintTapSummaryDesc.
  ///
  /// In nl, this message translates to:
  /// **'Tik op een rit voor een uitgebreid weeroverzicht per uur, score-opbouw en windadvies.'**
  String get hintTapSummaryDesc;

  /// No description provided for @hintSwipeDelete.
  ///
  /// In nl, this message translates to:
  /// **'Swipe om te verwijderen'**
  String get hintSwipeDelete;

  /// No description provided for @hintSwipeDeleteDesc.
  ///
  /// In nl, this message translates to:
  /// **'Veeg een rit naar links om hem te verwijderen.'**
  String get hintSwipeDeleteDesc;

  /// No description provided for @hintDismiss.
  ///
  /// In nl, this message translates to:
  /// **'Tik om door te gaan'**
  String get hintDismiss;

  /// No description provided for @calendarEventTitle.
  ///
  /// In nl, this message translates to:
  /// **'Fietsrit {timeRange}'**
  String calendarEventTitle(String timeRange);

  /// No description provided for @calendarNoWeatherData.
  ///
  /// In nl, this message translates to:
  /// **'Geen weerdata beschikbaar'**
  String get calendarNoWeatherData;

  /// No description provided for @calendarDry.
  ///
  /// In nl, this message translates to:
  /// **'droog'**
  String get calendarDry;

  /// No description provided for @calendarWind.
  ///
  /// In nl, this message translates to:
  /// **'{speed}km/u wind'**
  String calendarWind(String speed);

  /// No description provided for @calendarSignInCanceled.
  ///
  /// In nl, this message translates to:
  /// **'Aanmelden geannuleerd'**
  String get calendarSignInCanceled;

  /// No description provided for @notifEveningTitle.
  ///
  /// In nl, this message translates to:
  /// **'Top rijmoment morgen!'**
  String get notifEveningTitle;

  /// No description provided for @notifEveningBody.
  ///
  /// In nl, this message translates to:
  /// **'{slot} — perfecte omstandigheden verwacht'**
  String notifEveningBody(String slot);

  /// No description provided for @notifMorningTitle.
  ///
  /// In nl, this message translates to:
  /// **'Over 2 uur een top rijmoment!'**
  String get notifMorningTitle;

  /// No description provided for @notifMorningBody.
  ///
  /// In nl, this message translates to:
  /// **'{slot} — maak je klaar om te rijden'**
  String notifMorningBody(String slot);

  /// No description provided for @notifWeeklyTitle.
  ///
  /// In nl, this message translates to:
  /// **'Je rijoverzicht voor deze week'**
  String get notifWeeklyTitle;

  /// No description provided for @notifChannelRideAlerts.
  ///
  /// In nl, this message translates to:
  /// **'Rijmeldingen'**
  String get notifChannelRideAlerts;

  /// No description provided for @notifChannelRideAlertsDesc.
  ///
  /// In nl, this message translates to:
  /// **'Avond-van-tevoren en ochtend-van-de-dag rijmeldingen'**
  String get notifChannelRideAlertsDesc;

  /// No description provided for @notifChannelWeeklyDigest.
  ///
  /// In nl, this message translates to:
  /// **'Wekelijks overzicht'**
  String get notifChannelWeeklyDigest;

  /// No description provided for @notifChannelWeeklyDigestDesc.
  ///
  /// In nl, this message translates to:
  /// **'Zondagavond overzicht van de beste rijmomenten'**
  String get notifChannelWeeklyDigestDesc;

  /// No description provided for @widgetTierPerfect.
  ///
  /// In nl, this message translates to:
  /// **'Perfect'**
  String get widgetTierPerfect;

  /// No description provided for @widgetTierGreat.
  ///
  /// In nl, this message translates to:
  /// **'Geweldig'**
  String get widgetTierGreat;

  /// No description provided for @widgetTierAcceptable.
  ///
  /// In nl, this message translates to:
  /// **'Acceptabel'**
  String get widgetTierAcceptable;

  /// No description provided for @widgetTierPoor.
  ///
  /// In nl, this message translates to:
  /// **'Slecht'**
  String get widgetTierPoor;

  /// No description provided for @hourlyDry.
  ///
  /// In nl, this message translates to:
  /// **'droog'**
  String get hourlyDry;

  /// No description provided for @hourlyWindstil.
  ///
  /// In nl, this message translates to:
  /// **'windstil'**
  String get hourlyWindstil;

  /// No description provided for @hourlyFeelsLike.
  ///
  /// In nl, this message translates to:
  /// **'v.a. {temp}°C'**
  String hourlyFeelsLike(String temp);

  /// No description provided for @dayShortMon.
  ///
  /// In nl, this message translates to:
  /// **'Ma'**
  String get dayShortMon;

  /// No description provided for @dayShortTue.
  ///
  /// In nl, this message translates to:
  /// **'Di'**
  String get dayShortTue;

  /// No description provided for @dayShortWed.
  ///
  /// In nl, this message translates to:
  /// **'Wo'**
  String get dayShortWed;

  /// No description provided for @dayShortThu.
  ///
  /// In nl, this message translates to:
  /// **'Do'**
  String get dayShortThu;

  /// No description provided for @dayShortFri.
  ///
  /// In nl, this message translates to:
  /// **'Vr'**
  String get dayShortFri;

  /// No description provided for @dayShortSat.
  ///
  /// In nl, this message translates to:
  /// **'Za'**
  String get dayShortSat;

  /// No description provided for @dayShortSun.
  ///
  /// In nl, this message translates to:
  /// **'Zo'**
  String get dayShortSun;

  /// No description provided for @importFromCalendar.
  ///
  /// In nl, this message translates to:
  /// **'Importeer uit Google Agenda'**
  String get importFromCalendar;

  /// No description provided for @legendCalendar.
  ///
  /// In nl, this message translates to:
  /// **'Agenda'**
  String get legendCalendar;

  /// No description provided for @calendarImportSuccess.
  ///
  /// In nl, this message translates to:
  /// **'Agenda-afspraken geimporteerd!'**
  String get calendarImportSuccess;

  /// No description provided for @calendarImportError.
  ///
  /// In nl, this message translates to:
  /// **'Kon agenda-afspraken niet importeren'**
  String get calendarImportError;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'nl':
      return SNl();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
