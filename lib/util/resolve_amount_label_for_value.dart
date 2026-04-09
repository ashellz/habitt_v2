String resolveAmountLabelForValue(String label, int value) {
  final normalized = label.trim().toLowerCase();
  if (normalized != 'time' && normalized != 'times') {
    return label;
  }

  return value == 1 ? 'time' : 'times';
}
