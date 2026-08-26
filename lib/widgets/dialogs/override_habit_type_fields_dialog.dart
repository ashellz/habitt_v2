import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/animated_checkbox.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class OverrideHabitTypeFieldsDialog extends StatefulWidget {
  const OverrideHabitTypeFieldsDialog({
    super.key,
    required this.dialogContext,
    required this.template,
  });

  final BuildContext dialogContext;
  final PremadeHabitTemplate template;

  @override
  State<OverrideHabitTypeFieldsDialog> createState() =>
      _OverrideHabitTypeFieldsDialogState();
}

class _OverrideHabitTypeFieldsDialogState
    extends State<OverrideHabitTypeFieldsDialog> {
  late final bool _healthLocked;
  late Set<PremadeTemplateField> _selected;

  static const _allFields = PremadeTemplateField.values;

  @override
  void initState() {
    super.initState();
    _healthLocked = context.read<StateProvider>().selectedHealthMetric != null;
    _selected = _defaultSelection();
  }

  Set<PremadeTemplateField> _defaultSelection() {
    return {..._allFields};
  }

  void _toggle(PremadeTemplateField field, bool value) {
    if (field == PremadeTemplateField.healthSync && _healthLocked) return;
    setState(() {
      if (value) {
        _selected.add(field);
      } else {
        _selected.remove(field);
      }
    });
  }

  void _selectAll() => setState(() => _selected = _defaultSelection());

  void _deselectAll() {
    setState(() {
      _selected = {if (_healthLocked) PremadeTemplateField.healthSync};
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.read<StateProvider>();
    final healthProvider = context.read<HealthProvider>();
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.overrideFieldsDialogTitle,
      desc: loc.overrideFieldsDialogDesc,
      primaryButtonLabel: loc.apply,
      showSecondaryButton: true,
      secondaryButtonLabel: loc.cancel,
      onSecondaryButtonPressed: () => Navigator.of(widget.dialogContext).pop(),
      onPrimaryButtonPressed: () {
        final healthWasOff = sp.selectedHealthMetric == null;
        sp.applyPremadeHabitTemplateSelectively(
          widget.template,
          fields: _selected,
          localizedName: widget.template.localizedName(loc),
        );
        if (healthWasOff &&
            _selected.contains(PremadeTemplateField.healthSync) &&
            widget.template.defaultHealthMetric != null) {
          unawaited(healthProvider.requestPermissionIfNeeded());
        }
        Navigator.of(widget.dialogContext).pop();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 10,
            children: [
              NewDefaultButton.secondarySmall(
                width: null,
                label: loc.overrideFieldsDeselectAll,
                onPressed: _deselectAll,
              ),
              NewDefaultButton.primarySmall(
                width: null,
                label: loc.overrideFieldsSelectAll,
                onPressed: _selectAll,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _fieldRow(cp, loc.overrideFieldName, PremadeTemplateField.name),
          _fieldRow(cp, loc.overrideFieldIcon, PremadeTemplateField.icon),
          _fieldRow(
            cp,
            loc.overrideFieldCategory,
            PremadeTemplateField.category,
          ),
          _fieldRow(cp, loc.overrideFieldTarget, PremadeTemplateField.target),
          _healthSyncRow(cp, loc),
          _fieldRow(
            cp,
            loc.overrideFieldSchedule,
            PremadeTemplateField.schedule,
          ),
          _fieldRow(
            cp,
            loc.overrideFieldNotifications,
            PremadeTemplateField.notifications,
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(ColorProvider cp, String label, PremadeTemplateField field) {
    return GestureDetector(
      onTap: () => _toggle(field, !_selected.contains(field)),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: cp.text, fontSize: 16),
              ),
            ),
            AnimatedCheckbox(
              size: 24,
              value: _selected.contains(field),
              onChanged: (value) => _toggle(field, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthSyncRow(ColorProvider cp, AppLocalizations loc) {
    final checkboxRow = Row(
      children: [
        Expanded(
          child: Text(
            loc.overrideFieldHealthSync,
            style: TextStyle(color: cp.text, fontSize: 16),
          ),
        ),
        AnimatedCheckbox(
          size: 24,
          value: _selected.contains(PremadeTemplateField.healthSync),
          onChanged:
              _healthLocked
                  ? (_) {}
                  : (value) => _toggle(PremadeTemplateField.healthSync, value),
        ),
      ],
    );

    if (!_healthLocked) {
      return GestureDetector(
        onTap:
            () => _toggle(
              PremadeTemplateField.healthSync,
              !_selected.contains(PremadeTemplateField.healthSync),
            ),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: checkboxRow,
        ),
      );
    }

    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: checkboxRow,
      ),
    );
  }
}
