import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/scroll_edge_fade.dart';

class FadedListView extends StatelessWidget {
  const FadedListView({
    super.key,
    required this.height,
    this.scrollDirection = Axis.horizontal,
    this.children = const [],
  });

  final double height;
  final Axis scrollDirection;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ScrollEdgeFade(
        axis: scrollDirection,
        child: ListView(
          scrollDirection: scrollDirection,
          physics: const BouncingScrollPhysics(),
          children: children,
        ),
      ),
    );
  }
}
