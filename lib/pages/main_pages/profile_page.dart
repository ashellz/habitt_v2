import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/other_pages/paywall_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/rate_bug_report_service.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:habitt/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.habitBg,
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          ProfileTopPart(cp: cp),
          ProfileOptions(cp: cp),
        ],
      ),
    );
  }
}

class ProfileTopPart extends StatefulWidget {
  const ProfileTopPart({super.key, required this.cp});

  final ColorProvider cp;

  @override
  State<ProfileTopPart> createState() => _ProfileTopPartState();
}

class _ProfileTopPartState extends State<ProfileTopPart> {
  String? name;
  String? email;

  @override
  void initState() {
    super.initState();

    // Loading name
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name');
        email = prefs.getString('backup_user_email');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = this.name ?? 'Guest';
    final email = this.email ?? '';

    return Container(
      color: widget.cp.bg,
      child: Padding(
        padding: EdgeInsets.only(
          top: 20 + MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
        child: Column(
          spacing: 14,
          children: [
            _topBar(widget.cp),
            Column(
              spacing: 16,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Column(
                  spacing: 8,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.cp.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          color: widget.cp.lightGreyText,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Row _topBar(ColorProvider cp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),

        NewCircleButton(
          svgPath: 'assets/images/new-svg/edit.svg',
          cnIcon: CNSymbol('pencil.line', size: 14),
          width: 44,
          height: 44,
          color: cp.bg,
          padding: const EdgeInsets.all(13),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
              barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
              isScrollControlled: true,
              builder: (context) => EditProfileSheet(),
            );
          },
        ),
      ],
    );
  }
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  bool _isExitDialogOpen = false;
  bool _allowPop = false;
  final closeResult = false;
  final scrollController = ScrollController();
  final hasUnsavedChanges = false;

  void _popSheet({required bool result}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop(result);
  }

  Future<void> _showExitConfirmation(bool allowPop) async {
    if (_isExitDialogOpen) {
      return;
    }

    final title = AppLocalizations.of(context)!.exitWithoutSaving;
    final desc = AppLocalizations.of(context)!.allChangesYouMadeWillBeDiscarded;

    _isExitDialogOpen = true;
    await showDialogSheet(
      context: context,
      builder: (dialogContext) => NewDefaultDialog(
        title: title,
        desc: desc,
        primaryButtonLabel: AppLocalizations.of(context)!.exit,
        onPrimaryButtonPressed: () {
          Navigator.of(dialogContext).pop();
          _popSheet(result: closeResult);
        },
      ),
    );
    _isExitDialogOpen = false;
  }

  Future<void> _handleCloseAttempt() async {
    if (_allowPop || !hasUnsavedChanges) {
      _popSheet(result: closeResult);
      return;
    }

    await _showExitConfirmation(closeResult);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    final canSave = true;

    return PopScope(
      canPop: _allowPop || !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleCloseAttempt();
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
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topSection(context, cp, canSave),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [],
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

  Padding topSection(BuildContext context, ColorProvider cp, bool canSave) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _handleCloseAttempt();
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
            AppLocalizations.of(context)!.editProfile,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: NewDefaultButton.primarySmall(
              enabled: canSave,
              onPressed: () async {
                if (!canSave) {
                  return;
                }
                // Save logic here
              },
              label: AppLocalizations.of(context)!.save,
            ),
          ),
        ],
      ),
    );
  }
}

class GetPremiumWidget extends StatelessWidget {
  const GetPremiumWidget({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallPage()),
        );
      },
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: cp.bg,
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        'Get Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Enjoy all the benefits of the app',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
}

class RateReportSheet extends StatefulWidget {
  const RateReportSheet({super.key});

  @override
  State<RateReportSheet> createState() => _RateReportSheetState();
}

class _RateReportSheetState extends State<RateReportSheet> {
  bool _allowPop = false;

  void _popSheet() {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          _RateReportOption(
                            cp: cp,
                            text: 'Rate us',
                            svgPath: 'assets/images/new-svg/rate.svg',
                            onTap: () async {
                              try {
                                await RateBugReportService.rateUs();
                              } catch (e) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Unable to open rating. Please try again.'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          Divider(color: cp.border, height: 32),
                          _RateReportOption(
                            cp: cp,
                            text: 'Report a bug',
                            svgPath: 'assets/images/new-svg/rate.svg',
                            onTap: () async {
                              try {
                                await RateBugReportService.sendBugReport();
                              } catch (e) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Unable to open email. Please try again.'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
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
            "Rate & Report",
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

class _RateReportOption extends StatelessWidget {
  const _RateReportOption({
    required this.cp,
    required this.text,
    required this.svgPath,
    required this.onTap,
  });

  final ColorProvider cp;
  final String text;
  final String svgPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Row(
          spacing: 12,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: SvgPicture.asset(
                svgPath,
                colorFilter: ColorFilter.mode(
                  cp.lightGreyText,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.contain,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: cp.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(
                'assets/images/new-svg/back.svg',
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
