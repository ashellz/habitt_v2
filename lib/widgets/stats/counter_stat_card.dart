import 'package:flutter/material.dart';
import 'package:habitt/widgets/stats/stat_card.dart';

class CounterStatCard extends StatefulWidget {
  const CounterStatCard({
    super.key,
    required this.title,
    required this.iconPath,
    required this.value,
    required this.formatter,
    this.isLoading = false,
  });

  final String title;
  final String iconPath;
  final int value;
  final String Function(int value) formatter;
  final bool isLoading;

  @override
  State<CounterStatCard> createState() => _CounterStatCardState();
}

class _CounterStatCardState extends State<CounterStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(0, 999999999);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = AlwaysStoppedAnimation(_currentValue.toDouble());
  }

  @override
  void didUpdateWidget(covariant CounterStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextValue = widget.value.clamp(0, 999999999);
    if (nextValue == _currentValue) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentValue.toDouble(),
      end: nextValue.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentValue = nextValue;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedValue = _animation.value.round();

        return StatCard(
          title: widget.title,
          value: widget.formatter(animatedValue),
          iconPath: widget.iconPath,
          cloudProgress: widget.isLoading ? 0.1 : _controller.value,
        );
      },
    );
  }
}
