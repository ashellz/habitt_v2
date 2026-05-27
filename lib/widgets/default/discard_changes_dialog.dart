import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/l10n/app_localizations.dart';

class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return OldDefaultDialog(
      title: loc.discardChanges,
      desc: loc.youHaveUnsavedChangesAreYouSureYouWantToGoBackAndDiscardThem,
      content: Row(
        children: [
          Expanded(
            child: DefaultButton(
              label: "Cancel",
              outlined: true,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: DefaultButton(
              label: loc.discard,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                // close dialog
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                // go back
              },
            ),
          ),
        ],
      ),
    );
  }
}
