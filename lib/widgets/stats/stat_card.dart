import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/stats/value_blur_cloud.dart';
import 'package:provider/provider.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconPath,
    this.fullWidth = false,
    this.cloudProgress,
  });

  final String title;
  final String value;
  final String iconPath;
  final bool fullWidth;
  final double? cloudProgress;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: cp.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: ShapeDecoration(
              color: cp.field,
              shape: const OvalBorder(),
            ),
            padding: const EdgeInsets.all(7),
            child: SvgPicture.asset(iconPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                ),
                const SizedBox(height: 2),
                ValueBlurCloud(
                  progress: cloudProgress,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
