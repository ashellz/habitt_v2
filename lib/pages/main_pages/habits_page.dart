import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/pages/main_pages/daily_plan_page.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/glass_blur_container.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/habits_page/habits.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habits_completed_widget.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewKey = GlobalKey();

  // Popup control
  bool showPopup = false;
  late final AnimationController _popupController;
  late final Animation<double> _popupAnimation;
  final double popupHeight = 70;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _popupAnimation = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOutBack, // curve for appearing
      reverseCurve: Curves.easeIn, // curve for disappearing
    );

    _scrollController.addListener(_onScroll);
    // Get initial geometry after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );
  }

  void _togglePopup([bool? value]) {
    final newVal = value ?? !showPopup;
    setState(() => showPopup = newVal);
    if (newVal) {
      _popupController.forward();
    } else {
      _popupController.reverse();
    }
  }

  // ====================================
  // Configuration for the stacking effect
  // ====================================

  // Pixels from bottom of viewport where effect starts
  final double _effectZoneHeight = 120.0;

  // Smallest scale for a stacked item
  final double _minScale = 0.85;

  // Factor of item height for upward offset (e.g., 0.15 = 15% of its height)
  final double _stackOffsetFactor = 0.15;

  double _bottomViewportEdgeGlobalY = 0;

  void _updateListViewportGeom() {
    if (!mounted || !_scrollController.hasClients) {
      // If not mounted or scroll controller not ready, try again after next frame
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateListViewportGeom(),
        );
      }
      return;
    }

    final RenderBox? listViewRenderBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewRenderBox != null && listViewRenderBox.hasSize) {
      final listViewGlobalOffset = listViewRenderBox.localToGlobal(Offset.zero);
      final currentBottomViewportY =
          listViewGlobalOffset.dy +
          _scrollController.position.viewportDimension;

      // Only update state if the value actually changes to avoid unnecessary rebuilds
      if (_bottomViewportEdgeGlobalY != currentBottomViewportY) {
        setState(() {
          _bottomViewportEdgeGlobalY = currentBottomViewportY;
        });
      }
    } else {
      // If renderbox not available yet, retry
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateListViewportGeom(),
      );
    }
  }

  void _onScroll() {
    // On scroll we use to update state and widgets after
    // every scroll which is necessary to do

    if (!mounted) return;
    // We need to call _updateListViewportGeom in case the listview's position/size changes
    // for example, due to keyboard or other dynamic UI elements above it.
    // However, for pure scrolling, its global Y and viewportDimension are often stable.
    // The primary need for setState is to make children re-evaluate their position.
    // _updateListViewportGeom(); // Call if you suspect ListView geometry changes during scroll
    setState(() {
      // This will cause visible HabitWidgets to rebuild and update their transforms
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final stateProvider = context.watch<StateProvider>();

    if (stateProvider.showAlert) {
      _togglePopup(true);
      Future.delayed(const Duration(seconds: 3), () {
        stateProvider.toggleAlert(show: false);
        _togglePopup(false);
      });
    }

    // Ensure viewport geometry is updated if screen size changes (e.g. orientation)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            GradientBackground(
              child: ListView(
                key: _listViewKey,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Greeting(),

                            Row(
                              children: [
                                FloatingActionButton(
                                  mini: true,
                                  elevation: 0,
                                  backgroundColor:
                                      colorProvider.colorScheme.strokeColor,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const DailyPlanPage(),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.date_range,
                                    color: Colors.white,
                                  ),
                                ),
                                FloatingActionButton(
                                  mini: true,
                                  elevation: 0,
                                  backgroundColor:
                                      colorProvider
                                          .colorScheme
                                          .darkerStandardColor,
                                  onPressed:
                                      () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => AddHabitPage(),
                                            ),
                                          )
                                          .whenComplete(() {
                                            if (!context.mounted) return;
                                            final stateProvider =
                                                context.read<StateProvider>();
                                            stateProvider.reset();
                                          }),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const CategoriesList(),
                        const HabitsCompletedWidget(),
                      ],
                    ),
                  ),

                  // Pass down the necessary parameters for the effect
                  Habits(
                    scrollController: _scrollController,
                    bottomViewportEdgeGlobalY: _bottomViewportEdgeGlobalY,
                    effectZoneHeight: _effectZoneHeight,
                    minScale: _minScale,
                    stackOffsetFactor: _stackOffsetFactor,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Popup overlay
            // Uses SlideTransition (via a Transform.translate) driven by _popupAnimation.
            // When showPopup is false the popup is translated up off-screen.
            AnimatedBuilder(
              animation: _popupAnimation,
              builder: (context, child) {
                // progress goes 0..1
                final progress = _popupAnimation.value;
                // translateY from -popupHeight to 0
                final offsetY =
                    -popupHeight * 2 * (1 - progress) + 25 * (1 + progress);
                // background scrim opacity

                final alertText = stateProvider.alertText;
                late double alertTextWidth;

                final textPainter = TextPainter(
                  text: TextSpan(
                    text: alertText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorProvider.textColor,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                );
                textPainter.layout();
                alertTextWidth = textPainter.width;

                final width = alertTextWidth + 64;

                return IgnorePointer(
                  ignoring: progress == 0,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      _togglePopup(false);
                      stateProvider.toggleAlert(show: false);
                    },
                    child: Stack(
                      children: [
                        // Positioned popup container
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: Transform.translate(
                            offset: Offset(0, offsetY),
                            child: Center(
                              child: GlassBlurContainer(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                width: width,
                                height: popupHeight,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                borderRadius: 24,

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: width,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 24,
                                              color:
                                                  colorProvider
                                                      .colorScheme
                                                      .vividColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              alertText,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: colorProvider.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class XButton extends StatelessWidget {
  const XButton({super.key, this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          onPressed!();
        }
      },
      child: Container(
        height: 20,
        color: Colors.red,
        child: Icon(Icons.close, color: cp.textColor),
      ),
    );
  }
}
