class CategoryProgress {
  final String name; // Name of the category (e.g. "Morning")
  final int id; // Unique ID (e.g., 1, 2...)
  int totalHabits = 0;
  int completedHabits = 0;

  CategoryProgress(this.name, this.id);

  bool get hasHabits => totalHabits > 0;
  // A category is completed if it has habits and all of them are completed.
  bool get isCompleted => hasHabits && totalHabits == completedHabits;
  // A category is "ready" if it has habits and they are not all completed.
  bool get isReady => hasHabits && !isCompleted;
}
