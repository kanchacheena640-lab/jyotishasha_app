import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Jyotishasha'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @horoscope.
  ///
  /// In en, this message translates to:
  /// **'Horoscope'**
  String get horoscope;

  /// No description provided for @dailyHoroscope.
  ///
  /// In en, this message translates to:
  /// **'Daily Horoscope'**
  String get dailyHoroscope;

  /// No description provided for @monthlyHoroscope.
  ///
  /// In en, this message translates to:
  /// **'Monthly Horoscope'**
  String get monthlyHoroscope;

  /// No description provided for @yearlyHoroscope.
  ///
  /// In en, this message translates to:
  /// **'Yearly Horoscope'**
  String get yearlyHoroscope;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Free Tools'**
  String get tools;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @askNow.
  ///
  /// In en, this message translates to:
  /// **'Ask Now'**
  String get askNow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Details'**
  String get enterDetails;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @timeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Time of Birth'**
  String get timeOfBirth;

  /// No description provided for @placeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Place of Birth'**
  String get placeOfBirth;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @kundali.
  ///
  /// In en, this message translates to:
  /// **'Kundali'**
  String get kundali;

  /// No description provided for @kundaliDetails.
  ///
  /// In en, this message translates to:
  /// **'Kundali Details'**
  String get kundaliDetails;

  /// No description provided for @panchang.
  ///
  /// In en, this message translates to:
  /// **'Panchang'**
  String get panchang;

  /// No description provided for @todayPanchang.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Panchang'**
  String get todayPanchang;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @askNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Now 🔮'**
  String get askNowTitle;

  /// No description provided for @chooseTopic.
  ///
  /// In en, this message translates to:
  /// **'Choose a Topic'**
  String get chooseTopic;

  /// No description provided for @startConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start your free consultation by typing your question below 💬'**
  String get startConsultation;

  /// No description provided for @typeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type your question...'**
  String get typeQuestion;

  /// No description provided for @unableToLoadAstrology.
  ///
  /// In en, this message translates to:
  /// **'Unable to load astrology data'**
  String get unableToLoadAstrology;

  /// No description provided for @yourInsights.
  ///
  /// In en, this message translates to:
  /// **'Your Insights'**
  String get yourInsights;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share With Friends'**
  String get shareWithFriends;

  /// No description provided for @myAstrologyProfileShareText.
  ///
  /// In en, this message translates to:
  /// **'My Astrology Profile from Jyotishasha ✨'**
  String get myAstrologyProfileShareText;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get dobLabel;

  /// No description provided for @tobLabel.
  ///
  /// In en, this message translates to:
  /// **'TOB'**
  String get tobLabel;

  /// No description provided for @pobLabel.
  ///
  /// In en, this message translates to:
  /// **'POB'**
  String get pobLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @rashiLabel.
  ///
  /// In en, this message translates to:
  /// **'Rashi'**
  String get rashiLabel;

  /// No description provided for @lagnaLabel.
  ///
  /// In en, this message translates to:
  /// **'Lagna'**
  String get lagnaLabel;

  /// No description provided for @moonSign.
  ///
  /// In en, this message translates to:
  /// **'Moon Sign'**
  String get moonSign;

  /// No description provided for @element.
  ///
  /// In en, this message translates to:
  /// **'Element'**
  String get element;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @rulingPlanet.
  ///
  /// In en, this message translates to:
  /// **'Ruling Planet'**
  String get rulingPlanet;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get shareResult;

  /// No description provided for @astrologyProfile.
  ///
  /// In en, this message translates to:
  /// **'Astrology Profile'**
  String get astrologyProfile;

  /// No description provided for @ascendantLabel.
  ///
  /// In en, this message translates to:
  /// **'Ascendant'**
  String get ascendantLabel;

  /// No description provided for @nakshatraLabel.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get nakshatraLabel;

  /// No description provided for @activePlanetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Planets'**
  String get activePlanetsLabel;

  /// No description provided for @categoryProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get categoryProfile;

  /// No description provided for @categoryPlanets.
  ///
  /// In en, this message translates to:
  /// **'Planets'**
  String get categoryPlanets;

  /// No description provided for @categoryHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get categoryHouse;

  /// No description provided for @categoryMahadasha.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha'**
  String get categoryMahadasha;

  /// No description provided for @categoryLifeAspect.
  ///
  /// In en, this message translates to:
  /// **'Life Aspect'**
  String get categoryLifeAspect;

  /// No description provided for @categoryYogDosh.
  ///
  /// In en, this message translates to:
  /// **'Yog & Dosh'**
  String get categoryYogDosh;

  /// No description provided for @mahadashaTimeline.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha Timeline'**
  String get mahadashaTimeline;

  /// No description provided for @yourAscendant.
  ///
  /// In en, this message translates to:
  /// **'Your Ascendant (Lagna)'**
  String get yourAscendant;

  /// No description provided for @enterBirthDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Birth Details'**
  String get enterBirthDetails;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself 🌞'**
  String get tellUsAboutYourself;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterDob.
  ///
  /// In en, this message translates to:
  /// **'Please enter your DOB'**
  String get pleaseEnterDob;

  /// No description provided for @pleaseEnterTob.
  ///
  /// In en, this message translates to:
  /// **'Please enter your TOB'**
  String get pleaseEnterTob;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @bootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap failed'**
  String get bootstrapFailed;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @darshanTitleSuffix.
  ///
  /// In en, this message translates to:
  /// **'Darshan'**
  String get darshanTitleSuffix;

  /// No description provided for @mantraIsPlaying.
  ///
  /// In en, this message translates to:
  /// **'Mantra is Playing...'**
  String get mantraIsPlaying;

  /// No description provided for @adSpaceSilent.
  ///
  /// In en, this message translates to:
  /// **'Ad space (silent)'**
  String get adSpaceSilent;

  /// No description provided for @todaysDayLord.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Day Lord'**
  String get todaysDayLord;

  /// No description provided for @darshanWithMantra.
  ///
  /// In en, this message translates to:
  /// **'Darshan with Mantra'**
  String get darshanWithMantra;

  /// No description provided for @createManualKundali.
  ///
  /// In en, this message translates to:
  /// **'Create Manual Kundali'**
  String get createManualKundali;

  /// No description provided for @enterNameDateBirthplace.
  ///
  /// In en, this message translates to:
  /// **'Enter name, date & birthplace'**
  String get enterNameDateBirthplace;

  /// No description provided for @exploreYourChart.
  ///
  /// In en, this message translates to:
  /// **'Explore Your Chart'**
  String get exploreYourChart;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @weeklyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Weekly horoscope is coming soon...'**
  String get weeklyComingSoon;

  /// No description provided for @freeKundali.
  ///
  /// In en, this message translates to:
  /// **'Free Kundali'**
  String get freeKundali;

  /// No description provided for @lagnaFinder.
  ///
  /// In en, this message translates to:
  /// **'Lagna Finder'**
  String get lagnaFinder;

  /// No description provided for @rashiFinder.
  ///
  /// In en, this message translates to:
  /// **'Rashi Finder'**
  String get rashiFinder;

  /// No description provided for @gemstoneSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Gemstone Suggestion'**
  String get gemstoneSuggestion;

  /// No description provided for @currentDasha.
  ///
  /// In en, this message translates to:
  /// **'Current Dasha'**
  String get currentDasha;

  /// No description provided for @fullTimeline.
  ///
  /// In en, this message translates to:
  /// **'Full Timeline'**
  String get fullTimeline;

  /// No description provided for @housePrefix.
  ///
  /// In en, this message translates to:
  /// **'House {num}'**
  String housePrefix(Object num);

  /// No description provided for @gemstoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Gemstone'**
  String get gemstoneLabel;

  /// No description provided for @substoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-stone'**
  String get substoneLabel;

  /// No description provided for @planetLabel.
  ///
  /// In en, this message translates to:
  /// **'Planet'**
  String get planetLabel;

  /// No description provided for @gemstoneParagraph.
  ///
  /// In en, this message translates to:
  /// **'Gemstone Insight'**
  String get gemstoneParagraph;

  /// No description provided for @houseTitle.
  ///
  /// In en, this message translates to:
  /// **'House {house}'**
  String houseTitle(Object house);

  /// No description provided for @houseMeaning.
  ///
  /// In en, this message translates to:
  /// **'House Meaning'**
  String get houseMeaning;

  /// No description provided for @notablePlacements.
  ///
  /// In en, this message translates to:
  /// **'Notable Placements'**
  String get notablePlacements;

  /// No description provided for @houseLord.
  ///
  /// In en, this message translates to:
  /// **'House Lord'**
  String get houseLord;

  /// No description provided for @activateNow.
  ///
  /// In en, this message translates to:
  /// **'Activate Now'**
  String get activateNow;

  /// No description provided for @meaningNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Meaning not available.'**
  String get meaningNotAvailable;

  /// No description provided for @thisHouseDealsWith.
  ///
  /// In en, this message translates to:
  /// **'This house deals with {text}.'**
  String thisHouseDealsWith(Object text);

  /// No description provided for @noMajorPlacements.
  ///
  /// In en, this message translates to:
  /// **'No major planetary placements here.'**
  String get noMajorPlacements;

  /// No description provided for @lordOfHouseIs.
  ///
  /// In en, this message translates to:
  /// **'The Lord of House {house} is {lord}.'**
  String lordOfHouseIs(Object house, Object lord);

  /// No description provided for @defaultHouseActivation.
  ///
  /// In en, this message translates to:
  /// **'Do small consistent actions to activate this house.'**
  String get defaultHouseActivation;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get example;

  /// No description provided for @keyHouses.
  ///
  /// In en, this message translates to:
  /// **'Key Houses'**
  String get keyHouses;

  /// No description provided for @keyPlanets.
  ///
  /// In en, this message translates to:
  /// **'Key Planets'**
  String get keyPlanets;

  /// No description provided for @importantYogas.
  ///
  /// In en, this message translates to:
  /// **'Important Yogas'**
  String get importantYogas;

  /// No description provided for @housesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Houses: {value}'**
  String housesPrefix(Object value);

  /// No description provided for @planetsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Planets: {value}'**
  String planetsPrefix(Object value);

  /// No description provided for @shareLifeAspectText.
  ///
  /// In en, this message translates to:
  /// **'✨ Life Aspect Insight — Generated by Jyotishasha App'**
  String get shareLifeAspectText;

  /// No description provided for @currentMahadasha.
  ///
  /// In en, this message translates to:
  /// **'Current Mahadasha'**
  String get currentMahadasha;

  /// No description provided for @allMahadashas.
  ///
  /// In en, this message translates to:
  /// **'All Mahadashas'**
  String get allMahadashas;

  /// No description provided for @antardashaTimeline.
  ///
  /// In en, this message translates to:
  /// **'Antardasha Timeline'**
  String get antardashaTimeline;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @mahadashaOf.
  ///
  /// In en, this message translates to:
  /// **'{name} Mahadasha'**
  String mahadashaOf(Object name);

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @dashaDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dasha data is not available for this profile.'**
  String get dashaDataUnavailable;

  /// No description provided for @planetOverview.
  ///
  /// In en, this message translates to:
  /// **'Planet Overview'**
  String get planetOverview;

  /// No description provided for @benefitArea.
  ///
  /// In en, this message translates to:
  /// **'Benefit Area'**
  String get benefitArea;

  /// No description provided for @recommendedRemedy.
  ///
  /// In en, this message translates to:
  /// **'Recommended Remedy'**
  String get recommendedRemedy;

  /// No description provided for @detailedInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Detailed Interpretation'**
  String get detailedInterpretation;

  /// No description provided for @generatedByApp.
  ///
  /// In en, this message translates to:
  /// **'Generated by Jyotishasha App'**
  String get generatedByApp;

  /// No description provided for @yogDoshTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Yog / Dosh Analysis'**
  String get yogDoshTitleFallback;

  /// No description provided for @yogDoshStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active in your chart'**
  String get yogDoshStatusActive;

  /// No description provided for @yogDoshStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Not active in chart'**
  String get yogDoshStatusInactive;

  /// No description provided for @yogDoshStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get yogDoshStrengthLabel;

  /// No description provided for @yogDoshMainExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'What this Yog / Dosh means'**
  String get yogDoshMainExplanationTitle;

  /// No description provided for @yogDoshPositivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Key blessings & strengths'**
  String get yogDoshPositivesTitle;

  /// No description provided for @yogDoshChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible challenges'**
  String get yogDoshChallengesTitle;

  /// No description provided for @yogDoshReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this Yog / Dosh is formed'**
  String get yogDoshReasonsTitle;

  /// No description provided for @yogDoshDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed explanation'**
  String get yogDoshDetailTitle;

  /// No description provided for @yogDoshSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get yogDoshSummaryTitle;

  /// No description provided for @yogDoshEvaluationTitle.
  ///
  /// In en, this message translates to:
  /// **'Astrological evaluation'**
  String get yogDoshEvaluationTitle;

  /// No description provided for @yogDoshOverallStrength.
  ///
  /// In en, this message translates to:
  /// **'Overall strength'**
  String get yogDoshOverallStrength;

  /// No description provided for @yogDoshMitigationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mitigations / Balancing factors'**
  String get yogDoshMitigationsTitle;

  /// No description provided for @yogDoshTriggersTitle.
  ///
  /// In en, this message translates to:
  /// **'Trigger status'**
  String get yogDoshTriggersTitle;

  /// No description provided for @yogDoshContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart context (for reference)'**
  String get yogDoshContextTitle;

  /// No description provided for @yogDoshContextLagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna sign'**
  String get yogDoshContextLagna;

  /// No description provided for @yogDoshContextMars.
  ///
  /// In en, this message translates to:
  /// **'Mars sign (from Lagna)'**
  String get yogDoshContextMars;

  /// No description provided for @yogDoshContextMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon sign'**
  String get yogDoshContextMoon;

  /// No description provided for @yogDoshRemediesTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested remedies'**
  String get yogDoshRemediesTitle;

  /// No description provided for @yogDoshFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Based on your Kundali data and configured Yog/Dosh rules.'**
  String get yogDoshFooterNote;

  /// No description provided for @yogDoshShareSuffix.
  ///
  /// In en, this message translates to:
  /// **'— Jyotishasha Analysis'**
  String get yogDoshShareSuffix;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Jyotishasha'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover your personalized astrological path'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// No description provided for @loginFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get loginFacebook;

  /// No description provided for @loginApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginApple;

  /// No description provided for @loginAppleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple login coming soon 🍎'**
  String get loginAppleComingSoon;

  /// No description provided for @loginTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms & Privacy Policy'**
  String get loginTerms;

  /// No description provided for @loadingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get loadingPleaseWait;

  /// No description provided for @manualKundaliTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Kundali'**
  String get manualKundaliTitle;

  /// No description provided for @dobField.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (DD-MM-YYYY)'**
  String get dobField;

  /// No description provided for @tobField.
  ///
  /// In en, this message translates to:
  /// **'Time of Birth (HH:MM)'**
  String get tobField;

  /// No description provided for @placeOfBirthField.
  ///
  /// In en, this message translates to:
  /// **'Place of Birth'**
  String get placeOfBirthField;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @pleaseSelectValidPlace.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid place'**
  String get pleaseSelectValidPlace;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @generateKundali.
  ///
  /// In en, this message translates to:
  /// **'Generate Kundali'**
  String get generateKundali;

  /// No description provided for @yourKundali.
  ///
  /// In en, this message translates to:
  /// **'Your Kundali'**
  String get yourKundali;

  /// No description provided for @myKundaliShareText.
  ///
  /// In en, this message translates to:
  /// **'My Kundali Profile from Jyotishasha ✨'**
  String get myKundaliShareText;

  /// No description provided for @shubhMuhurth.
  ///
  /// In en, this message translates to:
  /// **'🕉️ Shubh Muhurth'**
  String get shubhMuhurth;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @selectOccasion.
  ///
  /// In en, this message translates to:
  /// **'Select Occasion'**
  String get selectOccasion;

  /// No description provided for @noMuhurthFound.
  ///
  /// In en, this message translates to:
  /// **'No Shubh Muhurth found 😔'**
  String get noMuhurthFound;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @tithiLabel.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get tithiLabel;

  /// No description provided for @weekdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weekdayLabel;

  /// No description provided for @reasonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get reasonsLabel;

  /// No description provided for @occasion_naamkaran.
  ///
  /// In en, this message translates to:
  /// **'Naamkaran'**
  String get occasion_naamkaran;

  /// No description provided for @occasion_marriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get occasion_marriage;

  /// No description provided for @occasion_grah_pravesh.
  ///
  /// In en, this message translates to:
  /// **'Grah Pravesh'**
  String get occasion_grah_pravesh;

  /// No description provided for @occasion_property.
  ///
  /// In en, this message translates to:
  /// **'Property Purchase'**
  String get occasion_property;

  /// No description provided for @occasion_gold.
  ///
  /// In en, this message translates to:
  /// **'Buy Gold'**
  String get occasion_gold;

  /// No description provided for @occasion_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Buy Vehicle'**
  String get occasion_vehicle;

  /// No description provided for @occasion_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get occasion_travel;

  /// No description provided for @occasion_childbirth.
  ///
  /// In en, this message translates to:
  /// **'Childbirth'**
  String get occasion_childbirth;

  /// No description provided for @scoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{score}/5'**
  String scoreOutOf(Object score);

  /// No description provided for @panchangTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s Panchang'**
  String get panchangTitle;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @mainPanchangElements.
  ///
  /// In en, this message translates to:
  /// **'Main Panchang Elements'**
  String get mainPanchangElements;

  /// No description provided for @tithi.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get tithi;

  /// No description provided for @nakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get nakshatra;

  /// No description provided for @yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @karana.
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get karana;

  /// No description provided for @weekday.
  ///
  /// In en, this message translates to:
  /// **'Vaar'**
  String get weekday;

  /// No description provided for @panchak.
  ///
  /// In en, this message translates to:
  /// **'Panchak'**
  String get panchak;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @abhijitMuhurta.
  ///
  /// In en, this message translates to:
  /// **'Abhijit Muhurta'**
  String get abhijitMuhurta;

  /// No description provided for @rahuKaal.
  ///
  /// In en, this message translates to:
  /// **'Rahu Kaal'**
  String get rahuKaal;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Unable to load Panchang data'**
  String get loadingError;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get locationPickerTitle;

  /// No description provided for @addProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Profile'**
  String get addProfileTitle;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @selectDob.
  ///
  /// In en, this message translates to:
  /// **'Select DOB'**
  String get selectDob;

  /// No description provided for @tob.
  ///
  /// In en, this message translates to:
  /// **'Time of Birth'**
  String get tob;

  /// No description provided for @selectTob.
  ///
  /// In en, this message translates to:
  /// **'Select TOB'**
  String get selectTob;

  /// No description provided for @enterPlaceOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please enter Place of Birth'**
  String get enterPlaceOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get profileSaveFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @noActiveProfile.
  ///
  /// In en, this message translates to:
  /// **'No active profile selected'**
  String get noActiveProfile;

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Personal Astrology Reports'**
  String get reports_title;

  /// No description provided for @reports_category_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reports_category_all;

  /// No description provided for @reports_price_prefix.
  ///
  /// In en, this message translates to:
  /// **'₹'**
  String get reports_price_prefix;

  /// No description provided for @reports_buy_now.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get reports_buy_now;

  /// No description provided for @reports_other_buy_button.
  ///
  /// In en, this message translates to:
  /// **'Buy Now ₹{price}'**
  String reports_other_buy_button(Object price);

  /// No description provided for @reports_no_reports.
  ///
  /// In en, this message translates to:
  /// **'No reports available'**
  String get reports_no_reports;

  /// No description provided for @checkout_fill_details.
  ///
  /// In en, this message translates to:
  /// **'Fill Your Details'**
  String get checkout_fill_details;

  /// No description provided for @checkout_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get checkout_name;

  /// No description provided for @checkout_name_error.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get checkout_name_error;

  /// No description provided for @checkout_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get checkout_email;

  /// No description provided for @checkout_email_error.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get checkout_email_error;

  /// No description provided for @checkout_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get checkout_phone;

  /// No description provided for @checkout_dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (YYYY-MM-DD)'**
  String get checkout_dob;

  /// No description provided for @checkout_tob.
  ///
  /// In en, this message translates to:
  /// **'Time of Birth (HH:MM)'**
  String get checkout_tob;

  /// No description provided for @checkout_pob.
  ///
  /// In en, this message translates to:
  /// **'Place of Birth'**
  String get checkout_pob;

  /// No description provided for @checkout_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get checkout_language;

  /// No description provided for @checkout_language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get checkout_language_en;

  /// No description provided for @checkout_language_hi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get checkout_language_hi;

  /// No description provided for @checkout_submit_success.
  ///
  /// In en, this message translates to:
  /// **'Form submitted (Next: Payment setup)'**
  String get checkout_submit_success;

  /// No description provided for @checkout_proceed_pay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Pay ₹{price}'**
  String checkout_proceed_pay(Object price);

  /// No description provided for @sub_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get sub_title;

  /// No description provided for @sub_description.
  ///
  /// In en, this message translates to:
  /// **'₹99/month and ₹999/year plans with feature list and Subscribe Now button will be here.'**
  String get sub_description;

  /// No description provided for @sub_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan – ₹99'**
  String get sub_monthly;

  /// No description provided for @sub_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly Plan – ₹999'**
  String get sub_yearly;

  /// No description provided for @sub_features_title.
  ///
  /// In en, this message translates to:
  /// **'Features Included'**
  String get sub_features_title;

  /// No description provided for @sub_button_subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get sub_button_subscribe;

  /// No description provided for @profile_lagna_finder.
  ///
  /// In en, this message translates to:
  /// **'Lagna Finder'**
  String get profile_lagna_finder;

  /// No description provided for @profile_rashi_finder.
  ///
  /// In en, this message translates to:
  /// **'Rashi Finder'**
  String get profile_rashi_finder;

  /// No description provided for @profile_gemstone_suggestion.
  ///
  /// In en, this message translates to:
  /// **'Gemstone Suggestion'**
  String get profile_gemstone_suggestion;

  /// No description provided for @astro_loading_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load astrology data'**
  String get astro_loading_error;

  /// No description provided for @astro_insights_title.
  ///
  /// In en, this message translates to:
  /// **'Your Insights'**
  String get astro_insights_title;

  /// No description provided for @astro_share_button.
  ///
  /// In en, this message translates to:
  /// **'Share With Friends'**
  String get astro_share_button;

  /// No description provided for @tool_share_result.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get tool_share_result;

  /// No description provided for @tool_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get tool_no_data;

  /// No description provided for @tool_dob.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get tool_dob;

  /// No description provided for @tool_tob.
  ///
  /// In en, this message translates to:
  /// **'TOB'**
  String get tool_tob;

  /// No description provided for @tool_pob.
  ///
  /// In en, this message translates to:
  /// **'POB'**
  String get tool_pob;

  /// No description provided for @tool_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tool_name;

  /// No description provided for @tool_rashi.
  ///
  /// In en, this message translates to:
  /// **'Rashi'**
  String get tool_rashi;

  /// No description provided for @tool_lagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna'**
  String get tool_lagna;

  /// No description provided for @tool_moon_sign.
  ///
  /// In en, this message translates to:
  /// **'Moon Sign'**
  String get tool_moon_sign;

  /// No description provided for @tool_element.
  ///
  /// In en, this message translates to:
  /// **'Element'**
  String get tool_element;

  /// No description provided for @tool_symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get tool_symbol;

  /// No description provided for @tool_ruling_planet.
  ///
  /// In en, this message translates to:
  /// **'Ruling Planet'**
  String get tool_ruling_planet;

  /// No description provided for @tool_zodiac_image_url.
  ///
  /// In en, this message translates to:
  /// **'Zodiac Image URL'**
  String get tool_zodiac_image_url;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Astrology Profile'**
  String get profile_title;

  /// No description provided for @profile_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_name;

  /// No description provided for @profile_dob.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get profile_dob;

  /// No description provided for @profile_tob.
  ///
  /// In en, this message translates to:
  /// **'TOB'**
  String get profile_tob;

  /// No description provided for @profile_pob.
  ///
  /// In en, this message translates to:
  /// **'POB'**
  String get profile_pob;

  /// No description provided for @profile_rashi.
  ///
  /// In en, this message translates to:
  /// **'Rashi'**
  String get profile_rashi;

  /// No description provided for @profile_lagna.
  ///
  /// In en, this message translates to:
  /// **'Ascendant'**
  String get profile_lagna;

  /// No description provided for @profile_nakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get profile_nakshatra;

  /// No description provided for @profile_active_planets.
  ///
  /// In en, this message translates to:
  /// **'Active Planets'**
  String get profile_active_planets;

  /// No description provided for @cat_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get cat_profile;

  /// No description provided for @cat_planets.
  ///
  /// In en, this message translates to:
  /// **'Planets'**
  String get cat_planets;

  /// No description provided for @cat_house.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get cat_house;

  /// No description provided for @cat_mahadasha.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha'**
  String get cat_mahadasha;

  /// No description provided for @cat_life_aspect.
  ///
  /// In en, this message translates to:
  /// **'Life Aspect'**
  String get cat_life_aspect;

  /// No description provided for @cat_yog_dosh.
  ///
  /// In en, this message translates to:
  /// **'Yog & Dosh'**
  String get cat_yog_dosh;

  /// No description provided for @tool_mahadasha.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha'**
  String get tool_mahadasha;

  /// No description provided for @tool_mahadasha_timeline.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha Timeline'**
  String get tool_mahadasha_timeline;

  /// No description provided for @lagna_title.
  ///
  /// In en, this message translates to:
  /// **'Your Ascendant (Lagna):'**
  String get lagna_title;

  /// No description provided for @house_header.
  ///
  /// In en, this message translates to:
  /// **'House {house}'**
  String house_header(Object house);

  /// No description provided for @house_meaning_not_available.
  ///
  /// In en, this message translates to:
  /// **'Meaning not available.'**
  String get house_meaning_not_available;

  /// No description provided for @house_deals_with.
  ///
  /// In en, this message translates to:
  /// **'This house deals with {text}.'**
  String house_deals_with(Object text);

  /// No description provided for @house_no_placements.
  ///
  /// In en, this message translates to:
  /// **'No major planetary placements here.'**
  String get house_no_placements;

  /// No description provided for @house_lord_line.
  ///
  /// In en, this message translates to:
  /// **'The Lord of House {house} is {lord}.'**
  String house_lord_line(Object house, Object lord);

  /// No description provided for @house_remedy_default.
  ///
  /// In en, this message translates to:
  /// **'Do small consistent actions to activate this house.'**
  String get house_remedy_default;

  /// No description provided for @house_meaning_title.
  ///
  /// In en, this message translates to:
  /// **'House Meaning'**
  String get house_meaning_title;

  /// No description provided for @house_placements_title.
  ///
  /// In en, this message translates to:
  /// **'Notable Placements'**
  String get house_placements_title;

  /// No description provided for @house_lord_title.
  ///
  /// In en, this message translates to:
  /// **'House Lord'**
  String get house_lord_title;

  /// No description provided for @house_activate_title.
  ///
  /// In en, this message translates to:
  /// **'Activate Now'**
  String get house_activate_title;

  /// No description provided for @yogDoshActive.
  ///
  /// In en, this message translates to:
  /// **'Active in your chart'**
  String get yogDoshActive;

  /// No description provided for @yogDoshInactive.
  ///
  /// In en, this message translates to:
  /// **'Not active in chart'**
  String get yogDoshInactive;

  /// No description provided for @yogDoshStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength: {value}'**
  String yogDoshStrength(Object value);

  /// No description provided for @yogDoshMeaning.
  ///
  /// In en, this message translates to:
  /// **'What this Yog / Dosh means'**
  String get yogDoshMeaning;

  /// No description provided for @yogDoshBlessings.
  ///
  /// In en, this message translates to:
  /// **'Key blessings & strengths'**
  String get yogDoshBlessings;

  /// No description provided for @yogDoshChallenge.
  ///
  /// In en, this message translates to:
  /// **'Possible challenges'**
  String get yogDoshChallenge;

  /// No description provided for @yogDoshReasons.
  ///
  /// In en, this message translates to:
  /// **'Why this Yog / Dosh is formed'**
  String get yogDoshReasons;

  /// No description provided for @yogDoshDetails.
  ///
  /// In en, this message translates to:
  /// **'Detailed explanation'**
  String get yogDoshDetails;

  /// No description provided for @yogDoshSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get yogDoshSummary;

  /// No description provided for @yogDoshEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Astrological evaluation'**
  String get yogDoshEvaluation;

  /// No description provided for @yogDoshContext.
  ///
  /// In en, this message translates to:
  /// **'Chart context (for reference)'**
  String get yogDoshContext;

  /// No description provided for @yogDoshRemedies.
  ///
  /// In en, this message translates to:
  /// **'Suggested remedies / focus points'**
  String get yogDoshRemedies;

  /// No description provided for @yogDoshFooter.
  ///
  /// In en, this message translates to:
  /// **'Note: Above points are based on your current Kundali data and Yog/Dosh rules configured in Jyotishasha engine.'**
  String get yogDoshFooter;

  /// No description provided for @dashboard_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard_home;

  /// No description provided for @dashboard_astrology.
  ///
  /// In en, this message translates to:
  /// **'Astrology'**
  String get dashboard_astrology;

  /// No description provided for @dashboard_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashboard_reports;

  /// No description provided for @dashboard_ask_now.
  ///
  /// In en, this message translates to:
  /// **'Ask Now'**
  String get dashboard_ask_now;

  /// No description provided for @dashboard_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dashboard_profile;

  /// No description provided for @panchang_view_full.
  ///
  /// In en, this message translates to:
  /// **'View Full Panchang →'**
  String get panchang_view_full;

  /// No description provided for @blog_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blog posts'**
  String get blog_load_error;

  /// No description provided for @blog_no_data.
  ///
  /// In en, this message translates to:
  /// **'No blog data found'**
  String get blog_no_data;

  /// No description provided for @panchangViewFull.
  ///
  /// In en, this message translates to:
  /// **'View Full Panchang →'**
  String get panchangViewFull;

  /// No description provided for @tool_free_kundali.
  ///
  /// In en, this message translates to:
  /// **'Free Kundali'**
  String get tool_free_kundali;

  /// No description provided for @tool_lagna_finder.
  ///
  /// In en, this message translates to:
  /// **'Lagna Finder'**
  String get tool_lagna_finder;

  /// No description provided for @tool_rashi_finder.
  ///
  /// In en, this message translates to:
  /// **'Rashi Finder'**
  String get tool_rashi_finder;

  /// No description provided for @tool_love_match.
  ///
  /// In en, this message translates to:
  /// **'Love Match'**
  String get tool_love_match;

  /// No description provided for @tool_rajyog_check.
  ///
  /// In en, this message translates to:
  /// **'Rajyog Check'**
  String get tool_rajyog_check;

  /// No description provided for @tool_health_insight.
  ///
  /// In en, this message translates to:
  /// **'Health Insight'**
  String get tool_health_insight;

  /// No description provided for @blog_highlights_title.
  ///
  /// In en, this message translates to:
  /// **'Astrology Blog Highlights'**
  String get blog_highlights_title;

  /// No description provided for @blog_highlights_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Read the latest updates, tips and celestial insights.'**
  String get blog_highlights_subtitle;

  /// No description provided for @blog_explore_button.
  ///
  /// In en, this message translates to:
  /// **'Explore Blog'**
  String get blog_explore_button;

  /// No description provided for @error_blog_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blog posts'**
  String get error_blog_failed;

  /// No description provided for @error_blog_none.
  ///
  /// In en, this message translates to:
  /// **'No blog data found'**
  String get error_blog_none;

  /// No description provided for @greetNamaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get greetNamaste;

  /// No description provided for @greetFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get greetFriend;

  /// No description provided for @dailyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your personal horoscope for today...'**
  String get dailyLoading;

  /// No description provided for @dailyRemedy.
  ///
  /// In en, this message translates to:
  /// **'Remedy'**
  String get dailyRemedy;

  /// No description provided for @panchangTimeAlert.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Time Alert'**
  String get panchangTimeAlert;

  /// No description provided for @panchangCalcLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating best and sensitive timings...'**
  String get panchangCalcLoading;

  /// No description provided for @timeToDo.
  ///
  /// In en, this message translates to:
  /// **'Time to Do'**
  String get timeToDo;

  /// No description provided for @timeToHold.
  ///
  /// In en, this message translates to:
  /// **'Time to Hold'**
  String get timeToHold;

  /// No description provided for @panchang_today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Panchang'**
  String get panchang_today;

  /// No description provided for @panchang_loading.
  ///
  /// In en, this message translates to:
  /// **'Fetching today\'s Panchang...'**
  String get panchang_loading;

  /// No description provided for @panchang_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch Panchang data.'**
  String get panchang_error;

  /// No description provided for @panchang_viewFull.
  ///
  /// In en, this message translates to:
  /// **'View Full Panchang →'**
  String get panchang_viewFull;

  /// No description provided for @panchang_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get panchang_yes;

  /// No description provided for @panchang_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get panchang_no;

  /// No description provided for @panchang_title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Panchang'**
  String get panchang_title;

  /// No description provided for @panchang_sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get panchang_sunrise;

  /// No description provided for @panchang_sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get panchang_sunset;

  /// No description provided for @panchang_elements.
  ///
  /// In en, this message translates to:
  /// **'Main Panchang Elements'**
  String get panchang_elements;

  /// No description provided for @panchang_tithi.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get panchang_tithi;

  /// No description provided for @panchang_nakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get panchang_nakshatra;

  /// No description provided for @panchang_yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get panchang_yoga;

  /// No description provided for @panchang_karana.
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get panchang_karana;

  /// No description provided for @panchang_vaar.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get panchang_vaar;

  /// No description provided for @panchang_panchak.
  ///
  /// In en, this message translates to:
  /// **'Panchak'**
  String get panchang_panchak;

  /// No description provided for @panchang_highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get panchang_highlights;

  /// No description provided for @panchang_abhijit.
  ///
  /// In en, this message translates to:
  /// **'Abhijit Muhurta'**
  String get panchang_abhijit;

  /// No description provided for @panchang_rahu.
  ///
  /// In en, this message translates to:
  /// **'Rahu Kaal'**
  String get panchang_rahu;

  /// No description provided for @change_location.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change_location;

  /// No description provided for @luckyColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Lucky Color'**
  String get luckyColorLabel;

  /// No description provided for @luckyNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Lucky Number'**
  String get luckyNumberLabel;

  /// No description provided for @favourableDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Favourable Direction'**
  String get favourableDirectionLabel;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @changeLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocationTitle;

  /// No description provided for @selectedPlace.
  ///
  /// In en, this message translates to:
  /// **'Selected Place'**
  String get selectedPlace;

  /// No description provided for @dataSyncedText.
  ///
  /// In en, this message translates to:
  /// **'✨ Data synced from Jyotishasha API ✨'**
  String get dataSyncedText;

  /// No description provided for @astrologyStudio.
  ///
  /// In en, this message translates to:
  /// **'Astrology Studio'**
  String get astrologyStudio;

  /// No description provided for @astrologyStudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore planets, houses, yogas and dasha — beautifully organized for you.'**
  String get astrologyStudioSubtitle;

  /// No description provided for @studioProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Astro Profile'**
  String get studioProfile;

  /// No description provided for @studioPlanets.
  ///
  /// In en, this message translates to:
  /// **'Your Planets'**
  String get studioPlanets;

  /// No description provided for @studioBhava.
  ///
  /// In en, this message translates to:
  /// **'Your Bhava'**
  String get studioBhava;

  /// No description provided for @studioDasha.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha'**
  String get studioDasha;

  /// No description provided for @studioLifeAspects.
  ///
  /// In en, this message translates to:
  /// **'Life Aspects'**
  String get studioLifeAspects;

  /// No description provided for @studioYogDosh.
  ///
  /// In en, this message translates to:
  /// **'Yog & Dosh'**
  String get studioYogDosh;

  /// No description provided for @shubhUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Shubh Muhurth'**
  String get shubhUpcomingTitle;

  /// No description provided for @shubhSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See More →'**
  String get shubhSeeMore;

  /// No description provided for @shubhScoreSuffix.
  ///
  /// In en, this message translates to:
  /// **'/10'**
  String get shubhScoreSuffix;

  /// No description provided for @footerFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts or suggestions...'**
  String get footerFeedbackHint;

  /// No description provided for @footerFeedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get footerFeedbackSend;

  /// No description provided for @footerFeedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get footerFeedbackThanks;

  /// No description provided for @footerCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Jyotishasha. All rights reserved.'**
  String get footerCopyright;

  /// No description provided for @footerPrivacyTerms.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy  •  Terms of Use'**
  String get footerPrivacyTerms;

  /// No description provided for @muhurthTitle.
  ///
  /// In en, this message translates to:
  /// **'🕉️ Shubh Muhurth'**
  String get muhurthTitle;

  /// No description provided for @muhurthLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get muhurthLocation;

  /// No description provided for @muhurthChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get muhurthChange;

  /// No description provided for @muhurthSelectOccasion.
  ///
  /// In en, this message translates to:
  /// **'Select Occasion'**
  String get muhurthSelectOccasion;

  /// No description provided for @muhurthNoResults.
  ///
  /// In en, this message translates to:
  /// **'No Shubh Muhurth found 😔'**
  String get muhurthNoResults;

  /// No description provided for @muhurthUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Muhurth Dates'**
  String get muhurthUpcoming;

  /// No description provided for @muhurthScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get muhurthScore;

  /// No description provided for @muhurthWeekdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get muhurthWeekdayLabel;

  /// No description provided for @muhurthNakshatraLabel.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get muhurthNakshatraLabel;

  /// No description provided for @muhurthTithiLabel.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get muhurthTithiLabel;

  /// No description provided for @muhurthPickerComing.
  ///
  /// In en, this message translates to:
  /// **'Location picker coming soon'**
  String get muhurthPickerComing;

  /// No description provided for @muhurthBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the best date of this month for'**
  String get muhurthBannerTitle;

  /// No description provided for @muhurthBannerNamkaran.
  ///
  /// In en, this message translates to:
  /// **'Naamkaran'**
  String get muhurthBannerNamkaran;

  /// No description provided for @muhurthBannerMarriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get muhurthBannerMarriage;

  /// No description provided for @muhurthBannerVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle purchase'**
  String get muhurthBannerVehicle;

  /// No description provided for @muhurthBannerGold.
  ///
  /// In en, this message translates to:
  /// **'Gold purchase'**
  String get muhurthBannerGold;

  /// No description provided for @muhurthBannerMore.
  ///
  /// In en, this message translates to:
  /// **'and more auspicious events'**
  String get muhurthBannerMore;

  /// No description provided for @muhurthBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Tap to see your Shubh Muhurth'**
  String get muhurthBannerCta;

  /// No description provided for @darshanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Touch ॐ for Darshan & Mantra'**
  String get darshanInstruction;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
