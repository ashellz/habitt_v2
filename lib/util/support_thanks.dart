import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/services/completion_sound_player.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/confetti_burst.dart';
import 'package:provider/provider.dart';

// Tickers that belong to no widget, so the toast can finish after the banner,
// card or sheet that triggered it has already gone. The popup controller
// removes its overlay and disposes its animation when it is done.
class _DetachedTickers implements TickerProvider {
  const _DetachedTickers();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// The sound that goes with the confetti: the same big one as a perfect day.
/// Replaceable so tests do not touch the audio plugin.
@visibleForTesting
Future<void> Function() donationSound =
    () => CompletionSoundPlayer.instance.play(allHabitsCompleted: true);

/// The thank-you after "I already donated": the status toast slides in from the
/// top, confetti fans down from it and the completion sound plays (unless the
/// user turned completion sounds off). Safe to call right before closing the
/// widget that triggered it.
void showDonationThanks(BuildContext context) {
  final cp = context.read<ColorProvider>();
  final loc = AppLocalizations.of(context)!;

  HapticFeedback.mediumImpact();
  if (context.read<PreferencesProvider>().playCompletionSound) {
    unawaited(donationSound());
  }
  StatusOverlayPopupController(vsync: const _DetachedTickers()).show(
    context: context,
    cp: cp,
    title: loc.supporterThankYouTitle,
    isError: false,
    iconWidget: Image.asset('assets/images/widget-images/love-bubble.png'),
  );

  // from the middle of the toast: top padding + its 10 px offset + half its height
  final origin = Offset(
    MediaQuery.sizeOf(context).width / 2,
    MediaQuery.viewPaddingOf(context).top + 10 + 24,
  );
  for (final direction in const [
    ConfettiDirection.bottomLeft,
    ConfettiDirection.bottom,
    ConfettiDirection.bottomRight,
  ]) {
    ConfettiBurst.show(
      context,
      origin: origin,
      direction: direction,
      maxDistance: 190,
    );
  }
}
