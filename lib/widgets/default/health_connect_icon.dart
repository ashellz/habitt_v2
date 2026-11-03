import 'package:flutter/material.dart';

/// The Health Connect logo clipped to the same squircle as the Apple Health
/// icon (the PNG itself is a plain square).
class HealthConnectIcon extends StatelessWidget {
  const HealthConnectIcon({super.key, this.size});

  /// Width and height. When null the icon fills the space it is given.
  final double? size;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = size ?? constraints.biggest.shortestSide;
        return ClipRSuperellipse(
          // matches the corner of apple-health.svg (~24% of the side)
          borderRadius: BorderRadius.circular(side.isFinite ? side * 0.24 : 0),
          child: Image.asset(
            'assets/images/widget-images/health-connect.png',
            width: size,
            height: size,
          ),
        );
      },
    );
  }
}
