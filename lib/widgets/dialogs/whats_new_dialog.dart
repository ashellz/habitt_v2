import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

/// One-time list of the main new things in 2.5.0, shown by `maybeShowWhatsNew`.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.whatsNewTitle,
      desc: loc.whatsNewDesc,
      showSecondaryButton: false,
      primaryButtonLabel: loc.gotIt,
      onPrimaryButtonPressed: () => Navigator.pop(context),
      child: Column(
        spacing: 16,
        children: [
          _FeatureRow(icon: Icons.favorite_rounded, text: loc.whatsNewHealth),
          _FeatureRow(icon: Icons.alarm_rounded, text: loc.whatsNewAlarms),
          _FeatureRow(
            icon: Icons.event_repeat_rounded,
            text: loc.whatsNewShowAgain,
          ),
          _FeatureRow(
            icon: Icons.calendar_view_day_rounded,
            text: loc.whatsNewPlan,
          ),
          _FeatureRow(
            icon: Icons.show_chart_rounded,
            text: loc.whatsNewStrength,
          ),
          _FeatureRow(icon: Icons.palette_rounded, text: loc.whatsNewThemes),
        ],
      ),
    );
  }
}

// ─── Feature row ─────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Row(
      spacing: 14,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cp.isDark ? cp.field : cp.habitBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: cp.main),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
