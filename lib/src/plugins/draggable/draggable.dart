import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../core/supreme_core.dart';
import '../../widgets/transform_props.dart';
import '../../widgets/supreme_widget.dart';
import 'inertia.dart';

enum DragType { x, y, xy, rotation }

/// A widget that enables physics-based dragging with inertia momentum and bounds in Supreme Animations.
class SupremeDraggable extends StatefulWidget {
  final Widget child;
  final TransformProps? transform;
  final DragType type;
  final Rect? bounds;
  final bool inertia;
  final Offset? snapStep;
  final VoidCallback? onDragStart;
  final VoidCallback? onDrag;
  final VoidCallback? onDragEnd;
  final VoidCallback? onThrowComplete;

  const SupremeDraggable({
    super.key,
    required this.child,
    this.transform,
    this.type = DragType.xy,
    this.bounds,
    this.inertia = true,
    this.snapStep,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
    this.onThrowComplete,
  });

  @override
  State<SupremeDraggable> createState() => _SupremeDraggableState();
}

class _SupremeDraggableState extends State<SupremeDraggable> {
  late TransformProps _props;
  bool _internalProps = false;
  InertiaTween? _inertiaTween;

  @override
  void initState() {
    super.initState();
    if (widget.transform != null) {
      _props = widget.transform!;
    } else {
      _props = TransformProps();
      _internalProps = true;
    }
  }

  @override
  void dispose() {
    _inertiaTween?.kill();
    if (_internalProps) {
      _props.dispose();
    }
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _inertiaTween?.kill();
    widget.onDragStart?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.type == DragType.rotation) {
      _props.rotation += details.delta.dx * (math.pi / 180.0);
      widget.onDrag?.call();
      return;
    }

    var newX = _props.x;
    var newY = _props.y;

    if (widget.type == DragType.x || widget.type == DragType.xy) {
      newX += details.delta.dx;
    }
    if (widget.type == DragType.y || widget.type == DragType.xy) {
      newY += details.delta.dy;
    }

    if (widget.bounds != null) {
      if (widget.type == DragType.x || widget.type == DragType.xy) {
        newX = newX.clamp(widget.bounds!.left, widget.bounds!.right);
      }
      if (widget.type == DragType.y || widget.type == DragType.xy) {
        newY = newY.clamp(widget.bounds!.top, widget.bounds!.bottom);
      }
    }

    _props.beginBatch();
    _props.x = newX;
    _props.y = newY;
    _props.endBatch();
    widget.onDrag?.call();
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onDragEnd?.call();

    if (widget.inertia) {
      final velocity = details.velocity.pixelsPerSecond;
      _inertiaTween = InertiaTween(
        target: _props,
        initialVelocity: Offset(
          widget.type == DragType.y ? 0.0 : velocity.dx,
          widget.type == DragType.x ? 0.0 : velocity.dy,
        ),
        bounds: widget.bounds,
        snapStep: widget.snapStep,
        onComplete: widget.onThrowComplete,
      );
      supreme.globalTimeline.add(_inertiaTween!);
    } else if (widget.snapStep != null &&
        widget.snapStep!.dx > 0 &&
        widget.snapStep!.dy > 0) {
      _props.x = (_props.x / widget.snapStep!.dx).round() * widget.snapStep!.dx;
      _props.y = (_props.y / widget.snapStep!.dy).round() * widget.snapStep!.dy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SupremeWidget(
        transform: _props,
        child: widget.child,
      ),
    );
  }
}

/// Backward compatibility typedef for [SupremeDraggable].
@Deprecated('Use SupremeDraggable instead')
typedef GsapDraggable = SupremeDraggable;
