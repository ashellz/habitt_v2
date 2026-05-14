// This is the new transforming wrapper widget
import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class ScrollTransformedHabitCategoryDivider extends StatefulWidget {
  const ScrollTransformedHabitCategoryDivider({
    super.key,
    this.hasHabits,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
  });

  final bool? hasHabits;
  // Scroll and transformation parameters (same as for ScrollTransformedHabitWidget)
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;

  @override
  State<ScrollTransformedHabitCategoryDivider> createState() =>
      _ScrollTransformedHabitCategoryTitleState();
}

class _ScrollTransformedHabitCategoryTitleState
    extends State<ScrollTransformedHabitCategoryDivider> {
  @override
  Widget build(BuildContext context) {
    Widget originalContent = _OriginalDividerContent(
      hasHabits: widget.hasHabits,
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

class _OriginalDividerContent extends StatelessWidget {
  const _OriginalDividerContent({this.hasHabits});

  final bool? hasHabits;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final bool isTitle = hasHabits != null && !hasHabits!;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding:
          isTitle
              ? EdgeInsets.symmetric(horizontal: 16)
              : EdgeInsets.fromLTRB(
                32,
                32,
                32,
                24,
              ), // 24 bc habit top margin is 8
      child: Row(
        children: [
          if (!isTitle)
            Expanded(child: Divider(thickness: 1, color: tp.mutedTextColor)),
          Padding(
            padding: EdgeInsets.only(left: isTitle ? 0 : 8.0, right: 8.0),
            child: Text(
              loc.optionalHabits,
              style: TextStyle(color: tp.mutedTextColor),
            ),
          ),

          Expanded(child: Divider(thickness: 1, color: tp.mutedTextColor)),
        ],
      ),
    );
  }
}
