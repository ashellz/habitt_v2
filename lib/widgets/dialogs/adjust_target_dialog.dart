import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class AdjustTargetDialog extends StatelessWidget {
  const AdjustTargetDialog({
    super.key,
    required this.title,
    required this.desc,
    required this.primaryLabel,
    required this.onSecondaryButtonPressed,
    required this.onPrimaryButtonPressed,
    required this.showSecondaryButton,
    this.currentAmount,
    this.suggestedAmount,
    required this.label,
    required this.trackingType,
  });

  final String title;
  final String desc;
  final String primaryLabel;
  final VoidCallback onSecondaryButtonPressed;
  final VoidCallback onPrimaryButtonPressed;
  final bool showSecondaryButton;
  final int? currentAmount;
  final int? suggestedAmount;
  final String label;
  final HabitTrackingType? trackingType;

  @override
  Widget build(BuildContext context) {
    final cp = context.read<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: title,
      desc: desc,
      primaryButtonLabel: primaryLabel,
      showSecondaryButton: showSecondaryButton,
      secondaryButtonLabel: loc.later,
      onSecondaryButtonPressed: onSecondaryButtonPressed,
      onPrimaryButtonPressed: onPrimaryButtonPressed,
      titleIconSvgPath: 'assets/images/new-svg/decrease.svg',
      child:
          showSecondaryButton &&
                  currentAmount != null &&
                  suggestedAmount != null
              ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cp.isDark ? cp.field : cp.bg,
                  border: Border.all(color: cp.border, width: 1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            loc.current,
                            style: TextStyle(
                              color: cp.isDark ? cp.lightGreyText : cp.greyText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trackingType == HabitTrackingType.duration
                                ? getDurationString(currentAmount!)
                                : currentAmount.toString(),
                            style: TextStyle(
                              color: cp.text,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (trackingType != HabitTrackingType.duration)
                            Text(
                              label,
                              style: TextStyle(
                                color:
                                    cp.isDark ? cp.lightGreyText : cp.greyText,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,

                      decoration: BoxDecoration(
                        color: cp.isDark ? cp.bg : cp.habitBg,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: SvgPicture.asset(
                        'assets/images/new-svg/arrow.svg',
                      ),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            loc.suggested,
                            style: TextStyle(
                              color: cp.main,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trackingType == HabitTrackingType.duration
                                ? getDurationString(suggestedAmount!)
                                : suggestedAmount.toString(),
                            style: TextStyle(
                              color: cp.main,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (trackingType != HabitTrackingType.duration)
                            Text(
                              label,
                              style: TextStyle(
                                color:
                                    cp.isDark ? cp.lightGreyText : cp.greyText,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
