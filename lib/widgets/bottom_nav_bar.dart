import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/glass_container.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatefulWidget {
  final ValueChanged<int>? onItemTapped;

  const BottomNavBar({super.key, this.onItemTapped});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

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
  }

  Widget _buildNavItem(int index) {
    final colorProvider = context.watch<ColorProvider>();

    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
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
            SizedBox(
              width: 28,
              height: 28,
              child: SvgPicture.asset(
                item.svgPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? colorProvider.colorScheme.vividColor
                      : colorProvider.textColor.withOpacity(0.9),
                  BlendMode.srcIn,
                ),
              ),
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
              child: DefaultTextStyle(
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected
                          ? colorProvider.colorScheme.vividColor
                          : colorProvider.textColor.withOpacity(0.9),
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
    final canEdit = context.watch<StateProvider>().canEditCalendar;

    final colorProvider = context.watch<ColorProvider>();

    return GlassContainer(
      padding: const EdgeInsets.all(2),
      height: 64,
      borderRadius: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated pill that goes around the nav bar depending on the selected index
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _selectedIndex * 70 + (_selectedIndex == 0 ? 2 : 0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: canEdit ? 0 : 1,
              child: GlassContainer(borderRadius: 100, width: 92, height: 58),
            ),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),

            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                axisAlignment: 0.0,
                child: FadeTransition(
                  opacity: animation,
                  child: Center(child: child),
                ),
              );
            },
            child: Padding(
              key: ValueKey<bool>(canEdit),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child:
                  canEdit
                      ? Row(
                        children: [
                          Text(
                            "Editing",
                            style: TextStyle(
                              color: colorProvider.textColor,
                              decoration: TextDecoration.none,
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              fontFamily: "Poppins",
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset(
                              "assets/images/icons/pencil.png",
                            ),
                          ),
                        ],
                      )
                      : SizedBox(
                        width: 280,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_navItems.length, (index) {
                            Widget navItemWidget = _buildNavItem(index);

                            return navItemWidget;
                          }),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
