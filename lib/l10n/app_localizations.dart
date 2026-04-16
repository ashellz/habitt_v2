import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('bs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('it'),
  ];

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'habits'**
  String get habits;

  /// No description provided for @habit.
  ///
  /// In en, this message translates to:
  /// **'habit'**
  String get habit;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @whatsUp.
  ///
  /// In en, this message translates to:
  /// **'What\'s up'**
  String get whatsUp;

  /// No description provided for @goodToSeeYou.
  ///
  /// In en, this message translates to:
  /// **'Good to see you'**
  String get goodToSeeYou;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @hiThere.
  ///
  /// In en, this message translates to:
  /// **'Hi there'**
  String get hiThere;

  /// No description provided for @helloThere.
  ///
  /// In en, this message translates to:
  /// **'Hello there'**
  String get helloThere;

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you'**
  String get howAreYou;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyTime;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get newHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit Name'**
  String get habitName;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @enterYourAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter your amount'**
  String get enterYourAmount;

  /// No description provided for @enterYourDuration.
  ///
  /// In en, this message translates to:
  /// **'Enter your duration'**
  String get enterYourDuration;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @youCanPressNumberAbove.
  ///
  /// In en, this message translates to:
  /// **'You can also press the number above to change {type}'**
  String youCanPressNumberAbove(Object type);

  /// No description provided for @orToChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'or the amount label'**
  String get orToChangeLabel;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @notificationFallbackGeneric.
  ///
  /// In en, this message translates to:
  /// **'Small actions today create long-term momentum.'**
  String get notificationFallbackGeneric;

  /// No description provided for @notificationFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit reminder'**
  String get notificationFallbackTitle;

  /// No description provided for @notificationOptional.
  ///
  /// In en, this message translates to:
  /// **'This one is optional today, but even one step still counts.'**
  String get notificationOptional;

  /// No description provided for @notificationFreshnessBrandNew.
  ///
  /// In en, this message translates to:
  /// **'This habit is brand new. Early reps matter most, so do not give up.'**
  String get notificationFreshnessBrandNew;

  /// No description provided for @notificationFreshnessNewDays.
  ///
  /// In en, this message translates to:
  /// **'You started this {days} days ago. Keep this fresh habit alive.'**
  String notificationFreshnessNewDays(Object days);

  /// No description provided for @notificationFreshnessEstablishedDays.
  ///
  /// In en, this message translates to:
  /// **'You have been building this for {days} days. Keep compounding wins.'**
  String notificationFreshnessEstablishedDays(Object days);

  /// No description provided for @notificationProgressNotStartedAmount.
  ///
  /// In en, this message translates to:
  /// **'You have not started yet. Begin with 1 {label} and build momentum.'**
  String notificationProgressNotStartedAmount(Object label);

  /// No description provided for @notificationProgressCompletedAmount.
  ///
  /// In en, this message translates to:
  /// **'You already hit {completed} {label}. Bonus rep?'**
  String notificationProgressCompletedAmount(Object completed, Object label);

  /// No description provided for @notificationProgressAlmostDoneAmount.
  ///
  /// In en, this message translates to:
  /// **'You are so close. Just {remaining} {label} left.'**
  String notificationProgressAlmostDoneAmount(Object label, Object remaining);

  /// No description provided for @notificationProgressInProgressAmount.
  ///
  /// In en, this message translates to:
  /// **'Progress is {completed}/{target} {label}. Keep the streak moving.'**
  String notificationProgressInProgressAmount(
    Object completed,
    Object label,
    Object target,
  );

  /// No description provided for @notificationProgressNotStartedDuration.
  ///
  /// In en, this message translates to:
  /// **'You have not started yet. Start with a short session to begin.'**
  String get notificationProgressNotStartedDuration;

  /// No description provided for @notificationProgressCompletedDuration.
  ///
  /// In en, this message translates to:
  /// **'Target done: {completed} completed already.'**
  String notificationProgressCompletedDuration(Object completed);

  /// No description provided for @notificationProgressAlmostDoneDuration.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left. You are very close now.'**
  String notificationProgressAlmostDoneDuration(Object remaining);

  /// No description provided for @notificationProgressInProgressDuration.
  ///
  /// In en, this message translates to:
  /// **'You logged {completed} of {target}.'**
  String notificationProgressInProgressDuration(
    Object completed,
    Object target,
  );

  /// No description provided for @notificationProgressNoTracking.
  ///
  /// In en, this message translates to:
  /// **'Small action now keeps this habit alive.'**
  String get notificationProgressNoTracking;

  /// No description provided for @notificationScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily rhythm: show up today and protect your momentum.'**
  String get notificationScheduleDaily;

  /// No description provided for @notificationScheduleCustomEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Custom cadence: every {days} days. Today is one of your slots.'**
  String notificationScheduleCustomEveryDays(Object days);

  /// No description provided for @notificationScheduleWeeklyReached.
  ///
  /// In en, this message translates to:
  /// **'Weekly target already reached ({completed}/{target}). This is bonus consistency.'**
  String notificationScheduleWeeklyReached(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyImpossible.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week ({completed}/{target} done). Even if you do it now, the target is out of reach this week.'**
  String notificationScheduleWeeklyImpossible(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleWeeklyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week ({completed}/{target} done). If you skip today, your goal gets much harder.'**
  String notificationScheduleWeeklyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleWeeklyOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One more completion this week and you hit your target ({completed}/{target}).'**
  String notificationScheduleWeeklyOneLeft(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyRemaining.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week to reach {target}.'**
  String notificationScheduleWeeklyRemaining(Object remaining, Object target);

  /// No description provided for @notificationScheduleMonthlyReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly target already reached ({completed}/{target}). Extra rep, extra momentum.'**
  String notificationScheduleMonthlyReached(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyImpossible.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month ({completed}/{target} done). Even if you do it now, the target is out of reach this month.'**
  String notificationScheduleMonthlyImpossible(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleMonthlyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month ({completed}/{target} done). Skipping today puts your target at risk.'**
  String notificationScheduleMonthlyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleMonthlyOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One more completion this month and you hit your target ({completed}/{target}).'**
  String notificationScheduleMonthlyOneLeft(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyRemaining.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month to reach {target}.'**
  String notificationScheduleMonthlyRemaining(Object remaining, Object target);

  /// No description provided for @notificationAmountLabelFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s target is {target} {label}.'**
  String notificationAmountLabelFocus(Object label, Object target);

  /// No description provided for @notificationPremadeGoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'Protect tonight so tomorrow starts easier.'**
  String get notificationPremadeGoToBedEarly;

  /// No description provided for @notificationPremadeBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Quick hygiene win now keeps your routine sharp.'**
  String get notificationPremadeBrushTeeth;

  /// No description provided for @notificationPremadeSkinCare.
  ///
  /// In en, this message translates to:
  /// **'Take care of your skin now to stay consistent.'**
  String get notificationPremadeSkinCare;

  /// No description provided for @notificationPremadeWakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'A strong start to your day begins with this choice.'**
  String get notificationPremadeWakeUpEarly;

  /// No description provided for @notificationPremadeShower.
  ///
  /// In en, this message translates to:
  /// **'Reset your energy with this simple routine.'**
  String get notificationPremadeShower;

  /// No description provided for @notificationPremadePraying.
  ///
  /// In en, this message translates to:
  /// **'Take a calm moment now and reconnect with intention.'**
  String get notificationPremadePraying;

  /// No description provided for @notificationPremadeRunning.
  ///
  /// In en, this message translates to:
  /// **'Lace up and collect a strong training rep today.'**
  String get notificationPremadeRunning;

  /// No description provided for @notificationPremadeWalk.
  ///
  /// In en, this message translates to:
  /// **'A short walk now is enough to keep momentum alive.'**
  String get notificationPremadeWalk;

  /// No description provided for @notificationPremadeGym.
  ///
  /// In en, this message translates to:
  /// **'Show up for a solid gym rep and build consistency.'**
  String get notificationPremadeGym;

  /// No description provided for @notificationPremadeNutrition.
  ///
  /// In en, this message translates to:
  /// **'Make one intentional nutrition choice right now.'**
  String get notificationPremadeNutrition;

  /// No description provided for @notificationPremadeMedications.
  ///
  /// In en, this message translates to:
  /// **'Take your meds on time to protect your health baseline.'**
  String get notificationPremadeMedications;

  /// No description provided for @notificationPremadeDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Hydrate now and keep your body performing well.'**
  String get notificationPremadeDrinkWater;

  /// No description provided for @notificationPremadeStudying.
  ///
  /// In en, this message translates to:
  /// **'Start a focused study block and build learning momentum.'**
  String get notificationPremadeStudying;

  /// No description provided for @notificationPremadeWork.
  ///
  /// In en, this message translates to:
  /// **'Start your most important task and gain traction.'**
  String get notificationPremadeWork;

  /// No description provided for @notificationPremadeResearch.
  ///
  /// In en, this message translates to:
  /// **'Capture one useful insight and move your research forward.'**
  String get notificationPremadeResearch;

  /// No description provided for @notificationPremadeProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'Run one focused session and protect deep work time.'**
  String get notificationPremadeProductivitySession;

  /// No description provided for @notificationPremadeRead.
  ///
  /// In en, this message translates to:
  /// **'Read a little now and let consistency do the rest.'**
  String get notificationPremadeRead;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bs', 'de', 'en', 'es', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bs':
      return AppLocalizationsBs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
