import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

enum ScheduleOptionType { daily, weekly, monthly, custom }

class SetScheduleDialog extends StatelessWidget {
  const SetScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return NewDefaultDialog(
      title: "Set Schedule",
      desc: "How often would you like to do this habit?",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          for (var option in ScheduleOptionType.values)
            ScheduleOptionWidget(scheduleOptionType: option),
        ],
      ),
    );
  }
}

class ScheduleOptionWidget extends StatelessWidget {
  const ScheduleOptionWidget({super.key, required this.scheduleOptionType});

  final ScheduleOptionType scheduleOptionType;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    final selectedOption = sp.selectedScheduleOption;
    final isSelected = selectedOption == scheduleOptionType;
    final svgPath =
        cp.isDark
            ? "assets/images/new-svg/check-on-dark.svg"
            : "assets/images/new-svg/check-on-light.svg";
    final borderColor = isSelected ? cp.main.withValues(alpha: 0.2) : cp.border;
    final backgroundColor =
        isSelected ? cp.main.withValues(alpha: 0.1) : Colors.transparent;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: () {
          sp.selectedScheduleOption = scheduleOptionType;
        },
        style: ButtonStyle(
          splashFactory: isAndroid ? null : NoSplash.splashFactory,
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (!states.contains(WidgetState.pressed)) {
              return null;
            }

            if (isAndroid) {
              return null;
            }

            return cp.bg.withValues(alpha: 0.2);
          }),
          backgroundColor: WidgetStatePropertyAll(backgroundColor),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              side: BorderSide(width: 1, color: borderColor),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              scheduleOptionType.name[0].toUpperCase() +
                  scheduleOptionType.name.substring(1),
              style: TextStyle(
                color: cp.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected) SvgPicture.asset(svgPath),
          ],
        ),
      ),
    );
  }
}
