import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/default_dialog.dart';

class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      title: "Discard changes?",
      desc:
          "You have unsaved changes. Are you sure you want to go back and discard them?",
      content: Row(
        children: [
          Expanded(
            child: DefaultButton(
              label: "Cancel",
              outlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: DefaultButton(
              label: "Discard",
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
            ),
          ),
        ],
      ),
    );
  }
}
