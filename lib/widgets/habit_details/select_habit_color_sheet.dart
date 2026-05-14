import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SelectHabitColorSheet extends StatelessWidget {
  const SelectHabitColorSheet({
    super.key,
    required this.tp,
    this.fromCompletionWidget = false,
  });

  final ThemeProvider tp;
  final bool fromCompletionWidget;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final colorOptions = tp.habitColorOptions;
    final isColorful =
        context.read<PreferencesProvider>().colorfulness ==
        Colorfulness.colorful;

    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.9; // allow up to 90% of screen

    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxHeight is the available height for the sheet
        // Build the content inside a Column so we can measure intrinsic height.

        final sheet = Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: tp.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: tp.borderColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.selectHabitColor,
                style: TextStyle(
                  color: tp.primaryTextColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (fromCompletionWidget && !isColorful)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    AppLocalizations.of(context)!.onlyVisibleOnDailyPlanEnableColorfulModeInSettingsToShowOnCompletion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tp.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final option in colorOptions)
                        GestureDetector(
                          onTap: () {
                            stateProvider.habitColor = option.color;
                            stateProvider.habitColorName = option.name;
                            Navigator.of(context).pop();
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: option.color,
                              border:
                                  (stateProvider.habitColorName ==
                                              option.name ||
                                          stateProvider.getHabitColor ==
                                              option.color)
                                      ? Border.all(
                                        color: option.color.darken(
                                          tp.isDark ? 20 : 10,
                                        ),
                                        width: 3,
                                      )
                                      : null,
                              boxShadow: [
                                BoxShadow(
                                  color: option.color.withOpacity(0.28),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 16,
                                  color: option.textColor,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  option.name,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: option.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        );

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: sheet,
          ),
        );
      },
    );
  }
}
