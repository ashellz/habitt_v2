import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const bottomNavBar = 86;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 2, child: Container(color: cp.bg)),
              Expanded(child: Container(color: cp.habitBg)),
            ],
          ),
          ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: MainPageTopSection(),
              ),
              SizedBox(height: 20),
              Container(
                color: cp.habitBg,
                child: Column(
                  children: [
                    NewCategoriesList(),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: NewHabits(),
                    ),
                    SizedBox(height: bottomPadding + bottomNavBar),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
