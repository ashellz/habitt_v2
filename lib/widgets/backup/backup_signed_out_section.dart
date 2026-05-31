import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/restore_choice_dialog.dart';
import 'package:provider/provider.dart';

class BackupSignedOutSection extends StatefulWidget {
  const BackupSignedOutSection({super.key, required this.onAfterSignIn});

  final VoidCallback onAfterSignIn;

  @override
  State<BackupSignedOutSection> createState() => _BackupSignedOutSectionState();
}

class _BackupSignedOutSectionState extends State<BackupSignedOutSection> {
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
    widget.onAfterSignIn();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: cp.field,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: cp.border),
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
                      cp.lightGreyText,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  loc.signInWithGoogle,
                  style: TextStyle(
                    color: cp.text,
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
                      color: cp.text,
                    ),
                  )
                else
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
        ),
      ),
    );
  }
}
