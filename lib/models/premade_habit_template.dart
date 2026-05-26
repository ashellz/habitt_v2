import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/util/amount_label_preset.dart';

class PremadeHabitTemplate {
  const PremadeHabitTemplate({
    required this.type,
    required this.name,
    required this.iconPath,
    required this.categoryId,
    required this.amount,
    required this.durationMinutes,
    this.amountLabel = AmountLabelPreset.defaultAmountLabel,
    this.amountLabelPreset,
    this.scheduleType = ScheduleType.daily,
    this.weeklyTarget = 1,
    this.monthlyTarget = 1,
    this.customIntervalDays = 2,
    List<int>? notificationTimesMinutesOfDay,
    Set<int>? selectedDaysAWeek,
    Set<int>? selectedDaysAMonth,
  }) : selectedDaysAWeek = selectedDaysAWeek ?? const <int>{},
       selectedDaysAMonth = selectedDaysAMonth ?? const <int>{},
       notificationTimesMinutesOfDay =
           notificationTimesMinutesOfDay ?? const <int>[];

  final PremadeHabitType type;
  final String name;
  final String iconPath;
  final int categoryId;
  final int amount;
  final int durationMinutes;
  final String amountLabel;
  final AmountLabelPreset? amountLabelPreset;
  final ScheduleType scheduleType;
  final int weeklyTarget;
  final int monthlyTarget;
  final int customIntervalDays;
  final List<int> notificationTimesMinutesOfDay;
  final Set<int> selectedDaysAWeek;
  final Set<int> selectedDaysAMonth;

  String get resolvedAmountLabel => amountLabelPreset?.plural ?? amountLabel;

  String localizedName(AppLocalizations l10n) => type.localizedName(l10n);
}

class PremadeHabitCategorySection {
  const PremadeHabitCategorySection({
    required this.title,
    required this.habits,
  });

  final String title;
  final List<PremadeHabitTemplate> habits;

  String localizedTitle(AppLocalizations l10n) {
    switch (title) {
      case 'Wellness / Self-care':
        return l10n.premadeSectionWellnessSelfCare;
      case 'Health & Fitness':
        return l10n.premadeSectionHealthFitness;
      case 'Productivity & Growth':
        return l10n.premadeSectionProductivityGrowth;
      default:
        return title;
    }
  }
}
