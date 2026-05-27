import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/feedback_service.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:provider/provider.dart';

class LeaveFeedbackSheet extends StatefulWidget {
  const LeaveFeedbackSheet({super.key});

  @override
  State<LeaveFeedbackSheet> createState() => _LeaveFeedbackSheetState();
}

class _LeaveFeedbackSheetState extends State<LeaveFeedbackSheet> {
  bool _allowPop = false;

  void _popSheet() {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        _popSheet();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topSection(context, cp),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: cp.field,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: cp.border),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileOption(
                              cp: cp,
                              text: loc.rateUs,
                              svgPath: 'assets/images/new-svg/rate.svg',
                              onTap: () async {
                                try {
                                  await FeedbackService.rateUs();
                                } catch (e) {
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to open rating. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            Divider(color: cp.border, height: 32),
                            ProfileOption(
                              cp: cp,
                              text: loc.reportBug,
                              svgPath: 'assets/images/new-svg/rate.svg',
                              onTap: () async {
                                try {
                                  await FeedbackService.sendBugReport();
                                } catch (e) {
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to open email. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _topSection(BuildContext context, ColorProvider cp) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _popSheet();
            },
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              color: Colors.transparent,
              height: 36,
              width: 66 + 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  "assets/images/new-svg/back.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Text(
            loc.leaveFeedback,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 66 + 16),
        ],
      ),
    );
  }
}
