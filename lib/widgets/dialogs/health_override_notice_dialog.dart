import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

// shown once, the first time a hand-edit pauses Health sync for a day
// the button stays disabled for [countdownSeconds] so it actually gets read
class HealthOverrideNoticeDialog extends StatefulWidget {
  const HealthOverrideNoticeDialog({super.key, this.countdownSeconds = 3});

  final int countdownSeconds;

  @override
  State<HealthOverrideNoticeDialog> createState() =>
      _HealthOverrideNoticeDialogState();
}

class _HealthOverrideNoticeDialogState
    extends State<HealthOverrideNoticeDialog> {
  late int _remaining = widget.countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final source = healthSourceName();
    final ready = _remaining <= 0;

    return PopScope(
      // also blocks the Android back button until the countdown is over
      canPop: ready,
      child: NewDefaultDialog(
        title: loc.healthOverrideNoticeTitle(source),
        desc: loc.healthOverrideNoticeBody(source),
        titleIcon:
            defaultTargetPlatform == TargetPlatform.iOS
                ? SvgPicture.asset('assets/images/widget-images/apple-health.svg')
                : Image.asset('assets/images/widget-images/health-connect.png'),
        showSecondaryButton: false,
        primaryButtonEnabled: ready,
        primaryButtonLabel:
            ready
                ? loc.healthOverrideNoticeUnderstood
                : '${loc.healthOverrideNoticeUnderstood} ($_remaining)',
      ),
    );
  }
}
