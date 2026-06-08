import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/billing_service.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Toggle to show placeholder plans in debug builds without a RevenueCat configuration.
const bool _debugShowPlaceholderPlans = false;

enum _ButtonAction { purchase, upgrade, downgrade, cancel, manage }

int _rankOf(PackageType type) => switch (type) {
  PackageType.weekly => 1,
  PackageType.monthly => 2,
  PackageType.threeMonth => 3,
  PackageType.sixMonth => 4,
  PackageType.annual => 5,
  PackageType.lifetime => 6,
  _ => 0,
};

class _PlanInfo {
  const _PlanInfo({
    required this.name,
    required this.price,
    required this.period,
    this.badge,
    this.package,
    this.isOneTimePurchase = false,
  });

  final String name;
  final String price;
  final String period;
  final String? badge;
  final bool isOneTimePurchase;
  // null for debug placeholder plans
  final Package? package;
}

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _hasPro = BillingService.hasPro;
  bool _isRefreshing = false;
  bool _isPresenting = false;
  bool _isLoadingOffers = true;

  List<Package> _packages = [];
  String? _activeProductId;
  String? _managementUrl;

  final PageController _pageController = PageController(viewportFraction: 0.88);
  double _pageValue = 0;

  Package? get _selectedPackage {
    if (kDebugMode && _debugShowPlaceholderPlans) return null;
    if (_packages.isEmpty) return null;
    return _packages[_pageValue.round().clamp(0, _packages.length - 1)];
  }

  PackageType? get _activePackageType {
    if (_activeProductId == null) return null;
    // Primary: match by store product identifier against loaded packages.
    try {
      return _packages
          .firstWhere((p) => p.storeProduct.identifier == _activeProductId)
          .packageType;
    } catch (_) {}
    // Fallback: infer from product ID string so sandbox/old products still work.
    final id = _activeProductId!.toLowerCase();
    if (id.contains('lifetime')) return PackageType.lifetime;
    if (id.contains('annual') || id.contains('yearly') || id.contains('year')) {
      return PackageType.annual;
    }
    if (id.contains('6month') || id.contains('six')) {
      return PackageType.sixMonth;
    }
    if (id.contains('3month') || id.contains('three')) {
      return PackageType.threeMonth;
    }
    if (id.contains('week')) return PackageType.weekly;
    if (id.contains('month')) return PackageType.monthly;
    return null;
  }

  _ButtonAction get _buttonAction {
    if (!_hasPro) return _ButtonAction.purchase;
    final selected = _selectedPackage;
    // Subscribed but no plan card shown yet — open management page.
    if (selected == null) return _ButtonAction.manage;
    final activeType = _activePackageType;
    // Subscribed but can't determine current plan — open management page.
    if (activeType == null) return _ButtonAction.manage;
    final activeRank = _rankOf(activeType);
    final selectedRank = _rankOf(selected.packageType);
    if (selectedRank == activeRank) return _ButtonAction.cancel;
    if (selectedRank > activeRank) return _ButtonAction.upgrade;
    return _ButtonAction.downgrade;
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageChanged);
    _refreshSubscriptionStatus();
    _loadOfferings();
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged() {
    if (mounted) {
      setState(() {
        _pageValue =
            _pageController.hasClients ? (_pageController.page ?? 0) : 0;
      });
    }
  }

  Future<void> _loadOfferings() async {
    if (kDebugMode && _debugShowPlaceholderPlans) {
      setState(() => _isLoadingOffers = false);
      return;
    }
    setState(() => _isLoadingOffers = true);
    final offerings = await BillingService.fetchOffers();
    if (!mounted) return;
    setState(() {
      if (offerings.isNotEmpty) {
        _packages = offerings.first.availablePackages;
      }
      _isLoadingOffers = false;
    });
  }

  Future<void> _refreshSubscriptionStatus() async {
    setState(() => _isRefreshing = true);
    try {
      final info = await Purchases.getCustomerInfo();
      if (!mounted) return;
      final entitlement = BillingService.activeEntitlement(info);
      setState(() {
        _hasPro = entitlement != null;
        BillingService.hasPro = _hasPro;
        _activeProductId = entitlement?.productIdentifier;
        _managementUrl = info.managementURL;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleRestorePurchases() async {
    HapticFeedback.selectionClick();
    setState(() => _isPresenting = true);
    try {
      await Purchases.restorePurchases();
      await _refreshSubscriptionStatus();
    } finally {
      if (mounted) setState(() => _isPresenting = false);
    }
  }

  Future<void> _handleUpgradeTap() async {
    HapticFeedback.selectionClick();

    /*
    
    final action = _buttonAction;

    if (action == _ButtonAction.cancel || action == _ButtonAction.manage) {
      await _handleCancelTap();
      return;
    }
    */

    setState(() => _isPresenting = true);
    try {
      await BillingService.purchasePackage(_selectedPackage!);

      await _refreshSubscriptionStatus();
    } finally {
      if (mounted) setState(() => _isPresenting = false);
    }
  }

  Future<void> _handleCancelTap() async {
    HapticFeedback.selectionClick();
    final url = _managementUrl;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  List<_PlanInfo> _buildPlanInfos(AppLocalizations loc) {
    if (kDebugMode && _debugShowPlaceholderPlans) {
      return [
        _PlanInfo(
          name: loc.paywallYearly,
          price: r'$19.99',
          period: loc.paywallPerYear,
          badge: loc.paywallBestValue,
        ),
        _PlanInfo(
          name: loc.paywallMonthly,
          price: r'$2.99',
          period: loc.paywallPerMonth,
          badge: loc.paywallMostPopular,
        ),
        _PlanInfo(
          name: loc.paywallLifetime,
          price: r'$49.99',
          period: loc.paywallOneTimePurchase,
          isOneTimePurchase: true,
        ),
      ];
    }
    return _packages
        .map(
          (p) => _PlanInfo(
            name: _localizedPlanName(p.packageType, p.identifier, loc),
            price: p.storeProduct.priceString,
            period: _localizedPeriodLabel(p.packageType, loc),
            badge: _localizedBadgeLabel(p.packageType, loc),
            isOneTimePurchase: p.packageType == PackageType.lifetime,
            package: p,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final plans = _buildPlanInfos(loc);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/paywall_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section — horizontally padded
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: const EdgeInsets.only(
                              right: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            color: Colors.transparent,
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: SvgPicture.asset(
                                height: 20,
                                width: 20,
                                'assets/images/new-svg/back.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          spacing: 8,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.paywallUpgradeTo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Row(
                                spacing: 8,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Image.asset(
                                      'assets/images/widget-images/gem.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.75,
                            child: Text(
                              loc.paywallSupportUs,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          spacing: 10,
                          children: [
                            PremiumBenefit(
                              icon: const Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: 20,
                              ),
                              text: loc.paywallCustomScheduling,
                            ),
                            PremiumBenefit(
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 20,
                              ),
                              text: loc.paywallPerHabitNotifications,
                            ),
                            PremiumBenefit(
                              icon: const Icon(
                                Icons.bar_chart,
                                color: Colors.white,
                                size: 20,
                              ),
                              text: loc.paywallImprovementSuggestions,
                            ),
                            PremiumBenefit(
                              icon: const Icon(
                                Icons.cloud,
                                color: Colors.white,
                                size: 20,
                              ),
                              text: loc.paywallCloudBackupSync,
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          width: double.infinity,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignCenter,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Plan cards — full width, top padding gives badge chip room
                  const SizedBox(height: 24 - 15),
                  SizedBox(
                    height: 175,
                    child:
                        _isLoadingOffers
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : plans.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  loc.paywallProductsUnavailable,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: plans.length,
                                itemBuilder: (context, index) {
                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    child: _PlanCard(
                                      plan: plans[index],
                                      isActive:
                                          plans[index]
                                              .package
                                              ?.storeProduct
                                              .identifier ==
                                          _activeProductId,
                                    ),
                                    builder: (context, child) {
                                      final distance = (_pageValue - index)
                                          .abs()
                                          .clamp(0.0, 1.0);
                                      final scale = 1.0 - distance * 0.05;
                                      final translateY = distance * 10.0;
                                      return Transform.translate(
                                        offset: Offset(0, translateY),
                                        child: Transform.scale(
                                          scale: scale,
                                          child: child,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                  ),
                  // Bottom section — horizontally padded
                  const SizedBox(height: 16),
                  if (!_isLoadingOffers && plans.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: List.generate(plans.length, (index) {
                        final isActive = _pageValue.round() == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: isActive ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: isActive ? 1.0 : 0.4,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        NewDefaultButton(
                          label: switch (_buttonAction) {
                            _ButtonAction.purchase => loc.paywallUpgradeNow,
                            _ButtonAction.upgrade => loc.paywallUpgrade,
                            _ButtonAction.downgrade => loc.paywallDowngrade,
                            _ButtonAction.cancel => loc.paywallCancel,
                            _ButtonAction.manage =>
                              loc.paywallManageSubscription,
                          },
                          onPressed: _isPresenting ? () {} : _handleUpgradeTap,
                          isLoading: _isRefreshing,
                          width: double.infinity,
                          color: Colors.white,
                          textColor: const Color(0xFF02D382),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isPresenting ? null : _handleRestorePurchases,
                          child: Text(
                            loc.paywallRestorePurchases,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedPlanName(
  PackageType type,
  String identifier,
  AppLocalizations loc,
) {
  return switch (type) {
    PackageType.annual => loc.paywallYearly,
    PackageType.monthly => loc.paywallMonthly,
    PackageType.lifetime => loc.paywallLifetime,
    PackageType.sixMonth => loc.paywallSixMonths,
    PackageType.threeMonth => loc.paywallThreeMonths,
    PackageType.weekly => loc.paywallWeekly,
    _ => identifier,
  };
}

String _localizedPeriodLabel(PackageType type, AppLocalizations loc) {
  return switch (type) {
    PackageType.annual => loc.paywallPerYear,
    PackageType.monthly => loc.paywallPerMonth,
    PackageType.lifetime => loc.paywallOneTimePurchase,
    PackageType.sixMonth => loc.paywallPerSixMonths,
    PackageType.threeMonth => loc.paywallPerThreeMonths,
    PackageType.weekly => loc.paywallPerWeek,
    _ => '',
  };
}

String? _localizedBadgeLabel(PackageType type, AppLocalizations loc) {
  return switch (type) {
    PackageType.annual => loc.paywallBestValue,
    PackageType.monthly => loc.paywallMostPopular,
    _ => null,
  };
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.isActive = false});

  final _PlanInfo plan;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isOneTime = plan.isOneTimePurchase;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 15),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Colors.white),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        opacity: isActive ? 1.0 : 0.0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          scale: isActive ? 1.0 : 0.7,
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            turns: isActive ? 0.0 : 0.18,
                            child: SvgPicture.asset(
                              'assets/images/new-svg/check-on-light.svg',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        plan.period,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: isOneTime ? 0.75 : 1.0,
                          ),
                          fontSize: isOneTime ? 13 : 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (plan.badge != null)
            Positioned(
              left: 16,
              top: -15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  plan.badge!,
                  style: const TextStyle(
                    color: Color(0xFF02D382),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumBenefit extends StatelessWidget {
  const PremiumBenefit({super.key, required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: icon,
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
