import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
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

class _SetAmountLabelDialogState extends State<SetAmountLabelDialog>
    with TickerProviderStateMixin {
  late String selectedLabel;
  OverlayEntry? _deleteFailedOverlayEntry;
  Timer? _deleteFailedOverlayTimer;
  AnimationController? _deleteFailedOverlayController;

  @override
  void initState() {
    super.initState();
    selectedLabel = widget.initialLabel;
  }

  @override
  void dispose() {
    _removeDeleteFailedOverlay();
    super.dispose();
  }

  void _removeDeleteFailedOverlay() {
    _deleteFailedOverlayTimer?.cancel();
    _deleteFailedOverlayTimer = null;
    _deleteFailedOverlayEntry?.remove();
    _deleteFailedOverlayEntry = null;
    _deleteFailedOverlayController?.dispose();
    _deleteFailedOverlayController = null;
  }

  void _showDeleteFailedOverlay({
    required BuildContext context,
    required ColorProvider cp,
  }) {
    _removeDeleteFailedOverlay();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay.mounted == false) {
      return;
    }

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _deleteFailedOverlayController = controller;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final topPadding = MediaQuery.viewPaddingOf(overlayContext).top;
        return Positioned(
          top: topPadding + 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.94,
                      end: 1,
                    ).animate(animation),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: ShapeDecoration(
                          color: cp.field,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: cp.fail.withValues(alpha: 0.35),
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: SvgPicture.asset(
                                "assets/images/new-svg/skipped.svg",
                              ),
                            ),
                            const Text(
                              "This label can't be deleted",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _deleteFailedOverlayEntry = entry;
    overlay.insert(entry);
    controller.forward();

    _deleteFailedOverlayTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted || _deleteFailedOverlayController != controller) {
        return;
      }

      controller.reverse().whenComplete(() {
        if (!mounted || _deleteFailedOverlayController != controller) {
          return;
        }
        _removeDeleteFailedOverlay();
      });
    });
  }

  Future<void> _showDeleteLabelDialog({
    required BuildContext context,
    required StateProvider sp,
    required ColorProvider cp,
    required String label,
  }) async {
    await showDialogSheet(
      context: context,
      builder: (dialogContext) {
        return NewDefaultDialog(
          title: "Delete '$label'?",
          desc: "This amount label will be removed.",
          primaryButtonLabel: "Delete",
          primaryButtonColor: cp.fail,
          onPrimaryButtonPressed: () {
            final removed = sp.removeCustomAmountLabel(label);
            Navigator.of(dialogContext).pop();

            if (removed && mounted && selectedLabel == label) {
              final labels = sp.allAmountLabels;
              setState(() {
                selectedLabel = labels.isNotEmpty ? labels.first : 'times';
              });
            }

            if (!removed && mounted) {
              _showDeleteFailedOverlay(context: context, cp: cp);
            }
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
    final labels = sp.allAmountLabels;
    final customLabels = sp.customAmountLabels.toSet();
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
          final isDeletable = customLabels.contains(item);
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
                onLongPress: () {
                  if (!isDeletable) {
                    _showDeleteFailedOverlay(context: context, cp: cp);
                    return;
                  }

                  _showDeleteLabelDialog(
                    context: context,
                    sp: sp,
                    cp: cp,
                    label: item,
                  );
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
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                child: Text(
                  item,
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
