import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/old_default_button.dart';
import 'package:habitt/widgets/default/default_switch.dart';
import 'package:habitt/widgets/dialogs/select_time_dialog.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SelectTimeInterval extends StatelessWidget {
  const SelectTimeInterval({super.key, required this.tp});

  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StateProvider>();
    bool timeIntervalEnabled = sp.timeIntervalEnabled;
    int timeIntervalStart = sp.timeIntervalStart;
    int timeIntervalEnd = sp.timeIntervalEnd;

    return Column(
      children: [
        titleAndSwitch(context, timeIntervalEnabled, sp),
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

  Row titleAndSwitch(
    BuildContext context,
    bool timeIntervalEnabled,
    StateProvider sp,
  ) {
    final loc = AppLocalizations.of(context)!;
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
            loc.selectTimeInterval,
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
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        _selectIntervalButton(
          label: loc.from,
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
          label: loc.to,
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
          OldDefaultButton(
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
