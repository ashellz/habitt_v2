import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/main_page/calendar_expansion_controller.dart';
import 'package:habitt/widgets/main_page/downward_drag_gesture_recognizer.dart';
import 'package:habitt/widgets/main_page/last_week_progress.dart';
import 'package:habitt/widgets/main_page/new_perfect_days_streak.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageTopSection extends StatefulWidget {
  const MainPageTopSection({super.key, this.expansionController});

  final CalendarExpansionController? expansionController;

  @override
  State<MainPageTopSection> createState() => _MainPageTopSectionState();
}

class _MainPageTopSectionState extends State<MainPageTopSection>
    with AutomaticKeepAliveClientMixin<MainPageTopSection> {
  String? name;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Loading name
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hasStreak = context.watch<StatsProvider>().perfectDaysStreak > 0;
    final expansionController = widget.expansionController;

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Greeting(),

                if (expansionController == null)
                  _settingsButton(context, native: true)
                else
                  AnimatedBuilder(
                    animation: expansionController.animation,
                    builder:
                        (context, _) => _settingsButton(
                          context,
                          native: expansionController.animation.value <= 0.2,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LastWeekProgress(expansionController: expansionController), // 79

          if (hasStreak) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: NewPerfectDaysStreak(),
            ), // 82
          ],

          if (expansionController != null)
            _CalendarDragHandle(controller: expansionController)
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _settingsButton(BuildContext context, {required bool native}) {
    return NewCircleButton(
      svgPath: "assets/images/new-svg/settings.svg",
      cnIcon: CNSymbol("gearshape", size: 16),
      native: native,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
    );
  }
}

// same thing as drag handle in lastweekprogress but separate for under the streak widget
class _CalendarDragHandle extends StatelessWidget {
  const _CalendarDragHandle({required this.controller});

  final CalendarExpansionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation,
      builder: (context, child) {
        final t = controller.animation.value;
        return Opacity(opacity: (1 - t / 0.3).clamp(0.0, 1.0), child: child);
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          DownwardDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            DownwardDragGestureRecognizer
          >(() => DownwardDragGestureRecognizer(debugOwner: this), (
            recognizer,
          ) {
            recognizer.onUpdate =
                (details) => controller.onDragUpdate(details.delta.dy);
            recognizer.onEnd =
                (details) =>
                    controller.onDragEnd(details.velocity.pixelsPerSecond.dy);
            recognizer.onCancel = () => controller.onDragEnd(0);
          }),
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Center(
            child: SvgPicture.asset('assets/images/new-svg/drag.svg'),
          ),
        ),
      ),
    );
  }
}

// MediaQuery.of(context).padding.top - top safe area
// 20 - top padding
// 60/40 - spacing
// 79 - LastWeekProgress
// 82 - NewPerfectDaysStreak
// 20 - bottom padding
// if has bigger streak
// TOPPADDING + 20 + 60 + 79 + 82 + 20
// else
// 20 + 40 + 79 + 20
