import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:habitt/widgets/faded_list_view.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/nav_back_button.dart';
import 'package:habitt/widgets/select_time_dialog.dart';
import 'package:provider/provider.dart';

class SelectHabitTimePage extends StatelessWidget {
  const SelectHabitTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    final listViewHeight = MediaQuery.of(context).size.height - 293;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavBackButton(colorProvider: colorProvider),
                  Text(
                    "SELECT HABIT TIME:",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1.2,
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  SelectHabitTimeBody(listViewHeight: listViewHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectHabitTimeBody extends StatefulWidget {
  const SelectHabitTimeBody({super.key, required this.listViewHeight});

  final double listViewHeight;

  @override
  State<SelectHabitTimeBody> createState() => _SelectHabitTimeBodyState();
}

class _SelectHabitTimeBodyState extends State<SelectHabitTimeBody> {
  final double hourHeight = 100;

  // Event state
  double? startHour;
  double? duration;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final habitName = sp.nameController.text;

    return FadedListView(
      scrollDirection: Axis.vertical,
      height: widget.listViewHeight,
      children: [
        FadedListView(
          scrollDirection: Axis.vertical,
          height: widget.listViewHeight,
          children: [
            FadedListView(
              height: widget.listViewHeight - 100,
              scrollDirection: Axis.vertical,
              children: [
                SizedBox(
                  height: 24 * hourHeight, // full day
                  child: Stack(
                    children: [
                      // Background hours
                      for (int i = 0; i < 24; i++)
                        Positioned(
                          top: i * hourHeight,
                          left: 0,
                          right: 0,
                          height: hourHeight,
                          child: Row(
                            children: [
                              Text(
                                "${i.toString().padLeft(2, '0')}:00",
                                style: TextStyle(color: cp.mutedTextColor),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: cp.mutedTextColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (startHour != null && duration != null)
                        Positioned(
                          top: startHour! * hourHeight,
                          left: 60,
                          right: 20,
                          height: duration! * hourHeight,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cp.colorScheme.darkerStandardColor
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: cp.colorScheme.vividColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  habitName,
                                  style: TextStyle(
                                    color: cp.colorScheme.vividColor,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            HabitTimeBottomOptions(cp: cp, sp: sp),
          ],
        ),
      ],
    );
  }
}

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

class SelectTimeIntervalSwitch extends StatelessWidget {
  const SelectTimeIntervalSwitch({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    return Column(children: [titleAndSwitch(), timeIntervalButtons(context)]);
  }

  Row titleAndSwitch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: SvgPicture.asset(
            "assets/images/svg/clock.svg",
            colorFilter: ColorFilter.mode(cp.textColor, BlendMode.srcIn),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            "Select time interval",
            style: TextStyle(
              color: cp.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Spacer(),
        Switch(
          activeTrackColor: cp.colorScheme.darkerStandardColor,
          activeColor: Colors.white,
          inactiveThumbColor: cp.textColor,
          inactiveTrackColor: cp.standardColor,
          value: false,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Row timeIntervalButtons(BuildContext context) {
    return Row(
      children: [
        _selectIntervalButton(
          label: "From",
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => SelectTimeDialog(),
            );
          },
          value: "9:00",
        ),
        SizedBox(width: 12),
        _selectIntervalButton(label: "To", onPressed: () {}, value: "9:30"),
      ],
    );
  }

  Expanded _selectIntervalButton({
    required String label,
    required VoidCallback onPressed,
    required String value,
  }) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          DefaultButton(
            label: label,
            offsetLabel: true,
            color: cp.standardColor,
            borderColor: cp.colorScheme.strokeColor,
            onPressed: onPressed,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              value,
              style: TextStyle(color: cp.textColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
