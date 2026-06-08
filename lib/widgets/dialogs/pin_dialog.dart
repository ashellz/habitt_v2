import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class PinDialog extends StatefulWidget {
  const PinDialog({
    super.key,
    required this.title,
    required this.desc,
    required this.buttonLabel,
    required this.onConfirm,
    this.buttonColor,
  });

  final String title;
  final String desc;
  final String buttonLabel;
  final Color? buttonColor;
  final Future<bool> Function(String pin) onConfirm;

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _ctrl.text.trim();
    final loc = AppLocalizations.of(context)!;
    if (pin.length < 4) {
      setState(() => _error = loc.pinTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await widget.onConfirm(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = loc.pinIncorrect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: widget.title,
      desc: widget.desc,
      primaryButtonLabel: widget.buttonLabel,
      primaryButtonColor: widget.buttonColor,
      primaryButtonEnabled: !_loading,
      onPrimaryButtonPressed: _submit,
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
      child: NewDefaultTextField(
        controller: _ctrl,
        obscureText: true,
        autofocus: true,
        hint: loc.pinHint,
        errorText: _error,
        color: cp.isDark ? cp.bg : cp.field,
        showBorder: true,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
