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
    final stateProvider = context.watch<StateProvider>();

    final timeIntervalStart = stateProvider.timeIntervalStart;
    final timeIntervalEnd = stateProvider.timeIntervalEnd;

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
                  SelectHabitTimeBody(
                    listViewHeight: listViewHeight,
                    timeIntervalStart: timeIntervalStart,
                    timeIntervalEnd: timeIntervalEnd,
                  ),
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
  const SelectHabitTimeBody({
    super.key,
    required this.listViewHeight,
    required this.timeIntervalStart,
    required this.timeIntervalEnd,
  });

  final double listViewHeight;
  final int timeIntervalStart;
  final int timeIntervalEnd;

  @override
  State<SelectHabitTimeBody> createState() => _SelectHabitTimeBodyState();
}

class _SelectHabitTimeBodyState extends State<SelectHabitTimeBody> {
  double hourHeight = 100;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    final durationMinutes = widget.timeIntervalEnd - widget.timeIntervalStart;

    hourHeight =
        durationMinutes <= 10
            ? 300
            : durationMinutes <= 30
            ? 200
            : 100;

    if (oldWidget.timeIntervalStart != widget.timeIntervalStart) {
      _scrollController.animateTo(
        (widget.timeIntervalStart / 60 * hourHeight) - 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("asdafsaf: ${widget.timeIntervalStart / 60 * hourHeight}");
      print("time changed: ${widget.timeIntervalStart}");
    }

    if (oldWidget.timeIntervalEnd != widget.timeIntervalEnd) {
      _scrollController.animateTo(
        (widget.timeIntervalStart / 60 * hourHeight) - 150,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("time changed: ${widget.timeIntervalEnd}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final habitName = sp.nameController.text;

    double? startHour =
        sp.timeIntervalEnabled ? widget.timeIntervalStart / 60 : null;
    double? duration =
        sp.timeIntervalEnabled
            ? sp.timeIntervalEnd / 60 - widget.timeIntervalStart / 60
            : null;

    return FadedListView(
      scrollDirection: Axis.vertical,
      height: widget.listViewHeight,
      children: [
        FadedListView(
          scrollDirection: Axis.vertical,
          height: widget.listViewHeight,
          children: [
            SizedBox(
              height: widget.listViewHeight - 100,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                children: [
                  SizedBox(
                    height: 24 * hourHeight, // full day
                    child: Stack(
                      children: [
                        // Background hours
                        for (int i = 0; i < 24; i++)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
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
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                            top: startHour * hourHeight + 100,
                            left: 60,
                            right: 20,
                            height: duration * hourHeight,
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
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      final offsetAnimation = Tween<Offset>(
                                        begin: const Offset(0.0, 0.2),
                                        end: Offset.zero,
                                      ).animate(animation);

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey<bool>(
                                        widget.timeIntervalEnd -
                                                widget.timeIntervalStart >
                                            5,
                                      ),
                                      child:
                                          widget.timeIntervalEnd -
                                                      widget.timeIntervalStart >
                                                  5
                                              ? Text(
                                                habitName,
                                                style: TextStyle(
                                                  color:
                                                      cp.colorScheme.vividColor,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 1,
                                                  fontSize: 16,
                                                ),
                                              )
                                              : Container(),
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
    final sp = context.watch<StateProvider>();
    bool timeIntervalEnabled = sp.timeIntervalEnabled;
    int timeIntervalStart = sp.timeIntervalStart;
    int timeIntervalEnd = sp.timeIntervalEnd;

    return Column(
      children: [
        titleAndSwitch(timeIntervalEnabled, sp),
        timeIntervalButtons(
          context,
          timeIntervalEnabled,
          timeIntervalStart,
          timeIntervalEnd,
          sp,
        ),
      ],
    );
  }

  Row titleAndSwitch(bool timeIntervalEnabled, StateProvider sp) {
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
          value: timeIntervalEnabled,
          onChanged: (value) {
            sp.timeIntervalEnabled = value;
          },
        ),
      ],
    );
  }

  Row timeIntervalButtons(
    BuildContext context,
    bool timeIntervalEnabled,
    int timeIntervalStart,
    int timeIntervalEnd,
    StateProvider sp,
  ) {
    return Row(
      children: [
        _selectIntervalButton(
          label: "From",
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) =>
                      SelectTimeDialog(isStartTime: true, stateProvider: sp),
            );
          },
          enabled: timeIntervalEnabled,
          value:
              "${(timeIntervalStart ~/ 60).toString().padLeft(2, "0")}:${(timeIntervalStart % 60).toString().padLeft(2, "0")}",
        ),

        SizedBox(width: 12),
        _selectIntervalButton(
          label: "To",
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) =>
                      SelectTimeDialog(isStartTime: false, stateProvider: sp),
            );
          },
          value:
              "${(timeIntervalEnd ~/ 60).toString().padLeft(2, "0")}:${(timeIntervalEnd % 60).toString().padLeft(2, "0")}",
          enabled: timeIntervalEnabled,
        ),
      ],
    );
  }

  Expanded _selectIntervalButton({
    required String label,
    required VoidCallback onPressed,
    required String value,
    required bool enabled,
  }) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          DefaultButton(
            enabled: enabled,
            label: label,
            offsetLabel: true,
            color: cp.standardColor,
            borderColor: cp.colorScheme.strokeColor,
            onPressed: onPressed,
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                value,
                style: TextStyle(
                  color: enabled ? cp.textColor : cp.mutedTextColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
