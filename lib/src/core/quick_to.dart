import '../easing/ease.dart';
import 'tween.dart';

typedef QuickToFunction = void Function(dynamic value);
typedef QuickSetterFunction = void Function(dynamic value);

/// Implements `supreme.quickTo()` and `supreme.quickSetter()`.
class SupremeQuick {
  /// Returns a high-performance reusable function that tweens a specific property
  /// to new values on demand, redirecting smoothly without GC churn.
  static QuickToFunction quickTo(
    dynamic target,
    String property, {
    double duration = 0.5,
    Ease? ease,
  }) {
    SupremeTween? activeTween;

    return (dynamic targetValue) {
      activeTween?.kill();
      // One tween on the global timeline. A fresh ticker listener per call
      // stacked updates and, once the timeline went idle, the driver put the
      // ticker back to sleep so later calls never ran.
      activeTween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: duration,
        ease: ease ?? Ease.power3.out,
        vars: {
          property: targetValue,
        },
      );
      activeTween!.wake();
    };
  }

  /// Returns an ultra-fast setter function for immediate property manipulation.
  static QuickSetterFunction quickSetter(
    dynamic target,
    String property,
  ) {
    return (dynamic value) {
      SupremeTween(
        target: target,
        type: TweenType.set,
        duration: 0.0,
        vars: {property: value},
      );
    };
  }
}

/// Backward compatibility typedef for [SupremeQuick].
@Deprecated('Use SupremeQuick instead')
typedef GsapQuick = SupremeQuick;
