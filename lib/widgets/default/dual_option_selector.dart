import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class DualOptionSelector<T> extends StatefulWidget {
  const DualOptionSelector({
    super.key,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstValue,
    required this.secondValue,
    required this.selectedValue,
    required this.onSelect,
    this.allowDeselect = true,
    this.showDeselectHint = false,
    this.alignDuration = const Duration(milliseconds: 250),
    this.color,
  }) : firstIcon = null,
       secondIcon = null,
       width = null;

  /// Compact icon-only variant: a bordered pill where the selected half is
  /// filled flat, so its corners toward the middle stay square.
  const DualOptionSelector.icons({
    super.key,
    required Widget Function(Color color) this.firstIcon,
    required Widget Function(Color color) this.secondIcon,
    required this.firstValue,
    required this.secondValue,
    required this.selectedValue,
    required this.onSelect,
    this.allowDeselect = false,
    this.alignDuration = const Duration(milliseconds: 250),
    this.color,
    this.width = 80,
  }) : firstLabel = '',
       secondLabel = '',
       showDeselectHint = false;

  final String firstLabel;
  final String secondLabel;
  final T firstValue;
  final T secondValue;
  final T? selectedValue;
  final void Function(T?) onSelect;
  final bool allowDeselect;
  final bool showDeselectHint;
  final Duration alignDuration;
  final Color? color;
  final Widget Function(Color color)? firstIcon;
  final Widget Function(Color color)? secondIcon;
  final double? width;

  @override
  State<DualOptionSelector<T>> createState() => _DualOptionSelectorState<T>();
}

class _DualOptionSelectorState<T> extends State<DualOptionSelector<T>> {
  int _lastSelectedIndex = 0;
  Duration _effectiveAlignDuration = const Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _effectiveAlignDuration = widget.alignDuration;
    if (widget.selectedValue != null) {
      _lastSelectedIndex = widget.selectedValue == widget.firstValue ? 0 : 1;
    }
  }

  @override
  void didUpdateWidget(DualOptionSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != null) {
      _lastSelectedIndex = widget.selectedValue == widget.firstValue ? 0 : 1;
    }
    if (oldWidget.alignDuration != widget.alignDuration) {
      _effectiveAlignDuration = widget.alignDuration;
    }
  }

  Alignment _getIndicatorAlignment() {
    if (widget.selectedValue == widget.firstValue) return Alignment.centerLeft;
    if (widget.selectedValue == widget.secondValue) {
      return Alignment.centerRight;
    }
    return _lastSelectedIndex == 0
        ? Alignment.centerLeft
        : Alignment.centerRight;
  }

  void _onTapFirst() {
    if (widget.selectedValue == widget.firstValue) {
      if (widget.allowDeselect) widget.onSelect(null);
      return;
    }
    setState(() {
      if (_lastSelectedIndex == 1 && widget.selectedValue == null) {
        _effectiveAlignDuration = Duration.zero;
      } else {
        _effectiveAlignDuration = widget.alignDuration;
      }
    });
    widget.onSelect(widget.firstValue);
  }

  void _onTapSecond() {
    if (widget.selectedValue == widget.secondValue) {
      if (widget.allowDeselect) widget.onSelect(null);
      return;
    }
    setState(() {
      if (_lastSelectedIndex == 0 && widget.selectedValue == null) {
        _effectiveAlignDuration = Duration.zero;
      } else {
        _effectiveAlignDuration = widget.alignDuration;
      }
    });
    widget.onSelect(widget.secondValue);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    if (widget.firstIcon != null && widget.secondIcon != null) {
      return _buildIconStyle(cp);
    }
    final isDeselected = widget.selectedValue == null;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.color ?? cp.field,
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedAlign(
                duration: _effectiveAlignDuration,
                curve: Curves.easeOutCubic,
                alignment: _getIndicatorAlignment(),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  opacity: isDeselected ? 0 : 1,
                  child: Container(
                    width: constraints.maxWidth / 2,
                    decoration: BoxDecoration(
                      color: cp.text,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _OptionButton(
                      label: widget.firstLabel,
                      isSelected: widget.selectedValue == widget.firstValue,
                      showDeselectHint: widget.showDeselectHint,
                      onTap: _onTapFirst,
                    ),
                  ),
                  Expanded(
                    child: _OptionButton(
                      label: widget.secondLabel,
                      isSelected: widget.selectedValue == widget.secondValue,
                      showDeselectHint: widget.showDeselectHint,
                      onTap: _onTapSecond,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIconStyle(ColorProvider cp) {
    final isFirst = _getIndicatorAlignment() == Alignment.centerLeft;
    // Pill radius (36 / 2) minus the 1px border.
    const outerRadius = 17.0;

    return Container(
      width: widget.width,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.color ?? (cp.isDark ? cp.field : cp.border),
        border: Border.all(color: cp.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedAlign(
                duration: _effectiveAlignDuration,
                curve: Curves.easeOutCubic,
                alignment: _getIndicatorAlignment(),
                child: AnimatedContainer(
                  duration: _effectiveAlignDuration,
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth / 2,
                  decoration: BoxDecoration(
                    color: cp.bg,
                    // Round only the sides facing the outside of the pill.
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(isFirst ? outerRadius : 0),
                      right: Radius.circular(isFirst ? 0 : outerRadius),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _IconOptionButton(
                      icon: widget.firstIcon!,
                      isSelected: widget.selectedValue == widget.firstValue,
                      onTap: _onTapFirst,
                    ),
                  ),
                  Expanded(
                    child: _IconOptionButton(
                      icon: widget.secondIcon!,
                      isSelected: widget.selectedValue == widget.secondValue,
                      onTap: _onTapSecond,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IconOptionButton extends StatelessWidget {
  const _IconOptionButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final Widget Function(Color color) icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final iconColor =
        isSelected
            ? cp.main
            : cp.isDark
            ? cp.greyText
            : cp.lightGreyText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: ColorTween(end: iconColor),
          builder: (context, color, _) => icon(color ?? iconColor),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showDeselectHint = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDeselectHint;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final textColor = isSelected ? cp.bg : cp.lightGreyText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showDeselectHint)
                SizedBox(width: 16), // Placeholder for the close icon

              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Satoshi'),
                  ),
                ),
              ),
              if (showDeselectHint)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isSelected ? 0.7 : 0,
                  child: Icon(Icons.close_rounded, size: 16, color: textColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
