import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:habitt/util/premade_health_sync.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:provider/provider.dart';

/// Whether premade Health habits sync with Health. Set by the first premade
/// Health dialog (or here); once set, only this toggle changes it. Shown on
/// iOS / Android only when Health is available.
class PremadeHealthSetting extends StatefulWidget {
  const PremadeHealthSetting({super.key});

  @override
  State<PremadeHealthSetting> createState() => _PremadeHealthSettingState();
}

class _PremadeHealthSettingState extends State<PremadeHealthSetting> {
  // not decided yet reads as off
  bool _value = false;

  @override
  void initState() {
    super.initState();
    loadPremadeHealthSync().then((v) {
      if (mounted && v != null) setState(() => _value = v);
    });
    context.read<HealthProvider>().ensureAvailabilityChecked();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS && !Platform.isAndroid) return const SizedBox.shrink();

    // nothing to configure where Health can't be used
    if (!context.watch<HealthProvider>().isAvailable) {
      return const SizedBox.shrink();
    }

    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Divider(color: cp.border, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    healthSourceName(),
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            NewDefaultSwitch(
              value: _value,
              onChanged: (value) {
                setState(() => _value = value);
                // a manual change also counts as the decision: no dialog after
                savePremadeHealthSync(value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
