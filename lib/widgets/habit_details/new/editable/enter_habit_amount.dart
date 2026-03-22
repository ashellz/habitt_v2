import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/create_amount_label.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/set_amount_label.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class EnterHabitAmount extends StatelessWidget {
  const EnterHabitAmount({super.key});

  Future<void> _showAmountLabelPicker(
    BuildContext context, {
    String? initialSelection,
  }) async {
    final cp = context.read<ColorProvider>();
    final sp = context.read<StateProvider>();

    String selectedLabel =
        initialSelection ??
        (sp.habitAmountLabelController.text.trim().isNotEmpty
            ? sp.normalizeAmountLabel(sp.habitAmountLabelController.text)
            : 'reps');

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SetAmountLabelDialog(
          initialLabel: selectedLabel,
          onAddPressed: () {
            Navigator.of(sheetContext).pop();
            _showCreateAmountLabelDialog(
              context,
              previousSelection: selectedLabel,
            );
          },
          onConfirm: (label) {
            sp.habitAmountLabelController.text = label;
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _showCreateAmountLabelDialog(
    BuildContext context, {
    required String previousSelection,
  }) async {
    final cp = context.read<ColorProvider>();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (sheetContext) {
        return CreateAmountLabelDialog(
          previousSelection: previousSelection,
          onCancel: () {
            Navigator.of(sheetContext).pop();
            _showAmountLabelPicker(
              context,
              initialSelection: previousSelection,
            );
          },
          onConfirm: (label, wasAdded) {
            Navigator.of(sheetContext).pop();
            _showAmountLabelPicker(context, initialSelection: label);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();

    return Row(
      spacing: 10,
      children: [
        Expanded(child: AmountProgressInput(amount: sp.habitAmount)),
        Expanded(
          child: NewDefaultTextField(
            controller: sp.habitAmountLabelController,
            title: "Amount name",
            fontWeight: FontWeight.w500,
            hint: "Amount name",
            suffix: GestureDetector(
              onTap: () => _showAmountLabelPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SvgPicture.asset(
                  "assets/images/new-svg/dropdown.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
