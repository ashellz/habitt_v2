import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/select_habit_color_sheet.dart';
import 'package:habitt/widgets/select_habit_time_page/select_time_interval_switch.dart';

class HabitTimeBottomOptions extends StatelessWidget {
  const HabitTimeBottomOptions({super.key, required this.tp, required this.sp});

  final ThemeProvider tp;
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
                  color: tp.mutedTextColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SelectTimeIntervalSwitch(tp: tp),

            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SelectHabitColorSheet(tp: tp),
                );
              },
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.color_lens,
                        color: tp.primaryTextColor,
                        size: 32,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        "Select habit color",
                        style: TextStyle(
                          color: tp.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),

                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: sp.habitColor ?? tp.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
