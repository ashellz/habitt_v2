import 'types.dart';

class HabitNotificationComposer {
  static List<HabitNotificationSegment> selectTopSegments(
    List<HabitNotificationSegment> segments, {
    int maxSegments = 3,
  }) {
    if (segments.isEmpty) {
      return const [];
    }

    final sorted = List<HabitNotificationSegment>.from(segments)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final selected = <HabitNotificationSegment>[];

    final identity =
        sorted
            .where(
              (s) => s.category == HabitNotificationSegmentCategory.identity,
            )
            .toList();
    if (identity.isNotEmpty && selected.length < maxSegments) {
      selected.add(identity.first);
    }

    for (final segment in sorted) {
      if (selected.length >= maxSegments) {
        break;
      }

      final alreadySelectedCategory = selected.any(
        (candidate) => candidate.category == segment.category,
      );
      if (alreadySelectedCategory) {
        continue;
      }

      selected.add(segment);
    }

    return selected;
  }
}
