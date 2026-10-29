import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/whats_new/whats_new_alarm_graphic.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:habitt/widgets/whats_new/whats_new_health_graphic.dart';
import 'package:habitt/widgets/whats_new/whats_new_pager_controls.dart';
import 'package:habitt/widgets/whats_new/whats_new_plan_graphic.dart';
import 'package:habitt/widgets/whats_new/whats_new_strength_graphic.dart';
import 'package:habitt/widgets/whats_new/whats_new_themes_graphic.dart';
import 'package:provider/provider.dart';

/// One-time tour of the main new things in 2.5.0, shown by `maybeShowWhatsNew`.
/// Each feature is a graphic with its description underneath, paged with the
/// arrows or by swiping.
class WhatsNewDialog extends StatefulWidget {
  const WhatsNewDialog({super.key});

  @override
  State<WhatsNewDialog> createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends State<WhatsNewDialog> {
  static const int _count = 5;
  static const Duration _pageDuration = Duration(milliseconds: 350);

  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: _pageDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();

    final features = [
      (title: loc.whatsNewHealthTitle, desc: loc.whatsNewHealthDesc),
      (title: loc.whatsNewAlarmsTitle, desc: loc.whatsNewAlarmsDesc),
      (title: loc.whatsNewPlanTitle, desc: loc.whatsNewPlanDesc),
      (title: loc.whatsNewStrengthTitle, desc: loc.whatsNewStrengthDesc),
      (title: loc.whatsNewThemesTitle, desc: loc.whatsNewThemesDesc),
    ];
    final feature = features[_index];

    return NewDefaultDialog(
      title: loc.whatsNewTitle,
      showSecondaryButton: false,
      primaryButtonLabel: loc.gotIt,
      onPrimaryButtonPressed: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // ─── Graphics ─────────────────────────────────────
          SizedBox(
            height: WhatsNewGraphicFrame.height,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final graphic in [
                  const WhatsNewHealthGraphic(),
                  const WhatsNewAlarmGraphic(),
                  WhatsNewPlanGraphic(active: _index == 2),
                  const WhatsNewStrengthGraphic(),
                  const WhatsNewThemesGraphic(),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: graphic,
                  ),
              ],
            ),
          ),
          // ─── Description ──────────────────────────────────
          AnimatedSize(
            duration: _pageDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _pageDuration,
              layoutBuilder:
                  (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, if (current != null) current],
                  ),
              child: Column(
                key: ValueKey(_index),
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    feature.title,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    feature.desc,
                    style: TextStyle(
                      color: cp.greyText,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ─── Controls ─────────────────────────────────────
          WhatsNewPagerControls(
            index: _index,
            count: _count,
            onPrevious: () => _goTo(_index - 1),
            onNext: () => _goTo(_index + 1),
            previousLabel: loc.back,
            nextLabel: loc.next,
          ),
        ],
      ),
    );
  }
}
