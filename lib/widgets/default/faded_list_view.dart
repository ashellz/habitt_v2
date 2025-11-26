import 'package:flutter/material.dart';

class FadedListView extends StatefulWidget {
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
  State<FadedListView> createState() => _FadedListViewState();
}

class _FadedListViewState extends State<FadedListView> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFadeVisibility);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFadeVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFadeVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFadeVisibility() {
    if (!_scrollController.hasClients) return;

    final canScroll = _scrollController.position.maxScrollExtent > 0;
    final atStart =
        _scrollController.position.pixels <=
        _scrollController.position.minScrollExtent;
    final atEnd =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent;

    if (mounted) {
      setState(() {
        _showLeftFade = canScroll && !atStart;
        _showRightFade = canScroll && !atEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: _showLeftFade ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, double leftValue, child) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: _showRightFade ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          builder: (context, double rightValue, child) {
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin:
                      widget.scrollDirection == Axis.horizontal
                          ? Alignment.centerLeft
                          : Alignment.topCenter,
                  end:
                      widget.scrollDirection == Axis.horizontal
                          ? Alignment.centerRight
                          : Alignment.bottomCenter,
                  colors: [
                    Color.lerp(Colors.white, Colors.transparent, leftValue)!,
                    Colors.white,
                    Colors.white,
                    Color.lerp(Colors.white, Colors.transparent, rightValue)!,
                  ],
                  stops: const [0.0, 0.05, 0.95, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: widget.height,
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: widget.scrollDirection,
                  physics: const BouncingScrollPhysics(),
                  children: widget.children,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
