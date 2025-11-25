import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:habitt/widgets/default_switch.dart';
import 'package:habitt/widgets/select_time_dialog.dart';
import 'package:provider/provider.dart';

class SelectTimeIntervalSwitch extends StatelessWidget {
  const SelectTimeIntervalSwitch({super.key, required this.tp});

  final ThemeProvider tp;

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
            colorFilter: ColorFilter.mode(tp.primaryTextColor, BlendMode.srcIn),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            "Select time interval",
            style: TextStyle(
              color: tp.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Spacer(),
        DefaultSwitch(
          switchValue: timeIntervalEnabled,
          onTap: () {
            sp.timeIntervalEnabled = !timeIntervalEnabled;
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
            color: tp.surfaceColor,
            borderColor: tp.borderColor,
            onPressed: onPressed,
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                value,
                style: TextStyle(
                  color: enabled ? tp.primaryTextColor : tp.mutedTextColor,
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
