import 'package:flutter/cupertino.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// Wraps one optional habit so it can be revealed by the section's stagger.
typedef OptionalHabitReveal = Widget Function(int index, Widget child);

/// "Optional habits" pseudo category shown below the real categories.
///
/// When [onToggle] is given, tapping the title row hides/shows the habits one
/// by one (fade + slide up when appearing, the same way back when hiding).
/// Without it the habits are always shown and the title has no chevron.
class OptionalHabitsSection extends StatefulWidget {
  const OptionalHabitsSection({
    super.key,
    required this.count,
    required this.builder,
    this.expanded = true,
    this.onToggle,
    this.horizontalPadding = 0,
  });

  /// Number of optional habits [builder] lays out.
  final int count;

  /// Builds the habits. Every habit must be passed through `reveal` with its
  /// index so it takes part in the staggered animation.
  final Widget Function(BuildContext context, OptionalHabitReveal reveal)
  builder;

  /// Whether the habits are shown. Owned by the parent so it survives this
  /// widget being rebuilt from scratch.
  final bool expanded;

  /// Called when the title is tapped. Null makes the section non-collapsible.
  final VoidCallback? onToggle;

  final double horizontalPadding;

  @override
  State<OptionalHabitsSection> createState() => _OptionalHabitsSectionState();
}

class _OptionalHabitsSectionState extends State<OptionalHabitsSection>
    with SingleTickerProviderStateMixin {
  static const double _itemDurationMs = 220;
  static const double _maxStepMs = 70;
  static const double _maxTotalStaggerMs = 350;

  late final AnimationController _controller;

  bool get _expanded => widget.onToggle == null || widget.expanded;

  double get _stepMs =>
      widget.count <= 1
          ? 0
          : (_maxTotalStaggerMs / (widget.count - 1)).clamp(0, _maxStepMs);

  double get _totalMs =>
      _itemDurationMs + (widget.count <= 1 ? 0 : (widget.count - 1) * _stepMs);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: _expanded ? 1 : 0,
      duration: Duration(milliseconds: _totalMs.round()),
    );
  }

  @override
  void didUpdateWidget(covariant OptionalHabitsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.duration = Duration(milliseconds: _totalMs.round());
    }

    final wasExpanded = oldWidget.onToggle == null || oldWidget.expanded;
    if (wasExpanded != _expanded) {
      _expanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, child) {
        final elapsedMs = _controller.value * _totalMs;
        final t = ((elapsedMs - index * _stepMs) / _itemDurationMs).clamp(
          0.0,
          1.0,
        );
        final eased = Curves.easeInOut.transform(t);

        return Align(
          alignment: Alignment.topCenter,
          heightFactor: eased,
          child: Opacity(
            opacity: eased,
            child: FractionalTranslation(
              translation: Offset(0, 0.2 * (1 - eased)),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Title ────────────────────────────────────────────
          _title(context),
          // ─── Habits ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.isDismissed) return const SizedBox.shrink();
              return child!;
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: widget.builder(context, _reveal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggle,
      child: SizedBox(
        height: 26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.optionalHabits, style: TextStyle(color: cp.greyText)),
            if (widget.onToggle != null)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Points down while the habits are shown, up once hidden.
                  return Transform.rotate(
                    angle: (1 - _controller.value) * 3.14159265,
                    child: child,
                  );
                },
                child: Container(
                  height: 26,
                  width: 26,
                  decoration: ShapeDecoration(
                    color: cp.disabled,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 13,
                    color: cp.text,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
