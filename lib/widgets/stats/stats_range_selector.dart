import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:habitt/widgets/default/multiple_option_selector.dart';

/// Compact 7D / 30D / ALL switch for the habit details stats sections.
class StatsRangeSelector extends StatelessWidget {
  const StatsRangeSelector({
    super.key,
    required this.range,
    required this.onChanged,
  });

  final StatsRange range;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      width: 136,
      child: MultipleOptionSelector<StatsRange>(
        compact: true,
        allowDeselect: false,
        labels: [loc.statsRange7Days, loc.statsRange30Days, loc.statsRangeAll],
        values: StatsRange.values,
        selectedValue: range,
        onSelect: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
