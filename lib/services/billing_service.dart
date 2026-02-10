import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class BillingService {
  static const _apiKey = "test_AxmjNvvJVnAlusZlAaANIqyUXDm";
  static bool hasPro = false;

  static Future<void> init() async {
    debugPrint("Initializing BillingService with API key: $_apiKey");
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.configure(PurchasesConfiguration(_apiKey));

    hasPro = await checkHasPro();
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

  static void presentPaywall() async {
    final paywallResult = await RevenueCatUI.presentPaywall();
    debugPrint('Paywall result: $paywallResult');
  }

  static void presentPaywallIfNeeded() async {
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
