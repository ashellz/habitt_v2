// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bosnian (`bs`).
class AppLocalizationsBs extends AppLocalizations {
  AppLocalizationsBs([String locale = 'bs']) : super(locale);

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
  String get whatsUp => 'What\'s up';

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
  String get howAreYou => 'How are you';

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

  @override
  String get notificationPeriodWeekly => 'weekly';

  @override
  String get notificationPeriodMonthly => 'monthly';

  @override
  String notificationCombinedOneOff(Object encouragement, Object period) {
    return 'Don\'t miss today, it\'s your last $period chance and $encouragement.';
  }

  @override
  String notificationCombinedFresh(Object days, Object encouragement) {
    return 'You started this habit $days days ago, and $encouragement.';
  }

  @override
  String notificationCombinedAmountNotStarted(Object encouragement) {
    return 'Start now, even one step counts, and $encouragement.';
  }

  @override
  String notificationCombinedAmountInProgress(
    Object encouragement,
    Object progress,
  ) {
    return 'You are at $progress, and $encouragement.';
  }

  @override
  String notificationCombinedAmountAlmostDone(
    Object encouragement,
    Object remaining,
  ) {
    return 'Only $remaining left, and $encouragement.';
  }

  @override
  String notificationCombinedAmountCompleted(Object encouragement) {
    return 'Target reached already, and $encouragement.';
  }

  @override
  String notificationCombinedDurationNotStarted(Object encouragement) {
    return 'Start a short session now, and $encouragement.';
  }

  @override
  String notificationCombinedDurationInProgress(
    Object encouragement,
    Object progress,
  ) {
    return 'You are at $progress, and $encouragement.';
  }

  @override
  String notificationCombinedDurationAlmostDone(
    Object encouragement,
    Object remaining,
  ) {
    return 'Only $remaining left, and $encouragement.';
  }

  @override
  String notificationCombinedDurationCompleted(Object encouragement) {
    return 'Target reached already, and $encouragement.';
  }

  @override
  String notificationCombinedGeneral(Object encouragement) {
    return '$encouragement.';
  }

  @override
  String get notificationEncourageGeneric1 =>
      'showing up today keeps the habit alive';

  @override
  String get notificationEncourageGeneric2 =>
      'a small action now protects your momentum';

  @override
  String get notificationEncourageGeneric3 =>
      'consistency today makes tomorrow easier';

  @override
  String get notificationEncourageGoToBedEarly1 =>
      'protecting tonight helps tomorrow feel lighter';

  @override
  String get notificationEncourageGoToBedEarly2 =>
      'an earlier bedtime now gives your mind a cleaner start';

  @override
  String get notificationEncourageGoToBedEarly3 =>
      'this choice tonight sets up a better morning';

  @override
  String get notificationEncourageGoToBedEarly4 =>
      'sleep consistency now pays off all day tomorrow';

  @override
  String get notificationEncourageGoToBedEarly5 =>
      'one calm night routine protects your energy curve';

  @override
  String get notificationEncourageGoToBedEarly6 =>
      'ending the day on time keeps your rhythm stable';

  @override
  String get notificationEncourageGoToBedEarly7 =>
      'better sleep timing is a quiet performance advantage';

  @override
  String get notificationEncourageGoToBedEarly8 =>
      'an earlier lights-out keeps your recovery on track';

  @override
  String get notificationEncourageGoToBedEarly9 =>
      'small bedtime discipline creates stronger mornings';

  @override
  String get notificationEncourageGoToBedEarly10 =>
      'this evening decision helps your whole week run smoother';

  @override
  String get notificationEncourageBrushTeeth1 =>
      'keeping your hygiene streak strong';

  @override
  String get notificationEncourageBrushTeeth2 =>
      'protecting your routine with a quick win';

  @override
  String get notificationEncourageBrushTeeth3 =>
      'staying consistent with basic care';

  @override
  String get notificationEncourageSkinCare1 =>
      'protecting your skin with one steady step';

  @override
  String get notificationEncourageSkinCare2 =>
      'making consistency your skincare advantage';

