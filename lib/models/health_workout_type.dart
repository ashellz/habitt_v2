import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';

enum HealthWorkoutType {
  walking,
  running,
  cycling,
  swimming,
  hiking,
  flexibility,
  dancing,
  rowing,
  other,
}

extension HealthWorkoutTypeMapping on HealthWorkoutType? {
  IconData get icon {
    switch (this) {
      case HealthWorkoutType.walking:
        return Icons.directions_walk_rounded;
      case HealthWorkoutType.running:
        return Icons.directions_run_rounded;
      case HealthWorkoutType.cycling:
        return Icons.directions_bike_rounded;
      case HealthWorkoutType.swimming:
        return Icons.pool_rounded;
      case HealthWorkoutType.hiking:
        return Icons.terrain_rounded;
      case HealthWorkoutType.flexibility:
        return Icons.self_improvement_rounded;
      case HealthWorkoutType.dancing:
        return Icons.music_note_rounded;
      case HealthWorkoutType.rowing:
        return Icons.rowing_rounded;
      case HealthWorkoutType.other:
      case null:
        return Icons.fitness_center_rounded;
    }
  }

  String label(AppLocalizations loc) {
    switch (this) {
      case HealthWorkoutType.walking:
        return loc.premadeHabitWorkoutWalking;
      case HealthWorkoutType.running:
        return loc.premadeHabitWorkoutRunning;
      case HealthWorkoutType.cycling:
        return loc.premadeHabitWorkoutCycling;
      case HealthWorkoutType.swimming:
        return loc.premadeHabitWorkoutSwimming;
      case HealthWorkoutType.hiking:
        return loc.premadeHabitWorkoutHiking;
      case HealthWorkoutType.flexibility:
        return loc.premadeHabitWorkoutFlexibility;
      case HealthWorkoutType.dancing:
        return loc.premadeHabitWorkoutDancing;
      case HealthWorkoutType.rowing:
        return loc.premadeHabitWorkoutRowing;
      case HealthWorkoutType.other:
      case null:
        return loc.premadeHabitWorkoutCombined;
    }
  }
}
