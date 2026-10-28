import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Wraps an item in how it looks while lifted. [lift] goes from 0 (resting)
/// to 1 (fully lifted), so a shadow or tint can fade in with it. Called for
/// every item on every frame, so keep the widget tree it returns the same
/// shape whatever [lift] is.
typedef ReorderableGridLiftBuilder =
    Widget Function(BuildContext context, Widget child, double lift);

/// Grid of equally sized square items that are rearranged by long-pressing
/// one and dragging it.
///
/// Every item moves on its own spring, so cards make way with a bit of bounce
/// and a move that gets interrupted mid-flight carries on smoothly instead of
/// jumping. The lifted card follows the finger exactly, tilts with its speed
/// and scrolls the surrounding list when held near its top or bottom edge.
///
/// Every child needs a unique [Key]. [onReorder] is called once, on drop, with
/// indices into [children] (remove at `oldIndex`, insert at `newIndex`).
class ReorderableGrid extends StatefulWidget {
  const ReorderableGrid({
    super.key,
    required this.children,
    required this.itemSize,
    required this.onReorder,
    this.columns = 2,
    this.spacing = 10,
    this.liftBuilder,
    this.longPressDuration = const Duration(milliseconds: 280),
  });

  final List<Widget> children;
  final double itemSize;
  final void Function(int oldIndex, int newIndex) onReorder;
  final int columns;
  final double spacing;
  final ReorderableGridLiftBuilder? liftBuilder;
  final Duration longPressDuration;

  @override
  State<ReorderableGrid> createState() => _ReorderableGridState();
}

