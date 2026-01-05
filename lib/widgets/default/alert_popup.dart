import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';

class AlertPopup extends StatefulWidget {
  const AlertPopup({
    super.key,
    required this.message,
    this.animationDuration = const Duration(milliseconds: 500),
    this.appearCurve = Curves.easeOutBack,
    this.disappearCurve = Curves.easeIn,
    required this.show,
  });

  final String message;
  final Duration animationDuration;
  final Curve appearCurve;
  final Curve disappearCurve;
  final bool show;

  @override
  State<AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<AlertPopup> {
  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final alertTextWidth = textPainter.width;
    final width = alertTextWidth + 64;

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSlide(
        offset: widget.show ? const Offset(0, 0.5) : const Offset(0, -1),
        duration: widget.animationDuration,
        curve: widget.show ? widget.appearCurve : widget.disappearCurve,
        child: IgnorePointer(
          ignoring: !widget.show,
          child: GlassBlurContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: width,
            height: 70,
            margin: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 24,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
