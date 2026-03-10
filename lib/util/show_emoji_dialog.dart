import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:tinycolor2/tinycolor2.dart';

Future<String?> showEmojiKeyboardDialog(
  BuildContext context,
  ColorProvider cp,
) async {
  final textController = TextEditingController();
  final focusNode = FocusNode();

  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: cp.greyText.darken().withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (dialogContext, _, __) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Center(
              child: SizedBox(
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 1),
                    onChanged: (value) {
                      final emoji = _extractFirstEmojiGrapheme(value);
                      if (emoji != null) {
                        Navigator.of(dialogContext).pop(emoji);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  textController.dispose();
  focusNode.dispose();
  return result;
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
      r'(^\u00a9$)|(^\u00ae$)|(^[\u2000-\u3300]$)|(^[\ud83c-\ud83e][\ud000-\udfff]$)|(^[\ud83d][\ud000-\udfff]$)|(^[\u2600-\u27bf]$)|(^[\u2300-\u23ff]$)';

  return RegExp(emojiPattern).hasMatch(grapheme) ||
      grapheme.contains('\u200d') ||
      grapheme.contains('\ufe0f');
}
