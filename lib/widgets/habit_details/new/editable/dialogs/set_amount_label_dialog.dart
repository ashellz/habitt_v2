import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/delete_label_dialog.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SetAmountLabelDialog extends StatefulWidget {
  final String initialLabel;
  final VoidCallback onAddPressed;
  final Function(String) onConfirm;

  const SetAmountLabelDialog({
    super.key,
    required this.initialLabel,
    required this.onAddPressed,
    required this.onConfirm,
  });

  @override
  State<SetAmountLabelDialog> createState() => _SetAmountLabelDialogState();
}

class _SetAmountLabelDialogState extends State<SetAmountLabelDialog>
    with TickerProviderStateMixin {
  late String selectedLabel;
  late final StatusOverlayPopupController _statusOverlay;

  @override
  void initState() {
    super.initState();
    selectedLabel = widget.initialLabel;
    _statusOverlay = StatusOverlayPopupController(vsync: this);
  }

  @override
  void dispose() {
    _statusOverlay.dispose();
    super.dispose();
  }

  Future<void> _showDeleteLabelDialog({
    required BuildContext context,
    required String label,
  }) async {
    await showDialogSheet(
      context: context,
      builder: (dialogContext) {
        return DeleteLabelDialog(
          mounted: mounted,
          statusOverlay: _statusOverlay,
          dialogContext: dialogContext,
          label: label,
          selectedLabel: selectedLabel,
          onSelectedLabelChanged: (updatedLabel) {
            setState(() {
              selectedLabel = updatedLabel;
            });
          },
        );
      },
    );
  }

  List<Widget> _buildLabelRows({
    required BuildContext context,
    required StateProvider sp,
    required ColorProvider cp,
  }) {
    final loc = AppLocalizations.of(context)!;
    final labels = sp.allAmountLabels;
    final customLabels = sp.customAmountLabels.map((l) => l.canonical).toSet();
    final rows = <Widget>[];

    // Add button as the last "item"
    final items = [...labels, 'ADD_BUTTON'];

    // Split items into rows of max 2
    for (int i = 0; i < items.length; i += 2) {
      final rowItems = items.sublist(i, (i + 2).clamp(0, items.length));

      final rowChildren = <Widget>[];

      for (int j = 0; j < rowItems.length; j++) {
        final item = rowItems[j];

        if (item == 'ADD_BUTTON') {
          rowChildren.add(
            Expanded(
              child: NewDefaultButton.secondarySmall(
                height: 40,
                onPressed: widget.onAddPressed,
                label: loc.add,
                prefix: SvgPicture.asset(
                  "assets/images/new-svg/add.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          );
        } else {
          final isDeletable = customLabels.contains(item);
          final preset = AmountLabelPreset.fromLabel(item);
          final displayText =
              preset != null ? preset.localizedPlural(loc) : item;
          final labelWidget = SizedBox(
            height: 40,
            child: Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color:
                        selectedLabel == item
                            ? cp.main.withValues(alpha: 0.2)
                            : cp.border,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                color:
                    selectedLabel == item
                        ? cp.main.withValues(alpha: 0.1)
                        : Colors.transparent,
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedLabel = item;
                  });
                },
                style: ButtonStyle(
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  elevation: const WidgetStatePropertyAll(0),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (!states.contains(WidgetState.pressed)) {
                      return null;
                    }
                    return cp.bg.withValues(alpha: 0.2);
                  }),
                  backgroundColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    isDeletable
                        ? const EdgeInsets.only(left: 8, right: 8)
                        : const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                child:
                    isDeletable
                        ? Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                displayText,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: cp.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  () => _showDeleteLabelDialog(
                                    context: context,
                                    label: item,
                                  ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: cp.text.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        )
                        : Text(
                          displayText,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: cp.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
            ),
          );

          rowChildren.add(Expanded(child: labelWidget));
        }

        // Add spacing between items in the row
        if (j < rowItems.length - 1) {
          rowChildren.add(const SizedBox(width: 8));
        }
      }

      // If last row has only 1 item, add empty spacer to fill the second column
      if (rowItems.length == 1) {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(Expanded(child: SizedBox.shrink()));
      }

      rows.add(Row(children: rowChildren));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.setAmountLabel,
      desc: loc.whatAreYouCountingForThisHabit,
      onPrimaryButtonPressed: () {
        widget.onConfirm(selectedLabel);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: _buildLabelRows(context: context, sp: sp, cp: cp),
      ),
    );
  }
}
