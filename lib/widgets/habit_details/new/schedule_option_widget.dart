import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/schedule_option_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

class ScheduleOptionWidget extends StatelessWidget {
  static const _selectionDuration = Duration(milliseconds: 200);
  static const _iconTurns = 0.18;

  const ScheduleOptionWidget({super.key, required this.scheduleOptionType});

  final ScheduleOptionType scheduleOptionType;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.read<StateProvider>();
    final isSelected = context.select<StateProvider, bool>(
      (state) => state.selectedScheduleOption == scheduleOptionType,
    );
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    final svgPath =
        cp.isDark
            ? "assets/images/new-svg/check-on-dark.svg"
            : "assets/images/new-svg/check-on-light.svg";
    final selectedBorderColor = cp.main.withValues(alpha: 0.2);
    final selectedBackgroundColor = cp.main.withValues(alpha: 0.1);

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: AnimatedContainer(
        duration: _selectionDuration,
        curve: Curves.easeOut,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isSelected ? selectedBorderColor : cp.border,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          color: isSelected ? selectedBackgroundColor : Colors.transparent,
        ),
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
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
              SizedBox(
                width: 20,
                height: 20,
                child: AnimatedOpacity(
                  duration: _selectionDuration,
                  curve: Curves.easeOut,
                  opacity: isSelected ? 1 : 0,
                  child: AnimatedScale(
                    duration: _selectionDuration,
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1 : 0.7,
                    child: AnimatedRotation(
                      duration: _selectionDuration,
                      curve: Curves.easeOutBack,
                      turns: isSelected ? 0 : _iconTurns,
                      child: SvgPicture.asset(svgPath),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
