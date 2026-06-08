import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';

class SetLocalPinDialog extends StatefulWidget {
  const SetLocalPinDialog({super.key});

  @override
  State<SetLocalPinDialog> createState() => _SetLocalPinDialogState();
}

class _SetLocalPinDialogState extends State<SetLocalPinDialog> {
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return StatefulBuilder(
      builder: (ctx, setDialogState) {
        void rebuild(_) => setDialogState(() {});

        final canConfirm = _pinCtrl.text.length >= 4;

        return NewDefaultDialog(
          title: loc.setPin,
          desc: loc.setLocalPinDesc,
          primaryButtonLabel: loc.save,
          primaryButtonEnabled: canConfirm,
          onPrimaryButtonPressed:
              canConfirm ? () => Navigator.of(ctx).pop(_pinCtrl.text) : null,
          child: NewDefaultTextField(
            controller: _pinCtrl,
            obscureText: true,
            showBorder: true,
            autofocus: true,
            onChanged: rebuild,
          ),
        );
      },
    );
  }
}