  @override
  String get notificationEncourageSkinCare3 =>
      'keeping your routine reliable and simple';

  @override
  String get notificationEncourageWakeUpEarly1 =>
      'starting your day with intention';

  @override
  String get notificationEncourageWakeUpEarly2 =>
      'keeping your morning rhythm consistent';

  @override
  String get notificationEncourageWakeUpEarly3 =>
      'giving yourself a calmer start';

  @override
  String get notificationEncourageShower1 =>
      'a quick reset can lift your focus';

  @override
  String get notificationEncourageShower2 =>
      'this routine helps you feel switched on';

  @override
  String get notificationEncourageShower3 =>
      'a clean reset keeps your day moving';

  @override
  String get notificationEncourageRunning1 =>
      'one training rep today builds endurance';

  @override
  String get notificationEncourageRunning2 =>
      'showing up now strengthens your running baseline';

  @override
  String get notificationEncourageRunning3 =>
      'this effort keeps your fitness momentum real';

  @override
  String get notificationEncourageWalk1 =>
      'a short walk is enough to keep momentum';

  @override
  String get notificationEncourageWalk2 =>
      'moving now helps your energy and focus';

  @override
  String get notificationEncourageWalk3 =>
      'this simple rep supports long-term consistency';

  @override
  String get notificationEncourageGym1 =>
      'one gym rep today keeps your standard high';

  @override
  String get notificationEncourageGym2 =>
      'showing up now protects your strength momentum';

  @override
  String get notificationEncourageGym3 =>
      'today\'s session compounds over time';

  @override
  String get notificationEncourageNutrition1 =>
      'one intentional choice now supports your baseline';

  @override
  String get notificationEncourageNutrition2 =>
      'small nutrition wins add up fast';

  @override
  String get notificationEncourageNutrition3 =>
      'consistency here improves everything else';

  @override
  String get notificationEncourageMedications1 =>
      'timing this right protects your health routine';

  @override
  String get notificationEncourageMedications2 =>
      'staying on schedule keeps your baseline stable';

  @override
  String get notificationEncourageMedications3 =>
      'this step supports your long-term wellbeing';

  @override
  String get notificationEncourageDrinkWater1 =>
      'hydration now supports your whole system';

  @override
  String get notificationEncourageDrinkWater2 =>
      'one glass now keeps your energy steadier';

  @override
  String get notificationEncourageDrinkWater3 =>
      'small hydration reps improve daily performance';

  @override
  String get notificationEncourageStudying1 =>
      'one focused block now builds learning momentum';

  @override
  String get notificationEncourageStudying2 =>
      'showing up today keeps knowledge compounding';

  @override
  String get notificationEncourageStudying3 =>
      'small sessions consistently beat cramming';

  @override
  String get notificationEncourageWork1 => 'starting now creates real traction';

  @override
  String get notificationEncourageWork2 =>
      'one meaningful push can unlock your day';

  @override
  String get notificationEncourageWork3 =>
      'consistent execution keeps progress visible';

  @override
  String get notificationEncourageResearch1 =>
      'one insight today moves your work forward';

  @override
  String get notificationEncourageResearch2 =>
      'steady exploration compounds into clarity';

  @override
  String get notificationEncourageResearch3 =>
      'capturing one finding now keeps momentum';

  @override
  String get notificationEncourageProductivitySession1 =>
      'one focused session protects deep work time';

  @override
  String get notificationEncourageProductivitySession2 =>
      'a clean focus block now can change your day';

  @override
  String get notificationEncourageProductivitySession3 =>
      'consistency in focus drives better output';

  @override
  String get notificationEncourageRead1 =>
      'a few pages now keep your reading identity strong';

  @override
  String get notificationEncourageRead2 =>
      'small daily reading compounds into real progress';

  @override
  String get notificationEncourageRead3 =>
      'showing up today keeps the streak alive';

  @override
  String insightStrengthKeepPushingTitle(Object habitName) {
    return 'Keep pushing $habitName';
  }

  @override
  String insightStrengthLowerTargetTitle(Object habitName) {
    return 'Lower target for $habitName';
  }

