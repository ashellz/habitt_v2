import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/l10n/app_localizations.dart';

class DeleteHabitDialogNameConfirm extends StatefulWidget {
  const DeleteHabitDialogNameConfirm({
    super.key,
    required this.expectedHabitName,
    required this.primaryButtonColor,
    required this.onConfirmed,
  });

  final String expectedHabitName;
  final Color primaryButtonColor;
  final VoidCallback onConfirmed;

  @override
  State<DeleteHabitDialogNameConfirm> createState() =>
      _DeleteHabitNameDialogState();
}

class _DeleteHabitNameDialogState extends State<DeleteHabitDialogNameConfirm> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isMatch(String text) {
    return text.trim() == widget.expectedHabitName.trim();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nameController,
      builder: (context, value, _) {
        final isMatch = _isMatch(value.text);
        final loc = AppLocalizations.of(context)!;

        return NewDefaultDialog(
          title: loc.confirmDeletion,
          desc: loc.enterHabitNameToConfirmDeletion(widget.expectedHabitName),
          primaryButtonLabel: loc.delete,
          primaryButtonEnabled: isMatch,
          primaryButtonColor: widget.primaryButtonColor,
          onPrimaryButtonPressed: widget.onConfirmed,
          child: NewDefaultTextField(
            controller: _nameController,
            title: loc.habitName,
            fontWeight: FontWeight.w500,
            maxLines: 1,
          ),
        );
      },
    );
  }
}
