import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class DeleteLabelDialog extends StatelessWidget {
  const DeleteLabelDialog({
    super.key,
    required this.mounted,
    required StatusOverlayPopupController statusOverlay,
    required this.dialogContext,
    required this.label,
    required this.selectedLabel,
    required this.onSelectedLabelChanged,
  }) : _statusOverlay = statusOverlay;

  final bool mounted;
  final StatusOverlayPopupController _statusOverlay;
  final BuildContext dialogContext;
  final String label;
  final String selectedLabel;
  final ValueChanged<String> onSelectedLabelChanged;

  @override
  Widget build(BuildContext context) {
    final cp = context.read<ColorProvider>();
    final sp = context.read<StateProvider>();

    return NewDefaultDialog(
      title: "Delete '$label'?",
      desc: "This amount label will be removed.",
      primaryButtonLabel: "Delete",
      primaryButtonColor: cp.fail,
      onPrimaryButtonPressed: () {
        final removed = sp.removeCustomAmountLabel(label);
        Navigator.of(dialogContext).pop();

        if (!mounted) {
          return;
        }

        if (removed && selectedLabel == label) {
          final labels = sp.allAmountLabels;
          onSelectedLabelChanged(labels.isNotEmpty ? labels.first : 'times');
        }

        _statusOverlay.show(
          context: context,
          cp: cp,
          title: removed ? 'Amount label deleted' : "This label can't be deleted",
          isError: !removed,
        );
      },
    );
  }
}