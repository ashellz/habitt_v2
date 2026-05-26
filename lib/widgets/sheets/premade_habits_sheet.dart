import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/premade_habit_catalog.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

enum PremadeHabitSheetMode { create, editFromHabitSheet }

enum PremadeHabitSheetAction { select, skip, clear }

class PremadeHabitSheetResult {
  const PremadeHabitSheetResult._({required this.action, this.template});

  final PremadeHabitSheetAction action;
  final PremadeHabitTemplate? template;

  factory PremadeHabitSheetResult.select(PremadeHabitTemplate template) {
    return PremadeHabitSheetResult._(
      action: PremadeHabitSheetAction.select,
      template: template,
    );
  }

  factory PremadeHabitSheetResult.skip() {
    return const PremadeHabitSheetResult._(
      action: PremadeHabitSheetAction.skip,
    );
  }

  factory PremadeHabitSheetResult.clear() {
    return const PremadeHabitSheetResult._(
      action: PremadeHabitSheetAction.clear,
    );
  }
}

class PremadeHabitsSheet extends StatelessWidget {
  const PremadeHabitsSheet({
    super.key,
    required this.mode,
    this.selectedPremadeHabitType,
  });

  final PremadeHabitSheetMode mode;
  final PremadeHabitType? selectedPremadeHabitType;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

    final rightActionLabel =
        mode == PremadeHabitSheetMode.create ? l10n.skip : l10n.clear;
    final desc =
        mode == PremadeHabitSheetMode.create
            ? l10n.premadeSheetDescCreate
            : l10n.premadeSheetDescEdit;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              _topSection(context, cp, rightActionLabel),
              Text(
                desc,
                style: TextStyle(
                  color: cp.isDark ? cp.lightGreyText : cp.greyText,
                  fontSize: 16,
                ),
              ),
              ...PremadeHabitCatalog.sections.map(
                (section) => _buildCategorySection(context, section),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    PremadeHabitCategorySection section,
  ) {
    final cp = context.watch<ColorProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          section.localizedTitle(l10n),
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              section.habits.map((template) {
                final isSelected = selectedPremadeHabitType == template.type;

                return NewDefaultButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(PremadeHabitSheetResult.select(template));
                  },
                  height: 50,
                  color: isSelected ? cp.main : cp.field,
                  textColor: isSelected ? cp.bg : cp.text,
                  isGradient: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextIcon(template.iconPath, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        template.localizedName(l10n),
                        style: TextStyle(
                          color: isSelected ? cp.bg : cp.text,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _topSection(
    BuildContext context,
    ColorProvider cp,
    String rightActionLabel,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final shouldShowRightButton =
        mode == PremadeHabitSheetMode.create ||
        selectedPremadeHabitType != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 36,
          width: 66,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'assets/images/new-svg/back.svg',
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
          ),
        ),
        Text(
          l10n.premadeSheetTitle,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        shouldShowRightButton
            ? NewDefaultButton.secondarySmall(
              width: null,
              label: rightActionLabel,
              onPressed: () {
                final result =
                    mode == PremadeHabitSheetMode.create
                        ? PremadeHabitSheetResult.skip()
                        : PremadeHabitSheetResult.clear();
                Navigator.of(context).pop(result);
              },
            )
            : const SizedBox(width: 66),
      ],
    );
  }
}
