import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/dialogs/confirm_restore_backup_dialog.dart';
import 'package:habitt/widgets/dialogs/local_pin/change_pin_dialog.dart';
import 'package:habitt/widgets/dialogs/local_pin/fallback_pin_dialog.dart';
import 'package:habitt/widgets/dialogs/local_pin/remove_pin_dialog.dart';
import 'package:habitt/widgets/dialogs/local_pin/set_local_pin_dialog.dart';
import 'package:habitt/widgets/dialogs/local_pin/unencrypted_warning_dialog.dart';
import 'package:habitt/widgets/dialogs/local_pin/use_this_pin_dialog.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:provider/provider.dart';

class LocalBackupSheet extends StatefulWidget {
  const LocalBackupSheet({super.key});

  @override
  State<LocalBackupSheet> createState() => _LocalBackupSheetState();
}

class _LocalBackupSheetState extends State<LocalBackupSheet>
    with TickerProviderStateMixin {
  bool _allowPop = false;
  bool _pinEnabled = false;
  bool _exporting = false;
  bool _importing = false;
  final _storage = const FlutterSecureStorage();
  late final StatusOverlayPopupController _overlay;

  @override
  void initState() {
    super.initState();
    _overlay = StatusOverlayPopupController(vsync: this);
    _loadPinState();
  }

  @override
  void dispose() {
    _overlay.dispose();
    super.dispose();
  }

  Future<void> _loadPinState() async {
    final pin = await BackupService.readLocalBackupPin(_storage);
    if (mounted) setState(() => _pinEnabled = pin != null);
  }

  void _popSheet() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showOverlay({required String title, required bool isError}) {
    if (!mounted) return;
    final cp = context.read<ColorProvider>();
    _overlay.show(context: context, cp: cp, title: title, isError: isError);
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Future<void> _handleExport() async {
    if (!mounted || _exporting) return;
    final loc = AppLocalizations.of(context)!;

    final pin = await BackupService.readLocalBackupPin(_storage);

    if (pin != null) {
      setState(() => _exporting = true);
      final result = await BackupService.exportDataLocally(
        context: context,
        passphrase: pin,
      );
      if (!mounted) return;
      setState(() => _exporting = false);
      if (result == BackupOperationResult.success) {
        _showOverlay(title: loc.exportSuccess, isError: false);
      } else if (result == BackupOperationResult.failed) {
        _showOverlay(title: loc.exportFailed, isError: true);
      }
    } else {
      final confirmed = await _showUnencryptedWarning();
      if (!mounted || confirmed != true) return;
      setState(() => _exporting = true);
      final result = await BackupService.exportDataLocally(
        context: context,
        passphrase: null,
      );
      if (!mounted) return;
      setState(() => _exporting = false);
      if (result == BackupOperationResult.success) {
        _showOverlay(title: loc.exportSuccess, isError: false);
      } else if (result == BackupOperationResult.failed) {
        _showOverlay(title: loc.exportFailed, isError: true);
      }
    }
  }

  Future<bool?> _showUnencryptedWarning() {
    return showDialogSheet<bool>(
      context: context,
      builder: (_) => const UnencryptedWarningDialog(),
    );
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  Future<void> _handleImport() async {
    if (!mounted || _importing) return;
    final loc = AppLocalizations.of(context)!;

    setState(() => _importing = true);

    final storedPin = await BackupService.readLocalBackupPin(_storage);

    // Pick the file once so the same path can be reused in the fallback dialog.
    final filePath = await BackupService.pickImportPath();
    if (filePath == null) {
      if (mounted) setState(() => _importing = false);
      return;
    }

    // Show confirmation before touching any local data.
    if (!mounted) return;
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => ConfirmRestoreBackupDialog(cp: ctx.read<ColorProvider>()),
    );
    if (!mounted || confirmed != true) {
      if (mounted) setState(() => _importing = false);
      return;
    }
    final result = await BackupService.importLocalData(
      context: context,
      passphrase: storedPin,
      filePath: filePath,
    );

    if (!mounted) return;
    setState(() => _importing = false);

    if (result == BackupOperationResult.success) {
      _showOverlay(title: loc.importSuccess, isError: false);
      return;
    }
    if (result == BackupOperationResult.cancelled) return;
    if (result == BackupOperationResult.failed) {
      _showOverlay(title: loc.importFailed, isError: true);
      return;
    }
    if (result == BackupOperationResult.wrongPassphrase) {
      await _showFallbackPinDialog(storedPin: storedPin, filePath: filePath);
    }
  }

  Future<void> _showFallbackPinDialog({
    required String? storedPin,
    required String filePath,
  }) async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    await showDialogSheet(
      context: context,
      builder:
          (_) => FallbackPinDialog(
            filePath: filePath,
            onSuccess:
                (pin) => _handlePostImportPinSave(
                  enteredPin: pin,
                  storedPin: storedPin,
                ),
            onFailed:
                () => _showOverlay(title: loc.importFailed, isError: true),
          ),
    );
  }

  Future<void> _handlePostImportPinSave({
    required String enteredPin,
    required String? storedPin,
  }) async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    if (storedPin == null) {
      await BackupService.saveLocalBackupPin(_storage, enteredPin);
      if (mounted) setState(() => _pinEnabled = true);
      _showOverlay(title: loc.importSuccessPinSaved, isError: false);
    } else {
      _showOverlay(title: loc.importSuccess, isError: false);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final save = await showDialogSheet<bool>(
        context: context,
        builder: (_) => const UseThisPinDialog(),
      );
      if (save == true && mounted) {
        await BackupService.saveLocalBackupPin(_storage, enteredPin);
        if (mounted) setState(() => _pinEnabled = true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PIN management
  // ---------------------------------------------------------------------------

  Future<void> _handleSetPin() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    final pin = await showDialogSheet<String>(
      context: context,
      builder: (_) => const SetLocalPinDialog(),
    );

    if (pin == null || !mounted) return;
    await BackupService.saveLocalBackupPin(_storage, pin);
    if (mounted) {
      setState(() => _pinEnabled = true);
      _showOverlay(title: loc.pinSetSuccess, isError: false);
    }
  }

  Future<String?> _handleRevealPin() async {
    return BackupService.readLocalBackupPin(_storage);
  }

  void _handlePinCopied() {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final cp = context.read<ColorProvider>();
    _overlay.show(
      context: context,
      cp: cp,
      title: loc.pinCopied,
      isError: false,
      iconWidget: Icon(Icons.copy_rounded, color: cp.main, size: 20),
    );
  }

  Future<void> _handleChangePin() async {
    if (!mounted) return;
    await showDialogSheet<void>(
      context: context,
      builder:
          (_) => ChangePinDialog(
            storage: _storage,
            onSuccess: () {
              if (!mounted) return;
              _showOverlay(
                title: AppLocalizations.of(context)!.pinChangedSuccess,
                isError: false,
              );
            },
          ),
    );
  }

  Future<void> _handleRemovePin() async {
    if (!mounted) return;
    await showDialogSheet<void>(
      context: context,
      builder:
          (_) => RemovePinDialog(
            storage: _storage,
            onSuccess: () {
              if (!mounted) return;
              setState(() => _pinEnabled = false);
              _showOverlay(
                title: AppLocalizations.of(context)!.pinRemovedSuccess,
                isError: false,
              );
            },
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
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
                    // Header
                    Padding(
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
                                  colorFilter: ColorFilter.mode(
                                    cp.text,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                loc.localBackups,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: cp.text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 66 + 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        loc.localBackupsDesc,
                        style: TextStyle(
                          color: cp.greyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Export / Import card
                    Padding(
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
                        child: Column(
                          children: [
                            ProfileOption(
                              cp: cp,
                              text: loc.exportBackup,
                              svgPath:
                                  'assets/images/new-svg/export-backup.svg',
                              onTap: _handleExport,
                              isLoading: _exporting,
                            ),
                            Divider(color: cp.border, height: 0),
                            ProfileOption(
                              cp: cp,
                              text: loc.importBackup,
                              svgPath:
                                  'assets/images/new-svg/import-backup.svg',
                              onTap: _handleImport,
                              isLoading: _importing,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // PIN management card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          _pinEnabled ? 0 : 16,
                          0,
                        ),
                        decoration: ShapeDecoration(
                          color: cp.field,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: cp.border),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child:
                            _pinEnabled
                                ? _PinEnabledRows(
                                  cp: cp,
                                  loc: loc,
                                  onReveal: _handleRevealPin,
                                  onCopied: _handlePinCopied,
                                  onChange: _handleChangePin,
                                  onRemove: _handleRemovePin,
                                )
                                : ProfileOption(
                                  cp: cp,
                                  text: loc.setPin,
                                  svgPath: 'assets/images/new-svg/pin.svg',
                                  onTap: _handleSetPin,
                                ),
                      ),
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

class _PinEnabledRows extends StatefulWidget {
  const _PinEnabledRows({
    required this.cp,
    required this.loc,
    required this.onReveal,
    required this.onCopied,
    required this.onChange,
    required this.onRemove,
  });

  final ColorProvider cp;
  final AppLocalizations loc;
  final Future<String?> Function() onReveal;
  final VoidCallback onCopied;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  State<_PinEnabledRows> createState() => _PinEnabledRowsState();
}

class _PinEnabledRowsState extends State<_PinEnabledRows> {
  String? _revealedPin;

  Future<void> _toggleReveal() async {
    if (_revealedPin != null) {
      setState(() => _revealedPin = null);
      return;
    }
    final pin = await widget.onReveal();
    if (mounted && pin != null) setState(() => _revealedPin = pin);
  }

  @override
  Widget build(BuildContext context) {
    final cp = widget.cp;
    final loc = widget.loc;
    final isRevealed = _revealedPin != null;

    return Column(
      children: [
        // "PIN enabled" row with eye button
        Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: SvgPicture.asset(
                'assets/images/new-svg/pin.svg',
                colorFilter: ColorFilter.mode(
                  cp.lightGreyText,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap:
                  isRevealed
                      ? () {
                        Clipboard.setData(ClipboardData(text: _revealedPin!));
                        widget.onCopied();
                      }
                      : null,
              child: Text(
                isRevealed ? _revealedPin! : loc.pinEnabled,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _toggleReveal,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                child: SvgPicture.asset(
                  isRevealed
                      ? 'assets/images/new-svg/eye-shut.svg'
                      : 'assets/images/new-svg/eye.svg',
                  colorFilter: ColorFilter.mode(
                    cp.lightGreyText,
                    BlendMode.srcIn,
                  ),
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Divider(color: cp.border, height: 0),
              ProfileOption(
                cp: cp,
                text: loc.changePin,
                onTap: widget.onChange,
              ),
              Divider(color: cp.border, height: 0),
              // Remove PIN — red text, red chevron
              ProfileOption(
                cp: cp,
                text: loc.removePin,
                onTap: widget.onRemove,
                textColor: cp.fail,
                arrowColor: cp.fail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
