import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/pages/other_pages/notification_settings_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:provider/provider.dart';

class OnboardingStep4 extends StatefulWidget {
  const OnboardingStep4({super.key});

  @override
  State<OnboardingStep4> createState() => _OnboardingStep4State();
}

class _OnboardingStep4State extends State<OnboardingStep4>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animPhone;
  late Animation<double> _animToggles;
  late Animation<double> _animBell;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animPhone = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.40, curve: Curves.easeOut),
    );
    _animToggles = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.60, curve: Curves.easeOut),
    );
    _animBell = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final allowed = await NotificationService.requestPermissions(context);
      if (!mounted || !allowed) return;

      final np = context.read<NotificationsProvider>();
      await np.applyGlobalToggles(
        context: context,
        masterEnabled: true,
        periodsEnabled: true,
        habitsEnabled: true,
      );
      if (!mounted) return;
      await np.setSettings(
        NotificationPeriod.morning,
        np.getSettings(NotificationPeriod.morning).copyWith(enabled: false),
      );
      if (!mounted) return;
      await np.setSettings(
        NotificationPeriod.midday,
        np.getSettings(NotificationPeriod.midday).copyWith(enabled: false),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _slide(Widget child, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder:
          (context, child) => Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -40 * (1 - anim.value)),
              child: child,
            ),
          ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.only(right: 16, left: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _slide(
            Transform.scale(
              scale: 0.8,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cp.border,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: IgnorePointer(child: NotificationSettingsPage.demo()),
                ),
              ),
            ),
            _animPhone,
          ),
          Align(
            alignment: const FractionalOffset(0.94, 0.25),
            child: _slide(const _NotificationGradientCircle(), _animBell),
          ),
          Positioned(
            top: 220,
            left: 12,
            right: 12,
            child: _slide(const _NotificationTogglesCard(), _animToggles),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.2,
                widthFactor: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [cp.main, cp.main.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTogglesCard extends StatelessWidget {
  const _NotificationTogglesCard();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final np = context.watch<NotificationsProvider>();
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cp.isDark ? cp.habitBg : cp.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.allNotifications,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                NewDefaultSwitch(
                  value: np.isMasterEnabled,
                  onChanged: (value) async {
                    await np.applyGlobalToggles(
                      context: context,
                      masterEnabled: value,
                      periodsEnabled:
                          value ? np.arePeriodNotificationsEnabled : false,
                      habitsEnabled:
                          value ? np.areHabitNotificationsEnabled : false,
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(color: cp.border, height: 32),
          Container(
            height: 32,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.habitNotifications,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                NewDefaultSwitch(
                  value: np.areHabitNotificationsEnabled,
                  onChanged: (value) async {
                    await np.applyGlobalToggles(
                      context: context,
                      masterEnabled: value || np.isMasterEnabled,
                      periodsEnabled: np.arePeriodNotificationsEnabled,
                      habitsEnabled: value,
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(color: cp.border, height: 32),
          Container(
            height: 32,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.dailyReminders,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                NewDefaultSwitch(
                  value: np.arePeriodNotificationsEnabled,
                  onChanged: (value) async {
                    await np.applyGlobalToggles(
                      context: context,
                      masterEnabled: value || np.isMasterEnabled,
                      periodsEnabled: value,
                      habitsEnabled: np.areHabitNotificationsEnabled,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationGradientCircle extends StatelessWidget {
  const _NotificationGradientCircle();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6DA), Color(0xFFFFDFB1)],
        ),
      ),
      child: Transform.rotate(
        angle: 0.2,
        child: Center(
          child: SvgPicture.asset(
            'assets/images/new-svg/notifications.svg',
            width: 34,
            height: 34,
            colorFilter: ColorFilter.mode(cp.orange300, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
