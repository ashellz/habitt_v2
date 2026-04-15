import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/util/amount_label_preset.dart';

class PremadeHabitCatalog {
  static const List<PremadeHabitCategorySection> sections = [
    PremadeHabitCategorySection(
      title: 'Wellness / Self-care',
      habits: [
        PremadeHabitTemplate(
          type: PremadeHabitType.goToBedEarly,
          name: 'Go to bed early',
          iconPath: '🛌',
          categoryId: 4,
          amount: 0,
          durationMinutes: 0,
          notificationTimesMinutesOfDay: [22 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.brushTeeth,
          name: 'Brush teeth',
          iconPath: '🪥',
          categoryId: 4,
          amount: 0,
          durationMinutes: 0,
          notificationTimesMinutesOfDay: [21 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.skinCare,
          name: 'Skin care',
          iconPath: '🧴',
          categoryId: 4,
          amount: 0,
          durationMinutes: 0,
          notificationTimesMinutesOfDay: [(7 * 60) + 20],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.wakeUpEarly,
          name: 'Wake up early',
          iconPath: '⏰',
          categoryId: 2,
          amount: 0,
          durationMinutes: 0,
          notificationTimesMinutesOfDay: [7 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.shower,
          name: 'Shower',
          iconPath: '🚿',
          categoryId: 2,
          amount: 0,
          durationMinutes: 10,
          notificationTimesMinutesOfDay: [(7 * 60) + 5],
        ),
      ],
    ),
    PremadeHabitCategorySection(
      title: 'Health & Fitness',
      habits: [
        PremadeHabitTemplate(
          type: PremadeHabitType.running,
          name: 'Running',
          iconPath: '🏃',
          categoryId: 1,
          amount: 3,
          amountLabelPreset: AmountLabelPreset.km,
          durationMinutes: 15,
          scheduleType: ScheduleType.weekly,
          weeklyTarget: 3,
          notificationTimesMinutesOfDay: [17 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.walk,
          name: 'Walk',
          iconPath: '🚶',
          categoryId: 1,
          amount: 1,
          amountLabelPreset: AmountLabelPreset.km,
          durationMinutes: 15,
          notificationTimesMinutesOfDay: [15 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.gym,
          name: 'Gym',
          iconPath: '🏋️',
          categoryId: 1,
          amount: 0,
          durationMinutes: 60,
          scheduleType: ScheduleType.weekly,
          weeklyTarget: 3,
          notificationTimesMinutesOfDay: [18 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.nutrition,
          name: 'Nutrition',
          iconPath: '🥗',
          categoryId: 1,
          amount: 3,
          durationMinutes: 0,
          amountLabelPreset: AmountLabelPreset.meals,
          notificationTimesMinutesOfDay: [8 * 60, 12 * 60, 15 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.medications,
          name: 'Medications',
          iconPath: '💊',
          categoryId: 2,
          amount: 2,
          durationMinutes: 0,
          notificationTimesMinutesOfDay: [8 * 60, 20 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.drinkWater,
          name: 'Drink water',
          iconPath: '💧',
          categoryId: 1,
          amount: 10,
          durationMinutes: 0,
          amountLabelPreset: AmountLabelPreset.dl,
          notificationTimesMinutesOfDay: [9 * 60, 14 * 60, 19 * 60],
        ),
      ],
    ),
    PremadeHabitCategorySection(
      title: 'Productivity & Growth',
      habits: [
        PremadeHabitTemplate(
          type: PremadeHabitType.studying,
          name: 'Studying',
          iconPath: '📚',
          categoryId: 2,
          amount: 0,
          durationMinutes: 45,
          notificationTimesMinutesOfDay: [(8 * 60) + 30],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.work,
          name: 'Work',
          iconPath: '💼',
          categoryId: 2,
          amount: 0,
          durationMinutes: 120,
          notificationTimesMinutesOfDay: [(8 * 60) + 45],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.research,
          name: 'Research',
          iconPath: '🔍',
          categoryId: 3,
          amount: 0,
          durationMinutes: 30,
          notificationTimesMinutesOfDay: [15 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.read,
          name: 'Read',
          iconPath: '📖',
          categoryId: 1,
          amount: 5,
          amountLabelPreset: AmountLabelPreset.pages,
          durationMinutes: 0,
          scheduleType: ScheduleType.daily,
          notificationTimesMinutesOfDay: [(7 * 60) + 30, 17 * 60],
        ),
        PremadeHabitTemplate(
          type: PremadeHabitType.productivitySession,
          name: 'Productivity session',
          iconPath: '⚡',
          categoryId: 3,
          amount: 0,
          durationMinutes: 45,
          notificationTimesMinutesOfDay: [(8 * 60) + 45, 20 * 60],
        ),
      ],
    ),
  ];

  static PremadeHabitTemplate? byType(PremadeHabitType type) {
    for (final section in sections) {
      for (final habit in section.habits) {
        if (habit.type == type) {
          return habit;
        }
      }
    }
    return null;
  }
}
