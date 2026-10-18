import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;
import '../../core/tween.dart';
import '../../widgets/transform_props.dart';

/// Physics deceleration tween in Supreme Animations.
class InertiaTween extends SupremeTween {
  final Offset initialVelocity;
  final Rect? bounds;
  final double resistance; // Deceleration factor (e.g. 0.95)
  final Offset? snapStep;

  Offset _currentVelocity;
  Offset _currentPos;

  InertiaTween({
    required TransformProps super.target,
    required this.initialVelocity,
    this.bounds,
    this.resistance = 0.92,
    this.snapStep,
    double duration = 1.0,
    super.onUpdate,
    super.onComplete,
  })  : _currentVelocity = initialVelocity,
        _currentPos = Offset(target.x, target.y),
        super(
          duration: duration,
          vars: const {},
        );

  @override
  void update(double deltaSeconds) {
    if (isPaused() || isKilled()) return;

    final tp = target as TransformProps;

    // Apply velocity step
    _currentPos += _currentVelocity * deltaSeconds;
    _currentVelocity *= math.pow(resistance, deltaSeconds * 60.0).toDouble();

    var newX = _currentPos.dx;
    var newY = _currentPos.dy;

    // Write the clamped position back. Leaving the integrator outside the
    // bounds makes the next step start from an ever-growing overshoot.
    if (bounds != null) {
      if (newX < bounds!.left) {
        newX = bounds!.left;
        _currentVelocity =
            Offset(-_currentVelocity.dx * 0.2, _currentVelocity.dy);
      } else if (newX > bounds!.right) {
        newX = bounds!.right;
        _currentVelocity =
            Offset(-_currentVelocity.dx * 0.2, _currentVelocity.dy);
      }

      if (newY < bounds!.top) {
        newY = bounds!.top;
        _currentVelocity =
            Offset(_currentVelocity.dx, -_currentVelocity.dy * 0.2);
      } else if (newY > bounds!.bottom) {
        newY = bounds!.bottom;
        _currentVelocity =
            Offset(_currentVelocity.dx, -_currentVelocity.dy * 0.2);
      }
    }

    _currentPos = Offset(newX, newY);
    tp.beginBatch();
    tp.x = newX;
    tp.y = newY;
    tp.endBatch();

    // Check if stopped
    if (_currentVelocity.distance < 10.0) {
      if (snapStep != null && snapStep!.dx > 0 && snapStep!.dy > 0) {
        tp.x = (tp.x / snapStep!.dx).round() * snapStep!.dx;
        tp.y = (tp.y / snapStep!.dy).round() * snapStep!.dy;
      }
      kill();
      onComplete?.call();
      return;
    }

    onUpdate?.call();
  }

  @override
  void renderProgress(double rawProgress) {
    // Handled in frame update physics
  }
}
