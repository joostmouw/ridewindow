// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class SNl extends S {
  SNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Ridewindow';

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
      other: 'fietsmomenten',
      one: 'fietsmoment',
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
  String get rideTimes => 'FIETSMOMENTEN';

  @override
  String get plannedRidesLabel => 'GEPLAND';

  @override
  String scoreSectionTitle(Object score) {
    return 'Dit venster: $score van de 100';
  }

  @override
  String scoreInsideIdeal(Object value) {
    return '$value valt binnen het bereik dat je hebt ingesteld, dus dit scoort de volle 100.';
  }

  @override
  String scoreOutsideIdeal(Object value) {
    return '$value valt buiten het bereik dat je hebt ingesteld, en dát kost de punten.';
  }

  @override
  String scaleTemp(Object ex1, Object ex2, Object score1, Object score2) {
    return 'Buiten je bereik zakt de score met 5 punten per graad. $ex1 zou dus $score1 scoren, en $ex2 zou $score2 scoren.';
  }

  @override
  String scaleRain(Object ex1, Object ex2, Object score1, Object score2) {
    return 'Boven je grens kosten de eerste druppels het meest en vlakt het daarna af: $ex1 scoort $score1, $ex2 scoort $score2. De kans op regen telt ook mee: de slechtste van die twee wordt de score.';
  }

  @override
  String scaleWind(Object ex1, Object ex2, Object score1, Object score2) {
    return 'Boven je grens zakt het eerst rustig en daarna steil, want harde wind is een veiligheidskwestie: $ex1 scoort $score1, $ex2 scoort $score2.';
  }

  @override
  String get scoreCombines =>
      'De zwakste van temperatuur, regen en wind weegt het zwaarst: de ritscore is 60% van de laagste plus 40% van het gemiddelde van alle drie.';

  @override
  String showAllWindows(Object count) {
    return 'Toon alle $count momenten';
  }

  @override
  String get showFewerWindows => 'Toon minder';

  @override
  String morePlannedRides(Object count) {
    return 'nog $count';
  }

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
  String get decreaseStartTime => 'Starttijd vroeger zetten';

  @override
  String get increaseStartTime => 'Starttijd later zetten';

  @override
  String get decreaseEndTime => 'Eindtijd vroeger zetten';

  @override
  String get increaseEndTime => 'Eindtijd later zetten';

  @override
  String weatherMetricInfoTooltip(String label) {
    return '$label info';
  }

  @override
  String weatherTierDescription(String tier) {
    return '$tier fietsweer';
  }

  @override
  String get infoTemp =>
      'De groene zone toont je ideale temperatuurbereik. De stip toont de gemiddelde temperatuur voor dit fietsmoment. Pas je bereik aan in Profiel.';

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
  String get tierPerfect => 'Toprit';

  @override
  String get tierGreat => 'Fijne rit';

  @override
  String get tierAcceptable => 'Te doen';

  @override
  String get tierPoor => 'Binnenblijver';

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
      'Fietsmoment toegevoegd aan Google Agenda';

  @override
  String couldNotAdd(String error) {
    return 'Kon niet toevoegen: $error';
  }

  @override
  String get weatherLoadError => 'Het weerbericht kon niet worden geladen.';

  @override
  String get emptyBadWeather =>
      'Geen goede fietsmomenten deze week. Slecht weer verwacht.';

  @override
  String get emptyAllBlocked =>
      'Alle goede momenten zijn geblokkeerd. Pas je schema aan.';

  @override
  String get emptyNoSlots => 'Geen fietsmomenten gevonden.';

  @override
  String get emptyNoSlotsDay => 'Geen fietsmomenten op deze dag.';

  @override
  String staleDataBannerWithTime(String time) {
    return 'Offline, toont fietsmomenten van $time';
  }

  @override
  String get staleDataBannerNoTime =>
      'Offline, toont laatst bekende fietsmomenten';

  @override
  String get unitKmh => 'km/u';

  @override
  String get comboShortShort => 'Kort/kort';

  @override
  String get comboLongShort => 'Lang/kort';

  @override
  String get comboLongLong => 'Lang/lang';

  @override
  String get comboLongLongExtra => 'Lang/lang +';

  @override
  String get windCalm => 'Windstil';

  @override
  String durationHours(int hours) {
    return '${hours}u';
  }

  @override
  String get welcomeTitle => 'Jouw perfecte fietsmoment';

  @override
  String get welcomeSubtitle =>
      'Combineer het weerbericht met jouw agenda en ontdek de beste momenten om te fietsen.';

  @override
  String get welcomeButton => 'Aan de slag →';

  @override
  String get welcomeHaveAccount => 'Ik heb al een account';

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
  String get sectionNotifications => 'MELDINGEN';

  @override
  String get sectionTheme => 'THEMA';

  @override
  String get sectionUnits => 'EENHEDEN';

  @override
  String get unitsTemperature => 'Temperatuur';

  @override
  String get unitsWind => 'Wind';

  @override
  String get unitsCelsius => '°C';

  @override
  String get unitsFahrenheit => '°F';

  @override
  String get unitsKmh => 'km/u';

  @override
  String get unitsBeaufort => 'Bft';

  @override
  String get unitsMph => 'mph';

  @override
  String get unitsHint =>
      'Alleen hoe de app getallen toont. Je grenzen hierboven blijven staan waar ze staan.';

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
  String get clearLocationOverride => 'Terug naar mijn GPS-locatie';

  @override
  String get grantPermission => 'Toestemming geven';

  @override
  String get gpsAutomatic => 'GPS (automatisch)';

  @override
  String get tapToChooseCity => 'Tik om stad te kiezen';

  @override
  String get locationBlockedWebHint =>
      'Schakel locatietoegang in via de site-instellingen van je browser, of kies hieronder een stad.';

  @override
  String get chooseCityPrimaryTitle => 'Kies je stad voor een voorspelling';

  @override
  String get chooseCityPrimaryHint =>
      'We konden je locatie niet ophalen. Kies hieronder een stad om toch een weersvoorspelling te zien.';

  @override
  String get notifEveningBefore => 'Avond van tevoren';

  @override
  String get notifEveningBeforeSub =>
      '19:00 de avond ervoor, als er een mooi moment aankomt';

  @override
  String get notifMorningOf => 'Ochtend van de dag';

  @override
  String get notifMorningOfSub => '2 uur voordat het begint';

  @override
  String get notifWeeklyDigest => 'Wekelijks overzicht';

  @override
  String get notifWeeklyDigestSub =>
      'Zondagavond 19:00, beste momenten van de week';

  @override
  String get notifExactTimingWarning =>
      'Exacte timing niet gegarandeerd. Sta exacte alarmen toe in Instellingen voor betrouwbaarheid.';

  @override
  String get notifPermissionDenied =>
      'Meldingen staan uit in de systeeminstellingen.';

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
      'Stel je ideale fietstemperatuur in. Uren binnen dit bereik scoren 100 voor temperatuur. Buiten het bereik daalt de score geleidelijk: hoe verder van je bereik, hoe lager de score.\n\nEen breder bereik geeft meer fietsmomenten; een smaller bereik toont alleen je ideale omstandigheden.';

  @override
  String get toleranceRainInfoTitle => 'Regentolerantie';

  @override
  String get toleranceRainInfo =>
      'Stel de maximale neerslag per uur in waar je in wilt fietsen. Uren op of onder deze limiet scoren 100 voor regen. Boven de limiet daalt de score: meer regen betekent een lagere score.\n\nZet op 0 mm voor alleen droog weer, of hoger als je wat regen niet erg vindt.';

  @override
  String get toleranceWindInfoTitle => 'Windtolerantie';

  @override
  String get toleranceWindInfo =>
      'Stel de maximale windsnelheid in waar je comfortabel in fietst. Uren op of onder deze limiet scoren 100 voor wind. Boven de limiet daalt de score: hardere wind betekent een lagere score.\n\nEen hogere tolerantie geeft meer fietsmomenten, maar verwacht zwaarder fietsen.';

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
  String get rainDescDrizzleOk => 'Een beetje motregen is prima';

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
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get sendFeedback => 'Feedback versturen';

  @override
  String get feedbackRatingLabel => 'Hoe zou je Ridewindow beoordelen?';

  @override
  String get feedbackCommentHint => 'Wil je iets delen? (optioneel)';

  @override
  String get feedbackCommentLabel => 'Opmerking';

  @override
  String feedbackStarRating(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sterren',
      one: '$count ster',
    );
    return '$_temp0';
  }

  @override
  String get feedbackSendButton => 'Versturen';

  @override
  String get googleCalendarLabel => 'Google Agenda';

  @override
  String get calendarStatusChecking => 'Controleren…';

  @override
  String get calendarStatusConnected => 'Verbonden';

  @override
  String get calendarStatusNotConnected => 'Niet verbonden';

  @override
  String get calendarDisconnectButton => 'Loskoppelen';

  @override
  String get calendarDisconnectedSnackbar => 'Losgekoppeld van Google Agenda.';

  @override
  String get sectionAccount => 'Account';

  @override
  String get signInWithGoogle => 'Inloggen met Google';

  @override
  String get signInWithEmail => 'Inloggen met e-mail';

  @override
  String get emailSignInTitle => 'Inloggen met e-mail';

  @override
  String get emailCreateTitle => 'Account aanmaken';

  @override
  String get emailFieldLabel => 'E-mailadres';

  @override
  String get passwordFieldLabel => 'Wachtwoord';

  @override
  String get emailSignInAction => 'Inloggen';

  @override
  String get emailCreateAction => 'Aanmaken';

  @override
  String get emailSwitchToCreate => 'Nog geen account? Maak er een aan.';

  @override
  String get emailSwitchToSignIn => 'Al een account? Log in.';

  @override
  String get emailInvalidError => 'Voer een geldig e-mailadres in.';

  @override
  String get passwordTooShortError => 'Wachtwoord van minstens 6 tekens.';

  @override
  String get emailConfirmSent =>
      'Controleer je e-mail om je account te bevestigen, en log daarna in.';

  @override
  String get emailNotConfirmed =>
      'Dit e-mailadres is nog niet bevestigd. Klik de link in je e-mail.';

  @override
  String get emailAlreadyExists =>
      'Er bestaat al een account met dit e-mailadres.';

  @override
  String get accountEmailSignInFailed =>
      'Inloggen met dit e-mailadres is mislukt. Probeer het opnieuw.';

  @override
  String get accountEmailCreateFailed =>
      'Account aanmaken is mislukt. Probeer het opnieuw.';

  @override
  String get accountSyncPromise =>
      'Je instellingen en geplande ritten, op al je apparaten.';

  @override
  String get accountLoading => 'Bezig met laden…';

  @override
  String get accountSignOut => 'Uitloggen';

  @override
  String get accountSignOutConfirmTitle => 'Uitloggen?';

  @override
  String get accountSignOutConfirmBody =>
      'Je gegevens op dit toestel blijven staan. Je kunt altijd opnieuw inloggen.';

  @override
  String get accountSignInError => 'Inloggen mislukt. Probeer het opnieuw.';

  @override
  String get accountSignOutFailed =>
      'Uitloggen is niet gelukt. Probeer het opnieuw.';

  @override
  String get accountAvatarSemanticLabel => 'Profielfoto';

  @override
  String get accountSwitchDialogTitle => 'Ander Google-account';

  @override
  String get accountSwitchDialogBody =>
      'Je bent nu ingelogd met een ander account dan voorheen op dit toestel. Wil je de gegevens op dit toestel bewaren, of opnieuw beginnen?';

  @override
  String get accountSwitchKeepAction => 'Gegevens bewaren';

  @override
  String get accountSwitchRestartAction => 'Opnieuw beginnen';

  @override
  String get accountConflictProfileTitle => 'Profielinstellingen verschillen';

  @override
  String get accountConflictProfileBody =>
      'Je profielinstellingen verschillen tussen dit toestel en de cloud. Welke versie wil je bewaren?';

  @override
  String get accountConflictAvailabilityTitle => 'Beschikbaarheid verschilt';

  @override
  String get accountConflictAvailabilityBody =>
      'Je beschikbaarheidskalender verschilt tussen dit toestel en de cloud. Welke versie wil je bewaren?';

  @override
  String get accountConflictKeepLocalAction => 'Dit toestel';

  @override
  String get accountConflictKeepCloudAction => 'Cloud';

  @override
  String get accountSyncStatusSynced => 'Gesynchroniseerd';

  @override
  String get accountSyncStatusPending => 'Wordt gesynchroniseerd…';

  @override
  String get accountDeleteAction => 'Account verwijderen';

  @override
  String get accountDeleteConfirmTitle => 'Account verwijderen?';

  @override
  String get accountDeleteConfirmBody =>
      'Dit kan niet ongedaan worden gemaakt. Je profiel, beschikbaarheid en geplande ritten worden permanent uit de cloud verwijderd.';

  @override
  String get accountDeleteConfirmAction => 'Verwijderen';

  @override
  String get accountDeletedSnackbar => 'Account verwijderd';

  @override
  String get accountDeleteError => 'Verwijderen mislukt. Probeer het opnieuw.';

  @override
  String calendarMismatchWarning(String email) {
    return 'Agenda gekoppeld aan een ander account: $email';
  }

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get weatherDataAttribution => 'Weerdata door Open-Meteo.com';

  @override
  String get version => 'Versie';

  @override
  String get debugMenu => 'Debug Menu';

  @override
  String get debugResetAnalytics => 'Statistiek-toestemming terugzetten';

  @override
  String get debugAnalyticsReset =>
      'Toestemming, toestel-id, startteller en wachtkamer zijn gewist';

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
  String get debugOutbox => 'Sync-outbox bekijken';

  @override
  String get debugOutboxTitle => 'Sync-outbox';

  @override
  String get debugOutboxEmpty => 'Outbox is leeg. Alles is verzonden.';

  @override
  String debugOutboxRowSubtitle(int attempts, String error) {
    return '$attempts pogingen · $error';
  }

  @override
  String get debugOutboxNoError => 'nog geen fout vastgelegd';

  @override
  String get debugOutboxClear => 'Outbox wissen';

  @override
  String debugOutboxCleared(int count) {
    return 'Outbox gewist ($count rijen).';
  }

  @override
  String get detailTierPerfectDesc => 'Ideaal fietsweer';

  @override
  String get detailTierGreatDesc => 'Prettig fietsweer';

  @override
  String get detailTierAcceptableDesc => 'Pak een extra laag';

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
  String weatherYourRange(String range) {
    return 'jouw bereik $range';
  }

  @override
  String get showWeatherDetails => 'Toon de weerbalken';

  @override
  String get hideWeatherDetails => 'Verberg de weerbalken';

  @override
  String get verdictDry => 'Droog';

  @override
  String get verdictLight => 'Motregen';

  @override
  String get verdictShowers => 'Buien';

  @override
  String get verdictWet => 'Nat';

  @override
  String get verdictCalm => 'Windstil';

  @override
  String get verdictBreezy => 'Briesje';

  @override
  String get verdictGusty => 'Winderig';

  @override
  String get verdictChilly => 'Fris';

  @override
  String get verdictIdeal => 'Ideaal';

  @override
  String get verdictWarm => 'Warm';

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
    return '$speed uit $direction';
  }

  @override
  String windPenalty(String pct) {
    return 'Wisselende windrichting (-$pct% op score)';
  }

  @override
  String get clothingTitle => 'Wat trek je aan';

  @override
  String get clothingOnTheBike => 'Op de fiets';

  @override
  String clothingBandBelow(int to) {
    return 'onder $to°';
  }

  @override
  String clothingBandAbove(int from) {
    return 'vanaf $from°';
  }

  @override
  String clothingBandBetween(int from, int to) {
    return '$from–$to°';
  }

  @override
  String get clothingFeelsLikeInfo =>
      'De “voelt als” in de weerlijst verrekent zon, vocht en de wind die er staat, maar gaat uit van stilstaan. Op de fiets maak je zelf zo’n 15 km/u tegenwind, en alleen dat stukje gaat er hier nog af. Dit getal is waar je kledingadvies op stoelt. De gekleurde banden laten zien welk advies bij welke temperatuur hoort.';

  @override
  String clothingFeelsLikeDrop(int airTemp, int bikeTemp, int chill) {
    return 'In de weerlijst voelt het als $airTemp°. Op de fiets wordt dat $bikeTemp°, want je eigen tegenwind haalt er $chill° af.';
  }

  @override
  String clothingFeelsLikeNoDrop(int airTemp) {
    return 'In de weerlijst voelt het als $airTemp°, en het fietsen haalt daar nauwelijks iets af.';
  }

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
  String get clothingLegWarmers => 'Lange broek';

  @override
  String get clothingShortSleeveJersey => 'Korte mouw jersey';

  @override
  String get clothingArmWarmersJustInCase => 'Armwarmers voor de zekerheid';

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
  String get plannedButtonLabel => 'Ingepland';

  @override
  String get addToGoogleCalendar => 'Toevoegen aan Google Agenda';

  @override
  String get remindEveningBefore => 'Herinner me de avond ervoor';

  @override
  String get reminderPlanned => 'Herinnering gepland voor de avond ervoor!';

  @override
  String get shareRideWindow => 'Deel dit fietsmoment';

  @override
  String shareText(String day, String timeRange, String tier, String summary) {
    return 'Fietsrit $day $timeRange ($tier)\n$summary\n\nVia Ridewindow';
  }

  @override
  String insightsTitle(String tier, String score) {
    return 'Waarom \'$tier\': $score/100';
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
  String get insightsTempNoteIdeal => 'Ideale temperatuur, comfortabel rijden';

  @override
  String get insightsTempNoteAcceptable =>
      'Acceptabele temperatuur, pak een extra laag';

  @override
  String get insightsTempNoteExtreme =>
      'Buiten het ideale bereik, kleding aanpassen';

  @override
  String get insightsRainNoteDry => 'Droog, geen neerslag verwacht';

  @override
  String get insightsRainNoteLight =>
      'Lichte neerslag verwacht, spatborden handig';

  @override
  String get insightsRainNoteWet => 'Neerslag verwacht, overweeg een regenjas';

  @override
  String get insightsWindNoteCalm => 'Lichte wind, nauwelijks merkbaar';

  @override
  String get insightsWindNoteModerate => 'Matige wind, verwacht wat weerstand';

  @override
  String get insightsWindNoteStrong => 'Sterke wind, plan de route strategisch';

  @override
  String get totalScore => 'Totaalscore';

  @override
  String get understood => 'Duidelijk';

  @override
  String get showScoreDetails => 'Waarom deze score';

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
      'Maak wat uren vrij om je perfecte fietsmomenten te vinden.';

  @override
  String get riderFulltime => 'Fulltime fietser';

  @override
  String get riderFulltimeDesc =>
      'Je schema staat wagenwijd open. Genoeg keuze uit de beste momenten.';

  @override
  String get riderWeekend => 'Weekendstrijder';

  @override
  String get riderWeekendDesc =>
      'Het weekend is jouw speeltuin. We vinden de beste zaterdag- en zondagmomenten.';

  @override
  String get riderEarlyBird => 'Vroege vogel';

  @override
  String get riderEarlyBirdDesc =>
      'Je fietst voordat de wereld wakker wordt. De vroege uren zijn van jou.';

  @override
  String get riderAfterWork => 'Na-werk fietser';

  @override
  String get riderAfterWorkDesc =>
      'De avond is jouw ontsnapping. We zoeken de beste avondmomenten met het mooiste weer.';

  @override
  String get riderAfternoon => 'Middagfietser';

  @override
  String get riderAfternoonDesc =>
      'Je pakt de beste uren van de dag. De middaguren worden jouw beste ritten.';

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
  String get agendaCancel => 'Annuleren';

  @override
  String get agendaBusy => 'Bezet';

  @override
  String agendaHoursSelected(int count) {
    return '$count uur geselecteerd';
  }

  @override
  String dragRunsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'losse tijdvakken',
      one: 'tijdvak',
    );
    return '$count $_temp0 geselecteerd';
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
  String get removePlannedRideTooltip => 'Verwijder geplande rit';

  @override
  String get unplanConfirmTitle => 'Deze rit verwijderen?';

  @override
  String get unplanConfirmMessage =>
      'Dit verwijdert de rit uit je geplande ritten. Je kunt hem altijd opnieuw plannen.';

  @override
  String get unplanConfirmAction => 'Verwijderen';

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
  String get hintTapRideWindow => 'Tik op een fietsmoment';

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
  String get hintTapWeatherDetail => 'Houd ingedrukt voor weerdetails';

  @override
  String get hintTapWeatherDetailDesc =>
      'Houd een gekleurd uurvak ingedrukt om temperatuur, regen en wind te bekijken.';

  @override
  String get hintDragSelect => 'Tik tweemaal om een periode te selecteren';

  @override
  String get hintDragSelectDesc =>
      'Tik op een uur om te beginnen, tik daarna op een ander uur om de periode in te stellen. Tik daarna op \"Rit inplannen\" onderaan.';

  @override
  String get hintTapSummary => 'Tik voor weersamenvatting';

  @override
  String get hintTapSummaryDesc =>
      'Tik op een rit voor een uitgebreid weeroverzicht per uur, score-opbouw en windadvies.';

  @override
  String get hintSwipeDelete => 'Veeg om te verwijderen';

  @override
  String get hintSwipeDeleteDesc =>
      'Veeg een rit naar links om hem te verwijderen.';

  @override
  String get hintDismiss => 'Klaar';

  @override
  String get hintNext => 'Volgende';

  @override
  String get hintBack => 'Vorige';

  @override
  String get showTips => 'Uitleg tonen';

  @override
  String get showWelcomeTour => 'Rondleiding opnieuw bekijken';

  @override
  String get hintSkip => 'Overslaan';

  @override
  String hintStepOf(int current, int total) {
    return 'Stap $current van $total';
  }

  @override
  String get tourHomeTitle => 'Fietsmomenten';

  @override
  String get tourHomeBody =>
      'Home toont de beste momenten om deze week te fietsen. Elke kaart draagt de score, het tijdstip en het weer. Tik op een kaart voor details.';

  @override
  String get tourAgendaTitle => 'Agenda';

  @override
  String get tourAgendaBody =>
      'Zeven dagen met uurvakken: groen is goed, oranje niet. Tik op een vak voor het weer. Tik tweemaal om een periode te kiezen en een rit te plannen.';

  @override
  String get tourRidesTitle => 'Mijn ritten';

  @override
  String get tourRidesBody =>
      'Plan een rit vanuit Home of de Agenda en volg hier of het weer nog meezit. De windtip helpt je een route kiezen: eerst tegenwind, dan mee terug.';

  @override
  String get tourProfileTitle => 'Profiel';

  @override
  String get tourProfileBody =>
      'Stel je locatie in, je grenzen voor temperatuur, regen en wind, en je beschikbaarheid. Daar worden je scores mee berekend.';

  @override
  String get tourDone => 'Aan de slag';

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
    return '$speed wind';
  }

  @override
  String get calendarSignInCanceled => 'Inloggen geannuleerd';

  @override
  String get notifEveningTitle => 'Morgen ligt er een fietsmoment klaar';

  @override
  String notifEveningBody(String slot) {
    return '$slot. Zet je fiets alvast klaar';
  }

  @override
  String get notifMorningTitle => 'Over 2 uur stap je op';

  @override
  String notifMorningBody(String slot) {
    return '$slot. Maak je klaar om te rijden';
  }

  @override
  String get notifWeeklyTitle => 'De beste fietsmomenten van je week';

  @override
  String get notifChannelRideAlerts => 'Fietsmeldingen';

  @override
  String get notifChannelRideAlertsDesc =>
      'Avond-van-tevoren en ochtend-van-de-dag fietsmeldingen';

  @override
  String get notifChannelWeeklyDigest => 'Wekelijks overzicht';

  @override
  String get notifChannelWeeklyDigestDesc =>
      'Zondagavond overzicht van de beste fietsmomenten';

  @override
  String get widgetTierPerfect => 'Toprit';

  @override
  String get widgetTierGreat => 'Fijne rit';

  @override
  String get widgetTierAcceptable => 'Te doen';

  @override
  String get widgetTierPoor => 'Binnenblijver';

  @override
  String get hourlyDry => 'droog';

  @override
  String get hourlyWindstil => 'windstil';

  @override
  String hourlyFeelsLike(String temp) {
    return 'voelt als $temp°';
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
  String get calendarImportSuccess => 'Agenda-afspraken geïmporteerd';

  @override
  String get calendarImportError => 'Kon agenda-afspraken niet importeren';

  @override
  String get cellInfoStatusWork => 'Werk-geblokkeerd';

  @override
  String get cellInfoStatusCalendar => 'Agenda-geblokkeerd';

  @override
  String get cellInfoStatusCustom => 'Beschikbaar gezet';

  @override
  String get cellInfoStatusFree => 'Vrij';

  @override
  String get cellStatusPlanned => 'Gepland';

  @override
  String get cellStatusSelected => 'Geselecteerd';

  @override
  String get cellStatusBlocked => 'Geblokkeerd';

  @override
  String get dayHeaderToggleHint =>
      'Dubbeltik om alle uren voor deze dag te wisselen';

  @override
  String get hourHeaderToggleHint =>
      'Dubbeltik om dit uur voor alle dagen te wisselen';

  @override
  String get addToHomeScreenHint =>
      'Tik op het Deel-icoon en kies \'Zet op beginscherm\' om Ridewindow te installeren.';

  @override
  String get pelotonEmptyTitle => 'Samen fietsen';

  @override
  String get pelotonEmptyHint =>
      'Deel een ridewindow met een maatje. Hij opent je link, doet mee, en de rit staat in zijn app.';

  @override
  String get pelotonInvitesSent => 'Uitnodigingen die jij stuurde';

  @override
  String get pelotonJoinWithCode => 'Heb je een code? Vul \'m in';

  @override
  String get pelotonCodeHint => 'Uitnodigingscode';

  @override
  String get pelotonJoin => 'Meedoen';

  @override
  String get pelotonSignedOut => 'Log in om samen te fietsen';

  @override
  String get pelotonSignedOutHint =>
      'Een peloton is de groep waarmee je rijdt. Inloggen is nodig zodat je maatjes je kunnen vinden. De rest van de app werkt gewoon zonder.';

  @override
  String get pelotonFriends => 'Maatjes';

  @override
  String get pelotonNoFriends => 'Je peloton is nog leeg';

  @override
  String get pelotonNoFriendsHint =>
      'Een peloton is de groep waarmee je rijdt. Nodig een maatje uit en jullie zien elkaars ritten.';

  @override
  String get pelotonInviteFriend => 'Nodig een maatje uit';

  @override
  String pelotonInviteShare(String code) {
    return 'Fiets met me mee in Ridewindow. Open de app en vul code $code in.';
  }

  @override
  String pelotonYourCode(String code) {
    return 'Jouw code: $code';
  }

  @override
  String get pelotonRemoveFriend => 'Maatje verwijderen';

  @override
  String get pelotonRemoveFailed =>
      'Dit maatje kon niet worden verwijderd. Probeer het opnieuw.';

  @override
  String get pelotonAccept => 'Ik ga mee';

  @override
  String get pelotonDecline => 'Kan niet';

  @override
  String get pelotonWithdraw => 'Toch niet';

  @override
  String get pelotonWithdrawn => 'Je doet niet meer mee aan deze rit';

  @override
  String get pelotonRejoined => 'Je doet weer mee';

  @override
  String get pelotonUndo => 'Ongedaan maken';

  @override
  String get accountSyncFailed =>
      'Synchroniseren lukte nu even niet. De app probeert het vanzelf opnieuw.';

  @override
  String get pelotonCopyCode => 'Code kopiëren';

  @override
  String get pelotonCodeCopied => 'Code gekopieerd';

  @override
  String get pelotonSignInAction => 'Inloggen';

  @override
  String pelotonAutoJoined(String name) {
    return 'Je bent nu maatjes met $name';
  }

  @override
  String get feedbackThanks => 'Dank je, je feedback is onderweg.';

  @override
  String get feedbackFailed =>
      'Je feedback kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String scoreSemanticLabel(int score, String tier) {
    return 'Score $score van 100, $tier';
  }

  @override
  String pelotonFriendAdded(String name) {
    return '$name is nu je maatje';
  }

  @override
  String get pelotonCodeInvalid =>
      'Die code werkt niet. Hij kan verlopen zijn.';

  @override
  String get pelotonUnnamedFriend => 'Fietser';

  @override
  String get pelotonRetry => 'Opnieuw proberen';

  @override
  String get pelotonPickWindows => 'Welke vensters leg je voor?';

  @override
  String get pelotonPickWindowsHint =>
      'Kies er twee of drie. Je maatjes geven aan wanneer ze kunnen.';

  @override
  String get pelotonChooseTogether => 'Kies samen een venster';

  @override
  String get pelotonOptionCanRide => 'Ik kan';

  @override
  String get pelotonOptionCannot => 'Kan niet';

  @override
  String pelotonOptionTally(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kunnen',
      one: '1 kan',
      zero: 'nog niemand',
    );
    return '$_temp0';
  }

  @override
  String get pelotonOptionFrontRunner => 'Voorop';

  @override
  String get pelotonOptionChoose => 'Kies dit';

  @override
  String get pelotonOptionChosen => 'De rit staat nu op dit venster';

  @override
  String get pelotonOptionVoteFailed =>
      'Je antwoord kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get pelotonOptionChosenFailed =>
      'De rit kon niet op het gekozen venster worden gezet. Probeer het opnieuw.';

  @override
  String pelotonWindowsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vensters voorgelegd',
      one: '1 venster voorgelegd',
    );
    return '$_temp0';
  }

  @override
  String get pelotonInviteToRide => 'Nodig een maatje uit';

  @override
  String get pelotonPickFriends => 'Wie gaat er mee?';

  @override
  String get pelotonInviteSent => 'Uitnodiging verstuurd';

  @override
  String get pelotonInviteFailed =>
      'Uitnodigen is niet gelukt. Probeer het opnieuw.';

  @override
  String get pelotonNeedFriendsFirst =>
      'Voeg eerst een maatje toe via Ritten, tab Peloton.';

  @override
  String get pelotonInviteAction => 'Uitnodigen';

  @override
  String get pelotonJoinTitle => 'Uitnodiging van een maatje';

  @override
  String get pelotonJoining => 'Je wordt toegevoegd…';

  @override
  String get pelotonSignInToJoin =>
      'Log eerst in en vul deze code daarna in onder Ritten, tab Peloton.';

  @override
  String get pelotonGoToPeloton => 'Naar Peloton';

  @override
  String pelotonInviteShareLink(String link, String code) {
    return 'Fiets met me mee in Ridewindow: $link\n\nNog geen app? De link werkt gewoon in je browser. Of vul code $code in onder Ritten, tab Peloton.';
  }

  @override
  String get ridesTabRides => 'Ritten';

  @override
  String get ridesTabBuddies => 'Peloton';

  @override
  String get ridesFilterAll => 'Alles';

  @override
  String get ridesFilterOrganising => 'Ik organiseer';

  @override
  String get ridesFilterJoined => 'Ik ga mee';

  @override
  String get ridesFilterSolo => 'Alleen ik';

  @override
  String get ridesFilterPending => 'Wacht op jou';

  @override
  String get ridesFilterEmpty => 'Geen ritten in dit filter';

  @override
  String get ridesFilterEmptyHint => 'Tik op “Alles” om je hele week te zien.';

  @override
  String get roleOrganiser => 'Jij organiseert';

  @override
  String roleJoinedWith(String name) {
    return 'Je gaat mee met $name';
  }

  @override
  String get roleSolo => 'Alleen jij';

  @override
  String rolePendingFrom(String name) {
    return '$name vraagt of je meegaat';
  }

  @override
  String ridePelotonGoing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gaan mee',
      one: '1 gaat mee',
      zero: 'Nog niemand geantwoord',
    );
    return '$_temp0';
  }

  @override
  String ridePelotonWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wachten nog',
      one: '1 wacht nog',
    );
    return '$_temp0';
  }

  @override
  String ridePelotonGoingShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mee',
      one: '1 mee',
    );
    return '$_temp0';
  }

  @override
  String ridePelotonWaitingShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wachten',
      one: '1 wacht',
    );
    return '$_temp0';
  }

  @override
  String get pelotonStatusGoing => 'gaat mee';

  @override
  String get pelotonStatusWaiting => 'nog geen antwoord';

  @override
  String get pelotonStatusDeclined => 'kan niet';

  @override
  String get pelotonCancelRide => 'Rit afzeggen';

  @override
  String get pelotonCancelRideTitle => 'Deze rit afzeggen?';

  @override
  String get pelotonCancelRideBody =>
      'Iedereen die je hebt uitgenodigd ziet de rit verdwijnen. Je eigen planning voor dit tijdvak gaat er ook af.';

  @override
  String get pelotonRideCancelled => 'Rit afgezegd';

  @override
  String get pelotonCancelFailed =>
      'Afzeggen is niet gelukt. Probeer het opnieuw.';

  @override
  String get pelotonNobodyInvitedYet => 'Nog niemand uitgenodigd';

  @override
  String get weatherDaylight => 'Daglicht';

  @override
  String daylightLightBetween(String from, String to) {
    return 'licht van $from tot $to';
  }

  @override
  String daylightMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get daylightVerdictFull => 'Volledig licht';

  @override
  String get daylightVerdictMostlyLight => 'Grotendeels licht';

  @override
  String get daylightVerdictPartlyDark => 'Deels donker';

  @override
  String get daylightVerdictMostlyDark => 'Grotendeels donker';

  @override
  String get daylightVerdictDark => 'Donker';

  @override
  String get daylightPolarDay => 'de zon gaat niet onder';

  @override
  String get daylightPolarNight => 'de zon komt niet op';

  @override
  String get daylightScoreTitle => 'Wat daglicht met dit venster doet';

  @override
  String daylightScoreSplit(int total, int light, int dark) {
    return 'Van de $total minuten van deze rit valt $light in het licht en $dark in het donker.';
  }

  @override
  String daylightScorePenalty(String weight, int points) {
    return 'Jouw gevoeligheid staat op “$weight”. Dat kost dit venster $points punten.';
  }

  @override
  String get daylightScoreAllLight =>
      'Deze rit valt helemaal in het licht, dus daglicht haalt er niets vanaf.';

  @override
  String daylightScoreNone(String weight) {
    return 'Jouw gevoeligheid staat op “$weight”, dus daglicht verandert de score van dit venster niet.';
  }

  @override
  String daylightScoreScale(int full) {
    return 'Bij deze stand verliest een venster dat volledig in het donker valt $full punten; bij de zwaarste stand zijn dat er 40. Een venster dat helemaal in het licht valt verliest niets.';
  }

  @override
  String get daylightInfoTitle => 'Daglicht';

  @override
  String get daylightInfo =>
      'De gouden band toont wanneer de zon boven de horizon staat, van middernacht tot middernacht. Jouw rit staat er als blok in. Hoe meer daarvan in het donker valt, hoe lager de score. Hoeveel precies stel je in bij Profiel → Jouw grenzen → Daglicht.\n\nDonkere ritten verdwijnen nooit helemaal uit de lijst: in december is het hier licht van 08:45 tot 16:30, en dan blijft er anders niets over.';

  @override
  String rideSunsetMostlyDark(String time) {
    return 'Zon onder om $time, grotendeels in het donker';
  }

  @override
  String rideSunsetPartly(String time) {
    return 'Zon onder om $time, laatste deel in de schemer';
  }

  @override
  String rideSunriseAfter(String time) {
    return 'Zon op om $time, begin nog in het donker';
  }

  @override
  String get toleranceDaylight => 'Daglicht';

  @override
  String get toleranceDaylightInfoTitle => 'Daglicht';

  @override
  String get toleranceDaylightInfo =>
      'Anders dan de drie hierboven is dit geen grens maar een gewicht: hoe zwaar telt het voor jou dat een rit in het donker valt.\n\nHelemaal links verandert er niets aan je scores. Helemaal rechts verliest een rit die volledig in het donker valt 40 van de 100 punten. Zulke ritten verdwijnen ook dan niet uit je lijst: ze staan achter de vensters bij daglicht.';

  @override
  String get daylightWeightOff => 'Maakt me niet uit';

  @override
  String get daylightWeightLight => 'donker telt licht mee';

  @override
  String get daylightWeightHalf => 'donker telt half mee';

  @override
  String get daylightWeightHeavy => 'donker telt zwaar mee';

  @override
  String get daylightWeightOnly => 'Alleen bij daglicht';

  @override
  String daylightWeightDesc(int points) {
    return 'Een rit die helemaal in het donker valt verliest $points van de 100 punten.';
  }

  @override
  String get daylightWeightDescNone => 'Donker telt niet mee in je scores.';

  @override
  String get locationGuessTitle => 'We weten niet waar je bent';

  @override
  String locationGuessBody(String city) {
    return 'Je ziet het weer voor $city. Zet locatie aan of kies zelf je stad.';
  }

  @override
  String get locationClockTitle => 'Je klok en je plek lopen uiteen';

  @override
  String locationClockBody(String city) {
    return 'Dit toestel staat in een andere tijdzone dan $city. De tijden hieronder zijn die van je toestel.';
  }

  @override
  String get locationFixAction => 'Kies je stad';

  @override
  String get analyticsAskTitle => 'Help je de app beter maken?';

  @override
  String get analyticsAskBody =>
      'Ridewindow kan anoniem bijhouden welke schermen je gebruikt, zodat ik zie wat werkt en wat niet. Geen locatie, geen tekst, geen e-mailadres, en je kunt het altijd weer uitzetten in Profiel.';

  @override
  String get analyticsAskYes => 'Ja, doe maar';

  @override
  String get analyticsAskNo => 'Nee, liever niet';

  @override
  String get analyticsSettingTitle => 'Anonieme gebruiksstatistiek';

  @override
  String get analyticsSettingOn => 'Aan, je helpt de app beter te maken';

  @override
  String get analyticsSettingOff => 'Uit, er verlaat niets je toestel';

  @override
  String notifWeeklyBody(String slot) {
    return 'Je beste moment: $slot';
  }

  @override
  String get notifWeeklyBodyEmpty =>
      'Kijk welke momenten er deze week in zitten';

  @override
  String roleDeclined(String name) {
    return 'Je zei nee tegen $name';
  }

  @override
  String get ridesFilterDeclined => 'Afgezegd';

  @override
  String get rideRejoin => 'Toch meegaan';

  @override
  String get rideRejoined => 'Je gaat toch mee';

  @override
  String get rideRejoinFailed => 'Dat is niet gelukt. Probeer het opnieuw.';

  @override
  String get homeViewWindows => 'Vensters';

  @override
  String get homeViewBlocks => 'Blok';

  @override
  String get homeSortBest => 'Beste eerst';

  @override
  String get homeSortTime => 'Op tijd';

  @override
  String blockRidableSpans(String spans) {
    return 'je kunt rijden: $spans';
  }

  @override
  String blockLongestRide(int hours) {
    return 'Langste rit hier: $hours uur';
  }

  @override
  String get daylightWeightNone => 'donker telt niet mee';

  @override
  String get linkOpenFailed => 'De link kon niet geopend worden.';

  @override
  String get linkCopyAction => 'Adres kopiëren';

  @override
  String get linkCopied => 'Adres gekopieerd';

  @override
  String daylightLightShort(String from, String to) {
    return 'licht $from–$to';
  }

  @override
  String get groupErrorFull =>
      'Deze groep heeft al 30 leden, het maximum. Een beheerder kan eerst iemand uit de groep halen.';

  @override
  String groupErrorFullNamed(String group) {
    return '$group heeft al 30 leden, het maximum. Haal eerst iemand uit de groep.';
  }

  @override
  String get groupErrorTooManyGroupsSelf =>
      'Je zit al in 10 groepen, het maximum. Verlaat eerst een andere groep.';

  @override
  String groupErrorTooManyGroupsOther(String name) {
    return '$name zit al in 10 groepen, het maximum.';
  }

  @override
  String get groupErrorInviteInvalid =>
      'Deze groepslink werkt niet meer. Vraag iemand uit de groep om een nieuwe.';

  @override
  String get groupErrorLastAdmin =>
      'Je bent de enige beheerder. Maak eerst iemand anders beheerder, dan kun je dit afgeven.';

  @override
  String get groupErrorNameInvalid =>
      'Geef de groep een naam van 1 tot 40 tekens.';

  @override
  String get groupErrorSignedOut => 'Log eerst in om met groepen te werken.';

  @override
  String get groupErrorNotMember => 'Je bent geen lid meer van deze groep.';

  @override
  String get groupErrorNotFriend =>
      'Je kunt alleen je eigen maatjes voordragen.';

  @override
  String get groupErrorNotAllowed =>
      'Alleen een beheerder van de groep kan dit doen.';

  @override
  String get groupErrorTooManyRequests =>
      'Er liggen al 30 aanvragen bij de beheerders. Probeer het later opnieuw.';

  @override
  String get groupErrorGeneric => 'Dat is niet gelukt. Probeer het opnieuw.';

  @override
  String get groupNameLabel => 'Naam';

  @override
  String get groupCreateTitle => 'Nieuwe groep';

  @override
  String get groupCreateHint =>
      'Geef hem een naam die je club herkent. Je kunt hem later wijzigen.';

  @override
  String get groupsCreateAction => 'Groep maken';

  @override
  String get groupRulesTitle => 'Zo werken groepen';

  @override
  String get groupRuleProposing =>
      'Ieder lid kan mensen voordragen: met de groepslink of door een maatje voor te dragen. Een beheerder beslist wie er lid wordt. Draagt een beheerder iemand voor, dan is die meteen lid.';

  @override
  String get groupRuleLimits =>
      'Een groep heeft maximaal 30 leden, en je zit in maximaal 10 groepen.';

  @override
  String get groupRuleVisibility =>
      'Leden zien elkaars naam, wie beheerder is en elkaars antwoord op groepsritten. Je rooster, je instellingen en je e-mailadres zien ze niet.';

  @override
  String get groupRuleRides =>
      'Een groepsrit zien alle huidige leden, ook wie later lid werd. Wie de groep verlaat, ziet de groepsritten niet meer.';

  @override
  String get groupRuleLeaving =>
      'Je kunt een groep altijd zelf verlaten. Terugkomen gaat met een nieuwe aanvraag.';

  @override
  String get groupRuleLastAdmin =>
      'Vertrekt de laatste beheerder, dan wordt het lid dat er het langst in zit beheerder. Vertrekt het laatste lid, dan verdwijnt de groep.';

  @override
  String get groupRuleDisband =>
      'Een beheerder kan de groep opheffen. Ritten waarop al iemand geantwoord heeft, blijven staan zonder groepslabel.';

  @override
  String get groupsSection => 'Groepen';

  @override
  String get groupsNew => 'Nieuwe groep';

  @override
  String get groupsEmptyTitle => 'Fiets je met een vaste club?';

  @override
  String get groupsEmptyHint =>
      'Maak een groep. Dan zet je een rit in één keer uit voor iedereen.';

  @override
  String groupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leden',
      one: '1 lid',
    );
    return '$_temp0';
  }

  @override
  String get groupAdminChip => 'beheerder';

  @override
  String get groupRequestPendingShort => 'aanvraag loopt';

  @override
  String groupHeroSubtitle(String count, String date) {
    return '$count · sinds $date';
  }

  @override
  String get groupMembersSection => 'Leden';

  @override
  String groupYou(String name) {
    return '$name (jij)';
  }

  @override
  String get groupOnlyYouHint =>
      'Je bent nog alleen. Deel de groepslink of draag een maatje voor.';

  @override
  String get groupNotFound =>
      'Deze groep bestaat niet meer, of je bent er geen lid meer van.';

  @override
  String get groupRequestPending => 'Je aanvraag ligt bij de beheerders';

  @override
  String get groupWithdrawRequest => 'Aanvraag intrekken';

  @override
  String get groupRequestWithdrawn => 'Aanvraag ingetrokken';

  @override
  String get groupMemberMenuTooltip => 'Opties voor dit lid';

  @override
  String get groupMakeAdmin => 'Beheerder maken';

  @override
  String get groupRemoveAdmin => 'Beheerder af';

  @override
  String get groupRemoveMember => 'Uit de groep halen';

  @override
  String groupMadeAdmin(String name) {
    return '$name is nu beheerder';
  }

  @override
  String groupAdminRemoved(String name) {
    return '$name is geen beheerder meer';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name is uit de groep gehaald';
  }

  @override
  String get groupRequestsSection => 'Aanvragen';

  @override
  String get groupRequestViaLink => 'via de groepslink';

  @override
  String groupRequestProposedBy(String name) {
    return 'voorgedragen door $name';
  }

  @override
  String get groupAccept => 'Accepteren';

  @override
  String get groupReject => 'Afwijzen';

  @override
  String groupRequestAccepted(String name) {
    return '$name is nu lid';
  }

  @override
  String groupRequestRejected(String name) {
    return 'Aanvraag van $name afgewezen';
  }

  @override
  String get groupAddFriend => 'Maatje toevoegen';

  @override
  String get groupProposeFriend => 'Maatje voordragen';

  @override
  String get groupAddFriendHint => 'Wie je toevoegt is meteen lid.';

  @override
  String get groupProposeFriendHint =>
      'Een beheerder beslist of je maatje lid wordt.';

  @override
  String get groupAlreadyMember => 'al lid';

  @override
  String get groupAddAction => 'Toevoegen';

  @override
  String get groupProposeAction => 'Voordragen';

  @override
  String groupFriendAddedMember(String name) {
    return '$name is nu lid';
  }

  @override
  String groupFriendProposed(String name) {
    return '$name is voorgedragen. Een beheerder beslist.';
  }

  @override
  String get groupNoFriendsToPropose =>
      'Je hebt nog geen maatjes. Nodig er een uit onder Maatjes op de Peloton-tab.';

  @override
  String groupOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aanvragen',
      one: '1 aanvraag',
    );
    return '$_temp0';
  }

  @override
  String get groupShareLink => 'Deel de groepslink';

  @override
  String groupShareText(String group, String link, String code) {
    return 'Fiets mee met $group in Ridewindow: $link\n\nNog geen app? De link werkt gewoon in je browser. Of vul code $code in onder Ritten, tab Peloton. Een beheerder van de groep laat je erin.';
  }

  @override
  String get groupMenuTooltip => 'Groepsopties';

  @override
  String get groupReplaceLink => 'Link vervangen';

  @override
  String get groupLinkReplaced =>
      'Nieuwe link gemaakt. De oude werkt niet meer.';

  @override
  String get groupShareAction => 'Delen';

  @override
  String get groupRename => 'Naam wijzigen';

  @override
  String get groupSave => 'Opslaan';

  @override
  String get groupLeave => 'Groep verlaten';

  @override
  String groupLeaveTitle(String group) {
    return '$group verlaten?';
  }

  @override
  String get groupLeaveBody =>
      'Je ziet de groep en zijn ritten dan niet meer. Terugkomen gaat met een nieuwe aanvraag.';

  @override
  String groupLeaveBodySuccessor(String name) {
    return 'Je bent de enige beheerder. $name zit er het langst in en wordt dan beheerder. Terugkomen gaat met een nieuwe aanvraag.';
  }

  @override
  String get groupLeaveBodyLast =>
      'Je bent het laatste lid. De groep en de link verdwijnen dan.';

  @override
  String get groupLeaveAction => 'Verlaten';

  @override
  String groupLeft(String group) {
    return '$group verlaten';
  }

  @override
  String get groupDisband => 'Groep opheffen';

  @override
  String groupDisbandTitle(String group) {
    return '$group opheffen?';
  }

  @override
  String groupDisbandBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'De groep en de link verdwijnen voor alle $count leden.',
      one: 'De groep en de link verdwijnen voor het enige lid.',
    );
    return '$_temp0 Ritten waarop iemand al geantwoord heeft blijven staan, zonder groepslabel. Dit kun je niet terugdraaien.';
  }

  @override
  String get groupDisbandAction => 'Opheffen';

  @override
  String groupDisbanded(String group) {
    return '$group is opgeheven';
  }
}
