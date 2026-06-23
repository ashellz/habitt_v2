import 'dart:math' show pi;

import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/language_option.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class HabitNameLocalizationSheet extends StatefulWidget {
  const HabitNameLocalizationSheet({super.key, required this.cp});

  final ColorProvider cp;

  @override
  State<HabitNameLocalizationSheet> createState() =>
      _HabitNameLocalizationSheetState();
}

class _HabitNameLocalizationSheetState
    extends State<HabitNameLocalizationSheet> {
  String? _expandedLocale;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, bool> _buttonReady = {};

  late final StateProvider _sp;

  /// The currently active app locale — the only language whose row is
  /// auto-filled with the habit name when expanded. Resolved in
  /// [didChangeDependencies] because it needs the [Localizations] ancestor:
  /// `LanguageProvider.locale` is null when the app follows the system
  /// language, so we fall back to the resolved locale like the rest of the app.
  String? _activeLocale;

  /// Working copy — written to StateProvider only on Done.
  late Map<String, String> _localNames;

  /// Snapshot at open time — used for dirty check.
  late final Map<String, String> _initialNames;

  /// Set to true right before a programmatic pop so PopScope allows it.
  bool _allowClose = false;

  ColorProvider get cp => widget.cp;

  @override
  void initState() {
    super.initState();
    _sp = context.read<StateProvider>();
    _localNames = Map<String, String>.from(_sp.habitLocalizedNames);
    _initialNames = Map<String, String>.from(_sp.habitLocalizedNames);
    for (final option in LanguageOption.values) {
      _controllers[option.languageCode] = TextEditingController();
      _focusNodes[option.languageCode] = FocusNode();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeLocale ??=
        context.read<LanguageProvider>().locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _hasDirtyChanges {
    if (_localNames.length != _initialNames.length) return true;
    for (final entry in _localNames.entries) {
      if (_initialNames[entry.key] != entry.value) return true;
    }
    for (final key in _initialNames.keys) {
      if (!_localNames.containsKey(key)) return true;
    }
    return false;
  }

  void _expandRow(String localeCode) {
    setState(() {
      _buttonReady.remove(_expandedLocale);
      _expandedLocale = localeCode;
      // Convenience: expanding the active app language while its entry is empty
      // (and hasn't been cleared this session) seeds it with the current habit
      // name so the user doesn't have to retype it.
      final existing = _localNames[localeCode];
      final shouldPrefillActive =
          localeCode == _activeLocale &&
          (existing == null || existing.isEmpty) &&
          !_sp.activeNamePrefillCleared;
      if (shouldPrefillActive) {
        final habitName = _sp.nameController.text.trim();
        if (habitName.isNotEmpty) {
          _localNames[localeCode] = habitName;
        }
      }
      _controllers[localeCode]?.text = _localNames[localeCode] ?? '';
      _buttonReady[localeCode] = false;
    });
    _focusNodes[localeCode]?.requestFocus();
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted && _expandedLocale == localeCode) {
        setState(() => _buttonReady[localeCode] = true);
      }
    });
  }

  void _collapseRow() {
    _focusNodes[_expandedLocale]?.unfocus();
    setState(() {
      _buttonReady.remove(_expandedLocale);
      _expandedLocale = null;
    });
  }

  void _clearRow(String localeCode) {
    _focusNodes[localeCode]?.unfocus();
    setState(() {
      _localNames.remove(localeCode);
      _controllers[localeCode]?.clear();
      _buttonReady.remove(localeCode);
      _expandedLocale = null;
      // A deliberate clear of the active language disables auto-fill on
      // re-expand for the rest of this habit-sheet session.
      if (localeCode == _activeLocale) {
        _sp.activeNamePrefillCleared = true;
      }
    });
  }

  void _onNameChanged(String localeCode, String value) {
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _localNames.remove(localeCode);
      } else {
        _localNames[localeCode] = trimmed;
      }
    });
  }

  /// Bypasses PopScope and pops on the next frame.
  void _forceClose() {
    setState(() => _allowClose = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _handleDone() {
    _sp.habitLocalizedNames = Map<String, String>.from(_localNames);
    _sp.notifyHabitLocalizedNamesChanged();
    _forceClose();
  }

  void _handleBack() {
    if (!_hasDirtyChanges) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      return;
    }
    _showDiscardDialog();
  }

  Future<void> _showDiscardDialog() async {
    final loc = AppLocalizations.of(context)!;

    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: loc.discardChanges,
            desc:
                loc.youHaveUnsavedChangesAreYouSureYouWantToGoBackAndDiscardThem,
            primaryButtonLabel: loc.discard,
            onPrimaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
              _forceClose();
            },
            onSecondaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    final bottomInset =
        MediaQuery.viewInsetsOf(context).bottom + mediaQuery.padding.bottom;

    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _allowClose || !_hasDirtyChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showDiscardDialog();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topSection(context),
                  const SizedBox(height: 20),
                  Text(
                    loc.habitNamesDesc,
                    style: TextStyle(color: cp.lightGreyText, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    spacing: 10,
                    children: [
                      for (final option in LanguageOption.values)
                        _languageRow(context, lp, option),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topSection(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 36,
                width: 66,
                child: GestureDetector(
                  onTap: () {
                    _handleBack();
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                      "assets/images/new-svg/back.svg",
                      colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              NewDefaultButton.primarySmall(
                width: null,
                label: loc.save,
                enabled: _hasDirtyChanges,
                onPressed: _handleDone,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Text(
              loc.habitNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageRow(
    BuildContext context,
    LanguageProvider lp,
    LanguageOption option,
  ) {
    final localeCode = option.languageCode;
    final currentValue = _localNames[localeCode];
    final isExpanded = _expandedLocale == localeCode;
    final hasOverride = currentValue != null && currentValue.isNotEmpty;
    final isSessionEdited =
        _localNames[localeCode] != _initialNames[localeCode];
    final buttonTarget =
        hasOverride && (_buttonReady[localeCode] ?? false) ? 1.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Row pill ───────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            if (isExpanded) {
              _collapseRow();
            } else {
              _expandRow(localeCode);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 46,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color:
                      isSessionEdited || isExpanded
                          ? cp.main.withValues(alpha: 0.2)
                          : cp.border,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              color:
                  isSessionEdited || isExpanded
                      ? cp.main.withValues(alpha: 0.07)
                      : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (option.svgPath != null)
                  SvgPicture.asset(option.svgPath!, width: 20, height: 20)
                else
                  Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: cp.lightGreyText,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        option.displayName,
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasOverride && !isExpanded) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '· $currentValue',
                            style: TextStyle(
                              color: cp.lightGreyText,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: SvgPicture.asset(
                    'assets/images/new-svg/dropdown.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      cp.lightGreyText,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Expanded text field ────────────────────────────────────
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: isExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: NewDefaultTextField(
                      controller: _controllers[localeCode]!,
                      focusNode: _focusNodes[localeCode],
                      hint: option.displayName,
                      onChanged: (v) => _onNameChanged(localeCode, v),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: buttonTarget,
                      end: buttonTarget,
                    ),
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeInOut,
                    builder: (context, t, child) {
                      final size = 46.0 * t;
                      return SizedBox(
                        width: 56.0 * t, // 10 gap + 46 button
                        height: 46,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox.square(
                            dimension: size,
                            child: Transform.rotate(
                              angle: (1 - t) * pi,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: NewCircleButton(
                      svgPath: 'assets/images/new-svg/close.svg',
                      cnIcon: CNSymbol('xmark', size: 16),
                      color: cp.field,
                      textColor: cp.text,
                      width: 46,
                      height: 46,
                      onPressed: () => _clearRow(localeCode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
