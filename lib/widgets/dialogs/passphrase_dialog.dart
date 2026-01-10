import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_text_field.dart';

class PassphraseDialog extends StatelessWidget {
  const PassphraseDialog({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      title: "Set Backup Passphrase",
      desc:
          "You will use this passphrase for your data encryption. Save it securely, you will use it again when getting your data on other devices.",
      content: DefaultTextField(
        controller: controller,
        title: "Passphrase",
        obscureText: true,
      ),
      leftButtonText: "Cancel",
      rightButtonText: "Done",
      rightButtonEnabled: controller.text.isNotEmpty,
      rightButtonCallback: () async {
        final result = controller.text;
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
    );
  }
}
