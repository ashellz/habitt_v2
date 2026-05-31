import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class BackupPassphraseDialog extends StatefulWidget {
  const BackupPassphraseDialog({super.key, required this.bp});
  final BackupProvider bp;

  @override
  State<BackupPassphraseDialog> createState() => _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<BackupPassphraseDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final passphrase = _ctrl.text.trim();
    if (passphrase.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await widget.bp.retryRestoreWithPassphrase(passphrase);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.incorrectPassphrase;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.backupPassphrase,
      desc: loc.enterYourExistingBackupPassphraseToAccessYourData,
      primaryButtonLabel: loc.restore,
      primaryButtonEnabled: !_loading,
      secondaryButtonLabel: loc.cancel,
      onPrimaryButtonPressed: _submit,
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
      child: NewDefaultTextField(
        controller: _ctrl,
        obscureText: true,
        autofocus: true,
        hint: loc.passphrase,
        errorText: _error,
        color: cp.isDark ? cp.bg : cp.field,
        showBorder: true,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
