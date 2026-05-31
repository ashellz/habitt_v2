import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class PinDialog extends StatefulWidget {
  const PinDialog({
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40 + keyboardInset),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cp.isDark ? cp.habitBg : cp.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.desc,
                style: TextStyle(color: cp.greyText, fontSize: 16),
              ),
              const SizedBox(height: 20),
              NewDefaultTextField(
                controller: _ctrl,
                obscureText: true,
                autofocus: true,
                hint: loc.pinHint,
                errorText: _error,
                color: cp.isDark ? cp.bg : cp.field,
                showBorder: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NewDefaultButton.secondary(
                      onPressed: () => Navigator.of(context).pop(false),
                      label: loc.cancel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NewDefaultButton.primary(
                      onPressed: _submit,
                      label: widget.buttonLabel,
                      isLoading: _loading,
                      color: widget.buttonColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
