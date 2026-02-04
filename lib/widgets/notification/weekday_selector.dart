import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:provider/provider.dart';

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.notificationPeriod,
    required this.selectedWeekdays,
    required this.onToggleWeekday,
  });

  final NotificationPeriod notificationPeriod;
  final Set<int> selectedWeekdays;
  final ValueChanged<int> onToggleWeekday;

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final weekday = index + 1; // 1 = Monday, 7 = Sunday
        final isSelected = selectedWeekdays.contains(weekday);

        return GestureDetector(
          onTap: () => onToggleWeekday(weekday),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? tp.primaryColor : tp.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? tp.primaryColor : tp.borderColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: TextStyle(
                  color:
                      isSelected
                          ? bestContrastingOn(tp.backgroundColor)
                          : tp.mutedTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
