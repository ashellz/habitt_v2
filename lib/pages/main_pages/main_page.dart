import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.bg,
      body: SafeArea(
        child: Column(
          spacing: 20,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: MainPageTopSection(),
            ),
            Expanded(
              child: Container(
                color: cp.habitBg,
                child: Column(children: [NewCategoriesList()]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
