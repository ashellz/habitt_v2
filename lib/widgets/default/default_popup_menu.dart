import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class DefaultPopupMenuItem {
  const DefaultPopupMenuItem({
    required this.label,
    required this.svgPath,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final String svgPath;
  final VoidCallback onTap;
  final Widget? icon;
  final Color? color;
}

class DefaultPopupMenu extends StatefulWidget {
  const DefaultPopupMenu({super.key, required this.items, required this.child});

  final List<DefaultPopupMenuItem> items;
  final Widget child;

  @override
  State<DefaultPopupMenu> createState() => _DefaultPopupMenuState();
}

class _DefaultPopupMenuState extends State<DefaultPopupMenu>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _dismiss(immediate: true);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss({bool immediate = false}) async {
    if (_overlayEntry == null) return;
    if (!immediate) await _controller.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _show() {
    final cp = context.read<ColorProvider>();
    final button = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanDown: (_) => _dismiss(),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            right: overlay.size.width - position.dx - button.size.width,
            top: position.dy + button.size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _MenuPanel(
                    items: widget.items,
                    color: cp.bg,
                    controller: _controller,
                    onDismiss: _dismiss,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward(from: 0);
  }

  void _toggle() {
    if (_overlayEntry == null) {
      _show();
    } else {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.items,
    required this.color,
    required this.controller,
    required this.onDismiss,
  });

  final List<DefaultPopupMenuItem> items;
  final Color color;
  final AnimationController controller;
  final Future<void> Function() onDismiss;

  Animation<double> _itemFade(int index) {
    const windowStart = 0.25;
    const windowEnd = 1.0;
    final total = items.length;
    final step = (windowEnd - windowStart) / total;
    final start = windowStart + step * index;
    final end = (start + step * 0.85).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _itemSlide(int index) {
    const windowStart = 0.25;
    const windowEnd = 1.0;
    final total = items.length;
    final step = (windowEnd - windowStart) / total;
    final start = windowStart + step * index;
    final end = (start + step * 0.85).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadows: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, -8),
            spreadRadius: -12,
          ),
          BoxShadow(
            color: Color(0x2D000000),
            blurRadius: 64,
            offset: Offset(0, -11),
            spreadRadius: -12,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final itemColor = item.color ?? cp.text;
            return FadeTransition(
              opacity: _itemFade(index),
              child: SlideTransition(
                position: _itemSlide(index),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await onDismiss();
                    item.onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        if (item.icon != null)
                          item.icon!
                        else
                          SvgPicture.asset(
                            item.svgPath,
                            colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
                            width: 18,
                            height: 18,
                          ),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: itemColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
