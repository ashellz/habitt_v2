import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class EnterAmountSlider extends StatefulWidget {
  const EnterAmountSlider({
    required this.totalSegments,
    required this.filledSegments,
    required this.onChanged,
    required this.habitColor,
    super.key,
  });

  final int totalSegments;
  final int filledSegments;
  final void Function(int) onChanged;
  final Color? habitColor;
  @override
  State<EnterAmountSlider> createState() => _EnterAmountSliderState();
}

class _EnterAmountSliderState extends State<EnterAmountSlider> {
  late int currentFilled;

  void _updateFill(Offset localPos, double height) {
    final value =
        (widget.totalSegments - (localPos.dy / height) * widget.totalSegments)
            .clamp(0, widget.totalSegments)
            .floor();
    if (value != currentFilled) {
      setState(() => currentFilled = value);
      widget.onChanged(currentFilled);
    }
  }

  double getFontSize() {
    if (currentFilled < 10) {
      return 108;
    } else if (currentFilled < 100) {
      return 84;
    } else if (currentFilled < 1000) {
      return 74;
    } else {
      return 64;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    // final isSimpleSlider = widget.totalSegments > 50;
    currentFilled = widget.filledSegments;
    final prefs = context.watch<PreferencesProvider>();

    Color getColor(bool isFilled, [bool forText = false]) {
      if (forText) {
        switch (prefs.colorfulness) {
          case Colorfulness.tinted:
            return tp.primaryColor.darken(20).withOpacity(0.7);
          case Colorfulness.standard:
            return tp.successColor.darken(20).withOpacity(0.7);
          case Colorfulness.colorful:
            return widget.habitColor?.darken(20).withOpacity(0.7) ??
                tp.successColor;
        }
      }
      if (isFilled) {
        switch (prefs.colorfulness) {
          case Colorfulness.tinted:
            return tp.primaryColor;
          case Colorfulness.standard:
            return tp.successColor;
          case Colorfulness.colorful:
            return widget.habitColor ?? tp.successColor;
        }
      }
      return tp.borderColor.withOpacity(0.5);
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onVerticalDragUpdate: (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              final localPos = box.globalToLocal(details.globalPosition);
              _updateFill(localPos, box.size.height);
            },
            child: Container(
              decoration: BoxDecoration(
                color: tp.borderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              width: MediaQuery.of(context).size.width / 2.75,
              height: MediaQuery.of(context).size.height / 2.75,
              child: _buildSmoothSlider(tp, getColor),
            ),
          ),

          IgnorePointer(
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  currentFilled.toString(),
                  style: TextStyle(
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(100),
                        offset: const Offset(0, 1),
                        blurRadius: 5,
                      ),
                    ],
                    color: getColor(true, true),
                    fontWeight: FontWeight.bold,
                    fontSize: getFontSize(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /*
  Widget _buildSegmentedSlider(
    ThemeProvider tp,
    Color Function(bool) getColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: List.generate(widget.totalSegments, (index) {
          final reversedIndex = widget.totalSegments - index - 1;
          final isFilled = reversedIndex < currentFilled;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 0.5),
              decoration: BoxDecoration(color: getColor(isFilled)),
            ),
          );
        }),
      ),
    );
  }*/

  Widget _buildSmoothSlider(ThemeProvider tp, Color Function(bool) getColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          tween: Tween<double>(
            begin: 0,
            end: currentFilled / widget.totalSegments,
          ),
          builder: (context, value, _) {
            final endColor = getColor(true);

            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  // Vertical fill from bottom up
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: value,
                      widthFactor: 1,
                      child: Container(color: endColor),
                    ),
                  ),

                  GlassBlurContainer(
                    height: height,
                    forceBlur: true,
                    color: Colors.transparent,
                    borderColor: Colors.transparent,
                    hasGradient: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
