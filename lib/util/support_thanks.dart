import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/confetti_burst.dart';
import 'package:provider/provider.dart';

/// The thank-you after "I already donated": the status toast slides in from the
/// top and confetti fans down from it. The caller owns [popup] and must keep it
/// alive (not disposed) while the toast shows.
void showDonationThanks(
  BuildContext context,
  StatusOverlayPopupController popup,
) {
  final cp = context.read<ColorProvider>();
  final loc = AppLocalizations.of(context)!;

  HapticFeedback.mediumImpact();
  popup.show(
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
