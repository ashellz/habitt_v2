import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';

class SyncProgressOverlay {
  static OverlayEntry? _entry;

  static void showIfNeeded(
    BuildContext context,
    BackupProvider bp,
    ColorProvider cp,
  ) {
    if (_entry != null) return;
    if (!context.mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final loc = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.viewPaddingOf(context).top;

    _entry = OverlayEntry(
      builder:
          (_) => _SyncProgressOverlayWidget(
            bp: bp,
            cp: cp,
            loc: loc,
            topPadding: topPadding,
            onDismiss: _dismiss,
          ),
    );
    overlay.insert(_entry!);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _SyncProgressOverlayWidget extends StatefulWidget {
  const _SyncProgressOverlayWidget({
    required this.bp,
    required this.cp,
    required this.loc,
    required this.topPadding,
    required this.onDismiss,
  });

  final BackupProvider bp;
  final ColorProvider cp;
  final AppLocalizations loc;
  final double topPadding;
  final VoidCallback onDismiss;

  @override
  State<_SyncProgressOverlayWidget> createState() =>
      _SyncProgressOverlayWidgetState();
}

class _SyncProgressOverlayWidgetState extends State<_SyncProgressOverlayWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _entryAnimation;
  late final AnimationController _spinController;
  Timer? _dismissTimer;
  bool _showingSuccess = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _entryController.forward();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    widget.bp.addListener(_onBpChanged);
  }

  void _onBpChanged() {
    if (!mounted) return;
    final state = widget.bp.syncState;
    if (state == SyncState.success && !_showingSuccess) {
      setState(() => _showingSuccess = true);
      _spinController.stop();
      _dismissTimer = Timer(const Duration(milliseconds: 1200), _animateOut);
    } else if (state == SyncState.error) {
      _animateOut();
    }
  }

  void _animateOut() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    _entryController.reverse().whenComplete(widget.onDismiss);
  }

  @override
  void dispose() {
    widget.bp.removeListener(_onBpChanged);
    _dismissTimer?.cancel();
    _entryController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  String _bodyText() {
    if (_showingSuccess) return '';
    final bp = widget.bp;
    final loc = widget.loc;
    if (bp.syncIsUploading) return loc.syncOverlayUploadingChanges;
    if (bp.syncCurrentDelta > 0) {
      return loc.syncOverlayUpdatesRemaining(bp.syncCurrentDelta);
    }
    if (bp.syncHasBackup) return loc.syncOverlayDownloadingBackup;
    return loc.syncOverlayUploadingChanges;
  }

  String _titleText() {
    if (_showingSuccess) return widget.loc.syncOverlayTitleUpToDate;
    if (widget.bp.syncIsUploading) return widget.loc.syncOverlayTitleUploading;
    return widget.loc.syncOverlayTitleSyncing;
  }

  @override
  Widget build(BuildContext context) {
    final cp = widget.cp;

    return Positioned(
      top: widget.topPadding + 10,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: FadeTransition(
          opacity: _entryAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(_entryAnimation),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.94,
                end: 1,
              ).animate(_entryAnimation),
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: widget.bp,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: ShapeDecoration(
                            color: cp.field,
                            shape: const StadiumBorder(),
                            shadows: [
                              BoxShadow(
                                color: cp.bg.withValues(alpha: 0.6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                spacing: 12,
                                children: [
                                  // Icon circle
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: cp.main.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child:
                                          _showingSuccess
                                              ? SvgPicture.asset(
                                                cp.isDark
                                                    ? 'assets/images/new-svg/check-on-dark.svg'
                                                    : 'assets/images/new-svg/check-on-light.svg',
                                                width: 20,
                                                height: 20,
                                              )
                                              : RotationTransition(
                                                turns: _spinController,
                                                child: Icon(
                                                  Icons.sync,
                                                  size: 20,
                                                  color: cp.main,
                                                ),
                                              ),
                                    ),
                                  ),
                                  // Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 2,
                                      children: [
                                        Text(
                                          _titleText(),
                                          style: TextStyle(
                                            color: cp.text,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (!_showingSuccess)
                                          Text(
                                            _bodyText(),
                                            style: TextStyle(
                                              color: cp.lightGreyText,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (!_showingSuccess) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value:
                                        widget.bp.syncIsUploading
                                            ? null
                                            : widget.bp.syncProgress,
                                    minHeight: 3,
                                    backgroundColor: cp.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      cp.main,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
