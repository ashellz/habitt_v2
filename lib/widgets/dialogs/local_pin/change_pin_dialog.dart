import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';

class ChangePinDialog extends StatefulWidget {
  const ChangePinDialog({
    super.key,
    required this.storage,
    required this.onSuccess,
  });

  final FlutterSecureStorage storage;
  final VoidCallback onSuccess;

  @override
  State<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<ChangePinDialog> {
  final _newCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    setState(() => _isLoading = true);
    final newPin = _newCtrl.text;
    Navigator.of(context).pop();
    await BackupService.saveLocalBackupPin(widget.storage, newPin);
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final canConfirm = _newCtrl.text.length >= 4 && !_isLoading;

    return NewDefaultDialog(
      title: loc.changePin,
      primaryButtonLabel: loc.save,
      primaryButtonEnabled: canConfirm,
      onPrimaryButtonPressed: canConfirm ? _onConfirm : null,
      child: NewDefaultTextField(
        controller: _newCtrl,
        title: loc.newPin,
        obscureText: true,
        showBorder: true,
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
