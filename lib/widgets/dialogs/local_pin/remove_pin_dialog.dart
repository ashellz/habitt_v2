import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class RemovePinDialog extends StatelessWidget {
  const RemovePinDialog({
    super.key,
    required this.storage,
    required this.onSuccess,
  });

  final FlutterSecureStorage storage;
  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.read<ColorProvider>();

    return NewDefaultDialog(
      title: loc.removePin,
      desc: loc.removePinDesc,
      primaryButtonLabel: loc.removePin,
      primaryButtonColor: cp.fail,
      onPrimaryButtonPressed: () async {
        Navigator.of(context).pop();
        await BackupService.deleteLocalBackupPin(storage);
        onSuccess();
      },
    );
  }
}
