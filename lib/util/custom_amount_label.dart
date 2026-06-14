import 'package:shared_preferences/shared_preferences.dart';

class CustomAmountLabel {
  const CustomAmountLabel({required this.singular, required this.plural});

  final String singular;
  final String plural;

  String get canonical => plural;

  String toStorageString() => '$singular|$plural';

  static CustomAmountLabel fromStorageString(String s) {
    final idx = s.indexOf('|');
    if (idx == -1) {
      return CustomAmountLabel(singular: s, plural: s);
    }
    return CustomAmountLabel(
      singular: s.substring(0, idx),
      plural: s.substring(idx + 1),
    );
  }

  /// Loads the plural→singular map from SharedPreferences without needing StateProvider.
  static Future<Map<String, String>> loadCustomSingularsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('amount_labels') ?? [];
    final result = <String, String>{};
    for (final raw in stored) {
      final entry = fromStorageString(raw);
      if (entry.canonical.isNotEmpty) {
        result[entry.canonical] = entry.singular;
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is CustomAmountLabel &&
      singular == other.singular &&
      plural == other.plural;

  @override
  int get hashCode => Object.hash(singular, plural);
}
