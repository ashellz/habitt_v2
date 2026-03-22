import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class NewHabitCategoryTitle extends StatefulWidget {
  const NewHabitCategoryTitle({
    super.key,
    required this.category,
    this.isFirst = false,
  });

  final Category category;
  final bool isFirst;

  @override
  State<NewHabitCategoryTitle> createState() => _NewHabitCategoryTitleState();
}

class _NewHabitCategoryTitleState extends State<NewHabitCategoryTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      value: widget.isFirst ? 1.0 : 0.0,
    );
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_curved);
  }

  @override
  void didUpdateWidget(NewHabitCategoryTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFirst != oldWidget.isFirst) {
      if (widget.isFirst) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.category.name, style: TextStyle(color: cp.greyText)),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.isDismissed) return const SizedBox.shrink();
              return FadeTransition(
                opacity: _curved,
                child: SlideTransition(position: _slideAnimation, child: child),
              );
            },
            child: Container(
              height: 26,
              width: 43,
              decoration: ShapeDecoration(
                color: cp.disabled,
                shape: StadiumBorder(),
              ),
              child: Center(
                child: Text(
                  "Now",
                  style: TextStyle(color: cp.text, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
