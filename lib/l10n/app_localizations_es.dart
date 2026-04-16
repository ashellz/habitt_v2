// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get habits => 'habits';

  @override
  String get habit => 'habit';

  @override
  String get calendar => 'Calendar';

  @override
  String get stats => 'Stats';

  @override
  String get settings => 'Settings';

  @override
  String get hello => 'Hello';

  @override
  String get whatsUp => 'What\'s up?';

  @override
  String get goodToSeeYou => 'Good to see you';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get hi => 'Hi';

  @override
  String get hiThere => 'Hi there';

  @override
  String get helloThere => 'Hello there';

  @override
  String get howAreYou => 'How are you?';

  @override
  String get all => 'All';

  @override
  String get anyTime => 'Any time';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get completed => 'Completed';

  @override
  String get notCompleted => 'Not completed';

  @override
  String get selected => 'Selected';

  @override
  String get newHabit => 'New Habit';

  @override
  String get habitName => 'Habit Name';

  @override
  String get notes => 'Notes';

  @override
  String get moreOptions => 'More options';

  @override
  String get amount => 'Amount';

  @override
  String get duration => 'Duration';

  @override
  String get enterYourAmount => 'Enter your amount';

  @override
  String get enterYourDuration => 'Enter your duration';

  @override
  String get times => 'times';

  @override
  String get edit => 'Edit';

  @override
  String youCanPressNumberAbove(Object type) {
    return 'You can also press the number above to change $type';
  }

  @override
  String get orToChangeLabel => 'or the amount label';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get label => 'Label';

  @override
  String get editHabit => 'Edit Habit';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get notificationFallbackGeneric =>
      'Small actions today create long-term momentum.';

  @override
  String get notificationFallbackTitle => 'Habit reminder';

  @override
  String get notificationOptional =>
      'This one is optional today, but even one step still counts.';

  @override
  String get notificationFreshnessBrandNew =>
      'This habit is brand new. Early reps matter most, so do not give up.';

  @override
  String notificationFreshnessNewDays(Object days) {
    return 'You started this $days days ago. Keep this fresh habit alive.';
  }

  @override
  String notificationFreshnessEstablishedDays(Object days) {
    return 'You have been building this for $days days. Keep compounding wins.';
  }

  @override
  String notificationProgressNotStartedAmount(Object label) {
    return 'You have not started yet. Begin with 1 $label and build momentum.';
  }

  @override
  String notificationProgressCompletedAmount(Object completed, Object label) {
    return 'You already hit $completed $label. Bonus rep?';
  }

  @override
  String notificationProgressAlmostDoneAmount(Object label, Object remaining) {
    return 'You are so close. Just $remaining $label left.';
  }

  @override
  String notificationProgressInProgressAmount(
    Object completed,
    Object label,
    Object target,
  ) {
    return 'Progress is $completed/$target $label. Keep the streak moving.';
  }

  @override
  String get notificationProgressNotStartedDuration =>
      'You have not started yet. Start with a short session to begin.';

  @override
  String notificationProgressCompletedDuration(Object completed) {
    return 'Target done: $completed completed already.';
  }

  @override
  String notificationProgressAlmostDoneDuration(Object remaining) {
    return 'Only $remaining left. You are very close now.';
  }

  @override
  String notificationProgressInProgressDuration(
    Object completed,
    Object target,
  ) {
    return 'You logged $completed of $target.';
  }

  @override
  String get notificationProgressNoTracking =>
      'Small action now keeps this habit alive.';

  @override
  String get notificationScheduleDaily =>
      'Daily rhythm: show up today and protect your momentum.';

  @override
  String notificationScheduleCustomEveryDays(Object days) {
    return 'Custom cadence: every $days days. Today is one of your slots.';
  }

  @override
  String notificationScheduleWeeklyReached(Object completed, Object target) {
    return 'Weekly target already reached ($completed/$target). This is bonus consistency.';
  }

  @override
  String notificationScheduleWeeklyImpossible(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'You need $remaining more this week ($completed/$target done). Even if you do it now, the target is out of reach this week.';
  }

  @override
  String notificationScheduleWeeklyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'You need $remaining more this week ($completed/$target done). If you skip today, your goal gets much harder.';
  }

  @override
  String notificationScheduleWeeklyOneLeft(Object completed, Object target) {
    return 'One more completion this week and you hit your target ($completed/$target).';
  }

  @override
  String notificationScheduleWeeklyRemaining(Object remaining, Object target) {
    return 'You need $remaining more this week to reach $target.';
  }

  @override
  String notificationScheduleMonthlyReached(Object completed, Object target) {
    return 'Monthly target already reached ($completed/$target). Extra rep, extra momentum.';
  }

  @override
  String notificationScheduleMonthlyImpossible(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'You need $remaining more this month ($completed/$target done). Even if you do it now, the target is out of reach this month.';
  }

  @override
  String notificationScheduleMonthlyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'You need $remaining more this month ($completed/$target done). Skipping today puts your target at risk.';
  }

  @override
  String notificationScheduleMonthlyOneLeft(Object completed, Object target) {
    return 'One more completion this month and you hit your target ($completed/$target).';
  }

  @override
  String notificationScheduleMonthlyRemaining(Object remaining, Object target) {
    return 'You need $remaining more this month to reach $target.';
  }

  @override
  String notificationAmountLabelFocus(Object label, Object target) {
    return 'Today\'s target is $target $label.';
  }

  @override
  String get notificationPremadeGoToBedEarly =>
      'Protect tonight so tomorrow starts easier.';

  @override
  String get notificationPremadeBrushTeeth =>
      'Quick hygiene win now keeps your routine sharp.';

  @override
  String get notificationPremadeSkinCare =>
      'Take care of your skin now to stay consistent.';

  @override
  String get notificationPremadeWakeUpEarly =>
      'A strong start to your day begins with this choice.';

  @override
  String get notificationPremadeShower =>
      'Reset your energy with this simple routine.';

  @override
  String get notificationPremadePraying =>
      'Take a calm moment now and reconnect with intention.';

  @override
  String get notificationPremadeRunning =>
      'Lace up and collect a strong training rep today.';

  @override
  String get notificationPremadeWalk =>
      'A short walk now is enough to keep momentum alive.';

  @override
  String get notificationPremadeGym =>
      'Show up for a solid gym rep and build consistency.';

  @override
  String get notificationPremadeNutrition =>
      'Make one intentional nutrition choice right now.';

  @override
  String get notificationPremadeMedications =>
      'Take your meds on time to protect your health baseline.';

  @override
  String get notificationPremadeDrinkWater =>
      'Hydrate now and keep your body performing well.';

  @override
  String get notificationPremadeStudying =>
      'Start a focused study block and build learning momentum.';

  @override
  String get notificationPremadeWork =>
      'Start your most important task and gain traction.';

  @override
  String get notificationPremadeResearch =>
      'Capture one useful insight and move your research forward.';

  @override
  String get notificationPremadeProductivitySession =>
      'Run one focused session and protect deep work time.';

  @override
  String get notificationPremadeRead =>
      'Read a little now and let consistency do the rest.';
}
