import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/billing_service.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _hasPro = BillingService.hasPro;
  bool _isRefreshing = false;
  bool _isPresenting = false;

  @override
  void initState() {
    super.initState();
    _refreshSubscriptionStatus();
  }

  Future<void> _refreshSubscriptionStatus() async {
    setState(() {
      _isRefreshing = true;
    });
    final hasPro = await BillingService.checkHasPro();
    if (!mounted) return;
    setState(() {
      _hasPro = hasPro;
      _isRefreshing = false;
    });
  }

  Future<void> _handleUpgradeTap() async {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasPro ? 'Opening subscription settings...' : 'Opening paywall...',
        ),
      ),
    );
    setState(() {
      _isPresenting = true;
    });
    try {
      await BillingService.presentPaywall();
      await _refreshSubscriptionStatus();
    } finally {
      setState(() {
        _isPresenting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SizedBox(
                width: double.infinity,

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
                    SizedBox(height: 16),
                    Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Upgrade to',
                          style: TextStyle(
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
                              Text(
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
                    SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: Text(
                          'These features are available for free - support us by upgrading anyway',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Column(
                      spacing: 10,
                      children: [
                        PremiumBenefit(
                          icon: Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 20,
                          ),
                          text: 'Custom habit scheduling',
                        ),
                        PremiumBenefit(
                          icon: Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 20,
                          ),
                          text: 'Per habit notifications',
                        ),
                        PremiumBenefit(
                          icon: Icon(
                            Icons.bar_chart,
                            color: Colors.white,
                            size: 20,
                          ),
                          text: 'Habit improvement suggestions',
                        ),
                        PremiumBenefit(
                          icon: Icon(
                            Icons.cloud,
                            color: Colors.white,
                            size: 20,
                          ),

                          text: 'Cloud backup and sync',
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
                    SizedBox(height: 37),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 124,
                          width: 245,
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 1, color: Colors.white),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Yearly',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    'assets/images/new-svg/check-on-light.svg',
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                              'Best value',
                              style: TextStyle(
                                color: const Color(0xFF02D382),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
