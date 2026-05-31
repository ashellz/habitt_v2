import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/backup/backup_migration_section.dart';
import 'package:habitt/widgets/backup/backup_signed_in_section.dart';
import 'package:habitt/widgets/backup/backup_signed_out_section.dart';
import 'package:habitt/widgets/backup/backup_top_section.dart';
import 'package:habitt/widgets/dialogs/pin_dialog.dart';
import 'package:provider/provider.dart';

class BackupSheet extends StatefulWidget {
  const BackupSheet({super.key, required this.statusOverlay});

  final StatusOverlayPopupController statusOverlay;

  @override
  State<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<BackupSheet> {
  bool _allowPop = false;
  bool _pinDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndShowPinDialog(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bp = context.read<BackupProvider>();
    if (bp.pendingCloudPinEntry && !_pinDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkAndShowPinDialog(),
      );
    }
  }

  void _checkAndShowPinDialog() {
    if (!mounted || _pinDialogShowing) return;
    final bp = context.read<BackupProvider>();
    if (!bp.pendingCloudPinEntry) return;
    final loc = AppLocalizations.of(context)!;
    _pinDialogShowing = true;
    showDialogSheet<void>(
      context: context,
      builder:
          (_) => PinDialog(
            title: loc.unlockForSyncTitle,
            desc: loc.unlockForSyncDesc,
            buttonLabel: loc.unlockAction,
            onConfirm: (pin) => bp.submitCloudPin(pin),
          ),
    ).whenComplete(() => _pinDialogShowing = false);
  }

  void _popSheet() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _popSheet();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackupTopSection(onBack: _popSheet),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        loc.keepHabitsSafe,
                        style: TextStyle(
                          color: cp.greyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!bp.isLoggedIn)
                      BackupSignedOutSection(
                        onAfterSignIn: _checkAndShowPinDialog,
                      )
                    else if (bp.needsMigration)
                      const BackupMigrationSection()
                    else
                      BackupSignedInSection(
                        statusOverlay: widget.statusOverlay,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
