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
  /// **'This one is optional today, but still mind giving it a try?|You got some extra time?'**
  String get notificationOptional;

  /// No description provided for @notificationFreshnessBrandNew.
  ///
  /// In en, this message translates to:
  /// **'Time for this brand new habit to shine!'**
  String get notificationFreshnessBrandNew;

  /// No description provided for @notificationFreshnessNewDays.
  ///
  /// In en, this message translates to:
  /// **'You started {days} ago. Keep it up!|Day {days}. The early days are the foundation — solid work.|You started {days} days ago. Each one matters equally.'**
  String notificationFreshnessNewDays(Object days);

  /// No description provided for @notificationFreshnessEstablishedDays.
  ///
  /// In en, this message translates to:
  /// **'You have been building this for {days} days so far. Keep compounding wins.'**
  String notificationFreshnessEstablishedDays(Object days);

  /// No description provided for @notificationProgressNotStartedAmount.
  ///
  /// In en, this message translates to:
  /// **'Begin with 1 {label} only and build momentum. It\'s easy!|You don\'t need motivation. Just start.|The hardest part is starting. You can do it!'**
  String notificationProgressNotStartedAmount(Object label);

  /// No description provided for @notificationProgressCompletedAmount.
  ///
  /// In en, this message translates to:
  /// **'You already hit {completed} {label}. Ready for more?|{completed} {label} done. Momentum is on your side now.|{completed} {label} in the bank. Your habit is working.|Nice — {completed} {label} completed. Want to stretch a little?'**
  String notificationProgressCompletedAmount(Object completed, Object label);

  /// No description provided for @notificationProgressAlmostDoneAmount.
  ///
  /// In en, this message translates to:
  /// **'You are so close. Just {remaining} {label} left.|{remaining} {label} left. This is your rhythm — lean into it.|{remaining} {label} to go. You\'ve already done the majority.|Almost there — {remaining} {label} separates you from done.|You\'re {remaining} {label} away from your target. Finish strong.|The finish line is close. Just {remaining} {label} to wrap up.'**
  String notificationProgressAlmostDoneAmount(Object label, Object remaining);

  /// No description provided for @notificationProgressInProgressAmount.
  ///
  /// In en, this message translates to:
  /// **'{completed} out of {target} {label}. Get on it!.|You\'ve already logged {completed} {label}. Great start.|{completed}/{target} {label} so far. Keep the pace steady.|{completed} done, {remaining} to go. You\'ve got this.|{completed} out of {target}. Keep going.'**
  String notificationProgressInProgressAmount(
    Object completed,
    Object label,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationProgressNotStartedDuration.
  ///
  /// In en, this message translates to:
  /// **'Start with a short session at least!|You don\'t need motivation. Just start.|The hardest part is starting. You can do it!|Few minutes from now, you\'ll be glad you started.'**
  String get notificationProgressNotStartedDuration;

  /// No description provided for @notificationProgressCompletedDuration.
  ///
  /// In en, this message translates to:
  /// **'Target done: {completed} done already.|Time target hit: {completed}. You showed up and stayed.|{completed} of focused time. Done. That\'s real commitment.|Session complete: {completed}. Your consistency just grew.|{completed} logged. Your future self will thank you.|Target time reached: {completed}. Great use of focused effort.'**
  String notificationProgressCompletedDuration(Object completed);

  /// No description provided for @notificationProgressAlmostDoneDuration.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left. Tune in for a little bit more and you\'re done!|{remaining} to go. You can always do just a little more.|{remaining} remaining. Finishing is its own reward.|{remaining} to go. You can do this!'**
  String notificationProgressAlmostDoneDuration(Object remaining);

  /// No description provided for @notificationProgressInProgressDuration.
  ///
  /// In en, this message translates to:
  /// **'{completed} so far, your goal is {target} so keep it up!|You\'ve done the hard part — starting. Keep rolling.|You\'ve logged {completed} of {target}. Stay in the zone.|{completed} of {target} completed. That\'s good, keep it up!'**
  String notificationProgressInProgressDuration(
    Object completed,
    Object target,
  );

  /// No description provided for @notificationProgressNoTracking.
  ///
  /// In en, this message translates to:
  /// **'Small action now keeps this habit alive.|Don\'t let this habit fade, a little effort now protects your momentum.|Consistency today makes tomorrow easier. Mind giving it a try?|Don\'t forget about your habit today!|A small action now keeps your habit strong.|Hey there! Time for your habiiit!|One small step keeps the streak alive.|Done is better than perfect. Get it done.|Consistency compounds. One more day matters.|Your habit is a promise to yourself. Keep it.|Same habit, one day stronger. Keep building.|You don\'t need motivation. Just start.|Think of this as a gift to your future self. Get on it!|You\'re building something important. Keep going.|Making time for what matters. That\'s you.|Curious what happens when you never skip?|Habit used notification; What\'s your move?|Time to act on your plan.|Don\'t break the chain. One more day.|No need to be perfect. Just need to be present.|Small actions today = big results tomorrow.'**
  String get notificationProgressNoTracking;

  /// No description provided for @notificationScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Your daily anchor awaits. Lock it in.|Daily window is open. Step through it.|Your daily practice builds quietly. But it builds.|This is your daily habit call. Respond to it!'**
  String get notificationScheduleDaily;

  /// No description provided for @notificationScheduleCustomEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Custom cadence: every {days} days. Today is one of your slots.|Every {days} days rhythm. Today is a scheduled day.|Your {days}-day cycle aligns today. Time to act.|Custom schedule says: today is this habit\'s day. Use your slot!|This habit runs every {days} days. You\'re due right now.|Today is part of this habit\'s rhythm. Honor the pattern.'**
  String notificationScheduleCustomEveryDays(Object days);

  /// No description provided for @notificationScheduleWeeklyReached.
  ///
  /// In en, this message translates to:
  /// **'Weekly target already reached ({completed}/{target}). This is bonus consistency.|You hit your weekly goal ({completed}/{target}). Everything extra is a win.|Weekly target: achieved ({completed}/{target}). Bonus reps build elite habits.|{completed}/{target} for the week. You\'re above and beyond.|Weekly goal already met ({completed}/{target}). You\'re operating at a higher level.|You\'ve done your weekly target ({completed}/{target}). Consistency is now surplus.'**
  String notificationScheduleWeeklyReached(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyImpossible.
  ///
  /// In en, this message translates to:
  /// **'This week\'s target is out of reach ({completed}/{target}). Still, every rep builds for next week.|Goal won\'t be met this week ({completed}/{target}). But unfinished weeks teach us what to adjust.|The weekly number won\'t align ({completed}/{target}). Do it anyway — consistency ignores the scoreboard.|Target missed this week ({completed}/{target}). Each attempt still strengthens the habit loop.|{completed}/{target} this week. The goal is out of range — but the habit isn\'t.'**
  String notificationScheduleWeeklyImpossible(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week ({completed}/{target} done). If you skip today, your goal gets much harder.|You need {remaining} more this week ({completed}/{target}). Today keeps it manageable.|{remaining} to go this week ({completed}/{target}). Skipping today adds pressure.|Your weekly target ({completed}/{target}) is still reachable. Today is a leverage point.|{completed}/{target} for the week. One today keeps your goal on track.|{remaining} remaining this week ({completed}/{target}). Today is your best move.'**
  String notificationScheduleWeeklyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleWeeklyOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One more completion this week and you hit your target ({completed}/{target}).|One more this week and you\'re at {target} ({completed} done). Close the loop.|You\'re one session away from your weekly goal ({completed}/{target}). Make it count.|This week\'s target needs just one more ({completed}/{target}). You can close it now.|One more completion stands between you and {target} this week ({completed} done).|Weekly goal within reach: one more ({completed}/{target}). That\'s just today.'**
  String notificationScheduleWeeklyOneLeft(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyRemaining.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week to reach {target}.|{remaining} to go for weekly target of {target}. Steady pacing works.|You need {remaining} more this week. Today is a great time to start one.|Weekly goal: {remaining} remaining of {target}. Spread the effort.|{remaining} sessions left to hit {target} this week. Each one matters equally.|Your weekly target is {target}, with {remaining} to go. One step at a time.'**
  String notificationScheduleWeeklyRemaining(Object remaining, Object target);

  /// No description provided for @notificationScheduleMonthlyReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly target already reached ({completed}/{target}). Extra rep, extra momentum.|You\'ve nailed your monthly goal ({completed}/{target}). This is elite consistency.|Monthly target: done ({completed}/{target}). Everything now is exponential growth.|Monthly goal already crushed ({completed}/{target}). Bonus reps deepen the groove.'**
  String notificationScheduleMonthlyReached(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyImpossible.
  ///
  /// In en, this message translates to:
  /// **'This month\'s target won\'t be met ({completed}/{target}). Use the remaining days for practice, not pressure.|The monthly number is out of reach ({completed}/{target}). But habits are built in the gaps, not just the goals.|Target unreachable this month ({completed}/{target}). Every attempt still rewires the loop.|{completed}/{target} this month. The goal won\'t align — but the habit still counts.|This month\'s target exceeded your available days ({completed}/{target}). Adjust and keep moving.'**
  String notificationScheduleMonthlyImpossible(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month ({completed}/{target} done). Skipping today puts your target at risk.|{remaining} to go this month ({completed}/{target}). Today protects your progress.|Your monthly goal ({completed}/{target}) is still possible. Today is a key move.|{completed}/{target} for the month. Don\'t let today be the gap.|{remaining} needed this month ({completed}/{target}). One session at a time stays on track.|Monthly target within reach ({completed}/{target}). Today keeps the door open.'**
  String notificationScheduleMonthlyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleMonthlyOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One more completion this month and you hit your target ({completed}/{target}).|One more this month hits {target} ({completed} done). This is your closing move.|You\'re one session from your monthly goal ({completed}/{target}). Seal it.|Monthly target needs one final completion ({completed}/{target}). Today can be that day.|One more and you\'re at {target} for the month ({completed} done). Finish what you started.|Your monthly goal is one away ({completed}/{target}). That\'s a single session.'**
  String notificationScheduleMonthlyOneLeft(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyRemaining.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month to reach {target}.|{remaining} sessions left this month to hit {target}. Consistent pacing wins.|You need {remaining} more for your monthly goal of {target}. Each one builds.|Monthly target: {remaining} of {target} remaining. You have time — use it wisely.|{remaining} to go this month for {target}. Small, steady actions close the gap.|Your monthly number is {target} with {remaining} left. Today moves the goal forward.'**
  String notificationScheduleMonthlyRemaining(Object remaining, Object target);

  /// No description provided for @notificationAmountLabelFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s target is {target} {label}.|Your number for today: {target} {label}. Start with one.|Today\'s dose: {target} {label}. Clear target, simple execution.|Today asks for {target} {label}. You know the rhythm.|Target for today: {target} {label}. A precise goal is a powerful cue.'**
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

  /// No description provided for @notificationPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get notificationPeriodWeekly;

  /// No description provided for @notificationPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get notificationPeriodMonthly;

  /// No description provided for @notificationCombinedOneOff.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss today, it\'s your last {period} chance and {encouragement}.'**
  String notificationCombinedOneOff(Object encouragement, Object period);

  /// No description provided for @notificationCombinedFresh.
  ///
  /// In en, this message translates to:
  /// **'You started this habit {days} days ago, and {encouragement}.'**
  String notificationCombinedFresh(Object days, Object encouragement);

  /// No description provided for @notificationCombinedAmountNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start now, even one step counts, and {encouragement}.'**
  String notificationCombinedAmountNotStarted(Object encouragement);

  /// No description provided for @notificationCombinedAmountInProgress.
  ///
  /// In en, this message translates to:
  /// **'You are at {progress}, and {encouragement}.'**
  String notificationCombinedAmountInProgress(
    Object encouragement,
    Object progress,
  );

  /// No description provided for @notificationCombinedAmountAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left, and {encouragement}.'**
  String notificationCombinedAmountAlmostDone(
    Object encouragement,
    Object remaining,
  );

  /// No description provided for @notificationCombinedAmountCompleted.
  ///
  /// In en, this message translates to:
  /// **'Target reached already, and {encouragement}.'**
  String notificationCombinedAmountCompleted(Object encouragement);

  /// No description provided for @notificationCombinedDurationNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start a short session now, and {encouragement}.'**
  String notificationCombinedDurationNotStarted(Object encouragement);

  /// No description provided for @notificationCombinedDurationInProgress.
  ///
  /// In en, this message translates to:
  /// **'You are at {progress}, and {encouragement}.'**
  String notificationCombinedDurationInProgress(
    Object encouragement,
    Object progress,
  );

  /// No description provided for @notificationCombinedDurationAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left, and {encouragement}.'**
  String notificationCombinedDurationAlmostDone(
    Object encouragement,
    Object remaining,
  );

  /// No description provided for @notificationCombinedDurationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Target reached already, and {encouragement}.'**
  String notificationCombinedDurationCompleted(Object encouragement);

  /// No description provided for @notificationCombinedGeneral.
  ///
  /// In en, this message translates to:
  /// **'{encouragement}.'**
  String notificationCombinedGeneral(Object encouragement);

  /// No description provided for @notificationEncourageGeneric1.
  ///
  /// In en, this message translates to:
  /// **'showing up today keeps the habit alive'**
  String get notificationEncourageGeneric1;

  /// No description provided for @notificationEncourageGeneric2.
  ///
  /// In en, this message translates to:
  /// **'a small action now protects your momentum'**
  String get notificationEncourageGeneric2;

  /// No description provided for @notificationEncourageGeneric3.
  ///
  /// In en, this message translates to:
  /// **'consistency today makes tomorrow easier'**
  String get notificationEncourageGeneric3;

  /// No description provided for @notificationEncourageGoToBedEarly1.
  ///
  /// In en, this message translates to:
  /// **'protecting tonight helps tomorrow feel lighter'**
  String get notificationEncourageGoToBedEarly1;

  /// No description provided for @notificationEncourageGoToBedEarly2.
  ///
  /// In en, this message translates to:
  /// **'an earlier bedtime now gives your mind a cleaner start'**
  String get notificationEncourageGoToBedEarly2;

  /// No description provided for @notificationEncourageGoToBedEarly3.
  ///
  /// In en, this message translates to:
  /// **'this choice tonight sets up a better morning'**
  String get notificationEncourageGoToBedEarly3;

  /// No description provided for @notificationEncourageGoToBedEarly4.
  ///
  /// In en, this message translates to:
  /// **'sleep consistency now pays off all day tomorrow'**
  String get notificationEncourageGoToBedEarly4;

  /// No description provided for @notificationEncourageGoToBedEarly5.
  ///
  /// In en, this message translates to:
  /// **'one calm night routine protects your energy curve'**
  String get notificationEncourageGoToBedEarly5;

  /// No description provided for @notificationEncourageGoToBedEarly6.
  ///
  /// In en, this message translates to:
  /// **'ending the day on time keeps your rhythm stable'**
  String get notificationEncourageGoToBedEarly6;

  /// No description provided for @notificationEncourageGoToBedEarly7.
  ///
  /// In en, this message translates to:
  /// **'better sleep timing is a quiet performance advantage'**
  String get notificationEncourageGoToBedEarly7;

  /// No description provided for @notificationEncourageGoToBedEarly8.
  ///
  /// In en, this message translates to:
  /// **'an earlier lights-out keeps your recovery on track'**
  String get notificationEncourageGoToBedEarly8;

  /// No description provided for @notificationEncourageGoToBedEarly9.
  ///
  /// In en, this message translates to:
  /// **'small bedtime discipline creates stronger mornings'**
  String get notificationEncourageGoToBedEarly9;

  /// No description provided for @notificationEncourageGoToBedEarly10.
  ///
  /// In en, this message translates to:
  /// **'this evening decision helps your whole week run smoother'**
  String get notificationEncourageGoToBedEarly10;

  /// No description provided for @notificationEncourageBrushTeeth1.
  ///
  /// In en, this message translates to:
  /// **'keeping your hygiene streak strong'**
  String get notificationEncourageBrushTeeth1;

  /// No description provided for @notificationEncourageBrushTeeth2.
  ///
  /// In en, this message translates to:
  /// **'protecting your routine with a quick win'**
  String get notificationEncourageBrushTeeth2;

  /// No description provided for @notificationEncourageBrushTeeth3.
  ///
  /// In en, this message translates to:
  /// **'staying consistent with basic care'**
  String get notificationEncourageBrushTeeth3;

  /// No description provided for @notificationEncourageSkinCare1.
  ///
  /// In en, this message translates to:
  /// **'protecting your skin with one steady step'**
  String get notificationEncourageSkinCare1;

  /// No description provided for @notificationEncourageSkinCare2.
  ///
  /// In en, this message translates to:
  /// **'making consistency your skincare advantage'**
  String get notificationEncourageSkinCare2;

  /// No description provided for @notificationEncourageSkinCare3.
  ///
  /// In en, this message translates to:
  /// **'keeping your routine reliable and simple'**
  String get notificationEncourageSkinCare3;

  /// No description provided for @notificationEncourageWakeUpEarly1.
  ///
  /// In en, this message translates to:
  /// **'starting your day with intention'**
  String get notificationEncourageWakeUpEarly1;

  /// No description provided for @notificationEncourageWakeUpEarly2.
  ///
  /// In en, this message translates to:
  /// **'keeping your morning rhythm consistent'**
  String get notificationEncourageWakeUpEarly2;

  /// No description provided for @notificationEncourageWakeUpEarly3.
  ///
  /// In en, this message translates to:
  /// **'giving yourself a calmer start'**
  String get notificationEncourageWakeUpEarly3;

  /// No description provided for @notificationEncourageShower1.
  ///
  /// In en, this message translates to:
  /// **'a quick reset can lift your focus'**
  String get notificationEncourageShower1;

  /// No description provided for @notificationEncourageShower2.
  ///
  /// In en, this message translates to:
  /// **'this routine helps you feel switched on'**
  String get notificationEncourageShower2;

  /// No description provided for @notificationEncourageShower3.
  ///
  /// In en, this message translates to:
  /// **'a clean reset keeps your day moving'**
  String get notificationEncourageShower3;

  /// No description provided for @notificationEncourageRunning1.
  ///
  /// In en, this message translates to:
  /// **'one training rep today builds endurance'**
  String get notificationEncourageRunning1;

  /// No description provided for @notificationEncourageRunning2.
  ///
  /// In en, this message translates to:
  /// **'showing up now strengthens your running baseline'**
  String get notificationEncourageRunning2;

  /// No description provided for @notificationEncourageRunning3.
  ///
  /// In en, this message translates to:
  /// **'this effort keeps your fitness momentum real'**
  String get notificationEncourageRunning3;

  /// No description provided for @notificationEncourageWalk1.
  ///
  /// In en, this message translates to:
  /// **'a short walk is enough to keep momentum'**
  String get notificationEncourageWalk1;

  /// No description provided for @notificationEncourageWalk2.
  ///
  /// In en, this message translates to:
  /// **'moving now helps your energy and focus'**
  String get notificationEncourageWalk2;

  /// No description provided for @notificationEncourageWalk3.
  ///
  /// In en, this message translates to:
  /// **'this simple rep supports long-term consistency'**
  String get notificationEncourageWalk3;

  /// No description provided for @notificationEncourageGym1.
  ///
  /// In en, this message translates to:
  /// **'one gym rep today keeps your standard high'**
  String get notificationEncourageGym1;

  /// No description provided for @notificationEncourageGym2.
  ///
  /// In en, this message translates to:
  /// **'showing up now protects your strength momentum'**
  String get notificationEncourageGym2;

  /// No description provided for @notificationEncourageGym3.
  ///
  /// In en, this message translates to:
  /// **'today\'s session compounds over time'**
  String get notificationEncourageGym3;

  /// No description provided for @notificationEncourageNutrition1.
  ///
  /// In en, this message translates to:
  /// **'one intentional choice now supports your baseline'**
  String get notificationEncourageNutrition1;

  /// No description provided for @notificationEncourageNutrition2.
  ///
  /// In en, this message translates to:
  /// **'small nutrition wins add up fast'**
  String get notificationEncourageNutrition2;

  /// No description provided for @notificationEncourageNutrition3.
  ///
  /// In en, this message translates to:
  /// **'consistency here improves everything else'**
  String get notificationEncourageNutrition3;

  /// No description provided for @notificationEncourageMedications1.
  ///
  /// In en, this message translates to:
  /// **'timing this right protects your health routine'**
  String get notificationEncourageMedications1;

  /// No description provided for @notificationEncourageMedications2.
  ///
  /// In en, this message translates to:
  /// **'staying on schedule keeps your baseline stable'**
  String get notificationEncourageMedications2;

  /// No description provided for @notificationEncourageMedications3.
  ///
  /// In en, this message translates to:
  /// **'this step supports your long-term wellbeing'**
  String get notificationEncourageMedications3;

  /// No description provided for @notificationEncourageDrinkWater1.
  ///
  /// In en, this message translates to:
  /// **'hydration now supports your whole system'**
  String get notificationEncourageDrinkWater1;

  /// No description provided for @notificationEncourageDrinkWater2.
  ///
  /// In en, this message translates to:
  /// **'one glass now keeps your energy steadier'**
  String get notificationEncourageDrinkWater2;

  /// No description provided for @notificationEncourageDrinkWater3.
  ///
  /// In en, this message translates to:
  /// **'small hydration reps improve daily performance'**
  String get notificationEncourageDrinkWater3;

  /// No description provided for @notificationEncourageStudying1.
  ///
  /// In en, this message translates to:
  /// **'one focused block now builds learning momentum'**
  String get notificationEncourageStudying1;

  /// No description provided for @notificationEncourageStudying2.
  ///
  /// In en, this message translates to:
  /// **'showing up today keeps knowledge compounding'**
  String get notificationEncourageStudying2;

  /// No description provided for @notificationEncourageStudying3.
  ///
  /// In en, this message translates to:
  /// **'small sessions consistently beat cramming'**
  String get notificationEncourageStudying3;

  /// No description provided for @notificationEncourageWork1.
  ///
  /// In en, this message translates to:
  /// **'starting now creates real traction'**
  String get notificationEncourageWork1;

  /// No description provided for @notificationEncourageWork2.
  ///
  /// In en, this message translates to:
  /// **'one meaningful push can unlock your day'**
  String get notificationEncourageWork2;

  /// No description provided for @notificationEncourageWork3.
  ///
  /// In en, this message translates to:
  /// **'consistent execution keeps progress visible'**
  String get notificationEncourageWork3;

  /// No description provided for @notificationEncourageResearch1.
  ///
  /// In en, this message translates to:
  /// **'one insight today moves your work forward'**
  String get notificationEncourageResearch1;

  /// No description provided for @notificationEncourageResearch2.
  ///
  /// In en, this message translates to:
  /// **'steady exploration compounds into clarity'**
  String get notificationEncourageResearch2;

  /// No description provided for @notificationEncourageResearch3.
  ///
  /// In en, this message translates to:
  /// **'capturing one finding now keeps momentum'**
  String get notificationEncourageResearch3;

  /// No description provided for @notificationEncourageProductivitySession1.
  ///
  /// In en, this message translates to:
  /// **'one focused session protects deep work time'**
  String get notificationEncourageProductivitySession1;

  /// No description provided for @notificationEncourageProductivitySession2.
  ///
  /// In en, this message translates to:
  /// **'a clean focus block now can change your day'**
  String get notificationEncourageProductivitySession2;

  /// No description provided for @notificationEncourageProductivitySession3.
  ///
  /// In en, this message translates to:
  /// **'consistency in focus drives better output'**
  String get notificationEncourageProductivitySession3;

  /// No description provided for @notificationEncourageRead1.
  ///
  /// In en, this message translates to:
  /// **'a few pages now keep your reading identity strong'**
  String get notificationEncourageRead1;

  /// No description provided for @notificationEncourageRead2.
  ///
  /// In en, this message translates to:
  /// **'small daily reading compounds into real progress'**
  String get notificationEncourageRead2;

  /// No description provided for @notificationEncourageRead3.
  ///
  /// In en, this message translates to:
  /// **'showing up today keeps the streak alive'**
  String get notificationEncourageRead3;

  /// No description provided for @insightStrengthKeepPushingTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep pushing {habitName}'**
  String insightStrengthKeepPushingTitle(Object habitName);

  /// No description provided for @insightStrengthLowerTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Lower target for {habitName}'**
  String insightStrengthLowerTargetTitle(Object habitName);

  /// No description provided for @insightStrengthIncreaseTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase target for {habitName}'**
  String insightStrengthIncreaseTargetTitle(Object habitName);

  /// No description provided for @insightStrengthApplyDecrease.
  ///
  /// In en, this message translates to:
  /// **'Apply decrease'**
  String get insightStrengthApplyDecrease;

  /// No description provided for @insightStrengthApplyIncrease.
  ///
  /// In en, this message translates to:
  /// **'Apply increase'**
  String get insightStrengthApplyIncrease;

  /// No description provided for @insightStrengthGotItEven.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get insightStrengthGotItEven;

  /// No description provided for @insightStrengthGotItOdd.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get insightStrengthGotItOdd;

  /// No description provided for @insightStrengthStartSmallType1Generic.
  ///
  /// In en, this message translates to:
  /// **'You added this habit for a reason. Do not let it slip now.||Momentum is fading on this habit. Show up today and keep it alive.||You are falling behind on this habit. Lock in and get your rep done.||Do not negotiate with laziness here. Protect this habit today.||You came too far to let this habit drift. Stay consistent today.'**
  String get insightStrengthStartSmallType1Generic;

  /// No description provided for @insightStrengthStartSmallType2Generic.
  ///
  /// In en, this message translates to:
  /// **'Consistency dropped on this habit. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to stabilize again.||You have been off track lately. Strength dropped by {drop}%. Try this target shift: {fromValue} -> {toValue} to rebuild rhythm.||Recent performance is slipping. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to get back on track.||This habit needs a lighter target for now. Strength dropped by {drop}%. Move from {fromValue} to {toValue} to improve consistency.||Your habit signal weakened recently. Strength dropped by {drop}%. Recommended target: {fromValue} -> {toValue} so you can stay consistent.'**
  String insightStrengthStartSmallType2Generic(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your consistency is strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.||You are handling this habit well. Strength is stable at {strength}%. Push the target from {fromValue} to {toValue} for more growth.||Momentum is solid here. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to level up.||You built a reliable baseline. Strength is stable at {strength}%. Move from {fromValue} to {toValue} and keep improving.||Great consistency lately. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep your progress rising.'**
  String insightStrengthIncreaseGeneric(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1GoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'Your go to bed early habit is slipping. Do not let this routine fall off now.||You have been off track with go to bed early. Show up today and protect the habit.||Momentum on go to bed early is fading. Keep it alive with one solid rep today.||Do not let go to bed early become inconsistent. Lock in and do your part today.||You started to go to bed early for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1GoToBedEarly;

  /// No description provided for @insightStrengthStartSmallType2GoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with go to bed early lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Go to bed early has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent go to bed early consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your go to bed early habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Go to bed early needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2GoToBedEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseGoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with go to bed early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on go to bed early. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your go to bed early habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for go to bed early. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on go to bed early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseGoToBedEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1BrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Your brush your teeth habit is slipping. Do not let this routine fall off now.||You have been off track with brush your teeth. Show up today and protect the habit.||Momentum on brush your teeth is fading. Keep it alive with one solid rep today.||Do not let brush your teeth become inconsistent. Lock in and do your part today.||You started to brush your teeth for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1BrushTeeth;

  /// No description provided for @insightStrengthStartSmallType2BrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with brush your teeth lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Brush your teeth has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent brush your teeth consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your brush your teeth habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Brush your teeth needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2BrushTeeth(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with brush your teeth. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on brush your teeth. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your brush your teeth habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for brush your teeth. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on brush your teeth. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseBrushTeeth(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1SkinCare.
  ///
  /// In en, this message translates to:
  /// **'Your your skin care routine habit is slipping. Do not let this routine fall off now.||You have been off track with your skin care routine. Show up today and protect the habit.||Momentum on your skin care routine is fading. Keep it alive with one solid rep today.||Do not let your skin care routine become inconsistent. Lock in and do your part today.||You started to your skin care routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1SkinCare;

  /// No description provided for @insightStrengthStartSmallType2SkinCare.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your skin care routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your skin care routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your skin care routine consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your skin care routine habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your skin care routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2SkinCare(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseSkinCare.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your skin care routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your skin care routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your skin care routine habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your skin care routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your skin care routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseSkinCare(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1WakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'Your wake up early habit is slipping. Do not let this routine fall off now.||You have been off track with wake up early. Show up today and protect the habit.||Momentum on wake up early is fading. Keep it alive with one solid rep today.||Do not let wake up early become inconsistent. Lock in and do your part today.||You started to wake up early for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1WakeUpEarly;

  /// No description provided for @insightStrengthStartSmallType2WakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with wake up early lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Wake up early has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent wake up early consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your wake up early habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Wake up early needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2WakeUpEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseWakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with wake up early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on wake up early. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your wake up early habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for wake up early. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on wake up early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseWakeUpEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Shower.
  ///
  /// In en, this message translates to:
  /// **'Your take your shower habit is slipping. Do not let this routine fall off now.||You have been off track with take your shower. Show up today and protect the habit.||Momentum on take your shower is fading. Keep it alive with one solid rep today.||Do not let take your shower become inconsistent. Lock in and do your part today.||You started to take your shower for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Shower;

  /// No description provided for @insightStrengthStartSmallType2Shower.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with take your shower lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Take your shower has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent take your shower consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your take your shower habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Take your shower needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Shower(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseShower.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with take your shower. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on take your shower. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your take your shower habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for take your shower. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on take your shower. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseShower(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Praying.
  ///
  /// In en, this message translates to:
  /// **'Your pray consistently habit is slipping. Do not let this routine fall off now.||You have been off track with pray consistently. Show up today and protect the habit.||Momentum on pray consistently is fading. Keep it alive with one solid rep today.||Do not let pray consistently become inconsistent. Lock in and do your part today.||You started to pray consistently for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Praying;

  /// No description provided for @insightStrengthStartSmallType2Praying.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with pray consistently lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Pray consistently has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent pray consistently consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your pray consistently habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Pray consistently needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Praying(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreasePraying.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with pray consistently. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on pray consistently. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your pray consistently habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for pray consistently. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on pray consistently. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreasePraying(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Running.
  ///
  /// In en, this message translates to:
  /// **'Your your running routine habit is slipping. Do not let this routine fall off now.||You have been off track with your running routine. Show up today and protect the habit.||Momentum on your running routine is fading. Keep it alive with one solid rep today.||Do not let your running routine become inconsistent. Lock in and do your part today.||You started to your running routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Running;

  /// No description provided for @insightStrengthStartSmallType2Running.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your running routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your running routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your running routine consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your running routine habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your running routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Running(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseRunning.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your running routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your running routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your running routine habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your running routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your running routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseRunning(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Walk.
  ///
  /// In en, this message translates to:
  /// **'Your your walking routine habit is slipping. Do not let this routine fall off now.||You have been off track with your walking routine. Show up today and protect the habit.||Momentum on your walking routine is fading. Keep it alive with one solid rep today.||Do not let your walking routine become inconsistent. Lock in and do your part today.||You started to your walking routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Walk;

  /// No description provided for @insightStrengthStartSmallType2Walk.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your walking routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your walking routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your walking routine consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your walking routine habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your walking routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Walk(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseWalk.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your walking routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your walking routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your walking routine habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your walking routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your walking routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseWalk(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Gym.
  ///
  /// In en, this message translates to:
  /// **'Your your gym routine habit is slipping. Do not let this routine fall off now.||You have been off track with your gym routine. Show up today and protect the habit.||Momentum on your gym routine is fading. Keep it alive with one solid rep today.||Do not let your gym routine become inconsistent. Lock in and do your part today.||You started to your gym routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Gym;

  /// No description provided for @insightStrengthStartSmallType2Gym.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your gym routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your gym routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your gym routine consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your gym routine habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your gym routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Gym(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseGym.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your gym routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your gym routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your gym routine habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your gym routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your gym routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseGym(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Nutrition.
  ///
  /// In en, this message translates to:
  /// **'Your your nutrition plan habit is slipping. Do not let this routine fall off now.||You have been off track with your nutrition plan. Show up today and protect the habit.||Momentum on your nutrition plan is fading. Keep it alive with one solid rep today.||Do not let your nutrition plan become inconsistent. Lock in and do your part today.||You started to your nutrition plan for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Nutrition;

  /// No description provided for @insightStrengthStartSmallType2Nutrition.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your nutrition plan lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your nutrition plan has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your nutrition plan consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your nutrition plan habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your nutrition plan needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Nutrition(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseNutrition.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your nutrition plan. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your nutrition plan. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your nutrition plan habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your nutrition plan. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your nutrition plan. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseNutrition(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Medications.
  ///
  /// In en, this message translates to:
  /// **'Your take your medications on time habit is slipping. Do not let this routine fall off now.||You have been off track with take your medications on time. Show up today and protect the habit.||Momentum on take your medications on time is fading. Keep it alive with one solid rep today.||Do not let take your medications on time become inconsistent. Lock in and do your part today.||You started to take your medications on time for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Medications;

  /// No description provided for @insightStrengthStartSmallType2Medications.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with take your medications on time lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Take your medications on time has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent take your medications on time consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your take your medications on time habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Take your medications on time needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Medications(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseMedications.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with take your medications on time. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on take your medications on time. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your take your medications on time habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for take your medications on time. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on take your medications on time. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseMedications(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1DrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Your drink enough water habit is slipping. Do not let this routine fall off now.||You have been off track with drink enough water. Show up today and protect the habit.||Momentum on drink enough water is fading. Keep it alive with one solid rep today.||Do not let drink enough water become inconsistent. Lock in and do your part today.||You started to drink enough water for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1DrinkWater;

  /// No description provided for @insightStrengthStartSmallType2DrinkWater.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with drink enough water lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Drink enough water has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent drink enough water consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your drink enough water habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Drink enough water needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2DrinkWater(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with drink enough water. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on drink enough water. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your drink enough water habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for drink enough water. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on drink enough water. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseDrinkWater(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Studying.
  ///
  /// In en, this message translates to:
  /// **'Your your studying habit habit is slipping. Do not let this routine fall off now.||You have been off track with your studying habit. Show up today and protect the habit.||Momentum on your studying habit is fading. Keep it alive with one solid rep today.||Do not let your studying habit become inconsistent. Lock in and do your part today.||You started to your studying habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Studying;

  /// No description provided for @insightStrengthStartSmallType2Studying.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your studying habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your studying habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your studying habit consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your studying habit habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your studying habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Studying(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseStudying.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your studying habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your studying habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your studying habit habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your studying habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your studying habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseStudying(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Work.
  ///
  /// In en, this message translates to:
  /// **'Your your work habit habit is slipping. Do not let this routine fall off now.||You have been off track with your work habit. Show up today and protect the habit.||Momentum on your work habit is fading. Keep it alive with one solid rep today.||Do not let your work habit become inconsistent. Lock in and do your part today.||You started to your work habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Work;

  /// No description provided for @insightStrengthStartSmallType2Work.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your work habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your work habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your work habit consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your work habit habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your work habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Work(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseWork.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your work habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your work habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your work habit habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your work habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your work habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseWork(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Research.
  ///
  /// In en, this message translates to:
  /// **'Your your research habit habit is slipping. Do not let this routine fall off now.||You have been off track with your research habit. Show up today and protect the habit.||Momentum on your research habit is fading. Keep it alive with one solid rep today.||Do not let your research habit become inconsistent. Lock in and do your part today.||You started to your research habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Research;

  /// No description provided for @insightStrengthStartSmallType2Research.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your research habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your research habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your research habit consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your research habit habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your research habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Research(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseResearch.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your research habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your research habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your research habit habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your research habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your research habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseResearch(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1ProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'Your your productivity sessions habit is slipping. Do not let this routine fall off now.||You have been off track with your productivity sessions. Show up today and protect the habit.||Momentum on your productivity sessions is fading. Keep it alive with one solid rep today.||Do not let your productivity sessions become inconsistent. Lock in and do your part today.||You started to your productivity sessions for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1ProductivitySession;

  /// No description provided for @insightStrengthStartSmallType2ProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your productivity sessions lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your productivity sessions has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your productivity sessions consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your productivity sessions habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your productivity sessions needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2ProductivitySession(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your productivity sessions. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your productivity sessions. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your productivity sessions habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your productivity sessions. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your productivity sessions. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseProductivitySession(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType1Read.
  ///
  /// In en, this message translates to:
  /// **'Your your reading habit habit is slipping. Do not let this routine fall off now.||You have been off track with your reading habit. Show up today and protect the habit.||Momentum on your reading habit is fading. Keep it alive with one solid rep today.||Do not let your reading habit become inconsistent. Lock in and do your part today.||You started to your reading habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Read;

  /// No description provided for @insightStrengthStartSmallType2Read.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your reading habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.||Your reading habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.||Recent your reading habit consistency is down. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.||To protect your your reading habit habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.||Your reading habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Read(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseRead.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your reading habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing even more.||Great consistency on your reading habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.||Your your reading habit habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.||You are reliably showing up for your reading habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.||Excellent rhythm on your reading habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseRead(
    Object strength,
    Object fromValue,
    Object toValue,
  );
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
