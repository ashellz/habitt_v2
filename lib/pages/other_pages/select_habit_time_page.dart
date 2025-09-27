import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_localized_category_name.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/faded_list_view.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:provider/provider.dart';

class SelectHabitTimePage extends StatelessWidget {
  const SelectHabitTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final stateProvider = context.watch<StateProvider>();

    final selectedCategory = stateProvider.habitCategoryId;

    Category getCategoryById(int id) {
      final categoryProvider = context.read<CategoryProvider>();
      return categoryProvider.categories.firstWhere((c) => c.id == id);
    }

    final listViewHeight = MediaQuery.of(context).size.height - 293;

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
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SELECT HABIT TIME FOR",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1.2,
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  Text(
                    getLocalizedCategoryName(
                      getCategoryById(selectedCategory),
                      AppLocalizations.of(context)!,
                    ),
                    style: TextStyle(
                      fontSize: 56,
                      height: 0,
                      fontWeight: FontWeight.bold,
                      color: colorProvider.textColor,
                    ),
                  ),
                  TimelinePage(listViewHeight: listViewHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key, required this.listViewHeight});

  final double listViewHeight;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final double hourHeight = 100;

  // Event state
  double startHour = 7.5; // 7:30
  double duration = 1.25; // 1h 15m

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final habitName = context.watch<StateProvider>().nameController.text;

    return FadedListView(
      scrollDirection: Axis.vertical,
      height: widget.listViewHeight,
      children: [
        FadedListView(
          scrollDirection: Axis.vertical,
          height: widget.listViewHeight,
          children: [
            FadedListView(
              height: widget.listViewHeight - 100,
              scrollDirection: Axis.vertical,
              children: [
                SizedBox(
                  height: 24 * hourHeight, // full day
                  child: Stack(
                    children: [
                      // Background hours
                      for (int i = 0; i < 24; i++)
                        Positioned(
                          top: i * hourHeight,
                          left: 0,
                          right: 0,
                          height: hourHeight,
                          child: Row(
                            children: [
                              Text(
                                "${i.toString().padLeft(2, '0')}:00",
                                style: TextStyle(color: cp.mutedTextColor),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: cp.mutedTextColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Draggable + resizable event box
                      Positioned(
                        top: startHour * hourHeight,
                        left: 60,
                        right: 20,
                        height: duration * hourHeight,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cp.colorScheme.darkerStandardColor
                                .withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: cp.colorScheme.vividColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                habitName,
                                style: TextStyle(
                                  color: cp.colorScheme.vividColor,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Drag indicator
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16, top: 16),
                        height: 4,
                        width: 50,
                        decoration: BoxDecoration(
                          color: cp.mutedTextColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: SvgPicture.asset(
                            "assets/images/svg/clock.svg",
                            colorFilter: ColorFilter.mode(
                              cp.textColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "Select time interval",
                            style: TextStyle(
                              color: cp.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            title: "From",

                            controller: TextEditingController(),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "To",
                            controller: TextEditingController(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
