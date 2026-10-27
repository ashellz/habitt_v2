import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/app_theme.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:provider/provider.dart';

/// The accent themes as swatch chips, each drawn in the current light/dark mode
/// so the choice previews what the app will look like. All are free for everyone.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          loc.themeSettingTitle,
          style: TextStyle(
            color: cp.lightGreyText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final theme in ThemeCatalog.all)
              _ThemeChip(
                theme: theme,
                name: _themeName(loc, theme),
                selected: cp.theme.id == theme.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  cp.setTheme(theme);
                },
              ),
          ],
        ),
      ],
    );
  }

  String _themeName(AppLocalizations loc, AppTheme theme) => switch (theme.id) {
    'lagoon' => loc.themeNameLagoon,
    'ocean' => loc.themeNameOcean,
    'indigo' => loc.themeNameIndigo,
    'violet' => loc.themeNameViolet,
    'orchid' => loc.themeNameOrchid,
    _ => loc.themeNameHabitt,
  };
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    // the chip shows its own accent, not the active one
    final accent = theme.accent(isDark: cp.isDark).main;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: ShapeDecoration(
            color:
                selected ? accent.withValues(alpha: 0.1) : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(color: selected ? accent : cp.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  color: selected ? cp.text : cp.lightGreyText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
