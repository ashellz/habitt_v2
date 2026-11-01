import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:habitt/util/premade_health_sync.dart';
import 'package:habitt/widgets/default/multiple_option_selector.dart';
import 'package:provider/provider.dart';

/// Lets the user see or reset the standing answer to the premade Health
/// dialog (Ask / Sync / Manual). iOS and Android only.
class PremadeHealthSetting extends StatefulWidget {
  const PremadeHealthSetting({super.key});

  @override
  State<PremadeHealthSetting> createState() => _PremadeHealthSettingState();
}

class _PremadeHealthSettingState extends State<PremadeHealthSetting> {
  PremadeHealthChoice _choice = PremadeHealthChoice.ask;

  @override
  void initState() {
    super.initState();
    loadPremadeHealthChoice().then((c) {
      if (mounted) setState(() => _choice = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS && !Platform.isAndroid) return const SizedBox.shrink();

    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          loc.premadeHealthSettingTitle,
          style: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          loc.premadeHealthSettingDesc(healthSourceName()),
          style: TextStyle(color: cp.lightGreyText, fontSize: 13),
        ),
        MultipleOptionSelector<PremadeHealthChoice>(
          labels: [
            loc.premadeHealthChoiceAsk,
            loc.premadeHealthChoiceSync,
            loc.premadeHealthChoiceManual,
          ],
          values: const [
            PremadeHealthChoice.ask,
            PremadeHealthChoice.health,
            PremadeHealthChoice.manual,
          ],
          selectedValue: _choice,
          allowDeselect: false,
          onSelect: (value) {
            if (value == null) return;
            setState(() => _choice = value);
            savePremadeHealthChoice(value);
          },
        ),
      ],
    );
  }
}
