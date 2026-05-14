import 'package:flutter/material.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_text_field.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class PassphraseDialog extends StatefulWidget {
  const PassphraseDialog({
    super.key,
    required this.controller,
    this.dataExists = false,
    this.displayAlert,
  });

  final TextEditingController controller;
  final bool dataExists;
  final void Function(String message)? displayAlert;

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  late bool _hasText;
  bool _loading = false;

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
    final backupProvider = context.watch<BackupProvider>();

    final desc =
        widget.dataExists
            ? AppLocalizations.of(context)!.enterYourExistingBackupPassphraseToAccessYourData
            : AppLocalizations.of(context)!.thisPassphraseIsUsedForYourDataEncryptionSaveItSecurelyYouWillUseItAgainWhenGettingYourDataOnOtherDevices;

    return OldDefaultDialog(
      title: AppLocalizations.of(context)!.backupPassphrase,
      desc: desc,
      content: DefaultTextField(
        controller: widget.controller,
        title: AppLocalizations.of(context)!.passphrase,
        obscureText: true,
      ),
      leftButtonText: "Cancel",
      rightButtonText: "Done",
      rightButtonLoading: _loading,
      rightButtonEnabled: _hasText,
      rightButtonCallback: () async {
        final passphrase = widget.controller.text;

        setState(() => _loading = true);

        if (widget.dataExists) {
          final isCorrectPassphrase = await backupProvider.checkPassphrase(
            passphrase,
          );

          if (!isCorrectPassphrase && widget.displayAlert != null) {
            widget.displayAlert!(AppLocalizations.of(context)!.incorrectPassphrase);
          } else {
            await backupProvider.setPassphrase(passphrase);
            await backupProvider.performSync(true);
          }
        } else {
          await backupProvider.setPassphrase(passphrase);
        }

        setState(() => _loading = false);

        Navigator.pop(context);
      },
    );
  }
}
