import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/sync_device.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/accent_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// One device in the Health sync device picker: its name and OS, and either
/// "This device" or when it last synced.
class HealthDeviceOption extends StatelessWidget {
  const HealthDeviceOption({
    super.key,
    required this.device,
    required this.isSelected,
    required this.isThisDevice,
    required this.onTap,
  });

  final SyncDevice device;
  final bool isSelected;
  final bool isThisDevice;
  final VoidCallback onTap;

  static const _kDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final checkSvgPath =
        cp.isDark
            ? 'assets/images/new-svg/check-on-dark.svg'
            : 'assets/images/new-svg/check-on-light.svg';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: _kDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isSelected ? cp.main.withValues(alpha: 0.2) : cp.border,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          color:
              isSelected ? cp.main.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          spacing: 12,
          children: [
            Icon(
              device.isIos
                  ? Icons.phone_iphone_rounded
                  : Icons.phone_android_rounded,
              size: 20,
              color: cp.lightGreyText,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    device.displayName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isThisDevice
                        ? loc.healthDeviceThisDevice
                        : loc.lastSynced(_lastSeenLabel(context, loc)),
                    style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: AnimatedOpacity(
                duration: _kDuration,
                curve: Curves.easeOut,
                opacity: isSelected ? 1 : 0,
                child: AnimatedScale(
                  duration: _kDuration,
                  curve: Curves.easeOutBack,
                  scale: isSelected ? 1 : 0.7,
                  child: AccentSvg(checkSvgPath),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // a device refreshes its entry about once a day, so a day is all that's
  // worth showing: "Today" or "2 Nov"
  String _lastSeenLabel(BuildContext context, AppLocalizations loc) {
    final seen = device.lastSeen.toLocal();
    final now = DateTime.now();
    if (seen.year == now.year &&
        seen.month == now.month &&
        seen.day == now.day) {
      return loc.today;
    }
    return DateFormat(
      'd MMM',
      Localizations.localeOf(context).toString(),
    ).format(seen);
  }
}
