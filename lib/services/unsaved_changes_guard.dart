/// Static registry letting screens with an unsaved-changes guard (their own
/// PopScope) announce that state to code with no widget context, such as
/// notification-driven navigation, without introducing a shared base type.
///
/// Register a live closure (not a snapshot bool) in initState and unregister
/// the same closure in dispose. Add new guarded screens here if they ever
/// gain their own unsaved-changes PopScope.
class UnsavedChangesGuard {
  UnsavedChangesGuard._();

  static bool Function()? _check;

  static void register(bool Function() hasUnsavedChanges) {
    _check = hasUnsavedChanges;
  }

  static void unregister(bool Function() hasUnsavedChanges) {
    if (_check == hasUnsavedChanges) {
      _check = null;
    }
  }

  static bool get isBlocking => _check?.call() ?? false;
}
