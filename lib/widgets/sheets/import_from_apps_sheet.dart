import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/services/habitkit_import_service.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/dialogs/import_from_app_choice_dialog.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

class ImportFromAppsSheet extends StatefulWidget {
  const ImportFromAppsSheet({super.key});

  @override
  State<ImportFromAppsSheet> createState() => _ImportFromAppsSheetState();
}

class _ImportFromAppsSheetState extends State<ImportFromAppsSheet>
    with TickerProviderStateMixin {
  bool _allowPop = false;
  late final StatusOverlayPopupController _overlay;

  @override
  void initState() {
    super.initState();
    _overlay = StatusOverlayPopupController(vsync: this);
  }

  @override
  void dispose() {
    _overlay.dispose();
    super.dispose();
  }

  void _popSheet() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showOverlay({required String title, required bool isError}) {
    if (!mounted) return;
    _overlay.show(
      context: context,
      cp: context.read<ColorProvider>(),
      title: title,
      isError: isError,
    );
  }

  Future<void> _handleHabitKitImport() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    // 1. Pick file.
    final filePath = await BackupService.pickImportPath(true);
    if (filePath == null || !mounted) return;

    // 2. Read + parse — show error toast immediately on malformed JSON.
    HabitKitImportResult importResult;
    try {
      final content = await File(filePath).readAsString();
      importResult = HabitKitImportService.parse(content);
    } catch (_) {
      _showOverlay(title: loc.importFailed, isError: true);
      return;
    }

    if (!mounted) return;

    // 3. Show merge / overwrite choice dialog.
    final success = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => ImportFromAppChoiceDialog(
            appName: 'HabitKit',
            onMerge: () => HabitKitImportService.merge(ctx, importResult),
            onOverwrite:
                () => HabitKitImportService.overwrite(ctx, importResult),
          ),
    );

    if (!mounted || success == null) return;

    _showOverlay(
      title: success ? loc.importSuccess : loc.importFailed,
      isError: !success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final hasData =
        context.watch<HabitProvider>().habits.isNotEmpty ||
        Hive.box<Day>('days').values.any((d) => d.habits.isNotEmpty);
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

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
                            loc.importFromOtherApps,
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
                if (hasData) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      loc.backupBeforeImporting,
                      style: TextStyle(
                        color: cp.greyText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                    child: _AppRow(
                      cp: cp,
                      logoPath: 'assets/images/apps/habitkit.png',
                      appName: 'HabitKit',
                      onTap: _handleHabitKitImport,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.cp,
    required this.logoPath,
    required this.appName,
    required this.onTap,
  });

  final ColorProvider cp;
  final String logoPath;
  final String appName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          spacing: 12,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(logoPath, width: 32, height: 32),
            ),
            Text(
              appName,
              style: TextStyle(
                color: cp.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
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
    );
  }
}
