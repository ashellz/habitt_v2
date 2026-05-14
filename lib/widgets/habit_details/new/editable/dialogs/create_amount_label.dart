import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CreateAmountLabelDialog extends StatefulWidget {
  final String previousSelection;
  final VoidCallback onCancel;
  final Function(String, bool) onConfirm; // returns: label, wasAdded

  const CreateAmountLabelDialog({
    super.key,
    required this.previousSelection,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<CreateAmountLabelDialog> createState() =>
      _CreateAmountLabelDialogState();
}

class _CreateAmountLabelDialogState extends State<CreateAmountLabelDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StateProvider>();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return NewDefaultDialog(
          title: AppLocalizations.of(context)!.createAmountLabel,
          desc: AppLocalizations.of(context)!.addANewAmountLabelYouCanReuseLater,
          primaryButtonEnabled: value.text.trim().isNotEmpty,
          onSecondaryButtonPressed: widget.onCancel,
          onPrimaryButtonPressed: () {
            final normalized = sp.normalizeAmountLabel(controller.text);
            if (normalized.isEmpty) {
              return;
            }

            final added = sp.addCustomAmountLabel(normalized);
            widget.onConfirm(
              added ? normalized : widget.previousSelection,
              added,
            );
          },
          child: NewDefaultTextField(
            controller: controller,
            title: AppLocalizations.of(context)!.amountName,
            fontWeight: FontWeight.w500,
            hint: AppLocalizations.of(context)!.amountName,
          ),
        );
      },
    );
  }
}
