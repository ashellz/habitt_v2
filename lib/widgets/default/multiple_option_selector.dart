import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class MultipleOptionSelector<T> extends StatefulWidget {
  const MultipleOptionSelector({
    super.key,

    required this.labels,
    required this.values,
    required this.selectedValue,
    required this.onSelect,
    this.bgColor,
    this.allowDeselect = true,
    this.showDeselectHint = false,
    this.alignDuration = const Duration(milliseconds: 250),
  }) : assert(labels.length == values.length),
       assert(labels.length >= 2);

  final List<String> labels;
  final List<T> values;
  final T? selectedValue;
  final void Function(T?) onSelect;
  final bool allowDeselect;
  final bool showDeselectHint;
  final Duration alignDuration;
  final Color? bgColor;

  @override
  State<MultipleOptionSelector<T>> createState() =>
      _MultipleOptionSelectorState<T>();
}

class _MultipleOptionSelectorState<T> extends State<MultipleOptionSelector<T>> {
  int _lastSelectedIndex = 0;
  Duration _effectiveAlignDuration = const Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _effectiveAlignDuration = widget.alignDuration;
    _updateLastSelectedIndex();
  }

  @override
  void didUpdateWidget(MultipleOptionSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateLastSelectedIndex();
    if (oldWidget.alignDuration != widget.alignDuration) {
      _effectiveAlignDuration = widget.alignDuration;
    }
  }

  void _updateLastSelectedIndex() {
    if (widget.selectedValue == null) return;
    final index = widget.values.indexOf(widget.selectedValue as T);
    if (index != -1) _lastSelectedIndex = index;
  }

  Alignment _getIndicatorAlignment() {
    final optionCount = widget.values.length;
    var index = _lastSelectedIndex;
    if (widget.selectedValue != null) {
      final selectedIndex = widget.values.indexOf(widget.selectedValue as T);
      if (selectedIndex != -1) index = selectedIndex;
    }
    if (optionCount == 1) return Alignment.center;
    return Alignment(-1 + 2 * index / (optionCount - 1), 0);
  }

  void _onTapIndex(int index) {
    final value = widget.values[index];
    if (widget.selectedValue == value) {
      if (widget.allowDeselect) widget.onSelect(null);
      return;
    }
    setState(() {
      if (_lastSelectedIndex != index && widget.selectedValue == null) {
        _effectiveAlignDuration = Duration.zero;
      } else {
        _effectiveAlignDuration = widget.alignDuration;
      }
    });
    widget.onSelect(value);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isDeselected = widget.selectedValue == null;
    final optionCount = widget.values.length;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.bgColor ?? cp.field,
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
                    width: constraints.maxWidth / optionCount,
                    decoration: BoxDecoration(
                      color: cp.text,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < optionCount; i++)
                    Expanded(
                      child: _OptionButton(
                        label: widget.labels[i],
                        isSelected: widget.selectedValue == widget.values[i],
                        showDeselectHint: widget.showDeselectHint,
                        onTap: () => _onTapIndex(i),
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
