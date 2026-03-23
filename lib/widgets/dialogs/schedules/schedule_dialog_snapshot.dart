import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/state_provider.dart';

class ScheduleDialogSnapshot {
  const ScheduleDialogSnapshot({
    required this.selectedScheduleOption,
    required this.weeklyTarget,
    required this.monthlyTarget,
    required this.customIntervalDays,
    required this.selectedDaysAWeek,
    required this.selectedDaysAMonth,
  });

  final ScheduleType selectedScheduleOption;
  final int weeklyTarget;
  final int monthlyTarget;
  final int customIntervalDays;
  final Set<int> selectedDaysAWeek;
  final Set<int> selectedDaysAMonth;

  factory ScheduleDialogSnapshot.fromStateProvider(StateProvider sp) {
    return ScheduleDialogSnapshot(
      selectedScheduleOption: sp.selectedScheduleOption,
      weeklyTarget: sp.weeklyTarget,
      monthlyTarget: sp.monthlyTarget,
      customIntervalDays: sp.customIntervalDays,
      selectedDaysAWeek: Set<int>.from(sp.selectedDaysAWeek),
      selectedDaysAMonth: Set<int>.from(sp.selectedDaysAMonth),
    );
  }

  void restore(StateProvider sp) {
    sp.selectedScheduleOption = selectedScheduleOption;
    sp.weeklyTarget = weeklyTarget;
    sp.monthlyTarget = monthlyTarget;
    sp.customIntervalDays = customIntervalDays;
    sp.selectedDaysAWeek = Set<int>.from(selectedDaysAWeek);
    sp.selectedDaysAMonth = Set<int>.from(selectedDaysAMonth);
  }
}
