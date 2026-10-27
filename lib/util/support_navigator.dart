import 'package:flutter/material.dart';
import 'package:habitt/pages/other_pages/paywall_page.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:provider/provider.dart';

/// Opens the support page and re-reads the subscription when it closes, so every
/// "See ways to support" button behaves the same and a new supporter stops being
/// asked straight away.
Future<void> openSupportPage(BuildContext context) async {
  final support = context.read<SupportProvider>();
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
  await support.refreshSupporter();
}
