import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/theme_provider.dart';
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
    final tp = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tp.borderColor, width: 2),
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
            colorFilter: ColorFilter.mode(tp.primaryTextColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
