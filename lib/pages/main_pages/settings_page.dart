import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 38,
                color: colorProvider.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _opacity = 0.5;
                      });
                    },
                    onTapUp: (details) {
                      setState(() {
                        _opacity = 1.0;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _opacity = 1.0;
                      });
                    },
                    onTap: () {
                      setState(() {
                        _opacity = 0.5;
                      });

                      showModalBottomSheet(
                        context: context,
                        builder:
                            (context) =>
                                SelectColorSheet(colorProvider: colorProvider),
                      );

                      Future.delayed(const Duration(milliseconds: 150), () {
                        setState(() {
                          _opacity = 1.0;
                        });
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            Icons.color_lens,
                            color: colorProvider.colorScheme.strokeColor,
                            size: 32,
                          ),
                          const SizedBox(
                            width: 16,
                          ), // spacing between icon and text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Accent Color",
                                  style: TextStyle(
                                    color: colorProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Select a color theme for your interface",
                                  style: TextStyle(
                                    color: colorProvider.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorProvider.standardColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Change mode",
                      style: TextStyle(color: colorProvider.textColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        colorProvider.changeMode();
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorProvider.standardColor,
                          border: Border.all(
                            color: colorProvider.colorScheme.strokeColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectColorSheet extends StatelessWidget {
  const SelectColorSheet({super.key, required this.colorProvider});

  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorProvider.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            "Select color",
            style: TextStyle(
              color: colorProvider.textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(thickness: 2, color: colorProvider.colorScheme.strokeColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final colorScheme in colorProvider.colorSchemes)
                      GestureDetector(
                        onTap: () {
                          colorProvider.changeColorScheme(colorScheme.name);
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
                            color: colorScheme.vividColor,
                            border:
                                colorProvider.colorScheme == colorScheme
                                    ? Border.all(
                                      color: colorScheme.darkerStandardColor,
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
  }
}
