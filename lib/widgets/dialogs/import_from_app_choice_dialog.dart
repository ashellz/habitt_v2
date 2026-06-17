import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/animated_radio.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

class ImportFromAppChoiceDialog extends StatefulWidget {
  const ImportFromAppChoiceDialog({
    super.key,
    required this.appName,
    required this.onMerge,
    required this.onOverwrite,
  });

  final String appName;
  final Future<bool> Function() onMerge;
  final Future<bool> Function() onOverwrite;

  @override
  State<ImportFromAppChoiceDialog> createState() =>
      _ImportFromAppChoiceDialogState();
}

class _ImportFromAppChoiceDialogState extends State<ImportFromAppChoiceDialog> {
  // merge is the safe default
  String _choice = 'merge';
  bool _loading = false;

  Future<void> _import() async {
    if (_loading) return;
    setState(() => _loading = true);
    final success =
        await (_choice == 'merge' ? widget.onMerge() : widget.onOverwrite());
    if (mounted) Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final overwrite = _choice == 'overwrite';

    return PopScope(
      canPop: !_loading,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 40 + keyboardInset),
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
            spacing: 18,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    loc.importHabitKitTitle(widget.appName),
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    loc.importHabitKitDesc,
                    style: TextStyle(color: cp.greyText, fontSize: 16),
                  ),
                ],
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  _optionCard(
                    cp: cp,
                    value: 'merge',
                    title: loc.merge,
                    desc: loc.importHabitKitMergeDesc(widget.appName),
                  ),
                  _optionCard(
                    cp: cp,
                    value: 'overwrite',
                    title: loc.replace,
                    desc: loc.importHabitKitReplaceDesc(widget.appName),
                  ),
                ],
              ),

              Text(
                loc.importHabitKitNote,
                style: TextStyle(
                  color: cp.greyText,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),

              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: NewDefaultButton.secondary(
                      enabled: !_loading,
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      label: loc.cancel,
                    ),
                  ),
                  Expanded(
                    child: NewDefaultButton.primary(
                      isLoading: _loading,
                      color: overwrite ? cp.error : null,
                      onPressed: _loading ? null : _import,
                      label: loc.importBackup,
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

  Widget _optionCard({
    required ColorProvider cp,
    required String value,
    required String title,
    required String desc,
  }) {
    final selected = _choice == value;
    final highlight = cp.main;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _loading ? null : () => setState(() => _choice = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cp.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? highlight : cp.border,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedRadio<String>(
              value: value,
              groupValue: _choice,
              onChanged: _loading ? (_) {} : (v) => setState(() => _choice = v),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: cp.greyText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
