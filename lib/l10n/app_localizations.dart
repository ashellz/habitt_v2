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

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addANewAmountLabelYouCanReuseLater.
  ///
  /// In en, this message translates to:
  /// **'Add a new amount label you can reuse later.'**
  String get addANewAmountLabelYouCanReuseLater;

  /// No description provided for @addANotification.
  ///
  /// In en, this message translates to:
  /// **'Add a notification'**
  String get addANotification;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @addMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'Add more options'**
  String get addMoreOptions;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allChangesYouMadeWillBeDiscarded.
  ///
  /// In en, this message translates to:
  /// **'All changes you made will be discarded.'**
  String get allChangesYouMadeWillBeDiscarded;

  /// No description provided for @allChangesYouveMadeNowWillBeReset.
  ///
  /// In en, this message translates to:
  /// **'All changes you\'ve made now will be reset.'**
  String get allChangesYouveMadeNowWillBeReset;

  /// No description provided for @habitConfigDiscardDesc.
  ///
  /// In en, this message translates to:
  /// **'All habit configuration you have done will be discarded.'**
  String get habitConfigDiscardDesc;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountName.
  ///
  /// In en, this message translates to:
  /// **'Amount name'**
  String get amountName;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyTime;

  /// No description provided for @deleteHabitDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this habit?'**
  String get deleteHabitDesc;

  /// No description provided for @optOutOfBackup.
  ///
  /// In en, this message translates to:
  /// **'Opt out of Backup?'**
  String get optOutOfBackup;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @backupDataDownloadedFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup data downloaded from cloud.'**
  String get backupDataDownloadedFromCloud;

  /// No description provided for @backupDataFailedToDownloadFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup data failed to download from cloud.'**
  String get backupDataFailedToDownloadFromCloud;

  /// No description provided for @backupPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Backup Passphrase'**
  String get backupPassphrase;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changeAColorThemeForYourInterface.
  ///
  /// In en, this message translates to:
  /// **'Change a color theme for your interface'**
  String get changeAColorThemeForYourInterface;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved!'**
  String get changesSaved;

  /// No description provided for @chooseHowColorfulTheUiShouldBe.
  ///
  /// In en, this message translates to:
  /// **'Choose how colorful the UI should be'**
  String get chooseHowColorfulTheUiShouldBe;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearSelectedDays.
  ///
  /// In en, this message translates to:
  /// **'Clear selected days'**
  String get clearSelectedDays;

  /// No description provided for @colorfulInterface.
  ///
  /// In en, this message translates to:
  /// **'Colorful Interface'**
  String get colorfulInterface;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedHabitFoundHabitscompletedTotal.
  ///
  /// In en, this message translates to:
  /// **'Completed habit found, {habitsCompleted} total'**
  String completedHabitFoundHabitscompletedTotal(Object habitsCompleted);

  /// No description provided for @completedHabits.
  ///
  /// In en, this message translates to:
  /// **'Completed habits: '**
  String get completedHabits;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @connectToGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Google'**
  String get connectToGoogle;

  /// No description provided for @controlWhenAndHowYouGetNotifiedAboutYourHabits.
  ///
  /// In en, this message translates to:
  /// **'Control when and how you get notified about your habits.'**
  String get controlWhenAndHowYouGetNotifiedAboutYourHabits;

  /// No description provided for @createAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Create amount label'**
  String get createAmountLabel;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @dateJoinedIsNull.
  ///
  /// In en, this message translates to:
  /// **'Date joined is null'**
  String get dateJoinedIsNull;

  /// No description provided for @datejoined.
  ///
  /// In en, this message translates to:
  /// **'dateJoined'**
  String get datejoined;

  /// No description provided for @dayEntryIsNull.
  ///
  /// In en, this message translates to:
  /// **'Day entry is null'**
  String get dayEntryIsNull;

  /// No description provided for @decrementingHabitAmount.
  ///
  /// In en, this message translates to:
  /// **'Decrementing habit amount'**
  String get decrementingHabitAmount;

  /// No description provided for @defaultlabel.
  ///
  /// In en, this message translates to:
  /// **', defaultLabel: '**
  String get defaultlabel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete \'{label}\'?'**
  String deleteLabel(Object label);

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification?'**
  String get deleteNotification;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @driveApiReturnedNullFilesList.
  ///
  /// In en, this message translates to:
  /// **'Drive API returned null files list'**
  String get driveApiReturnedNullFilesList;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @enterHabitNameToConfirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Enter \'{habitName}\' to confirm deletion'**
  String enterHabitNameToConfirmDeletion(Object habitName);

  /// No description provided for @enterPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter Passphrase'**
  String get enterPassphrase;

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

  /// No description provided for @enterYourExistingBackupPassphraseToAccessYourData.
  ///
  /// In en, this message translates to:
  /// **'Enter your existing backup passphrase to access your data.'**
  String get enterYourExistingBackupPassphraseToAccessYourData;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Exit without saving?'**
  String get exitWithoutSaving;

  /// No description provided for @fetchOffers.
  ///
  /// In en, this message translates to:
  /// **'Fetch Offers'**
  String get fetchOffers;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @getRemindedAboutYourHabit.
  ///
  /// In en, this message translates to:
  /// **'Get reminded about your habit'**
  String get getRemindedAboutYourHabit;

  /// No description provided for @glassFeel.
  ///
  /// In en, this message translates to:
  /// **'Glass Feel'**
  String get glassFeel;

  /// No description provided for @showStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'Show streak badge'**
  String get showStreakBadge;

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

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @goodMorningTimeToCheckYourHabits.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Time to check your habits'**
  String get goodMorningTimeToCheckYourHabits;

  /// No description provided for @goodToSeeYou.
  ///
  /// In en, this message translates to:
  /// **'Good to see you'**
  String get goodToSeeYou;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @habit.
  ///
  /// In en, this message translates to:
  /// **'habit'**
  String get habit;

  /// No description provided for @habitAdded.
  ///
  /// In en, this message translates to:
  /// **'Habit added!'**
  String get habitAdded;

  /// No description provided for @habitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Habit deleted!'**
  String get habitDeleted;

  /// No description provided for @habitIsNotInABoxSkippingSave.
  ///
  /// In en, this message translates to:
  /// **'Habit is not in a box, skipping save()'**
  String get habitIsNotInABoxSkippingSave;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit Name'**
  String get habitName;

  /// No description provided for @habitNotFoundInDayEntry.
  ///
  /// In en, this message translates to:
  /// **'Habit not found in day entry'**
  String get habitNotFoundInDayEntry;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'habits'**
  String get habits;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @helloThere.
  ///
  /// In en, this message translates to:
  /// **'Hello there'**
  String get helloThere;

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

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you'**
  String get howAreYou;

  /// No description provided for @howLongWillThisHabitTake.
  ///
  /// In en, this message translates to:
  /// **'How long will this habit take?'**
  String get howLongWillThisHabitTake;

  /// No description provided for @howMuchDidYouCompleteToday.
  ///
  /// In en, this message translates to:
  /// **'How much did you complete today?'**
  String get howMuchDidYouCompleteToday;

  /// No description provided for @howMuchTimeDidYouSpendOnThisHabitToday.
  ///
  /// In en, this message translates to:
  /// **'How much time did you spend on this habit today?'**
  String get howMuchTimeDidYouSpendOnThisHabitToday;

  /// No description provided for @howOftenWouldYouLikeToDoThisHabit.
  ///
  /// In en, this message translates to:
  /// **'How often would you like to do this habit?'**
  String get howOftenWouldYouLikeToDoThisHabit;

  /// No description provided for @ifCheckedHabitWontCountForThePerfectDaysStreak.
  ///
  /// In en, this message translates to:
  /// **'If checked, habit won\'t count for the \'Perfect days streak\'.'**
  String get ifCheckedHabitWontCountForThePerfectDaysStreak;

  /// No description provided for @incorrectPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passphrase.'**
  String get incorrectPassphrase;

  /// No description provided for @initialProgressValuesLoadedForAllDays.
  ///
  /// In en, this message translates to:
  /// **'Initial progress values loaded for all days'**
  String get initialProgressValuesLoadedForAllDays;

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

  /// No description provided for @insightStrengthIncreaseBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with brushing your teeth. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on brushing your teeth. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Brushing your teeth is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up with brushing your teeth. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on brushing your teeth. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseBrushTeeth(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with drinking enough water. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on drinking enough water. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Drinking enough water is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up with drinking enough water. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on drinking enough water. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseDrinkWater(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your consistency is strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|You are handling this habit well. Strength is stable at {strength}%. Push the target from {fromValue} to {toValue} for more growth.|Momentum is solid here. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to level up.|You built a reliable baseline. Strength is stable at {strength}%. Move from {fromValue} to {toValue} and keep improving.|Great consistency lately. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep your progress rising.'**
  String insightStrengthIncreaseGeneric(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseGoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with going to bed early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on going to bed early. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Going to bed early is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up with going to bed early. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on going to bed early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseGoToBedEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseGym.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your gym routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your gym routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your gym routine is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your gym routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your gym routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseGym(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseNutrition.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your nutrition plan. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your nutrition plan. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your nutrition plan is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your nutrition plan. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your nutrition plan. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseNutrition(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreasePraying.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with praying consistently. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on praying consistently. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Praying consistently is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up with praying consistently. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on praying consistently. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreasePraying(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your productivity sessions. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your productivity sessions. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your productivity sessions are going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your productivity sessions. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your productivity sessions. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseProductivitySession(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseRead.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your reading habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your reading habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your reading habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your reading habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your reading habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseRead(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseResearch.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your research habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your research habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your research habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your research habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your research habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseResearch(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseRunning.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your running routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your running routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your running routine is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your running routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your running routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseRunning(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseShower.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with taking your shower. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on taking your shower. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Taking your shower consistently is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up with taking your shower. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on taking your shower. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseShower(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseSkinCare.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your skin care routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your skin care routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your skin care routine is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your skin care routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your skin care routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseSkinCare(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseStudying.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your studying habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your studying habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your studying habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your studying habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your studying habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseStudying(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase target for {habitName}'**
  String insightStrengthIncreaseTargetTitle(Object habitName);

  /// No description provided for @insightStrengthIncreaseWakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with waking up early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on waking up early. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Waking up early is going strong. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up with waking up early. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on waking up early. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseWakeUpEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseWalk.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your walking routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your walking routine. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your walking routine is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your walking routine. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your walking routine. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseWalk(
    Object strength,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthIncreaseWork.
  ///
  /// In en, this message translates to:
  /// **'You are doing great with your work habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to keep growing.|Great consistency on your work habit. Strength is stable at {strength}%. Increase your target from {fromValue} to {toValue} and keep momentum high.|Your work habit is strong right now. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} for the next level.|You are reliably showing up for your work habit. Strength is stable at {strength}%. Move from {fromValue} to {toValue} to keep improving.|Excellent rhythm on your work habit. Strength is stable at {strength}%. Recommended target: {fromValue} -> {toValue} to continue progress.'**
  String insightStrengthIncreaseWork(
    Object strength,
    Object fromValue,
    Object toValue,
  );

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

  /// No description provided for @insightStrengthStartSmallType1BrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Your brush your teeth habit is slipping. Do not let this routine fall off now.|You have been off track with brushing your teeth. Brush your teeth today and protect the habit.|Momentum on brushing your teeth is fading. Keep it alive by brushing your teeth today.|Do not let brushing your teeth become inconsistent. Lock in and brush them today.|You wanted to start brushing your teeth for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1BrushTeeth;

  /// No description provided for @insightStrengthStartSmallType1DrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Your drink water habit is slipping. Do not let this routine fall off now.|You have been off track with drinking enough water. Drink a glass of water today and protect the habit.|Momentum on drinking enough water is fading. Keep it alive by drinking your water today.|Do not let drinking enough water become inconsistent. Lock in and hydrate today.|You wanted to start drinking enough water for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1DrinkWater;

  /// No description provided for @insightStrengthStartSmallType1Generic.
  ///
  /// In en, this message translates to:
  /// **'You added this habit for a reason. Do not let it slip now.|Momentum is fading on this habit. Show up today and keep it alive.|You are falling behind on this habit. Lock in and get your rep done.|Do not negotiate with laziness here. Protect this habit today.|You came too far to let this habit drift. Stay consistent today.'**
  String get insightStrengthStartSmallType1Generic;

  /// No description provided for @insightStrengthStartSmallType1GoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'Your go to bed early habit is slipping. Do not let this routine fall off now.|You have been off track with going to bed early. Set a bedtime alarm and get to bed on time tonight.|Momentum on going to bed early is fading. Keep it alive by getting to bed on time tonight.|Do not let going to bed early become inconsistent. Lock in and get to bed on time tonight.|You wanted to start going to bed early for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1GoToBedEarly;

  /// No description provided for @insightStrengthStartSmallType1Gym.
  ///
  /// In en, this message translates to:
  /// **'Your gym routine habit is slipping. Do not let this routine fall off now.|You have been off track with your gym routine. Get to the gym today and protect the habit.|Momentum on your gym routine is fading. Keep it alive by training today.|Do not let your gym routine become inconsistent. Lock in and train today.|You wanted to build your gym routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Gym;

  /// No description provided for @insightStrengthStartSmallType1Medications.
  ///
  /// In en, this message translates to:
  /// **'Your medication habit is slipping. Do not let this routine fall off now.|You have been off track with taking your medications. Take them today and protect the habit.|Momentum on taking your medications is fading. Keep it alive by taking them on time today.|Do not let your medication schedule become inconsistent. Lock in and take them today.|You started taking your medications on time for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Medications;

  /// No description provided for @insightStrengthStartSmallType1Nutrition.
  ///
  /// In en, this message translates to:
  /// **'Your nutrition plan habit is slipping. Do not let this routine fall off now.|You have been off track with your nutrition plan. Follow your plan today and protect the habit.|Momentum on your nutrition plan is fading. Keep it alive by sticking to your plan today.|Do not let your nutrition plan become inconsistent. Lock in and follow it today.|You wanted to start your nutrition plan for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Nutrition;

  /// No description provided for @insightStrengthStartSmallType1Praying.
  ///
  /// In en, this message translates to:
  /// **'Your praying habit is slipping. Do not let this routine fall off now.|You have been off track with praying consistently. Pray today and protect the habit.|Momentum on praying consistently is fading. Keep it alive by praying today.|Do not let praying consistently become inconsistent. Lock in and pray today.|You wanted to start praying consistently for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Praying;

  /// No description provided for @insightStrengthStartSmallType1ProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'Your productivity sessions habit is slipping. Do not let this routine fall off now.|You have been off track with your productivity sessions. Do a focused session today and protect the habit.|Momentum on your productivity sessions is fading. Keep it alive by doing a session today.|Do not let your productivity sessions become inconsistent. Lock in and do a focused block today.|You wanted to start your productivity sessions for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1ProductivitySession;

  /// No description provided for @insightStrengthStartSmallType1Read.
  ///
  /// In en, this message translates to:
  /// **'Your reading habit is slipping. Do not let this routine fall off now.|You have been off track with your reading habit. Read a few pages today and protect the habit.|Momentum on your reading habit is fading. Keep it alive by reading something today.|Do not let your reading habit become inconsistent. Lock in and read today.|You wanted to start your reading habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Read;

  /// No description provided for @insightStrengthStartSmallType1Research.
  ///
  /// In en, this message translates to:
  /// **'Your research habit is slipping. Do not let this routine fall off now.|You have been off track with your research habit. Do some research today and protect the habit.|Momentum on your research habit is fading. Keep it alive by researching today.|Do not let your research habit become inconsistent. Lock in and do your research today.|You wanted to start your research habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Research;

  /// No description provided for @insightStrengthStartSmallType1Running.
  ///
  /// In en, this message translates to:
  /// **'Your running routine habit is slipping. Do not let this routine fall off now.|You have been off track with your running routine. Get out for a run today and protect the habit.|Momentum on your running routine is fading. Keep it alive by going for a run today.|Do not let your running routine become inconsistent. Lock in and run today.|You wanted to build your running routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Running;

  /// No description provided for @insightStrengthStartSmallType1Shower.
  ///
  /// In en, this message translates to:
  /// **'Your shower habit is slipping. Do not let this routine fall off now.|You have been off track with taking your shower. Take your shower today and protect the habit.|Momentum on taking your shower is fading. Keep it alive by showering today.|Do not let your shower routine become inconsistent. Lock in and take your shower today.|You wanted to start taking your shower regularly for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Shower;

  /// No description provided for @insightStrengthStartSmallType1SkinCare.
  ///
  /// In en, this message translates to:
  /// **'Your skin care routine habit is slipping. Do not let this routine fall off now.|You have been off track with your skin care routine. Do your skin care today and protect the habit.|Momentum on your skin care routine is fading. Keep it alive by doing your skin care today.|Do not let your skin care routine become inconsistent. Lock in and do it today.|You wanted to start your skin care routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1SkinCare;

  /// No description provided for @insightStrengthStartSmallType1Studying.
  ///
  /// In en, this message translates to:
  /// **'Your studying habit is slipping. Do not let this routine fall off now.|You have been off track with your studying habit. Study today and protect the habit.|Momentum on your studying habit is fading. Keep it alive by studying today.|Do not let your studying habit become inconsistent. Lock in and study today.|You wanted to start your studying habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Studying;

  /// No description provided for @insightStrengthStartSmallType1WakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'Your wake up early habit is slipping. Do not let this routine fall off now.|You have been off track with waking up early. Set your alarm and wake up on time tomorrow.|Momentum on waking up early is fading. Keep it alive by getting up on time tomorrow.|Do not let waking up early become inconsistent. Lock in and set your alarm tonight.|You wanted to start waking up early for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1WakeUpEarly;

  /// No description provided for @insightStrengthStartSmallType1Walk.
  ///
  /// In en, this message translates to:
  /// **'Your walking routine habit is slipping. Do not let this routine fall off now.|You have been off track with your walking routine. Go for a walk today and protect the habit.|Momentum on your walking routine is fading. Keep it alive by going for a walk today.|Do not let your walking routine become inconsistent. Lock in and walk today.|You wanted to build your walking routine for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Walk;

  /// No description provided for @insightStrengthStartSmallType1Work.
  ///
  /// In en, this message translates to:
  /// **'Your work habit is slipping. Do not let this routine fall off now.|You have been off track with your work habit. Do meaningful work today and protect the habit.|Momentum on your work habit is fading. Keep it alive by putting in work today.|Do not let your work habit become inconsistent. Lock in and do your work today.|You wanted to build your work habit for a reason. Stay disciplined and keep it from slipping.'**
  String get insightStrengthStartSmallType1Work;

  /// No description provided for @insightStrengthStartSmallType2BrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with brushing your teeth lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Brushing your teeth has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your teeth brushing consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your brushing habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Brushing your teeth needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2BrushTeeth(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2DrinkWater.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with drinking enough water lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Drinking enough water has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your hydration consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your hydration habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Drinking enough water needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2DrinkWater(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Generic.
  ///
  /// In en, this message translates to:
  /// **'Consistency dropped on this habit. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to stabilize again.|You have been off track lately. Strength dropped by {drop}%. Try this target shift: {fromValue} -> {toValue} to rebuild rhythm.|Recent performance is slipping. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to get back on track.|This habit needs a lighter target for now. Strength dropped by {drop}%. Move from {fromValue} to {toValue} to improve consistency.|Your habit signal weakened recently. Strength dropped by {drop}%. Recommended target: {fromValue} -> {toValue} so you can stay consistent.'**
  String insightStrengthStartSmallType2Generic(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2GoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with going to bed early lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Going to bed early has been harder recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your bedtime consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your bedtime habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Going to bed early needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2GoToBedEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Gym.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your gym routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your gym routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your gym consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your gym routine, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your gym routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Gym(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Medications.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with taking your medications on time lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Taking your medications on time has been harder recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your medication consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your medication habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your medication habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Medications(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Nutrition.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your nutrition plan lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your nutrition plan has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your nutrition consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your nutrition plan, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your nutrition plan needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Nutrition(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Praying.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with praying consistently lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Praying consistently has been harder recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your prayer consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your praying habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your praying habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Praying(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2ProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your productivity sessions lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your productivity sessions have been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your productivity consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your productivity sessions, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your productivity sessions need a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2ProductivitySession(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Read.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your reading habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your reading habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your reading consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your reading habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your reading habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Read(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Research.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your research habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your research habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your research consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your research habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your research habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Research(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Running.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your running routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your running routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your running consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your running routine, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your running routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Running(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Shower.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with taking your shower lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Taking your shower has been harder recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your shower consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your shower habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your shower habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Shower(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2SkinCare.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your skin care routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your skin care routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your skin care consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your skin care routine, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your skin care routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2SkinCare(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Studying.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your studying habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your studying habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your studying consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your studying habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your studying habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Studying(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2WakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with waking up early lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Waking up early has been harder recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your morning routine consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your wake up early habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Waking up early needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2WakeUpEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Walk.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your walking routine lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your walking routine has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your walking consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your walking routine, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your walking routine needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Walk(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @insightStrengthStartSmallType2Work.
  ///
  /// In en, this message translates to:
  /// **'You have not been consistent with your work habit lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to keep the habit alive.|Your work habit has been weaker recently. Strength dropped by {drop}%. Move your target from {fromValue} to {toValue} to rebuild consistency.|Your work consistency is down lately. Strength dropped by {drop}% in the last few days. Recommended target: {fromValue} -> {toValue} to recover momentum.|To protect your work habit, lower the target for now. Strength dropped by {drop}%. Recommended: {fromValue} -> {toValue}.|Your work habit needs a reset. Strength dropped by {drop}%. Try {fromValue} -> {toValue} so this habit stays alive.'**
  String insightStrengthStartSmallType2Work(
    Object drop,
    Object fromValue,
    Object toValue,
  );

  /// No description provided for @invalidTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid Time'**
  String get invalidTime;

  /// No description provided for @keepYourDataSafeByBackingItUpToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Keep your data safe by backing it up to Google Drive.'**
  String get keepYourDataSafeByBackingItUpToGoogleDrive;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @leaveSetup.
  ///
  /// In en, this message translates to:
  /// **'Leave setup?'**
  String get leaveSetup;

  /// No description provided for @logDuration.
  ///
  /// In en, this message translates to:
  /// **'Log duration'**
  String get logDuration;

  /// No description provided for @logProgress.
  ///
  /// In en, this message translates to:
  /// **'Log progress'**
  String get logProgress;

  /// No description provided for @makesWidgetsLookMoreGlassy.
  ///
  /// In en, this message translates to:
  /// **'Makes widgets look more glassy'**
  String get makesWidgetsLookMoreGlassy;

  /// No description provided for @manageYourNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get manageYourNotificationPreferences;

  /// No description provided for @manageYourSubscriptionsAndBillingPlansHere.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscriptions and billing plans here.'**
  String get manageYourSubscriptionsAndBillingPlansHere;

  /// No description provided for @manageYourSubscriptionsAndViewPremiumBenefits.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscriptions and view premium benefits'**
  String get manageYourSubscriptionsAndViewPremiumBenefits;

  /// No description provided for @midday.
  ///
  /// In en, this message translates to:
  /// **'Mid-day'**
  String get midday;

  /// No description provided for @middayCheckinTimeForYourHabits.
  ///
  /// In en, this message translates to:
  /// **'Mid-day check-in time for your habits'**
  String get middayCheckinTimeForYourHabits;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @missingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Missing Permissions'**
  String get missingPermissions;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get newHabit;

  /// No description provided for @noHabitsFoundUsingDefaultCategoryOrder.
  ///
  /// In en, this message translates to:
  /// **'No habits found, using default category order.'**
  String get noHabitsFoundUsingDefaultCategoryOrder;

  /// No description provided for @noHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'No habits yet.'**
  String get noHabitsYet;

  /// No description provided for @noOfferingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No offerings available'**
  String get noOfferingsAvailable;

  /// No description provided for @noTag.
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get noTag;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notificationAmountLabelFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s target is {target} {label}.|Your number for today: {target} {label}. Start with one.|Today\'s dose: {target} {label}. Clear target, simple execution.|Today asks for {target} {label}. You know the rhythm.|Target for today: {target} {label}. A precise goal is a powerful cue.'**
  String notificationAmountLabelFocus(Object label, Object target);

  /// No description provided for @notificationCombinedAmountAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left, {encouragement}.'**
  String notificationCombinedAmountAlmostDone(
    Object encouragement,
    Object remaining,
  );

  /// No description provided for @notificationCombinedAmountCompleted.
  ///
  /// In en, this message translates to:
  /// **'Target already reached, well done.|You\'ve completed today\'s target, congratulations!|You\'ve already hit your goal today — great job!|The target has already been met, awesome!|You\'ve already reached today\'s target, excellent work!'**
  String notificationCombinedAmountCompleted(Object encouragement);

  /// No description provided for @notificationCombinedAmountInProgress.
  ///
  /// In en, this message translates to:
  /// **'You are at {progress}, {encouragement}.'**
  String notificationCombinedAmountInProgress(
    Object encouragement,
    Object progress,
  );

  /// No description provided for @notificationCombinedAmountNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start now, even one step counts, {encouragement}.'**
  String notificationCombinedAmountNotStarted(Object encouragement);

  /// No description provided for @notificationCombinedDurationAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left, {encouragement}.'**
  String notificationCombinedDurationAlmostDone(
    Object encouragement,
    Object remaining,
  );

  /// No description provided for @notificationCombinedDurationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Target reached already, {encouragement}.'**
  String notificationCombinedDurationCompleted(Object encouragement);

  /// No description provided for @notificationCombinedDurationInProgress.
  ///
  /// In en, this message translates to:
  /// **'You are at {progress}, {encouragement}.'**
  String notificationCombinedDurationInProgress(
    Object encouragement,
    Object progress,
  );

  /// No description provided for @notificationCombinedDurationNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start a short session now, {encouragement}.'**
  String notificationCombinedDurationNotStarted(Object encouragement);

  /// No description provided for @notificationCombinedFresh.
  ///
  /// In en, this message translates to:
  /// **'You started this habit {days} days ago, {encouragement}.'**
  String notificationCombinedFresh(Object days, Object encouragement);

  /// No description provided for @notificationCombinedGeneral.
  ///
  /// In en, this message translates to:
  /// **'{encouragement}.'**
  String notificationCombinedGeneral(Object encouragement);

  /// No description provided for @notificationCombinedOneOff.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss today, it\'s your last {period} chance and {encouragement}.'**
  String notificationCombinedOneOff(Object encouragement, Object period);

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

  /// No description provided for @notificationEncourageGoToBedEarly10.
  ///
  /// In en, this message translates to:
  /// **'this evening decision helps your whole week run smoother'**
  String get notificationEncourageGoToBedEarly10;

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

  /// No description provided for @notificationFreshnessBrandNew.
  ///
  /// In en, this message translates to:
  /// **'Time for this brand new habit to shine!'**
  String get notificationFreshnessBrandNew;

  /// No description provided for @notificationFreshnessEstablishedDays.
  ///
  /// In en, this message translates to:
  /// **'You have been building this for {days} days so far. Keep compounding wins.'**
  String notificationFreshnessEstablishedDays(Object days);

  /// No description provided for @notificationFreshnessNewDays.
  ///
  /// In en, this message translates to:
  /// **'You started {days} ago. Keep it up!|Day {days}. The early days are the foundation — solid work.|You started {days} days ago. Each one matters equally.'**
  String notificationFreshnessNewDays(Object days);

  /// No description provided for @notificationOptional.
  ///
  /// In en, this message translates to:
  /// **'This one is optional today, but still mind giving it a try?|You got some extra time?'**
  String get notificationOptional;

  /// No description provided for @notificationPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get notificationPeriodMonthly;

  /// No description provided for @notificationPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get notificationPeriodWeekly;

  /// No description provided for @notificationPremadeBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Quick hygiene win now keeps your routine sharp.'**
  String get notificationPremadeBrushTeeth;

  /// No description provided for @notificationPremadeDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Hydrate now and keep your body performing well.'**
  String get notificationPremadeDrinkWater;

  /// No description provided for @notificationPremadeGoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'Protect tonight so tomorrow starts easier.'**
  String get notificationPremadeGoToBedEarly;

  /// No description provided for @notificationPremadeGym.
  ///
  /// In en, this message translates to:
  /// **'Show up for a solid gym rep and build consistency.'**
  String get notificationPremadeGym;

  /// No description provided for @notificationPremadeMedications.
  ///
  /// In en, this message translates to:
  /// **'Take your meds on time to protect your health baseline.'**
  String get notificationPremadeMedications;

  /// No description provided for @notificationPremadeNutrition.
  ///
  /// In en, this message translates to:
  /// **'Make one intentional nutrition choice right now.'**
  String get notificationPremadeNutrition;

  /// No description provided for @notificationPremadePraying.
  ///
  /// In en, this message translates to:
  /// **'Take a calm moment now and reconnect with intention.'**
  String get notificationPremadePraying;

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

  /// No description provided for @notificationPremadeResearch.
  ///
  /// In en, this message translates to:
  /// **'Capture one useful insight and move your research forward.'**
  String get notificationPremadeResearch;

  /// No description provided for @notificationPremadeRunning.
  ///
  /// In en, this message translates to:
  /// **'Lace up and collect a strong training rep today.'**
  String get notificationPremadeRunning;

  /// No description provided for @notificationPremadeShower.
  ///
  /// In en, this message translates to:
  /// **'Reset your energy with this simple routine.'**
  String get notificationPremadeShower;

  /// No description provided for @notificationPremadeSkinCare.
  ///
  /// In en, this message translates to:
  /// **'Take care of your skin now to stay consistent.'**
  String get notificationPremadeSkinCare;

  /// No description provided for @notificationPremadeStudying.
  ///
  /// In en, this message translates to:
  /// **'Start a focused study block and build learning momentum.'**
  String get notificationPremadeStudying;

  /// No description provided for @notificationPremadeWakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'A strong start to your day begins with this choice.'**
  String get notificationPremadeWakeUpEarly;

  /// No description provided for @notificationPremadeWalk.
  ///
  /// In en, this message translates to:
  /// **'A short walk now is enough to keep momentum alive.'**
  String get notificationPremadeWalk;

  /// No description provided for @notificationPremadeWork.
  ///
  /// In en, this message translates to:
  /// **'Start your most important task and gain traction.'**
  String get notificationPremadeWork;

  /// No description provided for @notificationProgressAlmostDoneAmount.
  ///
  /// In en, this message translates to:
  /// **'You are so close. Just {remaining} {label} left.|{remaining} {label} left. This is your rhythm — lean into it.|{remaining} {label} to go. You\'ve already done the majority.|Almost there — {remaining} {label} separates you from done.|You\'re {remaining} {label} away from your target. Finish strong.|The finish line is close. Just {remaining} {label} to wrap up.'**
  String notificationProgressAlmostDoneAmount(Object label, Object remaining);

  /// No description provided for @notificationProgressAlmostDoneDuration.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} left. Tune in for a little bit more and you\'re done!|{remaining} to go. You can always do just a little more.|{remaining} remaining. Finishing is its own reward.|{remaining} to go. You can do this!'**
  String notificationProgressAlmostDoneDuration(Object remaining);

  /// No description provided for @notificationProgressCompletedAmount.
  ///
  /// In en, this message translates to:
  /// **'You already hit {completed} {label}. Ready for more?|{completed} {label} done. Momentum is on your side now.|{completed} {label} in the bank. Your habit is working.|Nice — {completed} {label} completed. Want to stretch a little?'**
  String notificationProgressCompletedAmount(Object completed, Object label);

  /// No description provided for @notificationProgressCompletedDuration.
  ///
  /// In en, this message translates to:
  /// **'Target done: {completed} done already.|Time target hit: {completed}. You showed up and stayed.|{completed} of focused time. Done. That\'s real commitment.|Session complete: {completed}. Your consistency just grew.|{completed} logged. Your future self will thank you.|Target time reached: {completed}. Great use of focused effort.'**
  String notificationProgressCompletedDuration(Object completed);

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

  /// No description provided for @notificationProgressNotStartedAmount.
  ///
  /// In en, this message translates to:
  /// **'Begin with 1 {label} only and build momentum. It\'s easy!|You don\'t need motivation. Just start.|The hardest part is starting. You can do it!'**
  String notificationProgressNotStartedAmount(Object label);

  /// No description provided for @notificationProgressNotStartedDuration.
  ///
  /// In en, this message translates to:
  /// **'Start with a short session at least!|You don\'t need motivation. Just start.|The hardest part is starting. You can do it!|Few minutes from now, you\'ll be glad you started.'**
  String get notificationProgressNotStartedDuration;

  /// No description provided for @notificationScheduleCustomEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Custom cadence: every {days} days. Today is one of your slots.|Every {days} days rhythm. Today is a scheduled day.|Your {days}-day cycle aligns today. Time to act.|Custom schedule says: today is this habit\'s day. Use your slot!|This habit runs every {days} days. You\'re due right now.|Today is part of this habit\'s rhythm. Honor the pattern.'**
  String notificationScheduleCustomEveryDays(Object days);

  /// No description provided for @notificationScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Your daily anchor awaits. Lock it in.|Daily window is open. Step through it.|Your daily practice builds quietly. But it builds.|This is your daily habit call. Respond to it!'**
  String get notificationScheduleDaily;

  /// No description provided for @notificationScheduleMonthlyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month ({completed}/{target} done). Skipping today puts your target at risk.|{remaining} to go this month ({completed}/{target}). Today protects your progress.|Your monthly goal ({completed}/{target}) is still possible. Today is a key move.|{completed}/{target} for the month. Don\'t let today be the gap.|{remaining} needed this month ({completed}/{target}). One session at a time stays on track.|Monthly target within reach ({completed}/{target}). Today keeps the door open.'**
  String notificationScheduleMonthlyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleMonthlyImpossible.
  ///
  /// In en, this message translates to:
  /// **'This month\'s target won\'t be met ({completed}/{target}). Use the remaining days for practice, not pressure.|The monthly number is out of reach ({completed}/{target}). But habits are built in the gaps, not just the goals.|Target unreachable this month ({completed}/{target}). Every attempt still rewires the loop.|{completed}/{target} this month. The goal won\'t align — but the habit still counts.|This month\'s target exceeded your available days ({completed}/{target}). Adjust and keep moving.'**
  String notificationScheduleMonthlyImpossible(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One more completion this month and you hit your target ({completed}/{target}).|One more this month hits {target} ({completed} done). This is your closing move.|You\'re one session from your monthly goal ({completed}/{target}). Seal it.|Monthly target needs one final completion ({completed}/{target}). Today can be that day.|One more and you\'re at {target} for the month ({completed} done). Finish what you started.|Your monthly goal is one away ({completed}/{target}). That\'s a single session.'**
  String notificationScheduleMonthlyOneLeft(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly target already reached ({completed}/{target}). Extra rep, extra momentum.|You\'ve nailed your monthly goal ({completed}/{target}). This is elite consistency.|Monthly target: done ({completed}/{target}). Everything now is exponential growth.|Monthly goal already crushed ({completed}/{target}). Bonus reps deepen the groove.'**
  String notificationScheduleMonthlyReached(Object completed, Object target);

  /// No description provided for @notificationScheduleMonthlyRemaining.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this month to reach {target}.|{remaining} sessions left this month to hit {target}. Consistent pacing wins.|You need {remaining} more for your monthly goal of {target}. Each one builds.|Monthly target: {remaining} of {target} remaining. You have time — use it wisely.|{remaining} to go this month for {target}. Small, steady actions close the gap.|Your monthly number is {target} with {remaining} left. Today moves the goal forward.'**
  String notificationScheduleMonthlyRemaining(Object remaining, Object target);

  /// No description provided for @notificationScheduleWeeklyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week ({completed}/{target} done). If you skip today, your goal gets much harder.|You need {remaining} more this week ({completed}/{target}). Today keeps it manageable.|{remaining} to go this week ({completed}/{target}). Skipping today adds pressure.|Your weekly target ({completed}/{target}) is still reachable. Today is a leverage point.|{completed}/{target} for the week. One today keeps your goal on track.|{remaining} remaining this week ({completed}/{target}). Today is your best move.'**
  String notificationScheduleWeeklyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  );

  /// No description provided for @notificationScheduleWeeklyImpossible.
  ///
  /// In en, this message translates to:
  /// **'This week\'s target is out of reach ({completed}/{target}). Still, every rep builds for next week.|Goal won\'t be met this week ({completed}/{target}). But unfinished weeks teach us what to adjust.|The weekly number won\'t align ({completed}/{target}). Do it anyway — consistency ignores the scoreboard.|Target missed this week ({completed}/{target}). Each attempt still strengthens the habit loop.|{completed}/{target} this week. The goal is out of range — but the habit isn\'t.'**
  String notificationScheduleWeeklyImpossible(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyOneLeft.
  ///
  /// In en, this message translates to:
  /// **'One more completion this week and you hit your target ({completed}/{target}).|One more this week and you\'re at {target} ({completed} done). Close the loop.|You\'re one session away from your weekly goal ({completed}/{target}). Make it count.|This week\'s target needs just one more ({completed}/{target}). You can close it now.|One more completion stands between you and {target} this week ({completed} done).|Weekly goal within reach: one more ({completed}/{target}). That\'s just today.'**
  String notificationScheduleWeeklyOneLeft(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyReached.
  ///
  /// In en, this message translates to:
  /// **'Weekly target already reached ({completed}/{target}). This is bonus consistency.|You hit your weekly goal ({completed}/{target}). Everything extra is a win.|Weekly target: achieved ({completed}/{target}). Bonus reps build elite habits.|{completed}/{target} for the week. You\'re above and beyond.|Weekly goal already met ({completed}/{target}). You\'re operating at a higher level.|You\'ve done your weekly target ({completed}/{target}). Consistency is now surplus.'**
  String notificationScheduleWeeklyReached(Object completed, Object target);

  /// No description provided for @notificationScheduleWeeklyRemaining.
  ///
  /// In en, this message translates to:
  /// **'You need {remaining} more this week to reach {target}.|{remaining} to go for weekly target of {target}. Steady pacing works.|You need {remaining} more this week. Today is a great time to start one.|Weekly goal: {remaining} remaining of {target}. Spread the effort.|{remaining} sessions left to hit {target} this week. Each one matters equally.|Your weekly target is {target}, with {remaining} to go. One step at a time.'**
  String notificationScheduleWeeklyRemaining(Object remaining, Object target);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled'**
  String get notificationsAreDisabled;

  /// No description provided for @notificationsOffDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to receive reminders for this habit.'**
  String get notificationsOffDialogDesc;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @numberOfDaysInARowYouHaveCompletedAllYourHabits.
  ///
  /// In en, this message translates to:
  /// **'Number of days in a row you have completed all your habits.'**
  String get numberOfDaysInARowYouHaveCompletedAllYourHabits;

  /// No description provided for @onlyVisibleOnDailyPlanEnableColorfulModeInSettingsToShowOnCompletion.
  ///
  /// In en, this message translates to:
  /// **'Only visible on Daily plan. Enable \'Colorful\' mode in Settings to show on completion.'**
  String
  get onlyVisibleOnDailyPlanEnableColorfulModeInSettingsToShowOnCompletion;

  /// No description provided for @optOut.
  ///
  /// In en, this message translates to:
  /// **'Opt out'**
  String get optOut;

  /// No description provided for @optionalHabit.
  ///
  /// In en, this message translates to:
  /// **'Optional habit'**
  String get optionalHabit;

  /// No description provided for @optionalHabits.
  ///
  /// In en, this message translates to:
  /// **'Optional habits'**
  String get optionalHabits;

  /// No description provided for @orToChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'or the amount label'**
  String get orToChangeLabel;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @perfectDaysStreak.
  ///
  /// In en, this message translates to:
  /// **'Perfect days streak'**
  String get perfectDaysStreak;

  /// No description provided for @preparingBackupName.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup name...'**
  String get preparingBackupName;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @reorderingCategoriesBasedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Reordering categories based on time'**
  String get reorderingCategoriesBasedOnTime;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetChanges.
  ///
  /// In en, this message translates to:
  /// **'Reset changes?'**
  String get resetChanges;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @satoshi.
  ///
  /// In en, this message translates to:
  /// **'Satoshi'**
  String get satoshi;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @schedulingAndAlerts.
  ///
  /// In en, this message translates to:
  /// **'Scheduling and Alerts'**
  String get schedulingAndAlerts;

  /// No description provided for @schedulingFallbackToAll.
  ///
  /// In en, this message translates to:
  /// **'Scheduling fallback to \'All\''**
  String get schedulingFallbackToAll;

  /// No description provided for @selectAColorPaletteForYourInterface.
  ///
  /// In en, this message translates to:
  /// **'Select a color palette for your interface'**
  String get selectAColorPaletteForYourInterface;

  /// No description provided for @selectHabitColor.
  ///
  /// In en, this message translates to:
  /// **'Select habit color'**
  String get selectHabitColor;

  /// No description provided for @selectHabitTime.
  ///
  /// In en, this message translates to:
  /// **'SELECT HABIT TIME:'**
  String get selectHabitTime;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @selectTimeInterval.
  ///
  /// In en, this message translates to:
  /// **'Select time interval'**
  String get selectTimeInterval;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @setAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Set amount label'**
  String get setAmountLabel;

  /// No description provided for @setDuration.
  ///
  /// In en, this message translates to:
  /// **'Set duration'**
  String get setDuration;

  /// No description provided for @setNotificationTime.
  ///
  /// In en, this message translates to:
  /// **'Set notification time'**
  String get setNotificationTime;

  /// No description provided for @setPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Set Passphrase'**
  String get setPassphrase;

  /// No description provided for @setSchedule.
  ///
  /// In en, this message translates to:
  /// **'Set Schedule'**
  String get setSchedule;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signinFirstError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in first Error'**
  String get signinFirstError;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skippedHabitFoundHabitsskippedTotal.
  ///
  /// In en, this message translates to:
  /// **'Skipped habit found, {habitsSkipped} total'**
  String skippedHabitFoundHabitsskippedTotal(Object habitsSkipped);

  /// No description provided for @skippingHabitNotAllowedHabitDayBeforeSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipping habit not allowed, habit day before skipped'**
  String get skippingHabitNotAllowedHabitDayBeforeSkipped;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @syncErrorErrormessage.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {errorMessage}'**
  String syncErrorErrormessage(Object errorMessage);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncingProgressmessage.
  ///
  /// In en, this message translates to:
  /// **'Syncing: {progressMessage}'**
  String syncingProgressmessage(Object progressMessage);

  /// No description provided for @tappedAmount.
  ///
  /// In en, this message translates to:
  /// **'Tapped amount'**
  String get tappedAmount;

  /// No description provided for @tappedDuration.
  ///
  /// In en, this message translates to:
  /// **'Tapped duration'**
  String get tappedDuration;

  /// No description provided for @thisAmountLabelWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'This amount label will be removed.'**
  String get thisAmountLabelWillBeRemoved;

  /// No description provided for @thisLabelCantBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This label can\'t be deleted'**
  String get thisLabelCantBeDeleted;

  /// No description provided for @thisNotificationCantBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This notification can\'t be deleted'**
  String get thisNotificationCantBeDeleted;

  /// No description provided for @thisNotificationTimeWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'This notification time will be removed.'**
  String get thisNotificationTimeWillBeRemoved;

  /// No description provided for @thisPassphraseIsUsedForYourDataEncryptionSaveItSecurelyYouWillUseItAgainWhenGettingYourDataOnOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'This passphrase is used for your data encryption. Save it securely, you will use it again when getting your data on other devices.'**
  String
  get thisPassphraseIsUsedForYourDataEncryptionSaveItSecurelyYouWillUseItAgainWhenGettingYourDataOnOtherDevices;

  /// No description provided for @thisReminderWillTriggerOnlyOnScheduledHabitDays.
  ///
  /// In en, this message translates to:
  /// **'This reminder will trigger only on scheduled habit days.'**
  String get thisReminderWillTriggerOnlyOnScheduledHabitDays;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'step'**
  String get step;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get steps;

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'glass'**
  String get glass;

  /// No description provided for @glasses.
  ///
  /// In en, this message translates to:
  /// **'glasses'**
  String get glasses;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'page'**
  String get page;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get pages;

  /// No description provided for @dl.
  ///
  /// In en, this message translates to:
  /// **'dl'**
  String get dl;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'meal'**
  String get meal;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'meals'**
  String get meals;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @toReceiveRemindersPleaseEnableNotificationPermissionsForHabitt.
  ///
  /// In en, this message translates to:
  /// **'To receive reminders, please enable notification permissions for Habitt.'**
  String get toReceiveRemindersPleaseEnableNotificationPermissionsForHabitt;

  /// No description provided for @toUseHabitRemindersEnableNotificationsInYourDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'To use habit reminders, enable notifications in your device settings.'**
  String get toUseHabitRemindersEnableNotificationsInYourDeviceSettings;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @uploadingBackupToCloud.
  ///
  /// In en, this message translates to:
  /// **'Uploading backup to cloud!'**
  String get uploadingBackupToCloud;

  /// No description provided for @useYourGoogleDriveToBackupEncryptedAppData.
  ///
  /// In en, this message translates to:
  /// **'Use your google drive to backup encrypted app data'**
  String get useYourGoogleDriveToBackupEncryptedAppData;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @welcomeToHabitt.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Habitt.'**
  String get welcomeToHabitt;

  /// No description provided for @whatAreYouCountingForThisHabit.
  ///
  /// In en, this message translates to:
  /// **'What are you counting for this habit?'**
  String get whatAreYouCountingForThisHabit;

  /// No description provided for @whatShouldWeCallYou.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get whatShouldWeCallYou;

  /// No description provided for @whatsUp.
  ///
  /// In en, this message translates to:
  /// **'What\'s up'**
  String get whatsUp;

  /// No description provided for @wrapUp.
  ///
  /// In en, this message translates to:
  /// **'Wrap up'**
  String get wrapUp;

  /// No description provided for @wrapUpReflectionHowDidYourHabitsGoToday.
  ///
  /// In en, this message translates to:
  /// **'Wrap up reflection: How did your habits go today?'**
  String get wrapUpReflectionHowDidYourHabitsGoToday;

  /// No description provided for @youAreCurrentlyNotConnectedToYourGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'You are currently not connected to your Google account.'**
  String get youAreCurrentlyNotConnectedToYourGoogleAccount;

  /// No description provided for @youCanPressNumberAbove.
  ///
  /// In en, this message translates to:
  /// **'You can also press the number above to change {type}'**
  String youCanPressNumberAbove(Object type);

  /// No description provided for @youHaveUnsavedChangesAreYouSureYouWantToGoBackAndDiscardThem.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to go back and discard them?'**
  String get youHaveUnsavedChangesAreYouSureYouWantToGoBackAndDiscardThem;

  /// No description provided for @youHaventAddedAnyHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven’t added any habits yet'**
  String get youHaventAddedAnyHabitsYet;

  /// No description provided for @youWillUseThisPassphraseToDecryptYourDataWhenImportingIt.
  ///
  /// In en, this message translates to:
  /// **'You will use this passphrase to decrypt your data when importing it.'**
  String get youWillUseThisPassphraseToDecryptYourDataWhenImportingIt;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @gettingConsistantMakeNonOptional.
  ///
  /// In en, this message translates to:
  /// **'You\'re getting really consistent with this habit. Consider not making it optional to push yourself a bit more. Do you want to update this habit now?'**
  String get gettingConsistantMakeNonOptional;

  /// No description provided for @getPremium.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get getPremium;

  /// No description provided for @enjoyAllBenefits.
  ///
  /// In en, this message translates to:
  /// **'Enjoy all the benefits of the app'**
  String get enjoyAllBenefits;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get rateUs;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @leaveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Leave feedback'**
  String get leaveFeedback;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @backupAndSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get backupAndSync;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {lastSynced}'**
  String lastSynced(Object lastSynced);

  /// No description provided for @changeHabitTimesInPeriodWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing the amount of times habit appears in a {period} will clear selected days'**
  String changeHabitTimesInPeriodWarning(Object period);

  /// No description provided for @habitDetails.
  ///
  /// In en, this message translates to:
  /// **'Habit details'**
  String get habitDetails;

  /// No description provided for @deleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete habit'**
  String get deleteHabit;

  /// No description provided for @markAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as complete'**
  String get markAsComplete;

  /// No description provided for @habitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Habit not found'**
  String get habitNotFound;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreak;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRate;

  /// No description provided for @completionRatio.
  ///
  /// In en, this message translates to:
  /// **'Completion ratio'**
  String get completionRatio;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get consistency;

  /// No description provided for @yourActivityOverTime.
  ///
  /// In en, this message translates to:
  /// **'Your Activity Over Time'**
  String get yourActivityOverTime;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @allHabits.
  ///
  /// In en, this message translates to:
  /// **'All habits'**
  String get allHabits;

  /// No description provided for @isScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'Scheduled today'**
  String get isScheduledToday;

  /// No description provided for @time2.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time2;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose icon'**
  String get chooseIcon;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @habitType.
  ///
  /// In en, this message translates to:
  /// **'Habit type'**
  String get habitType;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every:'**
  String get repeatEvery;

  /// No description provided for @habitWillAppear.
  ///
  /// In en, this message translates to:
  /// **'This habit will appear every {days}. {dayLabel} starting from today'**
  String habitWillAppear(Object dayLabel, Object days);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseAppLanguage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get allNotifications;

  /// No description provided for @habitNotifications.
  ///
  /// In en, this message translates to:
  /// **'Habit notifications'**
  String get habitNotifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @dailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get dailyReminders;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @findALanguage.
  ///
  /// In en, this message translates to:
  /// **'Find a language'**
  String get findALanguage;

  /// No description provided for @noLanguagesFound.
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get noLanguagesFound;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @timesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Times per week:'**
  String get timesPerWeek;

  /// No description provided for @timesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Times per month:'**
  String get timesPerMonth;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @habitWillAppearWeekly.
  ///
  /// In en, this message translates to:
  /// **'This habit will appear {amount} {label} per week until completed'**
  String habitWillAppearWeekly(Object amount, Object label);

  /// No description provided for @habitWillAppearMonthly.
  ///
  /// In en, this message translates to:
  /// **'This habit will appear {amount} {label} per month until completed'**
  String habitWillAppearMonthly(Object amount, Object label);

  /// No description provided for @selectDaysForHabit.
  ///
  /// In en, this message translates to:
  /// **'Select days for this habit:'**
  String get selectDaysForHabit;

  /// No description provided for @leaveUnselected.
  ///
  /// In en, this message translates to:
  /// **'Leave unselected if you want the habit too appear every day of the {period} until goals are met'**
  String leaveUnselected(Object period);

  /// No description provided for @month2.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month2;

  /// No description provided for @week2.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week2;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileDetails;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @youDontHaveAnEmailYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an email yet'**
  String get youDontHaveAnEmailYet;

  /// No description provided for @yourUsername.
  ///
  /// In en, this message translates to:
  /// **'Your username'**
  String get yourUsername;

  /// No description provided for @youreDoingGreat.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing really great!'**
  String get youreDoingGreat;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Build habits that actually stick'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your progress. Stay consistent. See your growth over time.'**
  String get onboardingStep1Subtitle;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Track habits your way'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Count reps, measure duration, or simply mark your habit complete.'**
  String get onboardingStep2Subtitle;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'See your real consistency'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks, strength, weekly ratio and progress insights in one place.'**
  String get onboardingStep3Subtitle;

  /// No description provided for @onboardingStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get onboardingStep4Title;

  /// No description provided for @onboardingStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Morning, mid-day and wrap-up reminders with full control.'**
  String get onboardingStep4Subtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboardingDemoHabitStudying.
  ///
  /// In en, this message translates to:
  /// **'Studying'**
  String get onboardingDemoHabitStudying;

  /// No description provided for @onboardingDemoHabitBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Brush teeth'**
  String get onboardingDemoHabitBrushTeeth;

  /// No description provided for @onboardingDemoHabitReadBook.
  ///
  /// In en, this message translates to:
  /// **'Read a book'**
  String get onboardingDemoHabitReadBook;

  /// No description provided for @onboardingDemoHabitPushUps.
  ///
  /// In en, this message translates to:
  /// **'Push ups'**
  String get onboardingDemoHabitPushUps;

  /// No description provided for @supportDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Buying Premium supports the developer.'**
  String get supportDeveloper;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto sync and backup'**
  String get autoBackup;

  /// No description provided for @backUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backUpNow;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @keepHabitsSafe.
  ///
  /// In en, this message translates to:
  /// **'Keep your habits and progress safe'**
  String get keepHabitsSafe;

  /// No description provided for @neverBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverBackedUp;

  /// No description provided for @migrateToSeamlessSync.
  ///
  /// In en, this message translates to:
  /// **'Migrate to seamless sync'**
  String get migrateToSeamlessSync;

  /// No description provided for @legacyBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Your backup uses an old passphrase. Enter it once to switch to seamless, password-free sync — you won\'t need it again.'**
  String get legacyBackupDescription;

  /// No description provided for @migrate.
  ///
  /// In en, this message translates to:
  /// **'Migrate'**
  String get migrate;

  /// No description provided for @enterOldPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter old passphrase'**
  String get enterOldPassphrase;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @disconnectGoogle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google'**
  String get disconnectGoogle;

  /// No description provided for @restoreWithDeltasTitle.
  ///
  /// In en, this message translates to:
  /// **'Include recent changes?'**
  String get restoreWithDeltasTitle;

  /// No description provided for @restoreWithDeltasDesc.
  ///
  /// In en, this message translates to:
  /// **'Changes made after this backup exist on your Drive. You can include them on top of the restored backup, or restore the backup as-is.'**
  String get restoreWithDeltasDesc;

  /// No description provided for @restoreWithDeltasInclude.
  ///
  /// In en, this message translates to:
  /// **'Include changes'**
  String get restoreWithDeltasInclude;

  /// No description provided for @restoreWithDeltasSkip.
  ///
  /// In en, this message translates to:
  /// **'Restore only'**
  String get restoreWithDeltasSkip;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data will be completely replaced with this backup. Everything you\'ve tracked since this backup was made will be lost. This cannot be undone.'**
  String get restoreConfirmDesc;

  /// No description provided for @restoreConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'This will merge the cloud backup with your local data. Any conflicts will be resolved using the most recent changes.'**
  String get restoreConfirmDescription;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backup history'**
  String get backupHistory;

  /// No description provided for @noBackupsFound.
  ///
  /// In en, this message translates to:
  /// **'No backups found'**
  String get noBackupsFound;

  /// No description provided for @backupDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String backupDateToday(Object time);

  /// No description provided for @backupDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String backupDateYesterday(Object time);

  /// No description provided for @backupDateOther.
  ///
  /// In en, this message translates to:
  /// **'{month} {day} at {time}'**
  String backupDateOther(Object month, Object day, Object time);

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @migrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Migration failed. Check your passphrase.'**
  String get migrationFailed;

  /// No description provided for @pinProtection.
  ///
  /// In en, this message translates to:
  /// **'PIN protection'**
  String get pinProtection;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get setPinTitle;

  /// No description provided for @setPinDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a passphrase or PIN (at least 4 characters) to add extra protection to your backup key.'**
  String get setPinDesc;

  /// No description provided for @setLocalPinDesc.
  ///
  /// In en, this message translates to:
  /// **'This PIN will be used to encrypt your local backups. Without it, your backup files cannot be decrypted.'**
  String get setLocalPinDesc;

  /// No description provided for @disablePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable PIN'**
  String get disablePinTitle;

  /// No description provided for @disablePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN to remove PIN protection.'**
  String get disablePinDesc;

  /// No description provided for @unlockForSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock backup'**
  String get unlockForSyncTitle;

  /// No description provided for @unlockForSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to unlock backup access for this session.'**
  String get unlockForSyncDesc;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'Passphrase or PIN'**
  String get pinHint;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 4 characters'**
  String get pinTooShort;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passphrase or PIN'**
  String get pinIncorrect;

  /// No description provided for @unlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockAction;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @forgotPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Forgot your passphrase? Discard old backup'**
  String get forgotPassphrase;

  /// No description provided for @discardOldBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard old backup?'**
  String get discardOldBackupTitle;

  /// No description provided for @discardOldBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Your old encrypted backup will be permanently deleted from Google Drive and replaced with a fresh one. Your current local data is safe.'**
  String get discardOldBackupDesc;

  /// No description provided for @discardOldBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardOldBackupConfirm;

  /// No description provided for @paywallUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to'**
  String get paywallUpgradeTo;

  /// No description provided for @paywallSupportUs.
  ///
  /// In en, this message translates to:
  /// **'These features are available for free - support us by upgrading anyway'**
  String get paywallSupportUs;

  /// No description provided for @paywallCustomScheduling.
  ///
  /// In en, this message translates to:
  /// **'Custom habit scheduling'**
  String get paywallCustomScheduling;

  /// No description provided for @paywallPerHabitNotifications.
  ///
  /// In en, this message translates to:
  /// **'Per habit notifications'**
  String get paywallPerHabitNotifications;

  /// No description provided for @paywallImprovementSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Habit improvement suggestions'**
  String get paywallImprovementSuggestions;

  /// No description provided for @paywallCloudBackupSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup and sync'**
  String get paywallCloudBackupSync;

  /// No description provided for @paywallBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get paywallBestValue;

  /// No description provided for @paywallMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get paywallMostPopular;

  /// No description provided for @paywallUpgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now'**
  String get paywallUpgradeNow;

  /// No description provided for @paywallManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get paywallManageSubscription;

  /// No description provided for @paywallCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get paywallCancel;

  /// No description provided for @paywallDowngrade.
  ///
  /// In en, this message translates to:
  /// **'Downgrade'**
  String get paywallDowngrade;

  /// No description provided for @paywallUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get paywallUpgrade;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @renewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews {date}'**
  String renewsOn(String date);

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get paywallLifetime;

  /// No description provided for @paywallSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get paywallSixMonths;

  /// No description provided for @paywallThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get paywallThreeMonths;

  /// No description provided for @paywallWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get paywallWeekly;

  /// No description provided for @paywallPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get paywallPerYear;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get paywallPerMonth;

  /// No description provided for @paywallPerSixMonths.
  ///
  /// In en, this message translates to:
  /// **'/ 6 months'**
  String get paywallPerSixMonths;

  /// No description provided for @paywallPerThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'/ 3 months'**
  String get paywallPerThreeMonths;

  /// No description provided for @paywallPerWeek.
  ///
  /// In en, this message translates to:
  /// **'/ week'**
  String get paywallPerWeek;

  /// No description provided for @paywallOneTimePurchase.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase'**
  String get paywallOneTimePurchase;

  /// No description provided for @paywallProductsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plans. Please try again later.'**
  String get paywallProductsUnavailable;

  /// No description provided for @paywallRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestorePurchases;

  /// No description provided for @premadeSectionWellnessSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Wellness / Self-care'**
  String get premadeSectionWellnessSelfCare;

  /// No description provided for @premadeSectionHealthFitness.
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get premadeSectionHealthFitness;

  /// No description provided for @premadeSectionProductivityGrowth.
  ///
  /// In en, this message translates to:
  /// **'Productivity & Growth'**
  String get premadeSectionProductivityGrowth;

  /// No description provided for @premadeHabitGoToBedEarly.
  ///
  /// In en, this message translates to:
  /// **'Go to bed early'**
  String get premadeHabitGoToBedEarly;

  /// No description provided for @premadeHabitBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Brush teeth'**
  String get premadeHabitBrushTeeth;

  /// No description provided for @premadeHabitSkinCare.
  ///
  /// In en, this message translates to:
  /// **'Skin care'**
  String get premadeHabitSkinCare;

  /// No description provided for @premadeHabitWakeUpEarly.
  ///
  /// In en, this message translates to:
  /// **'Wake up early'**
  String get premadeHabitWakeUpEarly;

  /// No description provided for @premadeHabitShower.
  ///
  /// In en, this message translates to:
  /// **'Shower'**
  String get premadeHabitShower;

  /// No description provided for @premadeHabitRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get premadeHabitRunning;

  /// No description provided for @premadeHabitWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get premadeHabitWalk;

  /// No description provided for @premadeHabitGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get premadeHabitGym;

  /// No description provided for @premadeHabitNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get premadeHabitNutrition;

  /// No description provided for @premadeHabitMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get premadeHabitMedications;

  /// No description provided for @premadeHabitDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get premadeHabitDrinkWater;

  /// No description provided for @premadeHabitStudying.
  ///
  /// In en, this message translates to:
  /// **'Studying'**
  String get premadeHabitStudying;

  /// No description provided for @premadeHabitWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get premadeHabitWork;

  /// No description provided for @premadeHabitResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get premadeHabitResearch;

  /// No description provided for @premadeHabitRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get premadeHabitRead;

  /// No description provided for @premadeHabitPraying.
  ///
  /// In en, this message translates to:
  /// **'Praying'**
  String get premadeHabitPraying;

  /// No description provided for @premadeHabitProductivitySession.
  ///
  /// In en, this message translates to:
  /// **'Productivity session'**
  String get premadeHabitProductivitySession;

  /// No description provided for @premadeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Habit'**
  String get premadeSheetTitle;

  /// No description provided for @premadeSheetDescCreate.
  ///
  /// In en, this message translates to:
  /// **'Choose a habit from categories — or skip and create your own habit'**
  String get premadeSheetDescCreate;

  /// No description provided for @premadeSheetDescEdit.
  ///
  /// In en, this message translates to:
  /// **'Notifications, UI styling, and text gets customized based on the chosen habit.'**
  String get premadeSheetDescEdit;

  /// No description provided for @overrideCurrentConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Override current configuration?'**
  String get overrideCurrentConfigTitle;

  /// No description provided for @overrideCurrentConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Override current habit details with the template or keep current options?'**
  String get overrideCurrentConfigDesc;

  /// No description provided for @overrideCurrentConfigOverride.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get overrideCurrentConfigOverride;

  /// No description provided for @overrideCurrentConfigKeepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get overrideCurrentConfigKeepCurrent;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @logOutDesc.
  ///
  /// In en, this message translates to:
  /// **'Logging out will disable backup and sync, but your local data will remain on this device.'**
  String get logOutDesc;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Deletes your account from our servers. Encrypted backups in your Google Drive\'s habitt_backups folder will remain — delete them manually if needed.'**
  String get deleteAccountDesc;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @accountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed: {errorMessage}'**
  String accountDeletionFailed(Object errorMessage);

  /// No description provided for @backupFound.
  ///
  /// In en, this message translates to:
  /// **'Backup found'**
  String get backupFound;

  /// No description provided for @backupFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Google Drive has a backup. How would you like to restore?'**
  String get backupFoundDesc;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @overwriteLocalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite local data?'**
  String get overwriteLocalDataTitle;

  /// No description provided for @overwriteLocalDataDesc.
  ///
  /// In en, this message translates to:
  /// **'This will permanently replace all your local data with the backup. This action cannot be undone.'**
  String get overwriteLocalDataDesc;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @syncSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncSectionTitle;

  /// No description provided for @syncSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync speed'**
  String get syncSpeedTitle;

  /// No description provided for @syncSpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get syncSpeedFast;

  /// No description provided for @syncSpeedOptimized.
  ///
  /// In en, this message translates to:
  /// **'Optimized'**
  String get syncSpeedOptimized;

  /// No description provided for @syncSpeedFastDescription.
  ///
  /// In en, this message translates to:
  /// **'Syncs after 5s\nChecks every 30 s'**
  String get syncSpeedFastDescription;

  /// No description provided for @syncSpeedFastHint.
  ///
  /// In en, this message translates to:
  /// **'Changes upload after 5 seconds and your data is refreshed every 30 seconds.'**
  String get syncSpeedFastHint;

  /// No description provided for @syncSpeedOptimizedDescription.
  ///
  /// In en, this message translates to:
  /// **'Syncs after 15 s\nChecks every 2 min'**
  String get syncSpeedOptimizedDescription;

  /// No description provided for @syncSpeedOptimizedHint.
  ///
  /// In en, this message translates to:
  /// **'Changes are batched and uploaded after a short pause to save battery.'**
  String get syncSpeedOptimizedHint;

  /// No description provided for @disconnectGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive'**
  String get disconnectGoogleDrive;

  /// No description provided for @connectGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get connectGoogleDrive;

  /// No description provided for @pauseHabit.
  ///
  /// In en, this message translates to:
  /// **'Pause Habit'**
  String get pauseHabit;

  /// No description provided for @pauseHabitName.
  ///
  /// In en, this message translates to:
  /// **'Pause \'{name}\''**
  String pauseHabitName(Object name);

  /// No description provided for @unpauseHabit.
  ///
  /// In en, this message translates to:
  /// **'Unpause Habit'**
  String get unpauseHabit;

  /// No description provided for @pauseHabitDesc.
  ///
  /// In en, this message translates to:
  /// **'While paused, this habit won\'t appear in your daily list. Your streak and stats will be preserved.'**
  String get pauseHabitDesc;

  /// No description provided for @habitPaused.
  ///
  /// In en, this message translates to:
  /// **'Habit paused!'**
  String get habitPaused;

  /// No description provided for @habitUnpaused.
  ///
  /// In en, this message translates to:
  /// **'Habit unpaused!'**
  String get habitUnpaused;

  /// No description provided for @localBackups.
  ///
  /// In en, this message translates to:
  /// **'Local Backups'**
  String get localBackups;

  /// No description provided for @localBackupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Export or import encrypted backup files on this device'**
  String get localBackupsDesc;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save an encrypted backup file to your device'**
  String get exportBackupDesc;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @importBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore from an encrypted backup file'**
  String get importBackupDesc;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully.'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get exportFailed;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully.'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please try again.'**
  String get importFailed;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @pinEnabled.
  ///
  /// In en, this message translates to:
  /// **'PIN enabled'**
  String get pinEnabled;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @revealPin.
  ///
  /// In en, this message translates to:
  /// **'Show PIN'**
  String get revealPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get confirmNewPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match'**
  String get pinMismatch;

  /// No description provided for @pinChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get pinChangedSuccess;

  /// No description provided for @pinRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get pinRemovedSuccess;

  /// No description provided for @pinSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN set'**
  String get pinSetSuccess;

  /// No description provided for @pinCopied.
  ///
  /// In en, this message translates to:
  /// **'PIN copied'**
  String get pinCopied;

  /// No description provided for @exportUnencryptedWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Export without encryption?'**
  String get exportUnencryptedWarningTitle;

  /// No description provided for @exportUnencryptedWarningDesc.
  ///
  /// In en, this message translates to:
  /// **'No PIN is set. This backup file will not be encrypted. Anyone with access to the file will be able to read your data.'**
  String get exportUnencryptedWarningDesc;

  /// No description provided for @exportUnencryptedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Export anyway'**
  String get exportUnencryptedConfirm;

  /// No description provided for @enterPinToDecrypt.
  ///
  /// In en, this message translates to:
  /// **'Enter the backup PIN'**
  String get enterPinToDecrypt;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Please try again.'**
  String get wrongPin;

  /// No description provided for @importSuccessPinSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup imported. PIN saved for future backups.'**
  String get importSuccessPinSaved;

  /// No description provided for @useThisPinQuestion.
  ///
  /// In en, this message translates to:
  /// **'Use this PIN for future backups?'**
  String get useThisPinQuestion;

  /// No description provided for @savePin.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get savePin;

  /// No description provided for @removePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Future backup files will not be encrypted. Anyone with access to the file will be able to read your data.'**
  String get removePinDesc;

  /// No description provided for @connectICloud.
  ///
  /// In en, this message translates to:
  /// **'Connect iCloud'**
  String get connectICloud;

  /// No description provided for @disconnectICloud.
  ///
  /// In en, this message translates to:
  /// **'Disconnect iCloud'**
  String get disconnectICloud;

  /// No description provided for @syncFailedDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive sync failed'**
  String get syncFailedDrive;

  /// No description provided for @syncFailedICloud.
  ///
  /// In en, this message translates to:
  /// **'iCloud unavailable — check Settings'**
  String get syncFailedICloud;

  /// No description provided for @syncFailedICloudQuota.
  ///
  /// In en, this message translates to:
  /// **'Not enough iCloud storage'**
  String get syncFailedICloudQuota;

  /// No description provided for @syncWarningICloudQuota.
  ///
  /// In en, this message translates to:
  /// **'Apple storage full — data saved locally only'**
  String get syncWarningICloudQuota;

  /// No description provided for @syncFailedDriveQuota.
  ///
  /// In en, this message translates to:
  /// **'Google Drive storage full'**
  String get syncFailedDriveQuota;

  /// No description provided for @singular.
  ///
  /// In en, this message translates to:
  /// **'Singular'**
  String get singular;

  /// No description provided for @singularHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. glass'**
  String get singularHint;

  /// No description provided for @plural.
  ///
  /// In en, this message translates to:
  /// **'Plural'**
  String get plural;

  /// No description provided for @pluralHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. glasses'**
  String get pluralHint;

  /// No description provided for @habitNames.
  ///
  /// In en, this message translates to:
  /// **'Habit names'**
  String get habitNames;

  /// No description provided for @habitNamesDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a custom habit name for each language. When you switch the app language, the matching name will be shown automatically.'**
  String get habitNamesDesc;

  /// No description provided for @autoAssignHabitNames.
  ///
  /// In en, this message translates to:
  /// **'Auto-assign habit names'**
  String get autoAssignHabitNames;

  /// No description provided for @autoAssignHabitNamesDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically saves your habit name for the current language each time you save.'**
  String get autoAssignHabitNamesDesc;

  /// No description provided for @holdToCompleteTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold to complete'**
  String get holdToCompleteTipTitle;

  /// No description provided for @holdToCompleteTipBody.
  ///
  /// In en, this message translates to:
  /// **'Hold the checkmark to instantly log your full target.'**
  String get holdToCompleteTipBody;

  /// No description provided for @syncOverlayTitleSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncOverlayTitleSyncing;

  /// No description provided for @syncOverlayTitleUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get syncOverlayTitleUploading;

  /// No description provided for @syncOverlayTitleUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncOverlayTitleUpToDate;

  /// No description provided for @syncOverlayUpdatesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} updates remaining...'**
  String syncOverlayUpdatesRemaining(int count);

  /// No description provided for @syncOverlayDownloadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Downloading backup...'**
  String get syncOverlayDownloadingBackup;

  /// No description provided for @syncOverlayUploadingChanges.
  ///
  /// In en, this message translates to:
  /// **'Uploading recent changes to cloud...'**
  String get syncOverlayUploadingChanges;

  /// No description provided for @showUploadActivity.
  ///
  /// In en, this message translates to:
  /// **'Show upload activity'**
  String get showUploadActivity;

  /// No description provided for @showUploadActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'When on, a sync overlay appears while changes are being uploaded to the cloud. Turn off to upload silently in the background.'**
  String get showUploadActivityDesc;

  /// No description provided for @syncOverlayTitleOptimizing.
  ///
  /// In en, this message translates to:
  /// **'Optimizing'**
  String get syncOverlayTitleOptimizing;

  /// No description provided for @syncOverlayOptimizingRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} files remaining...'**
  String syncOverlayOptimizingRemaining(int count);

  /// No description provided for @followHabitSchedule.
  ///
  /// In en, this message translates to:
  /// **'Follow habit schedule'**
  String get followHabitSchedule;

  /// No description provided for @notificationScheduleDependencyTip.
  ///
  /// In en, this message translates to:
  /// **'This reminder only fires on days the habit is scheduled to appear.'**
  String get notificationScheduleDependencyTip;

  /// No description provided for @notificationWeekdaysFixedTip.
  ///
  /// In en, this message translates to:
  /// **'Habit will never appear on disabled days, to change this edit your weekly scheduling options.'**
  String get notificationWeekdaysFixedTip;

  /// No description provided for @importHabitKitDesc.
  ///
  /// In en, this message translates to:
  /// **'Your habits and history will be imported.'**
  String get importHabitKitDesc;

  /// No description provided for @importHabitKitMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep your habits and add {appName}\'s. Habits with the same name combine.'**
  String importHabitKitMergeDesc(String appName);

  /// No description provided for @importHabitKitReplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Deletes your current habits first, then imports from {appName}. This can\'t be undone.'**
  String importHabitKitReplaceDesc(Object appName);

  /// No description provided for @importHabitKitNote.
  ///
  /// In en, this message translates to:
  /// **'Icons & colors may change, “bad habits” are imported as regular habits'**
  String get importHabitKitNote;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @importFromOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Import from other apps'**
  String get importFromOtherApps;

  /// No description provided for @importHabitKitTitle.
  ///
  /// In en, this message translates to:
  /// **'Import {appName} data'**
  String importHabitKitTitle(String appName);

  /// No description provided for @backupBeforeImporting.
  ///
  /// In en, this message translates to:
  /// **'It\'s strongly recommended to back up your data before proceeding.'**
  String get backupBeforeImporting;

  /// No description provided for @streakCelebration.
  ///
  /// In en, this message translates to:
  /// **'Streak celebration'**
  String get streakCelebration;

  /// No description provided for @streakCelebrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Show a celebration when your perfect-days streak grows.'**
  String get streakCelebrationDesc;

  /// No description provided for @greatProgress.
  ///
  /// In en, this message translates to:
  /// **'Great progress'**
  String get greatProgress;

  /// No description provided for @buildingRealConsistency.
  ///
  /// In en, this message translates to:
  /// **'You\'re building real consistency'**
  String get buildingRealConsistency;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get keepGoing;

  /// No description provided for @goodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get goodJob;

  /// No description provided for @bravo.
  ///
  /// In en, this message translates to:
  /// **'Bravo!'**
  String get bravo;

  /// No description provided for @keepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get keepItUp;

  /// No description provided for @youreALegend.
  ///
  /// In en, this message translates to:
  /// **'You\'re a legend!'**
  String get youreALegend;

  /// No description provided for @streakInventYou.
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t exist, we\'d have to invent you!'**
  String get streakInventYou;

  /// No description provided for @streakPraiseExtra1.
  ///
  /// In en, this message translates to:
  /// **'That\'s the way, champ!'**
  String get streakPraiseExtra1;

  /// No description provided for @streakPraiseExtra2.
  ///
  /// In en, this message translates to:
  /// **'Well done, you!'**
  String get streakPraiseExtra2;

  /// No description provided for @streakPraiseExtra3.
  ///
  /// In en, this message translates to:
  /// **'Hats off to you!'**
  String get streakPraiseExtra3;

  /// No description provided for @backAtIt.
  ///
  /// In en, this message translates to:
  /// **'Back at it'**
  String get backAtIt;

  /// No description provided for @timeForHabits.
  ///
  /// In en, this message translates to:
  /// **'Time for habits?'**
  String get timeForHabits;

  /// No description provided for @notificationCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get notificationCompleteAction;

  /// No description provided for @notificationSoundSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSoundSettingTitle;

  /// No description provided for @notificationSoundSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sound played for reminders'**
  String get notificationSoundSettingSubtitle;

  /// No description provided for @habitSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get habitSoundTitle;

  /// No description provided for @useGlobalDefaultSound.
  ///
  /// In en, this message translates to:
  /// **'Use global default'**
  String get useGlobalDefaultSound;

  /// No description provided for @soundNumbered.
  ///
  /// In en, this message translates to:
  /// **'Sound {number}'**
  String soundNumbered(int number);

  /// No description provided for @notificationSoundAppDefault.
  ///
  /// In en, this message translates to:
  /// **'App Default'**
  String get notificationSoundAppDefault;

  /// No description provided for @notificationSoundSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get notificationSoundSystemDefault;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;
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
