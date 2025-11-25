import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class SelectHabitColorSheet extends StatelessWidget {
  const SelectHabitColorSheet({super.key, required this.tp});

  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();

    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.9; // allow up to 90% of screen

    // bunch of different colors to choose frm (shades of green, blue, etc.)
    // make on spot with hex or rgba
    final List<Color> colors = [
      Colors.green.shade300,
      Colors.green.shade400,
      Colors.green.shade500,
      Colors.green.shade600,
      Colors.green.shade700,
      Colors.green.shade800,
      Colors.green.shade900,
      Colors.blue.shade300,
      Colors.blue.shade400,
      Colors.blue.shade500,
      Colors.blue.shade600,
      Colors.blue.shade700,
      Colors.blue.shade800,
      Colors.blue.shade900,
      Colors.purple.shade300,
      Colors.purple.shade400,
      Colors.purple.shade500,
      Colors.purple.shade600,
      Colors.purple.shade700,
      Colors.purple.shade800,
      Colors.purple.shade900,
      Colors.red.shade300,
      Colors.red.shade400,
      Colors.red.shade500,
      Colors.red.shade600,
      Colors.red.shade700,
      Colors.red.shade800,
      Colors.red.shade900,
      Colors.yellow.shade300,
      Colors.yellow.shade400,
      Colors.yellow.shade500,
      Colors.yellow.shade600,
      Colors.yellow.shade700,
      Colors.yellow.shade800,
      Colors.yellow.shade900,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxHeight is the available height for the sheet
        // Build the content inside a Column so we can measure intrinsic height.

        final sheet = Container(
          width: double.infinity,
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
                "Select habit color",
                style: TextStyle(
                  color: tp.primaryTextColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (context) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (Color vividColor in colors)
                          GestureDetector(
                            onTap: () {
                              stateProvider.habitColor = vividColor;
                              Navigator.of(context).pop();
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: vividColor,
                                border:
                                    stateProvider.habitColor == vividColor
                                        ? Border.all(
                                          color: vividColor.darken(
                                            tp.isDark ? 30 : 15,
                                          ),
                                          width: 3,
                                        )
                                        : null,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
