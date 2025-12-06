import 'package:cupertino_native/components/tab_bar.dart';
import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatefulWidget {
  final ValueChanged<int>? onItemTapped;

  const BottomNavBar({super.key, this.onItemTapped});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  late double _dragOffset;
  bool _isDragging = false;

  late final List<NavItemData> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = [
      NavItemData(
        id: 'habits',
        svgPath: "assets/images/svg/habits.svg",
        defaultLabel: "Habits",
      ),
      NavItemData(
        id: 'calendar',
        svgPath: "assets/images/svg/calendar.svg",
        defaultLabel: "Calendar",
      ),
      NavItemData(
        id: 'stats',
        svgPath: "assets/images/svg/stats.svg",
        defaultLabel: "Stats",
      ),
      NavItemData(
        id: 'settings',
        svgPath: "assets/images/svg/settings.svg",
        defaultLabel: "Settings",
      ),
    ];

    _selectedIndex = _navItems.indexWhere(
      (item) => item.defaultLabel == "Habits",
    );

    if (_selectedIndex == -1) {
      _selectedIndex = 0;
    }

    _dragOffset = 0;
  }

  Widget _buildNavItem(int index, bool isGlassFeel) {
    final tp = context.watch<ThemeProvider>();

    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    Color getItemColor() {
      if (!isGlassFeel) {
        if (isSelected) return tp.backgroundColor;
      }
      if (isSelected) {
        return tp.primaryColor;
      }
      return tp.primaryTextColor.withOpacity(0.9);
    }

    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
            _dragOffset = 0;
            _isDragging = false;
          });
        }
        widget.onItemTapped?.call(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ColorMorphingIcon(
              svgPath: item.svgPath,
              targetColor: getItemColor(),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                );
              },
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: getItemColor(),
                  fontSize: 12,
                ),
                child: Padding(
                  key: ValueKey<String>("text_${item.id}"),
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(item.defaultLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final glassFeel = context.watch<PreferencesProvider>().glassFeel;

    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    final double extraPadding = platform == TargetPlatform.android ? 12 : 0;

    if (glassFeel && isIOS) {
      return Expanded(
        child: CNTabBar(
          tint: tp.primaryColor,
          height: 85,
          items: const [
            CNTabBarItem(label: 'Habits', icon: CNSymbol('house.fill')),
            CNTabBarItem(label: 'Calendar', icon: CNSymbol('calendar')),
            CNTabBarItem(label: 'Stats', icon: CNSymbol('chart.bar.fill')),
            CNTabBarItem(label: 'Settings', icon: CNSymbol('gearshape.fill')),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_selectedIndex != index) {
              setState(() {
                _selectedIndex = index;
              });
            }
            widget.onItemTapped?.call(index);
          },
        ),
      );
    }

    // Calculate pill position based on selected index and drag offset
    final itemSpacing = 70.0;
    final basePillPosition =
        _selectedIndex * itemSpacing + (_selectedIndex == 0 ? 2 : 0);
    final pillPosition = basePillPosition + _dragOffset;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _isDragging = true;
          _dragOffset += details.delta.dx;

          // Clamp drag offset symmetrically: allow dragging from first to last item
          final maxOffset = (_navItems.length - 1) * itemSpacing;
          final minClamp = -basePillPosition;
          final maxClamp = maxOffset - basePillPosition;
          _dragOffset = _dragOffset.clamp(minClamp, maxClamp);
        });
      },
      onHorizontalDragEnd: (details) {
        // Find the closest item index
        final currentPosition = basePillPosition + _dragOffset;
        int closestIndex = 0;
        double closestDistance = double.infinity;

        for (int i = 0; i < _navItems.length; i++) {
          final itemPosition = i * itemSpacing + (i == 0 ? 2 : 0);
          final distance = (currentPosition - itemPosition).abs();
          if (distance < closestDistance) {
            closestDistance = distance;
            closestIndex = i;
          }
        }

        // Animate to closest index
        setState(() {
          _selectedIndex = closestIndex;
          _dragOffset = 0;
          _isDragging = false;
        });

        widget.onItemTapped?.call(closestIndex);
      },
      child: GlassBlurContainer(
        padding: const EdgeInsets.all(2),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + extraPadding,
        ),
        height: 64,
        borderRadius: 100,
        color: !glassFeel ? tp.surfaceColor : null,
        borderColor:
            !glassFeel
                ? tp.borderColor
                : tp.isDark
                ? Colors.white24
                : Colors.black26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated pill that goes around the nav bar depending on the selected index
            AnimatedPositioned(
              duration: Duration(milliseconds: _isDragging ? 50 : 300),
              curve: _isDragging ? Curves.easeOut : Curves.easeInOut,
              left: pillPosition,
              child: GlassBlurContainer(
                color: !glassFeel ? tp.primaryButtonBackground : null,
                borderColor:
                    !glassFeel
                        ? tp.surfaceColor
                        : tp.isDark
                        ? Colors.white24
                        : Colors.black12,
                borderRadius: 100,
                width: 92,
                height: 58,
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 280,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_navItems.length, (index) {
                      Widget navItemWidget = _buildNavItem(index, glassFeel);

                      return navItemWidget;
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorMorphingIcon extends StatefulWidget {
  final String svgPath;
  final Color targetColor;

  const _ColorMorphingIcon({required this.svgPath, required this.targetColor});

  @override
  State<_ColorMorphingIcon> createState() => _ColorMorphingIconState();
}

class _ColorMorphingIconState extends State<_ColorMorphingIcon> {
  Color? _oldColor;

  @override
  void didUpdateWidget(covariant _ColorMorphingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetColor != widget.targetColor) {
      _oldColor = oldWidget.targetColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: _oldColor ?? widget.targetColor,
        end: widget.targetColor,
      ),
      duration: const Duration(milliseconds: 200),
      builder: (context, color, _) {
        return SizedBox(
          width: 28,
          height: 28,
          child: SvgPicture.asset(
            widget.svgPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              color ?? widget.targetColor,
              BlendMode.srcIn,
            ),
          ),
        );
      },
    );
  }
}
