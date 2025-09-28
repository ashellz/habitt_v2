import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/select_habit_time_page/select_time_interval_switch.dart';

class HabitTimeBottomOptions extends StatelessWidget {
  const HabitTimeBottomOptions({super.key, required this.cp, required this.sp});

  final ColorProvider cp;
  final StateProvider sp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Drag indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16, top: 16),
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: cp.mutedTextColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SelectTimeIntervalSwitch(cp: cp),
          ],
        ),
      ),
    );
  }
}
