import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_localized_category_name.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

class NewSelectCategoryWidget extends StatelessWidget {
  const NewSelectCategoryWidget({
    super.key,
    required this.category,
    this.onTap,
    required this.standardColor,
    this.selectedDay,
    this.isFirst = false,
    this.isLast = false,
  });

  final Category category;
  final VoidCallback? onTap;
  final bool standardColor;
  final DateTime? selectedDay;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final int selectedId = categoryProvider.selectedCategoryId;
    final bool isSelected = category.id == selectedId;

    return Padding(
      padding: EdgeInsets.only(
        right: isLast ? 16.0 : 8.0,
        left: isFirst ? 16.0 : 0,
      ),
      child: NewDefaultButton(
        onPressed: () => onTap?.call(),
        color:
            isSelected
                ? cp.main
                : standardColor
                ? cp.habitBg
                : cp.bg,
        child: Text(
          getLocalizedCategoryName(category, localizations),
          style: TextStyle(
            color: isSelected ? cp.bg : cp.lightGreyText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
