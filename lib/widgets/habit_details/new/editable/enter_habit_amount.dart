import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/create_amount_label.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/set_amount_label_dialog.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class EnterHabitAmount extends StatelessWidget {
  const EnterHabitAmount({super.key, this.color});

  final Color? color;

  Future<void> _showAmountLabelPicker(
    BuildContext context, {
    String? initialSelection,
  }) async {
    final sp = context.read<StateProvider>();
    final loc = AppLocalizations.of(context)!;

    String selectedLabel =
        initialSelection ??
        _canonicalForPicker(sp, loc, sp.habitAmountLabelController.text);

    if (!context.mounted) return;

    await showDialogSheet(
      context: context,
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
            // always store the plural form, it is resolved to singular/plural
            // for the amount wherever the label is displayed
            final preset = AmountLabelPreset.fromLabel(label);
            sp.habitAmountLabelController.text =
                preset?.localizedPlural(loc) ?? label;
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  /// Maps whatever is typed in the field (singular, plural, localized) to the
  /// canonical label used by the picker so the right pill is preselected.
  String _canonicalForPicker(
    StateProvider sp,
    AppLocalizations loc,
    String text,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return AmountLabelPreset.times.plural;

    final preset = AmountLabelPreset.fromLocalizedLabel(trimmed, loc);
    if (preset != null) return preset.plural;

    final lower = trimmed.toLowerCase();
    for (final custom in sp.customAmountLabels) {
      if (lower == custom.singular || lower == custom.plural) {
        return custom.canonical;
      }
    }
    return trimmed;
  }

  Future<void> _showCreateAmountLabelDialog(
    BuildContext context, {
    required String previousSelection,
  }) async {
    if (!context.mounted) return;

    await showDialogSheet(
      context: context,
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
    final loc = AppLocalizations.of(context)!;

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: AmountProgressInput(
            amount: sp.habitAmount,
            minValue: 1,
            color: color,
          ),
        ),
        Expanded(
          child: NewDefaultTextField(
            color: color,
            controller: sp.habitAmountLabelController,
            title: loc.amountName,
            fontWeight: FontWeight.w500,
            hint: loc.times,
            maxLines: 1,
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
