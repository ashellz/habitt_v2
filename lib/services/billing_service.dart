import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class BillingService {
  // RevenueCat public SDK keys baked into the app for all runs/builds.
  static const _iosApiKey = 'appl_BGjcLUxtFNlyHseGUicCYJcBxVP';
  static const _androidApiKey = 'goog_WcHBcWmpEfKekNShrAHdNmUCTgt';

  static bool hasPro = false;

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('RevenueCat is not configured for web in this app.');
      return;
    }

    final apiKey = _currentPlatformApiKey();
    if (apiKey.isEmpty) {
      throw StateError('RevenueCat API key missing for this platform.');
    }

    debugPrint('Initializing BillingService for ${Platform.operatingSystem}');
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.configure(PurchasesConfiguration(apiKey));

    hasPro = await checkHasPro();
  }

  static String _currentPlatformApiKey() {
    if (Platform.isIOS) return _iosApiKey;
    if (Platform.isAndroid) return _androidApiKey;
    return '';
  }

  static Future<bool> checkHasPro() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final hasPro = customerInfo.entitlements.active.containsKey('Habitt Pro');
      return hasPro;
    } catch (e) {
      print("Error checking subscription status: $e");
      return false;
    }
  }

  static Future<void> presentPaywall() async {
    final paywallResult = await RevenueCatUI.presentPaywall();
    debugPrint('Paywall result: $paywallResult');
  }

  static Future<void> presentPaywallIfNeeded() async {
    final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("pro");
    debugPrint('Paywall result: $paywallResult');
  }

  static Future<List<Offering>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      return current != null ? [current] : [];
    } catch (e) {
      print("Error fetching offerings: $e");
      return [];
    }
  }
}
