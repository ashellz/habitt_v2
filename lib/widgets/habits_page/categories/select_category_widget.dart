import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_localized_category_name.dart';
import 'package:provider/provider.dart';

class SelectCategoryWidget extends StatelessWidget {
  const SelectCategoryWidget({super.key, required this.category, this.onTap});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = context.watch<ColorProvider>().colorScheme;
    final categoryProvider = context.watch<CategoryProvider>();
    final int selectedId = categoryProvider.selectedCategoryId;
    final bool isSelected = category.id == selectedId;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.decelerate,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.standardColor
                    : colorScheme.disabledColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.vividColor
                      : colorScheme.standardColor,
              width: 2,
            ),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, isSelected ? 63 : 12, 8),
          height: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.decelerate,
                alignment: isSelected ? Alignment.center : Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isSelected ? 1.0 : 0.5,
                  child: Text(
                    getLocalizedCategoryName(category, localizations),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                curve: Curves.decelerate,
                child:
                    isSelected
                        ? Text(
                          "${category.habits} ${category.habits == 1 ? localizations.habit : localizations.habits}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6C757D),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
