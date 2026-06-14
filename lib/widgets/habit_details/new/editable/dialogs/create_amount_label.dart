import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CreateAmountLabelDialog extends StatefulWidget {
  final String previousSelection;
  final VoidCallback onCancel;
  final Function(String, bool) onConfirm; // returns: label (plural/canonical), wasAdded

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
  late TextEditingController singularController;
  late TextEditingController pluralController;

  @override
  void initState() {
    super.initState();
    singularController = TextEditingController();
    pluralController = TextEditingController();
  }

  @override
  void dispose() {
    singularController.dispose();
    pluralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StateProvider>();
    final loc = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([singularController, pluralController]),
      builder: (context, _) {
        final canCreate =
            singularController.text.trim().isNotEmpty &&
            pluralController.text.trim().isNotEmpty;

        return NewDefaultDialog(
          title: loc.createAmountLabel,
          desc: loc.addANewAmountLabelYouCanReuseLater,
          primaryButtonEnabled: canCreate,
          onSecondaryButtonPressed: widget.onCancel,
          onPrimaryButtonPressed: () {
            final normSingular = sp.normalizeAmountLabel(singularController.text);
            final normPlural = sp.normalizeAmountLabel(pluralController.text);

            if (normSingular.isEmpty || normPlural.isEmpty) {
              return;
            }

            final added = sp.addCustomAmountLabel(normSingular, normPlural);
            widget.onConfirm(
              added ? normPlural : widget.previousSelection,
              added,
            );
          },
          child: Column(
            spacing: 10,
            children: [
              NewDefaultTextField(
                controller: singularController,
                title: loc.singular,
                fontWeight: FontWeight.w500,
                hint: loc.singularHint,
              ),
              NewDefaultTextField(
                controller: pluralController,
                title: loc.plural,
                fontWeight: FontWeight.w500,
                hint: loc.pluralHint,
              ),
            ],
          ),
        );
      },
    );
  }
}
