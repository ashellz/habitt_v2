import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:provider/provider.dart';

class SelectHabitTypeOptions extends StatefulWidget {
  const SelectHabitTypeOptions({super.key});

  @override
  State<SelectHabitTypeOptions> createState() => _SelectHabitTypeOptionsState();
}

class _SelectHabitTypeOptionsState extends State<SelectHabitTypeOptions> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  void _scrollToSelectedCategory() {
    final categoryProvider = context.read<CategoryProvider>();
    final selectedId = categoryProvider.selectedCategoryId;
    List<Category> categories = categoryProvider.categories;

    if (_scrollController.hasClients && categories.isNotEmpty) {
      int selectedIndex = categories.indexWhere((c) => c.id == selectedId) + 1;
      if (selectedIndex != -1) {
        // Estimate position by multiplying index by item width (assumed 120px)
        double itemWidth = 120.0; // Adjust based on actual category width
        double screenWidth = MediaQuery.of(context).size.width;
        double scrollOffset =
            (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

        // (selectedIndex * itemWidth) --> Gets to the end of the selected category
        // (screenWidth / 2) --> Gets to the middle of the screen
        // (itemWidth / 2) --> Gets to the middle of the category

        _scrollController.animateTo(
          scrollOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ), // Keep within bounds
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 56,
        child: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            SelectHabitTypeWidget(
              type: HabitType.amount,
              selectedType: HabitType.amount,
              onTap: () {
                _scrollToSelectedCategory();
              },
            ),
            SelectHabitTypeWidget(
              type: HabitType.duration,
              selectedType: HabitType.amount,
              onTap: () {
                _scrollToSelectedCategory();
              },
            ),
          ],
        ),
      ),
    );
  }
}
