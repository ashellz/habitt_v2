import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class EnterAmountSlider extends StatefulWidget {
  final int totalSegments;
  final int filledSegments;
  final void Function(int) onChanged;

  const EnterAmountSlider({
    required this.totalSegments,
    required this.filledSegments,
    required this.onChanged,
    super.key,
  });

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
      return 98;
    } else if (currentFilled < 100) {
      return 54;
    } else if (currentFilled < 1000) {
      return 44;
    } else {
      return 34;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final isSimpleSlider = widget.totalSegments > 50;
    currentFilled = widget.filledSegments;

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
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2.75,
              height: MediaQuery.of(context).size.height / 2.75,
              child:
                  isSimpleSlider
                      ? _buildSmoothSlider(colorProvider)
                      : _buildSegmentedSlider(colorProvider),
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
                    color: colorProvider.colorScheme.strokeColor.withOpacity(
                      0.5,
                    ),
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

  Widget _buildSegmentedSlider(ColorProvider colorProvider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: List.generate(widget.totalSegments, (index) {
          final reversedIndex = widget.totalSegments - index - 1;
          final isFilled = reversedIndex < currentFilled;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 0.5),
              decoration: BoxDecoration(
                color:
                    isFilled
                        ? colorProvider.colorScheme.vividColor
                        : colorProvider.colorScheme.strokeColor.withOpacity(
                          0.5,
                        ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSmoothSlider(ColorProvider colorProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final fillHeight = (currentFilled / widget.totalSegments) * height;
        final fillRatio = currentFilled / widget.totalSegments;

        // Calculate top radius based on how close to full it is
        double topRadius = 0;
        if (fillRatio > 0.9) {
          topRadius = ((fillRatio - 0.9) / 0.1) * 30.clamp(0, 30);
        }

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorProvider.colorScheme.strokeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            Container(
              height: fillHeight,
              decoration: BoxDecoration(
                color: colorProvider.colorScheme.vividColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                  top: Radius.circular(topRadius),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
