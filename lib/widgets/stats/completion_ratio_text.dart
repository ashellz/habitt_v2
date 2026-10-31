import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:habitt/widgets/stats/stats_range_selector.dart';
import 'package:provider/provider.dart';

class CompletionRatioText extends StatelessWidget {
  const CompletionRatioText({
    super.key,
    required this.range,
    required this.onRangeChanged,
  });

  final StatsRange range;
  final ValueChanged<StatsRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.completionRatio,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        StatsRangeSelector(range: range, onChanged: onRangeChanged),
      ],
    );
  }
}
