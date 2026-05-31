import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SyncSpeedSetting extends StatelessWidget {
  const SyncSpeedSetting({super.key});

  static const _kAnimDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;

    if (!bp.isLoggedIn) return const SizedBox.shrink();

    final selected = bp.syncSpeed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          loc.syncSectionTitle,
          style: TextStyle(color: cp.lightGreyText, fontSize: 16),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(
                loc.syncSpeedTitle,
                style: TextStyle(
                  color: cp.lightGreyText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  _SpeedOption(
                    label: loc.syncSpeedFast,
                    description: loc.syncSpeedFastDescription,
                    isSelected: selected == SyncSpeed.fast,
                    onTap:
                        () => context.read<BackupProvider>().setSyncSpeed(
                          SyncSpeed.fast,
                        ),
                  ),
                  _SpeedOption(
                    label: loc.syncSpeedOptimized,
                    description: loc.syncSpeedOptimizedDescription,
                    isSelected: selected == SyncSpeed.optimized,
                    onTap:
                        () => context.read<BackupProvider>().setSyncSpeed(
                          SyncSpeed.optimized,
                        ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: _kAnimDuration,
                child: Text(
                  key: ValueKey(selected),
                  selected == SyncSpeed.fast
                      ? loc.syncSpeedFastHint
                      : loc.syncSpeedOptimizedHint,
                  style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeedOption extends StatelessWidget {
  const _SpeedOption({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  static const _kAnimDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _kAnimDuration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: ShapeDecoration(
            color:
                isSelected
                    ? cp.main.withValues(alpha: 0.08)
                    : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                width: 1,
                color: isSelected ? cp.main.withValues(alpha: 0.35) : cp.border,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              AnimatedDefaultTextStyle(
                duration: _kAnimDuration,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: isSelected ? cp.main : cp.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(label),
              ),
              AnimatedDefaultTextStyle(
                duration: _kAnimDuration,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color:
                      isSelected
                          ? cp.main.withValues(alpha: 0.75)
                          : cp.lightGreyText,
                  fontSize: 12,
                  height: 1.4,
                ),
                child: Text(description),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