  @override
  String insightStrengthIncreaseTargetTitle(Object habitName) {
    return 'Increase target for $habitName';
  }

  @override
  String get insightStrengthApplyDecrease => 'Apply decrease';

  @override
  String get insightStrengthApplyIncrease => 'Apply increase';

  @override
  String get insightStrengthGotItEven => 'Got it';

  @override
  String get insightStrengthGotItOdd => 'Got it';

  @override
  String get insightStrengthStartSmallType1Generic =>
      'You added this habit for a reason. Do not let it slip now.||Momentum is fading on this habit. Show up today and keep it alive.||You are falling behind on this habit. Lock in and get your rep done.||Do not negotiate with laziness here. Protect this habit today.||You came too far to let this habit drift. Stay consistent today.';

  @override
  String insightStrengthStartSmallType2Generic(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Consistency dropped on this habit. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to stabilize again.||You have been off track lately. Strength dropped by $drop%. Try this target shift: $fromValue -> $toValue to rebuild rhythm.||Recent performance is slipping. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to get back on track.||This habit needs a lighter target for now. Strength dropped by $drop%. Move from $fromValue to $toValue to improve consistency.||Your habit signal weakened recently. Strength dropped by $drop%. Recommended target: $fromValue -> $toValue so you can stay consistent.';
  }

  @override
  String insightStrengthIncreaseGeneric(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Your consistency is strong. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing.||You are handling this habit well. Strength is stable at $strength%. Push the target from $fromValue to $toValue for more growth.||Momentum is solid here. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to level up.||You built a reliable baseline. Strength is stable at $strength%. Move from $fromValue to $toValue and keep improving.||Great consistency lately. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep your progress rising.';
  }

