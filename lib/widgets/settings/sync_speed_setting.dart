import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/dual_option_selector.dart';
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
              DualOptionSelector<SyncSpeed>(
                firstLabel: loc.syncSpeedFast,
                firstValue: SyncSpeed.fast,
                secondLabel: loc.syncSpeedOptimized,
                secondValue: SyncSpeed.optimized,
                selectedValue: selected,
                onSelect: (v) {
                  if (v != null) context.read<BackupProvider>().setSyncSpeed(v);
                },
                allowDeselect: false,
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
