import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/sync_device.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/accent_svg.dart';
import 'package:habitt/util/sync_device_last_seen.dart';
import 'package:provider/provider.dart';

/// One device in the Health sync device picker: its name and OS, and either
/// "This device" or when it last synced. A device that can't read Health is
/// greyed out with an info button that says why ([onInfoTap]).
class HealthDeviceOption extends StatelessWidget {
  const HealthDeviceOption({
    super.key,
    required this.device,
    required this.isSelected,
    required this.isThisDevice,
    required this.onTap,
    this.enabled = true,
    this.onInfoTap,
  });

  final SyncDevice device;
  final bool isSelected;
  final bool isThisDevice;
  final VoidCallback onTap;
  final bool enabled;
  final VoidCallback? onInfoTap;

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
      onTap: enabled ? onTap : onInfoTap,
      child: AnimatedOpacity(
        duration: _kDuration,
        opacity: enabled ? 1 : 0.5,
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
                isSelected
                    ? cp.main.withValues(alpha: 0.1)
                    : Colors.transparent,
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
                          : loc.lastSynced(
                            syncDeviceLastSeenLabel(context, loc, device),
                          ),
                      style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!enabled)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onInfoTap,
                  child: SvgPicture.asset(
                    'assets/images/new-svg/info.svg',
                    width: 20,
                  ),
                )
              else
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
      ),
    );
  }
}
