import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class OutdatedOtherDeviceDialog extends StatelessWidget {
  const OutdatedOtherDeviceDialog({super.key, required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final cp = context.read<ColorProvider>();

    return NewDefaultDialog(
      title: loc.outdatedDeviceTitle,
      desc:
          "Another devices on your account is running an outdated version of Habitt. Please update it to the latest version to ensure proper syncing.",
      showSecondaryButton: false,
      primaryButtonLabel: loc.gotIt,
      onPrimaryButtonPressed: () => Navigator.pop(context),
      titleIconSvgPath: 'assets/images/new-svg/update.svg',
      child: Container(
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
                    "Current",
                    style: TextStyle(
                      color: cp.isDark ? cp.lightGreyText : cp.greyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "v2.3",
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,

              decoration: BoxDecoration(color: cp.bg, shape: BoxShape.circle),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SvgPicture.asset('assets/images/new-svg/arrow.svg'),
            ),

            Expanded(
              child: Column(
                children: [
                  Text(
                    "Needed",
                    style: TextStyle(
                      color: cp.main,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "v2.4+",
                    style: TextStyle(
                      color: cp.main,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
