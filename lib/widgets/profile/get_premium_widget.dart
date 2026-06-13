import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/other_pages/paywall_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/billing_service.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class GetPremiumWidget extends StatefulWidget {
  const GetPremiumWidget({super.key, required this.cp});

  final ColorProvider cp;

  @override
  State<GetPremiumWidget> createState() => _GetPremiumWidgetState();
}

class _GetPremiumWidgetState extends State<GetPremiumWidget> {
  EntitlementInfo? _entitlement;
  PackageType? _packageType;
  bool _hasPro = BillingService.hasPro;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final hasPro = await BillingService.checkHasPro();
    if (!mounted) return;
    setState(() {
      _hasPro = hasPro;
      BillingService.hasPro = hasPro;
    });
    if (hasPro && _entitlement == null) _loadEntitlement();
  }

  Future<void> _loadEntitlement() async {
    try {
      final results = await Future.wait([
        Purchases.getCustomerInfo(),
        BillingService.fetchOffers(),
      ]);
      final info = results[0] as CustomerInfo;
      final offerings = results[1] as List;
      final entitlement = BillingService.activeEntitlement(info);
      if (!mounted) return;

      PackageType? packageType;
      if (entitlement != null) {
        final productId = entitlement.productIdentifier;
        // Primary: match against loaded packages to get RevenueCat's PackageType.
        for (final offering in offerings) {
          for (final pkg in (offering as dynamic).availablePackages as List) {
            if ((pkg as dynamic).storeProduct.identifier == productId) {
              packageType = (pkg as dynamic).packageType as PackageType;
              break;
            }
          }
          if (packageType != null) break;
        }
        // Fallback: infer from product ID string.
        packageType ??= _inferPackageType(productId);
      }

      setState(() {
        _entitlement = entitlement;
        _packageType = packageType;
      });
    } catch (_) {}
  }

  PackageType? _inferPackageType(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('lifetime')) return PackageType.lifetime;
    if (id.contains('annual') || id.contains('yearly') || id.contains('year')) {
      return PackageType.annual;
    }
    if (id.contains('6month') || id.contains('six')) return PackageType.sixMonth;
    if (id.contains('3month') || id.contains('three')) return PackageType.threeMonth;
    if (id.contains('week')) return PackageType.weekly;
    if (id.contains('month')) return PackageType.monthly;
    return null;
  }

  String _planLabel(AppLocalizations loc) {
    return switch (_packageType) {
      PackageType.annual => loc.paywallYearly,
      PackageType.sixMonth => loc.paywallSixMonths,
      PackageType.threeMonth => loc.paywallThreeMonths,
      PackageType.weekly => loc.paywallWeekly,
      PackageType.lifetime => loc.paywallLifetime,
      PackageType.monthly => loc.paywallMonthly,
      _ => '',
    };
  }

  String _formatExpiration(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPro) return _buildSubscribedWidget(context);
    return _buildGetPremiumWidget(context);
  }

  Widget _buildGetPremiumWidget(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
        if (mounted) _refreshStatus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.cp.widget,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/widget-images/premium-widget.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          loc.getPremium,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          loc.supportDeveloper,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: Image.asset(
                      'assets/images/widget-images/gem.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribedWidget(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = widget.cp;
    final entitlement = _entitlement;
    final planLabel = _planLabel(loc);
    final expiryFormatted = _formatExpiration(entitlement?.expirationDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cp.widget,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cp.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      loc.currentPlan,
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (expiryFormatted.isNotEmpty)
                      Text(
                        loc.renewsOn(expiryFormatted),
                        style: TextStyle(color: cp.lightGreyText, fontSize: 16),
                      ),
                  ],
                ),
              ),
              if (planLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0x1911F29B),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0x330CD280),
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    planLabel,
                    style: TextStyle(color: cp.main, fontSize: 16),
                  ),
                ),
            ],
          ),
          NewDefaultButton.secondary(
            textStyle: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            height: 40,
            label: loc.paywallManageSubscription,
            width: double.infinity,
            onPressed: () async {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
            },
          ),
        ],
      ),
    );
  }
}
