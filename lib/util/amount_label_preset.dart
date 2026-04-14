enum AmountLabelPreset {
  steps(singular: 'step', plural: 'steps'),
  glasses(singular: 'glass', plural: 'glasses'),
  pages(singular: 'page', plural: 'pages'),
  times(singular: 'time', plural: 'times');

  static const String defaultAmountLabel = 'times';

  const AmountLabelPreset({required this.singular, required this.plural});

  final String singular;
  final String plural;

  static const List<AmountLabelPreset> _orderedValues = values;

  static List<String> get defaultLabels =>
      _orderedValues.map((preset) => preset.plural).toList(growable: false);

  static AmountLabelPreset? fromLabel(String value) {
    final normalized = value.trim().toLowerCase();
    for (final preset in _orderedValues) {
      if (normalized == preset.singular || normalized == preset.plural) {
        return preset;
      }
    }
    return null;
  }

  static bool isPredefinedLabel(String value) => fromLabel(value) != null;

  static String canonicalize(String value) {
    final preset = fromLabel(value);
    return preset?.plural ?? value.trim().toLowerCase();
  }

  static String resolveForValue(String value, int amount) {
    final preset = fromLabel(value);
    if (preset == null) {
      return value;
    }

    return amount == 1 ? preset.singular : preset.plural;
  }
}
