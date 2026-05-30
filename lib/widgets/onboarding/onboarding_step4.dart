import 'dart:async';

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
  OnboardingStep4State createState() => OnboardingStep4State();
}

// Public so onboarding_pages.dart can call commitDraft() via GlobalKey.
class OnboardingStep4State extends State<OnboardingStep4>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animPhone;
  late Animation<double> _animToggles;
  late Animation<double> _animBell;

  bool _draftMaster = true;
  bool _draftPeriods = true;
  bool _draftHabits = true;
  bool _draftInitialized = false;

  final Map<NotificationPeriod, NotificationSettings> _draftPeriodSettings = {};
  // Saved per-period enabled states before periods were disabled.
  final Map<NotificationPeriod, bool> _savedPeriodEnabled = {};

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

    // Rebuilding on every animation tick guarantees the phone demo reflects
    // draft state immediately — no AnimatedBuilder child-caching issues.
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.forward();

    // Pre-initialize with onboarding defaults (wrapUp on, rest off).
    for (final period in NotificationPeriod.values) {
      _draftPeriodSettings[period] = NotificationSettings.defaultForPeriod(
        period,
      ).copyWith(enabled: period == NotificationPeriod.wrapUp);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final allowed = await NotificationService.requestPermissions(context);
      if (!mounted) return;

      final np = context.read<NotificationsProvider>();

      if (allowed) {
        // One-time heavy setup persisted to the provider.
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
        if (!mounted) return;
      }

      setState(() {
        _draftMaster = np.isMasterEnabled;
        _draftPeriods = np.arePeriodNotificationsEnabled;
        _draftHabits = np.areHabitNotificationsEnabled;
        for (final period in NotificationPeriod.values) {
          _draftPeriodSettings[period] = np.getSettings(period);
        }
        _draftInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Called by the parent right before navigating away. Fires notification
  /// scheduling in the background so navigation is not blocked.
  void commitDraft() {
    if (!_draftInitialized || !mounted) return;
    final np = context.read<NotificationsProvider>();
    unawaited(() async {
      final applied = await np.applyGlobalToggles(
        context: context,
        masterEnabled: _draftMaster,
        periodsEnabled: _draftPeriods,
        habitsEnabled: _draftHabits,
      );
      if (!applied) return;
      for (final period in NotificationPeriod.values) {
        final draft = _draftPeriodSettings[period];
        if (draft != null) {
          await np.setSettings(period, draft);
        }
      }
    }());
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

    // Read animation value directly — the controller listener keeps this
    // widget rebuilding each frame during animation, and setState from toggle
    // callbacks keeps it current afterwards.
    final phoneV = _animPhone.value.clamp(0.0, 1.0);

    final periodEnabledOverrides = {
      for (final e in _draftPeriodSettings.entries) e.key: e.value.enabled,
    };

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.only(right: 16, left: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Phone is NOT wrapped in _slide / AnimatedBuilder so the demo
          // rerenders whenever draft state changes via setState.
          Opacity(
            opacity: phoneV,
            child: Transform.translate(
              offset: Offset(0, -40 * (1 - phoneV)),
              child: Transform.scale(
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
                    child: IgnorePointer(
                      child: NotificationSettingsPage.demo(
                        masterEnabled: _draftMaster,
                        periodsEnabled: _draftPeriods,
                        habitsEnabled: _draftHabits,
                        periodEnabledOverrides: periodEnabledOverrides,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const FractionalOffset(0.94, 0.25),
            child: _slide(const _NotificationGradientCircle(), _animBell),
          ),
          Positioned(
            top: 220,
            left: 12,
            right: 12,
            child: _slide(
              _NotificationTogglesCard(
                masterEnabled: _draftMaster,
                periodsEnabled: _draftPeriods,
                habitsEnabled: _draftHabits,
                onMasterChanged: (value) {
                  setState(() {
                    _draftMaster = value;
                    if (!value) {
                      _draftPeriods = false;
                      _draftHabits = false;
                      for (final p in NotificationPeriod.values) {
                        final cur = _draftPeriodSettings[p];
                        if (cur != null && cur.enabled) {
                          _draftPeriodSettings[p] = cur.copyWith(enabled: false);
                        }
                      }
                    }
                  });
                },
                onHabitsChanged: (value) {
                  setState(() {
                    _draftHabits = value;
                    if (value) _draftMaster = true;
                  });
                },
                onPeriodsChanged: (value) {
                  setState(() {
                    _draftPeriods = value;
                    if (value) {
                      _draftMaster = true;
                      for (final p in NotificationPeriod.values) {
                        final cur = _draftPeriodSettings[p];
                        if (cur != null) {
                          _draftPeriodSettings[p] = cur.copyWith(
                            enabled: _savedPeriodEnabled[p] ??
                                (p == NotificationPeriod.wrapUp),
                          );
                        }
                      }
                      _savedPeriodEnabled.clear();
                    } else {
                      for (final p in NotificationPeriod.values) {
                        _savedPeriodEnabled[p] =
                            _draftPeriodSettings[p]?.enabled ?? false;
                      }
                      for (final p in NotificationPeriod.values) {
                        final cur = _draftPeriodSettings[p];
                        if (cur != null && cur.enabled) {
                          _draftPeriodSettings[p] = cur.copyWith(enabled: false);
                        }
                      }
                    }
                  });
                },
              ),
              _animToggles,
            ),
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
  const _NotificationTogglesCard({
    required this.masterEnabled,
    required this.periodsEnabled,
    required this.habitsEnabled,
    required this.onMasterChanged,
    required this.onHabitsChanged,
    required this.onPeriodsChanged,
  });

  final bool masterEnabled;
  final bool periodsEnabled;
  final bool habitsEnabled;
  final ValueChanged<bool> onMasterChanged;
  final ValueChanged<bool> onHabitsChanged;
  final ValueChanged<bool> onPeriodsChanged;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
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
                NewDefaultSwitch(value: masterEnabled, onChanged: onMasterChanged),
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
                NewDefaultSwitch(value: habitsEnabled, onChanged: onHabitsChanged),
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
                NewDefaultSwitch(value: periodsEnabled, onChanged: onPeriodsChanged),
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
