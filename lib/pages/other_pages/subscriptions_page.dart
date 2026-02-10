import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/billing_service.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  var offers = [];

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return DefaultAnnotatedRegion(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            children: [
              ListView(
                children: [
                  NavBackButton(tp: tp),
                  Text(
                    "Subscriptions",
                    style: TextStyle(
                      fontSize: 38,
                      color: tp.primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Manage your subscriptions and billing plans here.",
                    style: TextStyle(
                      fontSize: 16,
                      color: tp.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DefaultButton(
                    onPressed: () {
                      fetchOffers();
                    },
                    label: "Fetch Offers",
                  ),
                  const SizedBox(height: 24),
                  for (final offer in offers)
                    Text(
                      "Offer: ${offer.identifier}",
                      style: TextStyle(
                        fontSize: 16,
                        color: tp.primaryTextColor,
                      ),
                    ),
                ],
              ),
              PaywallView(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchOffers() async {
    final offerings = await BillingService.fetchOffers();

    BillingService.presentPaywall();

    if (offerings.isNotEmpty) {
      final currentOffer = offerings.first;
      print("Current offering: ${currentOffer.identifier}");
      setState(() {
        offers = offerings;
      });
    } else {
      print("No offerings available");
    }
  }
}