  @override
  String get insightStrengthStartSmallType1GoToBedEarly =>
      'Your go to bed early habit is slipping. Do not let this routine fall off now.||You have been off track with go to bed early. Show up today and protect the habit.||Momentum on go to bed early is fading. Keep it alive with one solid rep today.||Do not let go to bed early become inconsistent. Lock in and do your part today.||You started to go to bed early for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2GoToBedEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with go to bed early lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Go to bed early has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent go to bed early consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your go to bed early habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Go to bed early needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseGoToBedEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with go to bed early. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on go to bed early. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your go to bed early habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for go to bed early. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on go to bed early. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1BrushTeeth =>
      'Your brush your teeth habit is slipping. Do not let this routine fall off now.||You have been off track with brush your teeth. Show up today and protect the habit.||Momentum on brush your teeth is fading. Keep it alive with one solid rep today.||Do not let brush your teeth become inconsistent. Lock in and do your part today.||You started to brush your teeth for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2BrushTeeth(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with brush your teeth lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Brush your teeth has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent brush your teeth consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your brush your teeth habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Brush your teeth needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseBrushTeeth(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with brush your teeth. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on brush your teeth. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your brush your teeth habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for brush your teeth. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on brush your teeth. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1SkinCare =>
      'Your your skin care routine habit is slipping. Do not let this routine fall off now.||You have been off track with your skin care routine. Show up today and protect the habit.||Momentum on your skin care routine is fading. Keep it alive with one solid rep today.||Do not let your skin care routine become inconsistent. Lock in and do your part today.||You started to your skin care routine for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2SkinCare(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your skin care routine lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your skin care routine has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your skin care routine consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your skin care routine habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your skin care routine needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseSkinCare(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your skin care routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your skin care routine. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your skin care routine habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your skin care routine. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your skin care routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1WakeUpEarly =>
      'Your wake up early habit is slipping. Do not let this routine fall off now.||You have been off track with wake up early. Show up today and protect the habit.||Momentum on wake up early is fading. Keep it alive with one solid rep today.||Do not let wake up early become inconsistent. Lock in and do your part today.||You started to wake up early for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2WakeUpEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with wake up early lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Wake up early has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent wake up early consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your wake up early habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Wake up early needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseWakeUpEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with wake up early. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on wake up early. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your wake up early habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for wake up early. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on wake up early. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Shower =>
      'Your take your shower habit is slipping. Do not let this routine fall off now.||You have been off track with take your shower. Show up today and protect the habit.||Momentum on take your shower is fading. Keep it alive with one solid rep today.||Do not let take your shower become inconsistent. Lock in and do your part today.||You started to take your shower for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Shower(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with take your shower lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Take your shower has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent take your shower consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your take your shower habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Take your shower needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseShower(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with take your shower. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on take your shower. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your take your shower habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for take your shower. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on take your shower. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Praying =>
      'Your pray consistently habit is slipping. Do not let this routine fall off now.||You have been off track with pray consistently. Show up today and protect the habit.||Momentum on pray consistently is fading. Keep it alive with one solid rep today.||Do not let pray consistently become inconsistent. Lock in and do your part today.||You started to pray consistently for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Praying(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with pray consistently lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Pray consistently has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent pray consistently consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your pray consistently habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Pray consistently needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreasePraying(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with pray consistently. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on pray consistently. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your pray consistently habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for pray consistently. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on pray consistently. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Running =>
      'Your your running routine habit is slipping. Do not let this routine fall off now.||You have been off track with your running routine. Show up today and protect the habit.||Momentum on your running routine is fading. Keep it alive with one solid rep today.||Do not let your running routine become inconsistent. Lock in and do your part today.||You started to your running routine for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Running(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your running routine lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your running routine has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your running routine consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your running routine habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your running routine needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseRunning(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your running routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your running routine. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your running routine habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your running routine. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your running routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Walk =>
      'Your your walking routine habit is slipping. Do not let this routine fall off now.||You have been off track with your walking routine. Show up today and protect the habit.||Momentum on your walking routine is fading. Keep it alive with one solid rep today.||Do not let your walking routine become inconsistent. Lock in and do your part today.||You started to your walking routine for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Walk(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your walking routine lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your walking routine has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your walking routine consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your walking routine habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your walking routine needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseWalk(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your walking routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your walking routine. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your walking routine habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your walking routine. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your walking routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Gym =>
      'Your your gym routine habit is slipping. Do not let this routine fall off now.||You have been off track with your gym routine. Show up today and protect the habit.||Momentum on your gym routine is fading. Keep it alive with one solid rep today.||Do not let your gym routine become inconsistent. Lock in and do your part today.||You started to your gym routine for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Gym(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your gym routine lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your gym routine has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your gym routine consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your gym routine habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your gym routine needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseGym(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your gym routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your gym routine. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your gym routine habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your gym routine. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your gym routine. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Nutrition =>
      'Your your nutrition plan habit is slipping. Do not let this routine fall off now.||You have been off track with your nutrition plan. Show up today and protect the habit.||Momentum on your nutrition plan is fading. Keep it alive with one solid rep today.||Do not let your nutrition plan become inconsistent. Lock in and do your part today.||You started to your nutrition plan for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Nutrition(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your nutrition plan lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your nutrition plan has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your nutrition plan consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your nutrition plan habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your nutrition plan needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseNutrition(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your nutrition plan. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your nutrition plan. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your nutrition plan habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your nutrition plan. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your nutrition plan. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Medications =>
      'Your take your medications on time habit is slipping. Do not let this routine fall off now.||You have been off track with take your medications on time. Show up today and protect the habit.||Momentum on take your medications on time is fading. Keep it alive with one solid rep today.||Do not let take your medications on time become inconsistent. Lock in and do your part today.||You started to take your medications on time for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Medications(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with take your medications on time lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Take your medications on time has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent take your medications on time consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your take your medications on time habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Take your medications on time needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseMedications(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with take your medications on time. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on take your medications on time. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your take your medications on time habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for take your medications on time. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on take your medications on time. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1DrinkWater =>
      'Your drink enough water habit is slipping. Do not let this routine fall off now.||You have been off track with drink enough water. Show up today and protect the habit.||Momentum on drink enough water is fading. Keep it alive with one solid rep today.||Do not let drink enough water become inconsistent. Lock in and do your part today.||You started to drink enough water for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2DrinkWater(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with drink enough water lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Drink enough water has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent drink enough water consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your drink enough water habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Drink enough water needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseDrinkWater(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with drink enough water. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on drink enough water. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your drink enough water habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for drink enough water. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on drink enough water. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Studying =>
      'Your your studying habit habit is slipping. Do not let this routine fall off now.||You have been off track with your studying habit. Show up today and protect the habit.||Momentum on your studying habit is fading. Keep it alive with one solid rep today.||Do not let your studying habit become inconsistent. Lock in and do your part today.||You started to your studying habit for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Studying(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your studying habit lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your studying habit has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your studying habit consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your studying habit habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your studying habit needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseStudying(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your studying habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your studying habit. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your studying habit habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your studying habit. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your studying habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Work =>
      'Your your work habit habit is slipping. Do not let this routine fall off now.||You have been off track with your work habit. Show up today and protect the habit.||Momentum on your work habit is fading. Keep it alive with one solid rep today.||Do not let your work habit become inconsistent. Lock in and do your part today.||You started to your work habit for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Work(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your work habit lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your work habit has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your work habit consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your work habit habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your work habit needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseWork(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your work habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your work habit. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your work habit habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your work habit. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your work habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Research =>
      'Your your research habit habit is slipping. Do not let this routine fall off now.||You have been off track with your research habit. Show up today and protect the habit.||Momentum on your research habit is fading. Keep it alive with one solid rep today.||Do not let your research habit become inconsistent. Lock in and do your part today.||You started to your research habit for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Research(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your research habit lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your research habit has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your research habit consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your research habit habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your research habit needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseResearch(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your research habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your research habit. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your research habit habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your research habit. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your research habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1ProductivitySession =>
      'Your your productivity sessions habit is slipping. Do not let this routine fall off now.||You have been off track with your productivity sessions. Show up today and protect the habit.||Momentum on your productivity sessions is fading. Keep it alive with one solid rep today.||Do not let your productivity sessions become inconsistent. Lock in and do your part today.||You started to your productivity sessions for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2ProductivitySession(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your productivity sessions lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your productivity sessions has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your productivity sessions consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your productivity sessions habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your productivity sessions needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseProductivitySession(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your productivity sessions. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your productivity sessions. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your productivity sessions habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your productivity sessions. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your productivity sessions. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }

