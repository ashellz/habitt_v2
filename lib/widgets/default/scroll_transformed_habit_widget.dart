import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart'; // Ensure this path is correct for your Habit model
import 'package:habitt/widgets/habit_widget/old_habit_widget.dart'; // Your original HabitWidget

// DEPRACATED, LEGACY, NOT USED

class ScrollTransformedHabitWidget extends StatefulWidget {
  final Habit habit;
  final bool editable;
  final ScrollController scrollController;
  final double
  bottomViewportEdgeGlobalY; // Pre-calculated global Y of ListView's bottom edge
  final double effectZoneHeight; // Height of the zone where effect applies
  final double minScale; // Minimum scale factor
  final double
  stackOffsetFactor; // Upward offset factor (percentage of item height)
  final bool isFirstCategory;
  final bool isToday;

  const ScrollTransformedHabitWidget({
    super.key,
    required this.habit,
    required this.editable,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
    required this.isFirstCategory,
    required this.isToday,
  });

  @override
  State<ScrollTransformedHabitWidget> createState() =>
      _ScrollTransformedHabitWidgetState();
}

class _ScrollTransformedHabitWidgetState
    extends State<ScrollTransformedHabitWidget> {
  @override
  Widget build(BuildContext context) {
    // This is your actual, original HabitWidget.
    // Ensure it's imported correctly.
    Widget actualHabitWidgetContent = OldHabitWidget(
      habit: widget.habit,
      editable: widget.editable,
      isFirstCategory: widget.isFirstCategory,
      isToday: widget.isToday,
    );

    double scale = 1.0;
    double offsetY = 0.0;
    double opacity = 1.0;

    // Ensure calculations only happen if geometry is valid
    if (widget.bottomViewportEdgeGlobalY <= 0 ||
        !widget.scrollController.hasClients) {
      // Not ready for calculation, render normally
      return actualHabitWidgetContent;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox != null && renderBox.hasSize) {
      final widgetSize = renderBox.size;
      final widgetGlobalOffset = renderBox.localToGlobal(Offset.zero);
      final widgetTopYGlobal = widgetGlobalOffset.dy;
      final widgetBottomYGlobal = widgetTopYGlobal + widgetSize.height;

      // The Y coordinate marking the start of the effect zone (further up the screen)
      final effectZoneStartLineGlobalY =
          widget.bottomViewportEdgeGlobalY - widget.effectZoneHeight;

      if (widgetBottomYGlobal > effectZoneStartLineGlobalY &&
          widgetTopYGlobal <
              widget.bottomViewportEdgeGlobalY + widgetSize.height * 0.25) {
        // Give some leeway
        // Widget is in or entering the effect zone.
        // Progress: 0 when widget's top is at effectZoneStartLineGlobalY,
        //           1 when widget's top is at bottomViewportEdgeGlobalY.
        // This means the effect is fully applied when the widget's top reaches the viewport bottom.
        double relativeWidgetTopToEffectZoneStart =
            widgetTopYGlobal - effectZoneStartLineGlobalY;
        double progress = (relativeWidgetTopToEffectZoneStart /
                widget.effectZoneHeight)
            .clamp(0.0, 1.0);

        scale = 1.0 - progress * (1.0 - widget.minScale);
        opacity = 1.0 - progress * 0.6; // Fade from 100% to 40% opacity

        // Offset upwards. Proportional to its height and progress.
        offsetY = -progress * widgetSize.height * widget.stackOffsetFactor;
      } else if (widgetTopYGlobal >= widget.bottomViewportEdgeGlobalY) {
        // Item is fully "below" or at the very bottom of the stacking context
        scale = widget.minScale;
        opacity = 1.0 - 0.6; // Minimum opacity
        offsetY = -widgetSize.height * widget.stackOffsetFactor; // Full offset
      }
      // Else (widget is above the effect zone): scale = 1.0, offsetY = 0.0, opacity = 1.0 (default)
    }

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter, // Crucial: scales towards the top edge
        child: Opacity(opacity: opacity, child: actualHabitWidgetContent),
      ),
    );
  }
}
