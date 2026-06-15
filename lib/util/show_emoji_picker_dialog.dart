import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

Future<String?> showEmojiPickerDialog(
  BuildContext context,
  ColorProvider cp,
) {
  final isDark = cp.isDark;
  final isIOS = Platform.isIOS;

  final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEBEFF2);
  final categoryBgColor =
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEBEFF2);
  final iconColor =
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C757D);
  final selectedColor = isDark ? Colors.white : Colors.black87;
  final accentColor = isDark ? Colors.white70 : Colors.black54;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: bgColor,
    barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
      return SizedBox(
        height: 280 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) {
              Navigator.of(sheetContext).pop(emoji.emoji);
            },
            config: Config(
              height: 280,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: bgColor,
                buttonMode:
                    isIOS ? ButtonMode.CUPERTINO : ButtonMode.MATERIAL,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: categoryBgColor,
                iconColor: iconColor,
                iconColorSelected: selectedColor,
                indicatorColor: selectedColor,
                backspaceColor: accentColor,
                dividerColor: Colors.transparent,
              ),
              bottomActionBarConfig: BottomActionBarConfig(
                backgroundColor: categoryBgColor,
                buttonColor: categoryBgColor,
                buttonIconColor: selectedColor,
              ),
            ),
          ),
        ),
      );
    },
  );
}
