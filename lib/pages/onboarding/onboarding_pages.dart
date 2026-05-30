import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:habitt/pages/onboarding/choose_app_language.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/onboarding/onboarding_step1.dart';
import 'package:habitt/widgets/onboarding/onboarding_step2.dart';
import 'package:habitt/widgets/onboarding/onboarding_step3.dart';
import 'package:habitt/widgets/onboarding/onboarding_step4.dart';
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
  final GlobalKey<OnboardingStep4State> _step4Key = GlobalKey();

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
      _step4Key.currentState?.commitDraft();
      await widget.onDone();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skip() async {
    _step4Key.currentState?.commitDraft();
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
              0,
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
                  child: Transform.translate(
                    offset: Offset(0, 30),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentStep = index;
                        });
                      },
                      itemCount: _stepCount,
                      itemBuilder: (context, index) {
                        return switch (index) {
                          0 => const OnboardingStep1(key: ValueKey(0)),
                          1 => const OnboardingStep2(key: ValueKey(1)),
                          2 => const OnboardingStep3(key: ValueKey(2)),
                          _ => OnboardingStep4(key: _step4Key),
                        };
                      },
                    ),
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
