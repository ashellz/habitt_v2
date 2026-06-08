import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';

class FallbackPinDialog extends StatefulWidget {
  const FallbackPinDialog({
    super.key,
    required this.filePath,
    required this.onSuccess,
    required this.onFailed,
  });

  final String filePath;
  final void Function(String enteredPin) onSuccess;
  final VoidCallback onFailed;

  @override
  State<FallbackPinDialog> createState() => _FallbackPinDialogState();
}

class _FallbackPinDialogState extends State<FallbackPinDialog> {
  final _ctrl = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final pin = _ctrl.text;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await BackupService.importLocalData(
      context: context,
      passphrase: pin,
      filePath: widget.filePath,
    );

    if (!mounted) return;

    if (result == BackupOperationResult.success) {
      Navigator.of(context).pop();
      widget.onSuccess(pin);
    } else if (result == BackupOperationResult.cancelled) {
      Navigator.of(context).pop();
    } else if (result == BackupOperationResult.wrongPassphrase) {
      setState(() {
        _isLoading = false;
        _errorText = AppLocalizations.of(context)!.wrongPin;
        _ctrl.clear();
      });
    } else {
      Navigator.of(context).pop();
      widget.onFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final canConfirm = _ctrl.text.trim().length >= 4 && !_isLoading;

    return NewDefaultDialog(
      title: loc.enterPinToDecrypt,
      primaryButtonLabel: loc.importBackup,
      primaryButtonEnabled: canConfirm,
      onPrimaryButtonPressed: canConfirm ? _onConfirm : null,
      onSecondaryButtonPressed: () => Navigator.of(context).pop(),
      child: NewDefaultTextField(
        controller: _ctrl,
        title: loc.currentPin,
        obscureText: true,
        showBorder: true,
        autofocus: true,
        errorText: _errorText,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
