import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/stats/value_blur_cloud.dart';
import 'package:provider/provider.dart';

class CompletionRate extends StatefulWidget {
  const CompletionRate({super.key, required this.percentage});

  final int percentage;

  @override
  State<CompletionRate> createState() => _CompletionRateState();
}

class _CompletionRateState extends State<CompletionRate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late int _currentPercentage;

  @override
  void initState() {
    super.initState();
    _currentPercentage = widget.percentage.clamp(0, 100);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = AlwaysStoppedAnimation(_currentPercentage.toDouble());
  }

  @override
  void didUpdateWidget(covariant CompletionRate oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextPercentage = widget.percentage.clamp(0, 100);
    if (nextPercentage == _currentPercentage) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentPercentage.toDouble(),
      end: nextPercentage.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentPercentage = nextPercentage;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedPercentage = _animation.value.round();

        return Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cp.field,
                shape: BoxShape.circle,
                border: Border.all(width: 1, color: cp.border),
              ),
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                'assets/images/new-svg/completion-rate.svg',
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueBlurCloud(
                  progress: _controller.value,
                  borderRadius: BorderRadius.circular(10),
                  child: Text(
                    '$animatedPercentage%',
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Completion rate',
                  style: TextStyle(color: cp.lightGreyText, fontSize: 16),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
