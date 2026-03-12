import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class SelectHabitDayPeriod extends StatefulWidget {
  const SelectHabitDayPeriod({super.key});

  @override
  State<SelectHabitDayPeriod> createState() => _SelectHabitDayPeriodState();
}

class _SelectHabitDayPeriodState extends State<SelectHabitDayPeriod>
    with SingleTickerProviderStateMixin {
  bool categoriesExpanded = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Animation<double> _categoryFadeAnimation(int index, int totalCount) {
    if (totalCount <= 0) {
      return const AlwaysStoppedAnimation(1);
    }

    const fadeWindowStart = 0.2;
    const fadeWindowEnd = 0.95;
    final step = (fadeWindowEnd - fadeWindowStart) / totalCount;
    final start = fadeWindowStart + (step * index);
    final end = (start + (step * 0.85)).clamp(0.0, 1.0);

    return CurvedAnimation(
      parent: _expandController,
      curve: Interval(start, end, curve: Curves.easeInOut),
    );
  }

  void toggleExpansion() {
    final shouldExpand =
        _expandController.status == AnimationStatus.dismissed ||
        _expandController.status == AnimationStatus.reverse;

    setState(() {
      categoriesExpanded = shouldExpand;
    });

    if (shouldExpand) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final chooseCategoriesList = categoryProvider.categories;
    final stateProvider = context.watch<StateProvider>();

    final cp = context.watch<ColorProvider>();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 23.0),
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Container(
                  color: cp.field.darken(5),
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _expandAnimation.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 23),
                        for (int i = 0; i < chooseCategoriesList.length; i++)
                          FadeTransition(
                            opacity: _categoryFadeAnimation(
                              i,
                              chooseCategoriesList.length,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 20.0,
                                  top: 12,
                                  bottom:
                                      i == chooseCategoriesList.length - 1
                                          ? 12
                                          : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    stateProvider.habitCategoryId = i;
                                    toggleExpansion();
                                  },
                                  child: Text(
                                    chooseCategoriesList[i].name,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: cp.text,
                                      fontSize: 16,

                                      fontWeight:
                                          i == stateProvider.habitCategoryId
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () => toggleExpansion(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cp.field,
              borderRadius: BorderRadius.circular(24),
            ),
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  chooseCategoriesList[stateProvider.habitCategoryId].name,
                  style: TextStyle(fontSize: 16, color: cp.text),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: 0.5).animate(
                    CurvedAnimation(
                      parent: _expandController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: SvgPicture.asset("assets/images/new-svg/dropdown.svg"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
