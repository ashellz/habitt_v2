import 'package:flutter/widgets.dart';

/// Tracks only what's currently on top of the root Navigator's stack, so
/// notification-driven navigation can decide whether a habit's details page
/// is already showing without Flutter exposing route-stack introspection.
///
/// Relies on HabitDetailsPage pushes tagging their route with
/// RouteSettings(arguments: habitId) — any other route (including modal
/// bottom sheets like HabitSheet, which push onto this same Navigator)
/// naturally resets [currentTopHabitId] to null.
class HabitRouteTracker extends NavigatorObserver {
  static int? currentTopHabitId;

  static int? _habitIdOf(Route<dynamic>? route) {
    final arguments = route?.settings.arguments;
    return arguments is int ? arguments : null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentTopHabitId = _habitIdOf(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentTopHabitId = _habitIdOf(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentTopHabitId = _habitIdOf(newRoute);
  }
}
