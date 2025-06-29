import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/glass_container.dart';
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
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(100),
                        offset: const Offset(0, 1),
                        blurRadius: 5,
                      ),
                    ],
                    color: colorProvider.colorScheme.strokeColor.withOpacity(
                      0.75,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final fillHeight = (currentFilled / widget.totalSegments) * height;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Column(
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
                                : colorProvider.colorScheme.strokeColor
                                    .withOpacity(0.5),
                      ),
                    ),
                  );
                }),
              ),

              GlassContainer(borderRadius: 30, height: height, blur: 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmoothSlider(ColorProvider colorProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final fillHeight = (currentFilled / widget.totalSegments) * height;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GlassContainer(
                color: colorProvider.colorScheme.strokeColor.withOpacity(0.5),
                borderRadius: 30,
                alignment: Alignment.topCenter,
                height: height,
              ),
              GlassContainer(
                alignment: Alignment.bottomCenter,
                borderRadius: 0,
                height: fillHeight,
                color: colorProvider.colorScheme.vividColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
