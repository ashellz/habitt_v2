import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:habitt/pages/onboarding/choose_app_language.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitt/l10n/app_localizations.dart';

class OnboardingPages extends StatefulWidget {
  const OnboardingPages({super.key});

  @override
  State<OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends State<OnboardingPages> {
  late PageController _outerController;

  @override
  void initState() {
    super.initState();
    _outerController = PageController();
  }

  @override
  void dispose() {
    _outerController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('didOnboard', true);

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  void _goToIntro() {
    _outerController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _backToLanguage() {
    _outerController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _outerController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ChooseAppLanguage(onNext: _goToIntro),
        _OnboardingIntroTemplate(
          onDone: _finishOnboarding,
          onBack: _backToLanguage,
        ),
      ],
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData accent;
}

class _OnboardingIntroTemplate extends StatefulWidget {
  const _OnboardingIntroTemplate({required this.onDone, required this.onBack});

  final Future<void> Function() onDone;
  final VoidCallback onBack;

  @override
  State<_OnboardingIntroTemplate> createState() =>
      _OnboardingIntroTemplateState();
}

class _OnboardingIntroTemplateState extends State<_OnboardingIntroTemplate> {
  static const int _stepCount = 4;

  List<_OnboardingStepData> _buildSteps(AppLocalizations loc) => [
    _OnboardingStepData(
      title: loc.onboardingStep1Title,
      subtitle: loc.onboardingStep1Subtitle,
      accent: Icons.check_circle_rounded,
    ),
    _OnboardingStepData(
      title: loc.onboardingStep2Title,
      subtitle: loc.onboardingStep2Subtitle,
      accent: Icons.track_changes_rounded,
    ),
    _OnboardingStepData(
      title: loc.onboardingStep3Title,
      subtitle: loc.onboardingStep3Subtitle,
      accent: Icons.local_fire_department_rounded,
    ),
    _OnboardingStepData(
      title: loc.onboardingStep4Title,
      subtitle: loc.onboardingStep4Subtitle,
      accent: Icons.notifications_active_rounded,
    ),
  ];

  late PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentStep == _stepCount - 1;

  Future<void> _goNext() async {
    if (_isLastStep) {
      await widget.onDone();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skip() async {
    await widget.onDone();
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final steps = _buildSteps(loc);

    return Scaffold(
      backgroundColor: cp.main,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).viewPadding.top,
              16,
              12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NewDefaultButton.secondarySmall(
                  width: null,
                  onPressed: _goBack,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: cp.text,
                  ),
                ),
                NewDefaultButton.secondarySmall(
                  width: null,
                  onPressed: _skip,
                  label: loc.skip,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    itemCount: _stepCount,
                    itemBuilder: (context, index) {
                      return _OnboardingVisualTemplate(
                        key: ValueKey(index),
                        stepIndex: index,
                        accentIcon: steps[index].accent,
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    32 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: cp.bg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 480),
                        tween: Tween<double>(
                          begin: 0,
                          end: _currentStep.toDouble(),
                        ),
                        curve: Curves.easeInOut,
                        builder: (context, value, _) {
                          final animStep = steps[value.round()];
                          final screenWidth = MediaQuery.of(context).size.width;
                          return ClipRect(
                            child: Stack(
                              children: [
                                Transform.translate(
                                  offset: Offset(
                                    -((value + 0.5).remainder(1) - 0.5) *
                                        screenWidth *
                                        2,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        animStep.title,
                                        style: TextStyle(
                                          color: cp.text,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        animStep.subtitle,
                                        style: TextStyle(
                                          color: cp.greyText,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: (value - value.round()).abs() * 30,
                                    sigmaY: 0,
                                  ),
                                  child: Container(color: Colors.transparent),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              _stepCount,
                              (index) => Container(
                                margin: EdgeInsets.only(
                                  right: index == _stepCount - 1 ? 0 : 6,
                                ),
                                width: index == _currentStep ? 20 : 7,
                                height: 5,
                                decoration: BoxDecoration(
                                  color:
                                      index == _currentStep
                                          ? cp.text
                                          : cp.border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          NewDefaultButton.primarySmall(
                            label: _isLastStep ? loc.getStarted : loc.next,
                            width: null,
                            onPressed: _goNext,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingVisualTemplate extends StatelessWidget {
  const _OnboardingVisualTemplate({
    super.key,
    required this.stepIndex,
    required this.accentIcon,
  });

  final int stepIndex;
  final IconData accentIcon;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10, right: 16, left: 16),
      decoration: BoxDecoration(
        color: cp.bg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Container(
          width: 250,
          height: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cp.bg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 2),
              Container(
                width: 95,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 26),
              Icon(accentIcon, size: 58, color: cp.main),
              const SizedBox(height: 16),
              _TemplateStatRow(cp: cp, widthFactor: 0.85),
              const SizedBox(height: 10),
              _TemplateStatRow(cp: cp, widthFactor: 1),
              const SizedBox(height: 10),
              _TemplateStatRow(cp: cp, widthFactor: 0.7),
              const Spacer(),
              Container(
                width: 120,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateStatRow extends StatelessWidget {
  const _TemplateStatRow({required this.cp, required this.widthFactor});

  final ColorProvider cp;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: cp.secondaryButton,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
