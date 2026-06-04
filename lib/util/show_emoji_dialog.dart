import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:tinycolor2/tinycolor2.dart';

Future<String?> showEmojiKeyboardDialog(
  BuildContext context,
  ColorProvider cp,
) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: cp.greyText.darken().withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (dialogContext, _, __) => const _EmojiDialog(),
  );
}

class _EmojiDialog extends StatefulWidget {
  const _EmojiDialog();

  @override
  State<_EmojiDialog> createState() => _EmojiDialogState();
}

class _EmojiDialogState extends State<_EmojiDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: NewDefaultDialog(
          title: loc.enterEmojiTitle,
          desc: loc.enterEmojiDesc,
          showSecondaryButton: false,
          primaryButtonLabel: loc.cancel,
          onPrimaryButtonPressed: () => Navigator.of(context).pop(),
          child: NewDefaultTextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) {
              final emoji = _extractFirstEmojiGrapheme(value);
              if (emoji != null) {
                Navigator.of(context).pop(emoji);
              }
            },
          ),
        ),
      ),
    );
  }
}

String? _extractFirstEmojiGrapheme(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  for (final grapheme in trimmed.characters) {
    if (_isEmojiGrapheme(grapheme)) {
      return grapheme;
    }
  }
  return null;
}

bool _isEmojiGrapheme(String grapheme) {
  if (grapheme.isEmpty) {
    return false;
  }

  const emojiPattern =
      r'(^©$)|(^®$)|(^[ -㌀]$)|(^[\ud83c-\ud83e][퀀-\udfff]$)|(^[\ud83d][퀀-\udfff]$)|(^[☀-➿]$)|(^[⌀-⏿]$)';

  return RegExp(emojiPattern).hasMatch(grapheme) ||
      grapheme.contains('‍') ||
      grapheme.contains('️');
}
