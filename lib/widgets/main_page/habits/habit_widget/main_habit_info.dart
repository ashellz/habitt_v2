import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/get_duration_string.dart';

class MainHabitInfo extends StatelessWidget {
  const MainHabitInfo({super.key, required this.habit, required this.cp});

  final Habit habit;
  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    final bool isAmount = habit.amount > 1;
    final bool isDuration = habit.duration > 0;

    final bool hasProgress =
        isAmount ? habit.amountCompleted > 0 : habit.durationCompleted > 0;
    final bool isCompleted = habit.completed;

    String amountText() {
      final String amountLabel =
          habit.amountLabel.isEmpty ? "times" : habit.amountLabel;

      if (hasProgress && !isCompleted) {
        return "${habit.amountCompleted} / ${habit.amount} $amountLabel";
      }
      return "${habit.amount} $amountLabel";
    }

    String durationText() {
      if (hasProgress && !isCompleted) {
        return "${getDurationString(habit.durationCompleted)} / ${getDurationString(habit.duration)}";
      }
      return getDurationString(habit.duration);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          habit.name,
          style: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isAmount || isDuration)
          Row(
            spacing: 8,
            children: [
              SvgPicture.asset(
                "assets/images/new-svg/clock.svg",
                width: 14,
                height: 14,
              ),
              Text(
                isAmount ? amountText() : durationText(),
                style: TextStyle(color: cp.lightGreyText, fontSize: 13),
              ),
            ],
          )
        else if (habit.description != "")
          Text(
            habit.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cp.lightGreyText, fontSize: 13),
          ),
      ],
    );
  }
}
