import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/notification_sounds.dart';
import 'package:habitt/services/sound_preview_player.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/notification/sound_option_widget.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

String notificationSoundDisplayName(AppLocalizations loc, String key) {
  if (key == NotificationSounds.defaultKey) {
    return loc.notificationSoundAppDefault;
  }
  if (key == NotificationSounds.systemKey) {
    return loc.notificationSoundSystemDefault;
  }
  // Numbered by POSITION in the list (not by filename), so the numbering stays
  // contiguous regardless of which file is the App Default.
  final number = NotificationSounds.numberFor(key);
  if (number != null) return loc.soundNumbered(number);
  return key;
}

Future<void> showSoundPickerSheet({
  required BuildContext context,
  required String selectedKey,
  required ValueChanged<String> onSelected,
  bool allowInherit = false,
}) {
  final cp = context.read<ColorProvider>();
  final maxSheetHeight = MediaQuery.of(context).size.height - 59 - 16;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
    barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
    isScrollControlled: true,
    builder:
        (_) => _SoundPickerSheet(
          selectedKey: selectedKey,
          allowInherit: allowInherit,
          onSelected: onSelected,
          maxSheetHeight: maxSheetHeight,
        ),
  );
}

class _SoundPickerSheet extends StatefulWidget {
  const _SoundPickerSheet({
    required this.selectedKey,
    required this.allowInherit,
    required this.onSelected,
    required this.maxSheetHeight,
  });

  final String selectedKey;
  final bool allowInherit;
  final ValueChanged<String> onSelected;
  final double maxSheetHeight;

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  late String _selected = widget.selectedKey;

  @override
  void dispose() {
    // stops playing sounds on sheet close
    SoundPreviewPlayer.instance.stop();
    super.dispose();
  }

  void _onPick(String key) {
    setState(() => _selected = key);
    widget.onSelected(key);
    if (NotificationSounds.isPreviewable(key)) {
      SoundPreviewPlayer.instance.preview(key);
    } else {
      // system default and habit global default have no preview
      SoundPreviewPlayer.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final entries = <_PickerEntry>[
      if (widget.allowInherit)
        _PickerEntry(
          key: NotificationSounds.inheritKey,
          label: loc.useGlobalDefaultSound,
        ),
      for (final key in NotificationSounds.pickerOrder)
        _PickerEntry(key: key, label: notificationSoundDisplayName(loc, key)),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxSheetHeight),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topSection(context, cp, loc),
              Column(
                spacing: 10,
                children: [
                  for (final entry in entries)
                    SoundOptionWidget(
                      label: entry.label,
                      isSelected: entry.key == _selected,
                      onTap: () => _onPick(entry.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topSection(
    BuildContext context,
    ColorProvider cp,
    AppLocalizations loc,
  ) {
    void close() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: close,
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
              NewDefaultButton.primarySmall(
                width: null,
                onPressed: close,
                label: loc.done,
              ),
            ],
          ),
          Center(
            child: Text(
              loc.notificationSoundSettingTitle,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerEntry {
  final String key;
  final String label;
  const _PickerEntry({required this.key, required this.label});
}
