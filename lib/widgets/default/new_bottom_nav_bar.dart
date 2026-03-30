import 'package:cupertino_native/components/tab_bar.dart';
import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class NewBottomNavBar extends StatefulWidget {
  final ValueChanged<int>? onItemTapped;
  final bool supportsLiquidGlass;

  const NewBottomNavBar({
    super.key,
    this.onItemTapped,
    required this.supportsLiquidGlass,
  });

  @override
  State<NewBottomNavBar> createState() => _NewBottomNavBarState();
}

class _NewBottomNavBarState extends State<NewBottomNavBar> {
  int _selectedIndex = 0;

  late final List<NavItemData> _navItems;

  @override
  void initState() {
    super.initState();

    _navItems = [
      NavItemData(
        id: 'home',
        svgPath: "assets/images/new-svg/home.svg",
        defaultLabel: "Home",
      ),
      NavItemData(
        id: 'habits',
        svgPath: "assets/images/new-svg/all-habits.svg",
        defaultLabel: "Habits",
      ),
      NavItemData(
        id: 'calendar',
        svgPath: "assets/images/new-svg/calendar.svg",
        defaultLabel: "Calendar",
      ),
      NavItemData(
        id: 'profile',
        svgPath: "assets/images/new-svg/profile.svg",
        defaultLabel: "Profile",
      ),
    ];

    _selectedIndex = _navItems.indexWhere((item) => item.id == "home");

    if (_selectedIndex == -1) {
      _selectedIndex = 0;
    }
  }

  Widget _buildNavItem(int index, bool isGlassFeel) {
    final cp = context.watch<ColorProvider>();

    final item = _navItems[index];
    // Use hovered index during dragging, otherwise use selected index
    final isHighlighted = _selectedIndex == index;

    Color getItemColor() {
      if (isHighlighted) {
        return cp.main;
      }
      return cp.lightGreyText;
    }

    Color getPillColor() {
      if (isHighlighted) {
        return cp.main.withOpacity(0.1);
      }
      return Colors.transparent;
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            if (_selectedIndex != index) {
              setState(() {
                _selectedIndex = index;
              });
            }
            widget.onItemTapped?.call(index);
          },
          child: TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: ColorTween(end: getPillColor()),
            builder: (context, color, _) {
              return Ink(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: color ?? getPillColor(),
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
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: getItemColor(),
                          fontSize: 12,
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w400,
                          height: 1,
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
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return Expanded(
        child: CNTabBar(
          tint: cp.main,
          height: widget.supportsLiquidGlass ? 86 : 88,
          items: const [
            CNTabBarItem(label: 'Home', icon: CNSymbol('house')),
            CNTabBarItem(label: 'Habits', icon: CNSymbol('square.grid.2x2')),
            CNTabBarItem(label: 'Calendar', icon: CNSymbol('calendar')),
            CNTabBarItem(
              label: 'Profile',
              icon: CNSymbol('person.crop.circle'),
            ),
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

    debugPrint("Using custom Android nav bar");

    return Expanded(
      child: Container(
        height: 95,

        width: double.infinity,
        padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 28),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cp.border, width: 1)),
          color: cp.bg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            _navItems.length,
            (index) => _buildNavItem(index, widget.supportsLiquidGlass),
          ),
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
            width: 28,
            height: 28,
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
