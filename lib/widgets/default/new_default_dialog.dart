import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

class NewDefaultDialog extends StatelessWidget {
  const NewDefaultDialog({
    super.key,
    this.child,
    required this.title,
    this.primaryButtonLabel = "Done",
    this.primaryButtonEnabled = true,
    this.secondaryButtonLabel = "Cancel",
    this.desc,
    this.onPrimaryButtonPressed,
    this.onSecondaryButtonPressed,
  });

  final Widget? child;
  final String title;
  final String? desc;
  final String secondaryButtonLabel;
  final String primaryButtonLabel;
  final bool primaryButtonEnabled;
  final VoidCallback? onPrimaryButtonPressed;
  final VoidCallback? onSecondaryButtonPressed;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cp.isDark ? cp.habitBg : cp.bg,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (desc != null)
                  Text(
                    desc!,
                    style: TextStyle(color: cp.greyText, fontSize: 16),
                  ),
              ],
            ),
            if (child != null) child!,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                Expanded(
                  child: NewDefaultButton.secondary(
                    onPressed: () {
                      if (onSecondaryButtonPressed != null) {
                        onSecondaryButtonPressed!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    label: secondaryButtonLabel,
                  ),
                ),
                Expanded(
                  child: NewDefaultButton.primary(
                    enabled: primaryButtonEnabled,
                    onPressed: () {
                      if (onPrimaryButtonPressed != null) {
                        onPrimaryButtonPressed!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    label: primaryButtonLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
