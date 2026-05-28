import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:habitt/config/app_secrets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class BillingService {
  static const _iosApiKey = AppSecrets.revenueCatIosApiKey;
  static const _androidApiKey = AppSecrets.revenueCatAndroidApiKey;

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
      debugPrint("Error checking subscription status: $e");
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

  static Future<bool> purchasePackage(Package package) async {
    try {
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      hasPro = result.customerInfo.entitlements.active.containsKey(
        'Habitt Pro',
      );
      return true;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  static Future<List<Offering>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) return [current];

      // Fall back to all available offerings when no current offering is set
      final all = offerings.all.values.toList();
      return all;
    } catch (e) {
      debugPrint("Error fetching offerings: $e");
      return [];
    }
  }
}
