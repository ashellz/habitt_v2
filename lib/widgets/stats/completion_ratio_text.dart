import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class CompletionRatioText extends StatelessWidget {
  const CompletionRatioText({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Completion ratio',
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text('Last 7 days', style: TextStyle(color: cp.lightGreyText)),
      ],
    );
  }
}
