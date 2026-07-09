import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasSelectedPastDay defaults to false for a fresh install', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = PreferencesProvider(prefs);

    expect(provider.hasSelectedPastDay, isFalse);
  });

  test('setHasSelectedPastDay(true) persists across provider instances', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = PreferencesProvider(prefs);

    provider.setHasSelectedPastDay(true);
    expect(provider.hasSelectedPastDay, isTrue);

    // Simulate an app restart: a new provider reading the same backing store.
    final restartedProvider = PreferencesProvider(prefs);
    expect(restartedProvider.hasSelectedPastDay, isTrue);
  });

  test('setHasSelectedPastDay notifies listeners only on an actual change', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = PreferencesProvider(prefs);

    var notifyCount = 0;
    provider.addListener(() => notifyCount++);

    provider.setHasSelectedPastDay(true);
    expect(notifyCount, 1);

    // Setting the same value again (e.g. tapping another past day later)
    // must not re-notify or re-write.
    provider.setHasSelectedPastDay(true);
    expect(notifyCount, 1);
  });
}
