import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.showButton});

  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, showButton ? -30 : 50, 0),
      child: SizedBox(
        height: 50,
        width: MediaQuery.of(context).size.width - 32,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: colorProvider.colorScheme.darkerStandardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          child: Text(
            "Save Changes",
            style: TextStyle(color: colorProvider.backgroundColor),
          ),
        ),
      ),
    );
  }
}
