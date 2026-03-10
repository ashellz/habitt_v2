import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class HabitIcon extends StatelessWidget {
  const HabitIcon({
    super.key,
    required this.editable,
    required this.tp,
    required this.alpha,
    required this.habit,
    required this.value,
  });

  final bool editable;
  final ThemeProvider tp;
  final int alpha;
  final Habit habit;
  // If habit is completed, opacity value from animation builder
  final double value;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.read<StateProvider>();
    final cp = context.read<ColorProvider>();
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      enableFeedback: false,
      onTap: () async {
        if (editable) {
          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => EmojiPickerPage()));
          final emoji = await showEmojiKeyboardDialog(context, cp);
          if (emoji != null && context.mounted) {
            stateProvider.iconPath = emoji;
          }
        }
      },
      child: Container(
        width: 50,
        height: 50,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              Color.lerp(
                tp.surfaceColor.withAlpha(alpha),
                tp.surfaceColor,
                value,
              )!,
        ),
        // Icon
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder:
              (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
          switchInCurve: Curves.decelerate,
          switchOutCurve: Curves.decelerate,
          child: AnimatedOpacity(
            key: ValueKey<String>(habit.iconPath),
            duration: const Duration(milliseconds: 150),
            opacity: habit.completed || habit.skipped ? 0.5 : 1,
            child: Center(
              child: Text(habit.iconPath, style: const TextStyle(fontSize: 28)),
            ),
          ),
        ),
      ),
    );
  }
}

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
