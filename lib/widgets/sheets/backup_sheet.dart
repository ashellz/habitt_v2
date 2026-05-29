import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:habitt/widgets/sheets/backup_history_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class BackupSheet extends StatefulWidget {
  const BackupSheet({super.key, required this.statusOverlay});

  final StatusOverlayPopupController statusOverlay;

  @override
  State<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<BackupSheet> {
  bool _allowPop = false;
  final _passphraseController = TextEditingController();
  bool _migrationLoading = false;
  bool _signingIn = false;

  void _popSheet() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  String _formatLastSync(DateTime? lastSync, AppLocalizations loc) {
    if (lastSync == null) return loc.neverBackedUp;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final syncDay = DateTime(lastSync.year, lastSync.month, lastSync.day);

    final hour = lastSync.hour.toString().padLeft(2, '0');
    final minute = lastSync.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (syncDay == today) return loc.backupDateToday(time);
    if (syncDay == yesterday) return loc.backupDateYesterday(time);

    final months = [
      loc.monthJan,
      loc.monthFeb,
      loc.monthMar,
      loc.monthApr,
      loc.monthMay,
      loc.monthJun,
      loc.monthJul,
      loc.monthAug,
      loc.monthSep,
      loc.monthOct,
      loc.monthNov,
      loc.monthDec,
    ];
    return loc.backupDateOther(
      months[lastSync.month - 1],
      '${lastSync.day}',
      time,
    );
  }

  Future<void> _handleMigrate(BackupProvider bp) async {
    final passphrase = _passphraseController.text.trim();
    if (passphrase.isEmpty) return;

    setState(() => _migrationLoading = true);
    final success = await bp.migrateFromLegacy(passphrase);
    if (mounted) {
      setState(() => _migrationLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bp.lastError ?? AppLocalizations.of(context)!.migrationFailed,
            ),
          ),
        );
      } else {
        _passphraseController.clear();
      }
    }
  }

  void _openBackupHistory(BuildContext context, ColorProvider cp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => const BackupHistorySheet(),
    );
  }
  /*
  void _showPinDialog(
    BuildContext context, {
    required String title,
    required String desc,
    required String buttonLabel,
    Color? buttonColor,
    required Future<bool> Function(String pin) onConfirm,
  }) {
    showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => _PinDialog(
            title: title,
            desc: desc,
            buttonLabel: buttonLabel,
            buttonColor: buttonColor,
            onConfirm: onConfirm,
          ),
    );
  } */

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
                    _topSection(context, cp, loc),
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
                      _signedOutState(context, cp, bp, loc)
                    else if (bp.needsMigration)
                      _migrationState(context, cp, bp, loc)
                    else
                      _signedInState(context, cp, bp, loc),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Sign-in state -----------------------------------------------------

  Widget _signedOutState(
    BuildContext context,
    ColorProvider cp,
    BackupProvider bp,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: cp.field,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: cp.border),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: GestureDetector(
          onTap:
              _signingIn
                  ? null
                  : () async {
                    setState(() => _signingIn = true);
                    await bp.signIn(context);
                    if (mounted) setState(() => _signingIn = false);
                  },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.transparent,
            child: Row(
              spacing: 12,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: SvgPicture.asset(
                    'assets/images/new-svg/google.svg',
                    colorFilter: ColorFilter.mode(
                      cp.lightGreyText,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  loc.signInWithGoogle,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_signingIn)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cp.text,
                    ),
                  )
                else
                  RotatedBox(
                    quarterTurns: 2,
                    child: SvgPicture.asset(
                      'assets/images/new-svg/back.svg',
                      colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Migration state ---------------------------------------------------

  Widget _migrationState(
    BuildContext context,
    ColorProvider cp,
    BackupProvider bp,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: cp.field,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: cp.border),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.migrateToSeamlessSync,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.legacyBackupDescription,
                  style: TextStyle(
                    color: cp.greyText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                NewDefaultTextField(
                  controller: _passphraseController,
                  obscureText: true,
                  color: cp.habitBg,
                ),
                const SizedBox(height: 16),
                NewDefaultButton.primary(
                  width: double.infinity,
                  onPressed: () => _handleMigrate(bp),
                  label: loc.migrate,
                  isLoading: _migrationLoading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _confirmDiscardLegacy(context, bp, loc),
              child: Text(
                loc.forgotPassphrase,
                style: TextStyle(
                  color: cp.greyText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => _confirmSignOut(context, bp, loc),
              child: Text(
                loc.disconnectGoogle,
                style: TextStyle(
                  color: cp.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscardLegacy(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.discardOldBackupTitle,
            desc: loc.discardOldBackupDesc,
            primaryButtonLabel: loc.discardOldBackupConfirm,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      await bp.discardLegacyBackup();
    }
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.logOut,
            desc: loc.logOutDesc,
            primaryButtonLabel: loc.logOut,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      await bp.signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.deleteAccount,
            desc: loc.deleteAccountDesc,
            primaryButtonLabel: loc.delete,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      final success = await bp.deleteAccount();
      if (!mounted) return;
      if (success) {
        widget.statusOverlay.show(
          context: context,
          cp: cp,
          title: loc.accountDeletedSuccessfully,
          isError: false,
        );
        Navigator.of(context).pop();
      } else {
        widget.statusOverlay.show(
          context: context,
          cp: cp,
          title: loc.accountDeletionFailed(bp.lastError ?? ''),
          isError: true,
        );
      }
    }
  }

  // --- Signed-in state ---------------------------------------------------

  Widget _signedInState(
    BuildContext context,
    ColorProvider cp,
    BackupProvider bp,
    AppLocalizations loc,
  ) {
    final isSyncing = bp.syncState == SyncState.syncing;
    final lastSyncText = _formatLastSync(bp.lastSyncTime, loc);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /*
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: ShapeDecoration(
              color: cp.habitBg,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: cp.border),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.pinProtection,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                NewDefaultSwitch(
                  value: bp.isPinEnabled,
                  onChanged: (v) {
                    if (v) {
                      _showPinDialog(
                        context,
                        title: loc.setPinTitle,
                        desc: loc.setPinDesc,
                        buttonLabel: loc.enable,
                        onConfirm: (pin) => bp.enablePin(pin),
                      );
                    } else {
                      _showPinDialog(
                        context,
                        title: loc.disablePinTitle,
                        desc: loc.disablePinDesc,
                        buttonLabel: loc.disable,
                        buttonColor: cp.error,
                        onConfirm: (pin) => bp.disablePin(pin),
                      );
                    }
                  },
                ),
              ],
            ),
          ), */
          NewDefaultButton.secondary(
            onPressed: isSyncing ? () {} : () => bp.performSync(true),
            label: loc.backUpNow,
            isLoading: isSyncing,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              loc.lastSynced(lastSyncText),
              style: TextStyle(
                color: bp.syncState == SyncState.error ? cp.error : cp.greyText,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (bp.syncState == SyncState.error && bp.lastError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                bp.lastError!,
                style: TextStyle(
                  color: cp.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

          const SizedBox(height: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: ShapeDecoration(
                  color: cp.habitBg,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: cp.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.autoBackup,
                            style: TextStyle(
                              color: cp.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          NewDefaultSwitch(
                            value: bp.isAutoSyncEnabled,
                            onChanged: (v) => bp.setAutoSyncEnabled(v),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: cp.border, height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.transparent,
                      child: ProfileOption(
                        cp: cp,
                        text: loc.restoreFromBackup,
                        onTap: () => _openBackupHistory(context, cp),
                      ),
                    ),
                    Divider(color: cp.border, height: 1),
                    GestureDetector(
                      onTap: () => _confirmSignOut(context, bp, loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.transparent,
                        child: Row(
                          spacing: 12,
                          children: [
                            Text(
                              loc.logOut,
                              style: TextStyle(
                                color: cp.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            SvgPicture.asset(
                              'assets/images/new-svg/log-out.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                cp.error,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(color: cp.border, height: 1),
                    GestureDetector(
                      onTap: () => _confirmDeleteAccount(context, bp, loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.transparent,
                        child: Row(
                          spacing: 12,
                          children: [
                            Text(
                              loc.deleteAccount,
                              style: TextStyle(
                                color: cp.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            SvgPicture.asset(
                              'assets/images/new-svg/trash.svg',
                              width: 19,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                cp.error,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Top bar -----------------------------------------------------------

  Widget _topSection(
    BuildContext context,
    ColorProvider cp,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _popSheet,
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              color: Colors.transparent,
              height: 36,
              width: 66 + 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  'assets/images/new-svg/back.svg',
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              loc.backupAndSync,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 66 + 16),
        ],
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.title,
    required this.desc,
    required this.buttonLabel,
    required this.onConfirm,
  }) : buttonColor = null;

  final String title;
  final String desc;
  final String buttonLabel;
  final Color? buttonColor;
  final Future<bool> Function(String pin) onConfirm;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _ctrl.text.trim();
    final loc = AppLocalizations.of(context)!;
    if (pin.length < 4) {
      setState(() => _error = loc.pinTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await widget.onConfirm(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = loc.pinIncorrect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40 + keyboardInset),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cp.isDark ? cp.habitBg : cp.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.desc,
                style: TextStyle(color: cp.greyText, fontSize: 16),
              ),
              const SizedBox(height: 20),
              NewDefaultTextField(
                controller: _ctrl,
                obscureText: true,
                autofocus: true,
                hint: loc.pinHint,
                errorText: _error,
                color: cp.isDark ? cp.bg : cp.field,
                showBorder: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NewDefaultButton.secondary(
                      onPressed: () => Navigator.of(context).pop(false),
                      label: loc.cancel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NewDefaultButton.primary(
                      onPressed: _submit,
                      label: widget.buttonLabel,
                      isLoading: _loading,
                      color: widget.buttonColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
