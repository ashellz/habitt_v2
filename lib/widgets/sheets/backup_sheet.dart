import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/sheets/backup_history_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class BackupSheet extends StatefulWidget {
  const BackupSheet({super.key});

  @override
  State<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<BackupSheet> {
  bool _allowPop = false;
  final _passphraseController = TextEditingController();
  bool _migrationLoading = false;

  void _popSheet() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
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
      loc.monthJan, loc.monthFeb, loc.monthMar, loc.monthApr,
      loc.monthMay, loc.monthJun, loc.monthJul, loc.monthAug,
      loc.monthSep, loc.monthOct, loc.monthNov, loc.monthDec,
    ];
    return loc.backupDateOther(months[lastSync.month - 1], '${lastSync.day}', time);
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
      child: NewDefaultButton.primary(
        onPressed: () => bp.signIn(context),
        label: loc.signInWithGoogle,
        isLoading: bp.syncState == SyncState.syncing,
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
                TextField(
                  controller: _passphraseController,
                  obscureText: true,
                  style: TextStyle(color: cp.text, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: loc.enterOldPassphrase,
                    hintStyle: TextStyle(color: cp.greyText),
                    filled: true,
                    fillColor: cp.bg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cp.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cp.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cp.main),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NewDefaultButton.primary(
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
              onTap: () => bp.signOut(),
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
          NewDefaultButton.secondary(
            onPressed: isSyncing ? () {} : () => bp.performSync(true),
            label: loc.backUpNow,
            isLoading: isSyncing,
          ),
          const SizedBox(height: 10),
          NewDefaultButton.secondary(
            onPressed: isSyncing
                ? () {}
                : () => _openBackupHistory(context, cp),
            label: loc.restoreFromBackup,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => bp.signOut(),
              child: Text(
                loc.disconnectGoogle,
                style: TextStyle(
                  color: cp.greyText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
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
