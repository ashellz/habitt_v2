import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_category_length.dart'; // Assuming this is still used
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

// This widget contains the actual visual content of your original HabitCategoryTitle
class _OriginalHabitCategoryTitleContent extends StatelessWidget {
  const _OriginalHabitCategoryTitleContent({
    required this.category,
    required this.isFirst,
    required this.countAdditionalTasks,
  });

  final Category category;
  final bool isFirst;
  final bool countAdditionalTasks;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;
    final int categoryHabits = getCategoryLength(
      category,
      context,
      countAdditionalTasks,
    );

    // If you're looking for the additional tasks divider
    // It's actually separate from here
    // It's in the AdditionalTasksDivider widget

    // I lost around 20 minutes looking for it here...

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isFirst ? 0 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category.name,
            style: TextStyle(
              color:
                  isFirst
                      ? colorProvider.textColor
                      : colorProvider.mutedTextColor,
            ),
          ),
          Text(
            "$categoryHabits ${categoryHabits == 1 ? localizations.habit : localizations.habits}",
            style: TextStyle(
              color:
                  isFirst
                      ? colorProvider.textColor
                      : colorProvider.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// This is the new transforming wrapper widget
class ScrollTransformedHabitCategoryTitle extends StatefulWidget {
  const ScrollTransformedHabitCategoryTitle({
    super.key,
    required this.isFirst,
    required this.category,
    required this.countAdditionalTasks,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
  });

  final bool isFirst;
  final Category category;
  final bool countAdditionalTasks;
  // Scroll and transformation parameters (same as for ScrollTransformedHabitWidget)
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;

  @override
  State<ScrollTransformedHabitCategoryTitle> createState() =>
      _ScrollTransformedHabitCategoryTitleState();
}

class _ScrollTransformedHabitCategoryTitleState
    extends State<ScrollTransformedHabitCategoryTitle> {
  @override
  Widget build(BuildContext context) {
    Widget originalContent = _OriginalHabitCategoryTitleContent(
      category: widget.category,
      isFirst: widget.isFirst,
      countAdditionalTasks: widget.countAdditionalTasks,
    );

    double scale = 1.0;
    double offsetY = 0.0;
    double opacity = 1.0;

    // Ensure calculations only happen if geometry is valid and controller is ready
    if (widget.bottomViewportEdgeGlobalY <= 0 ||
        !widget.scrollController.hasClients) {
      return originalContent; // Render normally if not ready for calculation
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox != null && renderBox.hasSize) {
      final widgetSize = renderBox.size;
      final widgetGlobalOffset = renderBox.localToGlobal(Offset.zero);
      final widgetTopYGlobal = widgetGlobalOffset.dy;
      final widgetBottomYGlobal = widgetTopYGlobal + widgetSize.height;

      final effectZoneStartLineGlobalY =
          widget.bottomViewportEdgeGlobalY - widget.effectZoneHeight;

      // Check if the widget is within the effect zone
      if (widgetBottomYGlobal > effectZoneStartLineGlobalY &&
          widgetTopYGlobal <
              widget.bottomViewportEdgeGlobalY + widgetSize.height * 0.25) {
        // Leeway
        double relativeWidgetTopToEffectZoneStart =
            widgetTopYGlobal - effectZoneStartLineGlobalY;
        double progress = (relativeWidgetTopToEffectZoneStart /
                widget.effectZoneHeight)
            .clamp(0.0, 1.0);

        scale = 1.0 - progress * (1.0 - widget.minScale);
        opacity = 1.0 - progress * 0.6; // Example: fade from 100% to 40%
        offsetY = -progress * widgetSize.height * widget.stackOffsetFactor;
      } else if (widgetTopYGlobal >= widget.bottomViewportEdgeGlobalY) {
        // Item is fully "below" or at the very bottom of the stacking context
        scale = widget.minScale;
        opacity = 1.0 - 0.6; // Minimum opacity
        offsetY = -widgetSize.height * widget.stackOffsetFactor; // Full offset
      }
      // Else (widget is above the effect zone): uses default scale=1.0, offsetY=0.0, opacity=1.0
    }

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter, // Scale towards its top edge
        child: Opacity(opacity: opacity, child: originalContent),
      ),
    );
  }
}
