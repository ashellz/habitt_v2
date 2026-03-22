import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

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

class _SetAmountLabelDialogState extends State<SetAmountLabelDialog> {
  late String selectedLabel;

  @override
  void initState() {
    super.initState();
    selectedLabel = widget.initialLabel;
  }

  List<Widget> _buildLabelRows({
    required BuildContext context,
    required StateProvider sp,
    required ColorProvider cp,
  }) {
    final labels = sp.allAmountLabels;
    final rows = <Widget>[];

    // Add button as the last "item"
    final items = [...labels, 'ADD_BUTTON'];

    // Split items into rows of max 3
    for (int i = 0; i < items.length; i += 3) {
      final rowItems = items.sublist(i, (i + 3).clamp(0, items.length));

      final rowChildren = <Widget>[];

      for (int j = 0; j < rowItems.length; j++) {
        final item = rowItems[j];

        if (item == 'ADD_BUTTON') {
          rowChildren.add(
            Expanded(
              child: NewDefaultButton.secondarySmall(
                height: 40,
                onPressed: widget.onAddPressed,
                label: "Add",
                prefix: SvgPicture.asset(
                  "assets/images/new-svg/add.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          );
        } else {
          final labelWidget = SizedBox(
            height: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
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
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                child: Text(
                  item,
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

      // If last row has only 1 label (not button), add empty spacer to fill the space
      if (rowItems.length == 1) {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(Expanded(child: SizedBox.shrink()));
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(Expanded(child: SizedBox.shrink()));
      } else if (rowItems.length == 2) {
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

    return NewDefaultDialog(
      title: "Set amount label",
      desc: "What are you counting for this habit?",
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
