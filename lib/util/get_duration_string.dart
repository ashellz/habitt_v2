String getDurationString(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  final parts = <String>[];
  if (hours > 0) parts.add("${hours}h");
  if (minutes > 0) parts.add("${minutes}m");
  if (secs > 0) parts.add("${secs}s");

  if (parts.isEmpty) return "0m";
  return parts.join();
}
