import 'package:flutter/material.dart';
import 'package:habitt/generated/assets.gen.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:provider/provider.dart';

class IconsPage extends StatelessWidget {
  const IconsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final stateProvider = context.watch<StateProvider>();

    List<String> iconFiles =
        Assets.images.icons.values.map((e) => e.path).toList();

    return Scaffold(
      backgroundColor: tp.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children:
                    iconFiles
                        .map(
                          (icon) => GestureDetector(
                            onTap: () {
                              stateProvider.iconPath = icon;
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: tp.surfaceColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Image.asset(icon),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