  @override
  String get insightStrengthStartSmallType1Read =>
      'Your your reading habit habit is slipping. Do not let this routine fall off now.||You have been off track with your reading habit. Show up today and protect the habit.||Momentum on your reading habit is fading. Keep it alive with one solid rep today.||Do not let your reading habit become inconsistent. Lock in and do your part today.||You started to your reading habit for a reason. Stay disciplined and keep it from slipping.';

  @override
  String insightStrengthStartSmallType2Read(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'You have not been consistent with your reading habit lately. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to keep the habit alive.||Your reading habit has been weaker recently. Strength dropped by $drop%. Move your target from $fromValue to $toValue to rebuild consistency.||Recent your reading habit consistency is down. Strength dropped by $drop% in the last few days. Recommended target: $fromValue -> $toValue to recover momentum.||To protect your your reading habit habit, lower the target for now. Strength dropped by $drop%. Recommended: $fromValue -> $toValue.||Your reading habit needs a reset. Strength dropped by $drop%. Try $fromValue -> $toValue so this habit stays alive.';
  }

  @override
  String insightStrengthIncreaseRead(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'You are doing great with your reading habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing even more.||Great consistency on your reading habit. Strength is stable at $strength%. Increase your target from $fromValue to $toValue and keep momentum high.||Your your reading habit habit is strong right now. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue for the next level.||You are reliably showing up for your reading habit. Strength is stable at $strength%. Move from $fromValue to $toValue to keep improving.||Excellent rhythm on your reading habit. Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to continue progress.';
  }
}
