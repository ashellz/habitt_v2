import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SwitchValuesArrow extends StatelessWidget {
  const SwitchValuesArrow({
    super.key,
    required this.editingHours,
    required this.switchValues,
  });

  final bool editingHours;
  final GestureTapCallback switchValues;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorProvider.colorScheme.standardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedRotation(
        turns: editingHours ? 0.5 : 1,
        curve: Curves.decelerate,
        duration: Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: () => switchValues(),
          child: SvgPicture.asset(
            width: 30,
            height: 30,
            "assets/images/svg/arrow-back.svg",
          ),
        ),
      ),
    );
  }
}
