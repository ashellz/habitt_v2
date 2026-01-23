import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_text_field.dart';

class PassphraseDialog extends StatefulWidget {
  const PassphraseDialog({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.controller.text.isNotEmpty;
    if (next != _hasText) {
      setState(() {
        _hasText = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      title: "Set Backup Passphrase",
      desc:
          "You will use this passphrase for your data encryption. Save it securely, you will use it again when getting your data on other devices.",
      content: DefaultTextField(
        controller: widget.controller,
        title: "Passphrase",
        obscureText: true,
      ),
      leftButtonText: "Cancel",
      rightButtonText: "Done",
      rightButtonEnabled: _hasText,
      rightButtonCallback: () async {
        final result = widget.controller.text;
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
    );
  }
}
