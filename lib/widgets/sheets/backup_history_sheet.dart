import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/drive_backup_file.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/dialogs/backup_passphrase_dialog.dart';
import 'package:habitt/widgets/dialogs/confirm_restore_backup_dialog.dart';
import 'package:habitt/widgets/dialogs/restore_with_deltas_dialog.dart';
import 'package:provider/provider.dart';

class BackupHistorySheet extends StatefulWidget {
  const BackupHistorySheet({super.key});

  @override
  State<BackupHistorySheet> createState() => _BackupHistorySheetState();
}

class _BackupHistorySheetState extends State<BackupHistorySheet> {
  bool _allowPop = false;
  late final Future<List<DriveBackupFile>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    _backupsFuture = context.read<BackupProvider>().listCloudBackups();
  }

  void _popSheet() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime dt, AppLocalizations loc) {
    dt = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (day == today) return loc.backupDateToday(time);
    if (day == yesterday) return loc.backupDateYesterday(time);

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
    return loc.backupDateOther(months[dt.month - 1], '${dt.day}', time);
  }

  Future<void> _confirmRestore(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
    DriveBackupFile file, {
    bool isNewest = false,
  }) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder: (ctx) => ConfirmRestoreBackupDialog(cp: cp),
    );

    if (confirmed != true || !context.mounted) return;

    bool includeDeltasSince = false;
    if (isNewest) {
      final hasDeltas = await bp.hasDeltaFiles();
      if (!context.mounted) return;
      if (hasDeltas) {
        final choice = await showDialogSheet<bool>(
          context: context,
          builder: (ctx) => RestoreWithDeltasDialog(cp: cp),
        );
        if (!context.mounted) return;
        if (choice == null) return;
        includeDeltasSince = choice;
      }
    }

    await bp.replaceFromBackupFile(
      file.id,
      includeDeltasSince: includeDeltasSince,
    );
    if (!context.mounted) return;

    if (bp.hasPendingBackupPassphrase) {
      final success = await showDialogSheet<bool>(
        context: context,
        builder: (ctx) => BackupPassphraseDialog(bp: bp),
      );
      if (success == true && context.mounted) _popSheet();
    } else if (bp.syncState != SyncState.error) {
      _popSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    final isSyncing = bp.syncState == SyncState.syncing && !bp.isBackingUp;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _popSheet();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topSection(cp, loc),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<List<DriveBackupFile>>(
                    future: _backupsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(cp.main),
                            ),
                          ),
                        );
                      }

                      final backups = snapshot.data ?? [];

                      if (backups.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              loc.noBackupsFound,
                              style: TextStyle(
                                color: cp.greyText,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: cp.field,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: cp.border),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < backups.length; i++) ...[
                              if (i > 0) Divider(color: cp.border, height: 32),
                              _backupEntry(
                                context,
                                cp,
                                bp,
                                loc,
                                backups[i],
                                isSyncing: isSyncing,
                                isNewest: i == 0,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backupEntry(
    BuildContext context,
    ColorProvider cp,
    BackupProvider bp,
    AppLocalizations loc,
    DriveBackupFile file, {
    required bool isSyncing,
    bool isNewest = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _formatDate(file.createdAt, loc),
            style: TextStyle(
              color: cp.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        NewDefaultButton.primarySmall(
          width: null,
          onPressed:
              isSyncing
                  ? () {}
                  : () => _confirmRestore(
                    context,
                    bp,
                    loc,
                    file,
                    isNewest: isNewest,
                  ),
          label: loc.restore,
          enabled: !isSyncing,
        ),
      ],
    );
  }

  Widget _topSection(ColorProvider cp, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
          Text(
            loc.backupHistory,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 66 + 16),
        ],
      ),
    );
  }
}
