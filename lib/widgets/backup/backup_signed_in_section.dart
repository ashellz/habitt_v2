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
import 'package:habitt/widgets/dialogs/pin_dialog.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:habitt/widgets/sheets/backup_history_sheet.dart';
import 'package:habitt/widgets/sheets/local_backup_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

// ignore: must_be_immutable
class BackupSignedInSection extends StatefulWidget {
  const BackupSignedInSection({
    super.key,
    required this.statusOverlay,
    this.isICloud = false,
  });

  final StatusOverlayPopupController statusOverlay;
  final bool isICloud;

  @override
  State<BackupSignedInSection> createState() => _BackupSignedInSectionState();
}

class _BackupSignedInSectionState extends State<BackupSignedInSection> {
  bool _localSyncLoading = false;

  String? _localizedSyncError(BackupProvider bp, AppLocalizations loc) {
    if (bp.syncState != SyncState.error || bp.lastError == null) return null;
    final raw = bp.lastError!.toLowerCase();
    if (raw.contains('quota') ||
        raw.contains('code=-1003') ||
        raw.contains('ckerrordomain:25')) {
      return loc.syncFailedICloudQuota;
    }
    if (raw == 'icloud_unavailable') return loc.syncFailedICloud;
    return widget.isICloud ? loc.syncFailedICloud : loc.syncFailedDrive;
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

  void _openBackupHistory(BuildContext context, ColorProvider cp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => const BackupHistorySheet(),
    );
  }

  _showLocalBackupSheet() {
    final cp = context.read<ColorProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => const LocalBackupSheet(),
    );
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

  Future<void> _confirmDisconnectICloud(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.disconnectICloud,
            desc: loc.logOutDesc,
            primaryButtonLabel: loc.disconnectICloud,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      await bp.deactivateICloud();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

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
          (ctx) => PinDialog(
            title: title,
            desc: desc,
            buttonLabel: buttonLabel,
            buttonColor: buttonColor,
            onConfirm: onConfirm,
          ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
    ColorProvider cp,
  ) async {
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
      if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;
    final isBackingUp = bp.isBackingUp;
    final isSyncing =
        _localSyncLoading ||
        (bp.syncState == SyncState.syncing && !isBackingUp);
    final lastSyncText = _formatLastSync(bp.lastSyncTime, loc);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: NewDefaultButton.secondary(
                  enabled: !isSyncing,
                  onPressed:
                      (isSyncing || isBackingUp) ? null : () => bp.backupNow(),
                  label: loc.backUpNow,
                  isLoading: isBackingUp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NewDefaultButton.primary(
                  enabled: !isBackingUp,
                  onPressed:
                      (isSyncing || isBackingUp)
                          ? null
                          : () async {
                            setState(() => _localSyncLoading = true);
                            try {
                              await bp.performSync(false, SyncMode.syncOnly);
                            } finally {
                              if (mounted) {
                                setState(() => _localSyncLoading = false);
                              }
                            }
                          },
                  label: loc.syncNow,
                  isLoading: isSyncing,
                ),
              ),
            ],
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
          if (_localizedSyncError(bp, loc) case final errorMsg?)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                errorMsg,
                style: TextStyle(
                  color: cp.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else if (bp.syncWarning == 'icloud_quota_warning')
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                loc.syncWarningICloudQuota,
                style: const TextStyle(
                  color: Colors.orange,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                    ),
                    Divider(color: cp.border, height: 0),
                    ProfileOption(
                      cp: cp,
                      text: loc.restoreFromBackup,
                      onTap: () => _openBackupHistory(context, cp),
                    ),
                    Divider(color: cp.border, height: 0),
                    ProfileOption(
                      cp: cp,
                      text: loc.localBackups,
                      onTap: _showLocalBackupSheet,
                    ),
                  ],
                ),
              ),

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
                    // ─── Disconnect ────────────────────────────────────────
                    GestureDetector(
                      onTap:
                          widget.isICloud
                              ? () => _confirmDisconnectICloud(context, bp, loc)
                              : () => _confirmSignOut(context, bp, loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.transparent,
                        child: Row(
                          spacing: 12,
                          children: [
                            Text(
                              widget.isICloud
                                  ? loc.disconnectICloud
                                  : loc.disconnectGoogleDrive,
                              style: TextStyle(
                                color: cp.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),

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
                    // ─── Delete account (Google Drive only) ────────────────
                    if (!widget.isICloud) ...[
                      Divider(color: cp.border, height: 1),
                      GestureDetector(
                        onTap:
                            () => _confirmDeleteAccount(context, bp, loc, cp),
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
                              const Spacer(),
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
