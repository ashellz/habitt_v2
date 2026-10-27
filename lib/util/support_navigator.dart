import 'package:flutter/material.dart';
import 'package:habitt/pages/other_pages/paywall_page.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:provider/provider.dart';

/// Opens the support page and re-reads the subscription when it closes, so every
/// "See ways to support" button behaves the same and a new supporter stops being
/// asked straight away. [popFirst] closes the calling dialog or sheet first.
Future<void> openSupportPage(
  BuildContext context, {
  bool popFirst = false,
}) async {
  // Taken before popping: the caller's context is gone once its route closes.
  final navigator = Navigator.of(context);
  final support = context.read<SupportProvider>();
  if (popFirst) navigator.pop();
  await navigator.push(MaterialPageRoute(builder: (_) => const PaywallPage()));
  await support.refreshSupporter();
}
