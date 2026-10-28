// perfect streak miilestones that show the banner
const List<int> kSupportMilestones = [7, 30, 90, 180, 365];

// show a review ask after this streak milestone
const int kReviewStreakMilestone = 7;

/// The highest milestone that [streak] has newly reached since [celebrated]
/// so if it crossed 7, or 30, or 180 and so on, it returns the highest one. Null if none.
int? crossedMilestone({required int celebrated, required int streak}) {
  int? crossed;
  for (final milestone in kSupportMilestones) {
    if (celebrated < milestone && milestone <= streak) crossed = milestone;
  }
  return crossed;
}
