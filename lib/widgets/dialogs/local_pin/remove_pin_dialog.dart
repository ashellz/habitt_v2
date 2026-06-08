import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class RemovePinDialog extends StatefulWidget {
  const RemovePinDialog({
    super.key,
    required this.storage,
    required this.onSuccess,
  });

  final FlutterSecureStorage storage;
  final VoidCallback onSuccess;

  @override
  State<RemovePinDialog> createState() => _RemovePinDialogState();
}

class _RemovePinDialogState extends State<RemovePinDialog> {
  final _ctrl = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final stored = await BackupService.readLocalBackupPin(widget.storage);
    if (!mounted) return;
    if (_ctrl.text != stored) {
      setState(() {
        _isLoading = false;
        _errorText = AppLocalizations.of(context)!.pinIncorrect;
      });
      return;
    }
    Navigator.of(context).pop();
    await BackupService.deleteLocalBackupPin(widget.storage);
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.read<ColorProvider>();
    final canConfirm = _ctrl.text.isNotEmpty && !_isLoading;

    return NewDefaultDialog(
      title: loc.removePin,
      primaryButtonLabel: loc.removePin,
      primaryButtonEnabled: canConfirm,
      primaryButtonColor: cp.fail,
      onPrimaryButtonPressed: canConfirm ? _onConfirm : null,
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