class _ReorderableGridState extends State<ReorderableGrid>
    with SingleTickerProviderStateMixin {
  // ─── Feel ─────────────────────────────────────────────
  static final _moveSpring = _Spring(stiffness: 620, dampingRatio: 0.64);
  static final _liftSpring = _Spring(stiffness: 700, dampingRatio: 0.45);
  static final _tiltSpring = _Spring(stiffness: 420, dampingRatio: 0.6);

  static const double _liftedScale = 1.06;
  static const double _restingScaleWhileDragging = 0.97;
  static const double _maxTilt = 0.07; // radians, ~4°
  static const double _maxDropVelocity = 1600;

  // how far past the grid edge the card can be pulled, and how much closer the
  // finger must be to a new slot before the card moves into it
  static const double _rubberBandLimit = 40;
  static const double _slotHysteresis = 12;

  static const double _autoScrollEdge = 90;
  static const double _autoScrollMaxSpeed = 900;

  // ─── State ────────────────────────────────────────────
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  List<Key> _order = [];
  final Map<Key, _Motion> _motions = {};

  Key? _dragKey;
  // stays on top of the others after the drop until another card is lifted
  Key? _topKey;
  int _dragStartIndex = -1;
  Offset _grabOffset = Offset.zero;
  Offset _pointerGlobal = Offset.zero;
  Offset _dragVelocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _syncChildren();
  }

  @override
  void didUpdateWidget(covariant ReorderableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncChildren();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<Key> get _childKeys => [for (final child in widget.children) child.key!];

  // keeps the drag order while dragging; otherwise takes the order given
  void _syncChildren() {
    final keys = _childKeys;
    assert(
      keys.toSet().length == keys.length,
      'ReorderableGrid children need unique keys',
    );

    if (_dragKey != null) {
      final sameItems =
          keys.length == _order.length && keys.toSet().containsAll(_order);
      if (!sameItems) {
        _dragKey = null;
      }
    }
    if (_dragKey == null) {
      _order = keys;
    }

    _motions.removeWhere((key, _) => !keys.contains(key));
    for (int i = 0; i < _order.length; i++) {
      _motions.putIfAbsent(_order[i], () => _Motion(_slotOffset(i)));
    }
    _wake();
  }

  // ─── Layout ───────────────────────────────────────────
  double get _step => widget.itemSize + widget.spacing;

  int get _rows => (_order.length / widget.columns).ceil();

  double get _gridWidth =>
      widget.columns * widget.itemSize + (widget.columns - 1) * widget.spacing;

  double get _gridHeight =>
      _rows == 0 ? 0 : _rows * widget.itemSize + (_rows - 1) * widget.spacing;

  Offset _slotOffset(int index) => Offset(
    (index % widget.columns) * _step,
    (index ~/ widget.columns) * _step,
  );

  // ─── Drag ─────────────────────────────────────────────
  void _startDrag(Key key, Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _dragKey != null) {
      return;
    }

    // a previous drop the parent didn't apply would leave indices off
    _order = _childKeys;
    final motion = _motions[key]!;

    setState(() {
      _dragKey = key;
      _topKey = key;
      _dragStartIndex = _order.indexOf(key);
      _grabOffset = box.globalToLocal(globalPosition) - motion.position;
      _pointerGlobal = globalPosition;
      _dragVelocity = Offset.zero;
    });
    HapticFeedback.mediumImpact();
    _wake();
  }

  void _drop(Offset velocity) {
    final key = _dragKey;
    if (key == null) {
      return;
    }

    final motion = _motions[key]!;
    final speed = velocity.distance;
    motion.velocity =
        speed > _maxDropVelocity
            ? velocity * (_maxDropVelocity / speed)
            : velocity;

    final from = _dragStartIndex;
    final to = _order.indexOf(key);
    setState(() => _dragKey = null);
    _wake();

    if (from != to) {
      HapticFeedback.lightImpact();
      widget.onReorder(from, to);
    }
  }

  void _updateDrag(double dt) {
    final box = context.findRenderObject() as RenderBox?;
    final key = _dragKey;
    if (box == null || !box.hasSize || key == null) {
      return;
    }

    _autoScroll(dt);

    final motion = _motions[key]!;
    final raw = box.globalToLocal(_pointerGlobal) - _grabOffset;
    final position = Offset(
      _rubberBand(raw.dx, _gridWidth - widget.itemSize),
      _rubberBand(raw.dy, _gridHeight - widget.itemSize),
    );
    _dragVelocity =
        Offset.lerp(_dragVelocity, (position - motion.position) / dt, 0.3)!;
    motion.position = position;
    motion.velocity = _dragVelocity;

    final current = _order.indexOf(key);
    final target = _nearestSlot(position, current);
    if (target != current) {
      _order.insert(target, _order.removeAt(current));
      HapticFeedback.selectionClick();
    }
  }

  int _nearestSlot(Offset position, int current) {
    double distanceTo(int index) => (_slotOffset(index) - position).distance;

    int nearest = current;
    double nearestDistance = distanceTo(current);
    for (int i = 0; i < _order.length; i++) {
      final distance = distanceTo(i);
      if (distance < nearestDistance) {
        nearest = i;
        nearestDistance = distance;
      }
    }
    if (nearest != current &&
        nearestDistance + _slotHysteresis > distanceTo(current)) {
      return current;
    }
    return nearest;
  }

  // follows the finger inside [0, max] and resists more the further past it
  double _rubberBand(double value, double max) {
    double resist(double overshoot) =>
        _rubberBandLimit * (1 - 1 / (overshoot * 0.6 / _rubberBandLimit + 1));

    if (value < 0) return -resist(-value);
    if (value > max) return max + resist(value - max);
    return value;
  }

  void _autoScroll(double dt) {
    final scrollable = context.findAncestorStateOfType<ScrollableState>();
    if (scrollable == null ||
        axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      return;
    }
    final viewport = scrollable.context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) {
      return;
    }

    final top = viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + viewport.size.height;
    final y = _pointerGlobal.dy;

    double speed = 0;
    if (y < top + _autoScrollEdge) {
      final t = ((top + _autoScrollEdge - y) / _autoScrollEdge).clamp(0.0, 1.0);
      speed = -_autoScrollMaxSpeed * t * t;
    } else if (y > bottom - _autoScrollEdge) {
      final t = ((y - bottom + _autoScrollEdge) / _autoScrollEdge).clamp(
        0.0,
        1.0,
      );
      speed = _autoScrollMaxSpeed * t * t;
    }
    if (speed == 0) {
      return;
    }

    final position = scrollable.position;
    final target = (position.pixels + speed * dt).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }

  // ─── Animation ────────────────────────────────────────
  void _wake() {
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = math.min((elapsed - _lastTick).inMicroseconds / 1e6, 1 / 30);
    _lastTick = elapsed;
    if (dt <= 0) {
      return;
    }

    if (_dragKey != null) {
      _updateDrag(dt);
    }

    bool moving = _dragKey != null;
    for (int i = 0; i < _order.length; i++) {
      final key = _order[i];
      final motion = _motions[key];
      if (motion == null) continue;
      final isDragged = key == _dragKey;

      if (!isDragged) {
        moving |= motion.settlePosition(_slotOffset(i), dt, _moveSpring);
      }

      final scaleTarget =
          isDragged
              ? _liftedScale
              : (_dragKey != null ? _restingScaleWhileDragging : 1.0);
      moving |= motion.scale.settle(scaleTarget, dt, _liftSpring, 0.0005);

      final tiltTarget =
          isDragged
              ? (_dragVelocity.dx / 1000 * 0.05).clamp(-_maxTilt, _maxTilt)
              : 0.0;
      moving |= motion.tilt.settle(tiltTarget, dt, _tiltSpring, 0.0005);
    }

    setState(() {});
    if (!moving) {
      _ticker.stop();
    }
  }

  // ─── Build ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final childrenByKey = {
      for (final child in widget.children) child.key!: child,
    };
    final paintOrder = [
      for (final key in _order)
        if (key != _topKey) key,
      if (_topKey != null && _order.contains(_topKey)) _topKey!,
    ];

    return SizedBox(
      width: _gridWidth,
      height: _gridHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final key in paintOrder)
            if (childrenByKey[key] != null)
              _buildItem(key, childrenByKey[key]!),
        ],
      ),
    );
  }

  Widget _buildItem(Key key, Widget child) {
    final motion = _motions[key]!;
    final lift = ((motion.scale.value - 1) / (_liftedScale - 1)).clamp(
      0.0,
      1.0,
    );

    return Positioned(
      key: ValueKey(key),
      left: 0,
      top: 0,
      width: widget.itemSize,
      height: widget.itemSize,
      child: Transform.translate(
        offset: motion.position,
        child: Transform.rotate(
          angle: motion.tilt.value,
          child: Transform.scale(
            scale: motion.scale.value,
            child: Listener(
              onPointerCancel: (_) {
                if (_dragKey == key) _drop(Offset.zero);
              },
              child: RawGestureDetector(
                gestures: {
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          duration: widget.longPressDuration,
                          debugOwner: this,
                        ),
                        (recognizer) {
                          // block bodies, or the cascades bind to the arrows
                          recognizer
                            ..onLongPressStart = (details) {
                              _startDrag(key, details.globalPosition);
                            }
                            ..onLongPressMoveUpdate = (details) {
                              _pointerGlobal = details.globalPosition;
                            }
                            ..onLongPressEnd = (details) {
                              _drop(details.velocity.pixelsPerSecond);
                            };
                        },
                      ),
                },
                child: widget.liftBuilder?.call(context, child, lift) ?? child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Springs ──────────────────────────────────────────

class _Spring {
  _Spring({required this.stiffness, required double dampingRatio})
    : damping = 2 * dampingRatio * math.sqrt(stiffness);

  final double stiffness;
  final double damping;
}

class _SpringValue {
  _SpringValue(this.value);

  double value;
  double velocity = 0;

  /// Moves towards [target] by [dt] seconds. Returns false once at rest.
  bool settle(double target, double dt, _Spring spring, double tolerance) {
    if (value == target && velocity == 0) {
      return false;
    }

    // small fixed steps keep the stiff springs stable on slow frames
    double x = value;
    double v = velocity;
    double remaining = dt;
    while (remaining > 0) {
      final h = math.min(remaining, 1 / 240);
      final acceleration =
          -spring.stiffness * (x - target) - spring.damping * v;
      v += acceleration * h;
      x += v * h;
      remaining -= h;
    }

    if ((x - target).abs() < tolerance && v.abs() < tolerance * 10) {
      value = target;
      velocity = 0;
      return false;
    }
    value = x;
    velocity = v;
    return true;
  }
}

class _Motion {
  _Motion(Offset position)
    : x = _SpringValue(position.dx),
      y = _SpringValue(position.dy);

  final _SpringValue x;
  final _SpringValue y;
  final _SpringValue scale = _SpringValue(1);
  final _SpringValue tilt = _SpringValue(0);

  Offset get position => Offset(x.value, y.value);
  set position(Offset value) {
    x.value = value.dx;
    y.value = value.dy;
  }

  set velocity(Offset value) {
    x.velocity = value.dx;
    y.velocity = value.dy;
  }

  bool settlePosition(Offset target, double dt, _Spring spring) {
    final movingX = x.settle(target.dx, dt, spring, 0.3);
    final movingY = y.settle(target.dy, dt, spring, 0.3);
    return movingX || movingY;
  }
}
