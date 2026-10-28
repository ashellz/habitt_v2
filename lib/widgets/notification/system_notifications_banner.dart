import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/util/open_system_notification_settings.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

/// Shown at the top of the notification settings while notifications are turned
/// off for Habitt in the OS. Not dismissible: nothing in Habitt can send a
/// reminder until it is fixed in the OS settings. Checks again when the app is
/// resumed, so it goes away once the user turns notifications back on.
class SystemNotificationsBanner extends StatefulWidget {
  const SystemNotificationsBanner({super.key});

  @override
  State<SystemNotificationsBanner> createState() =>
      _SystemNotificationsBannerState();
}

class _SystemNotificationsBannerState extends State<SystemNotificationsBanner>
    with WidgetsBindingObserver {
  bool _disabledInSystem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final disabled = await NotificationService.areDisabledInSystem();
    if (!mounted || disabled == _disabledInSystem) return;
    setState(() => _disabledInSystem = disabled);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child:
          _disabledInSystem
              ? const _BannerCard()
              : const SizedBox(width: double.infinity),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: cp.orange100,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: cp.orange200),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // ─── Message ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SvgPicture.asset(
                    'assets/images/new-svg/notifications.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      cp.orange300,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        loc.notificationsOffInSystemTitle,
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        loc.notificationsOffInSystemDesc,
                        style: TextStyle(
                          color: cp.greyText,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ─── Action ───────────────────────────────────────
            NewDefaultButton.primary(
              height: 44,
              label: loc.openSettings,
              onPressed: openSystemNotificationSettings,
            ),
          ],
        ),
      ),
    );
  }
}
