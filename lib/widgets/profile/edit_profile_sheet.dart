import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  bool _isExitDialogOpen = false;
  bool _allowPop = false;
  final closeResult = false;
  final scrollController = ScrollController();
  final hasUnsavedChanges = false;

  void _popSheet({required bool result}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop(result);
  }

  Future<void> _showExitConfirmation(bool allowPop) async {
    if (_isExitDialogOpen) {
      return;
    }
    final loc = AppLocalizations.of(context)!;

    final title = loc.exitWithoutSaving;
    final desc = loc.allChangesYouMadeWillBeDiscarded;

    _isExitDialogOpen = true;
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: title,
            desc: desc,
            primaryButtonLabel: loc.exit,
            onPrimaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
              _popSheet(result: closeResult);
            },
          ),
    );
    _isExitDialogOpen = false;
  }

  Future<void> _handleCloseAttempt() async {
    if (_allowPop || !hasUnsavedChanges) {
      _popSheet(result: closeResult);
      return;
    }

    await _showExitConfirmation(closeResult);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    final canSave = true;

    return PopScope(
      canPop: _allowPop || !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleCloseAttempt();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topSection(context, cp, canSave),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [],
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

  Padding topSection(BuildContext context, ColorProvider cp, bool canSave) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _handleCloseAttempt();
            },
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              color: Colors.transparent,
              height: 36,
              width: 66 + 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  "assets/images/new-svg/back.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Text(
            loc.editProfile,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: NewDefaultButton.primarySmall(
              enabled: canSave,
              onPressed: () async {
                if (!canSave) {
                  return;
                }
                // Save logic here
              },
              label: loc.save,
            ),
          ),
        ],
      ),
    );
  }
}
