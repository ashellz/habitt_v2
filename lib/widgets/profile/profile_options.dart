import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/restore_choice_dialog.dart';
import 'package:habitt/widgets/profile/get_premium_widget.dart';
import 'package:habitt/widgets/profile/leave_feedback_sheet.dart';
import 'package:habitt/widgets/sheets/backup_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileOptions extends StatefulWidget {
  const ProfileOptions({
    super.key,
    required this.cp,
    required this.statusOverlay,
  });

  final ColorProvider cp;
  final StatusOverlayPopupController statusOverlay;

  @override
  State<ProfileOptions> createState() => _ProfileOptionsState();
}

class _ProfileOptionsState extends State<ProfileOptions> {
  _showBackupSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.cp.isDark ? widget.cp.habitBg : widget.cp.bg,
      barrierColor: widget.cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => BackupSheet(statusOverlay: widget.statusOverlay),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.logOut,
            desc: loc.logOutDesc,
            primaryButtonLabel: loc.logOut,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      await bp.signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    BackupProvider bp,
    AppLocalizations loc,
    ColorProvider cp,
  ) async {
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.deleteAccount,
            desc: loc.deleteAccountDesc,
            primaryButtonLabel: loc.delete,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      final success = await bp.deleteAccount();
      if (!context.mounted) return;
      if (success) {
        widget.statusOverlay.show(
          context: context,
          cp: cp,
          title: loc.accountDeletedSuccessfully,
          isError: false,
        );
        Navigator.of(context).pop();
      } else {
        widget.statusOverlay.show(
          context: context,
          cp: cp,
          title: loc.accountDeletionFailed(bp.lastError ?? ''),
          isError: true,
        );
      }
    }
  }

  bool _signingIn = false;

  Future<void> _handleSignIn(BackupProvider bp) async {
    setState(() => _signingIn = true);
    await bp.signIn(context);
    if (mounted) setState(() => _signingIn = false);
    if (!mounted) return;
    if (context.read<BackupProvider>().pendingRestoreDecision) {
      await showDialogSheet<void>(
        context: context,
        builder: (_) => const RestoreChoiceDialog(),
      );
    }
    if (!mounted) return;
    if (context.read<BackupProvider>().isLoggedIn) {
      _showBackupSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bp = context.watch<BackupProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      color: widget.cp.habitBg,
      child: Column(
        spacing: 10,
        children: [
          GetPremiumWidget(cp: widget.cp),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: widget.cp.field,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: widget.cp.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    ProfileOption(
                      cp: widget.cp,
                      text: loc.privacyPolicy,
                      svgPath: 'assets/images/new-svg/privacy-policy.svg',
                      onTap: () async {
                        final privacyUrl = Uri.parse(
                          'https://ashellz.github.io/habitt_v2/privacy.html',
                        );
                        if (await canLaunchUrl(privacyUrl)) {
                          await launchUrl(
                            privacyUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),

                    Divider(color: widget.cp.border, height: 32),
                    ProfileOption(
                      cp: widget.cp,
                      text: loc.termsOfService,
                      svgPath: 'assets/images/new-svg/terms.svg',
                      onTap: () async {
                        final tosUrl = Uri.parse(
                          'https://ashellz.github.io/habitt_v2/tos.html',
                        );
                        if (await canLaunchUrl(tosUrl)) {
                          await launchUrl(
                            tosUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    Divider(color: widget.cp.border, height: 32),
                    ProfileOption(
                      cp: widget.cp,
                      text: loc.leaveFeedback,
                      svgPath: 'assets/images/new-svg/rate.svg',
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          backgroundColor:
                              widget.cp.isDark
                                  ? widget.cp.habitBg
                                  : widget.cp.bg,
                          barrierColor: widget.cp.greyText.darken().withValues(
                            alpha: 0.3,
                          ),
                          isScrollControlled: true,
                          builder: (context) => LeaveFeedbackSheet(),
                        );
                      },
                    ),
                    Divider(color: widget.cp.border, height: 32),
                    ProfileOption(
                      cp: widget.cp,
                      text: loc.backupAndSync,
                      svgPath: 'assets/images/new-svg/backup.svg',
                      onTap: _showBackupSheet,
                    ),
                  ],
                ),
              ),
              if (bp.isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: widget.cp.field,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: widget.cp.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _confirmSignOut(context, bp, loc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.transparent,
                          child: Row(
                            spacing: 12,
                            children: [
                              Text(
                                loc.logOut,
                                style: TextStyle(
                                  color: widget.cp.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              SvgPicture.asset(
                                'assets/images/new-svg/log-out.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  widget.cp.error,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: widget.cp.border, height: 1),
                      GestureDetector(
                        onTap:
                            () => _confirmDeleteAccount(
                              context,
                              bp,
                              loc,
                              widget.cp,
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.transparent,
                          child: Row(
                            spacing: 12,
                            children: [
                              Text(
                                loc.deleteAccount,
                                style: TextStyle(
                                  color: widget.cp.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              SvgPicture.asset(
                                'assets/images/new-svg/trash.svg',
                                width: 19,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  widget.cp.error,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: widget.cp.field,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: widget.cp.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: _signingIn ? null : () => _handleSignIn(bp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.transparent,
                      child: Row(
                        spacing: 12,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: SvgPicture.asset(
                              'assets/images/new-svg/google.svg',
                              colorFilter: ColorFilter.mode(
                                widget.cp.lightGreyText,
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Text(
                            loc.signInWithGoogle,
                            style: TextStyle(
                              color: widget.cp.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (_signingIn)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.cp.text,
                              ),
                            )
                          else
                            RotatedBox(
                              quarterTurns: 2,
                              child: SvgPicture.asset(
                                'assets/images/new-svg/back.svg',
                                colorFilter: ColorFilter.mode(
                                  widget.cp.text,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  const ProfileOption({
    super.key,
    required this.cp,
    required this.text,
    this.svgPath,
    this.onTap,
  });

  final ColorProvider cp;
  final String text;
  final String? svgPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Row(
          spacing: 12,
          children: [
            if (svgPath != null)
              SizedBox(
                height: 20,
                width: 20,
                child: SvgPicture.asset(
                  svgPath!,
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
