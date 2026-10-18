import 'package:flutter/widgets.dart';
import '../core/context.dart';
import '../core/supreme_core.dart';
import '../core/timeline.dart';

/// Mixin for Flutter [State] objects that automatically manages Supreme animations
/// within a [SupremeContext], safely killing and disposing of all animations when the State is disposed.
mixin SupremeStateMixin<T extends StatefulWidget> on State<T> {
  late final SupremeContext _supremeContext = SupremeContext();

  SupremeContext get supremeContext => _supremeContext;

  /// Backward compatibility getter for [supremeContext].
  @Deprecated('Use supremeContext instead')
  SupremeContext get gsapContext => _supremeContext;

  @override
  void dispose() {
    _supremeContext.revert();
    super.dispose();
  }

  /// Creates a Supreme `to` tween tracked within this State's lifecycle.
  dynamic supremeTo(dynamic target, Map<String, dynamic> vars,
      {double? duration, double? delay}) {
    return _supremeContext.run((ctx) {
      return supreme.to(target, vars, duration: duration, delay: delay);
    });
  }

  /// Backward compatibility method for [supremeTo].
  @Deprecated('Use supremeTo instead')
  dynamic gsapTo(dynamic target, Map<String, dynamic> vars,
      {double? duration, double? delay}) {
    return supremeTo(target, vars, duration: duration, delay: delay);
  }

  /// Creates a Supreme `from` tween tracked within this State's lifecycle.
  dynamic supremeFrom(dynamic target, Map<String, dynamic> vars,
      {double? duration, double? delay}) {
    return _supremeContext.run((ctx) {
      return supreme.from(target, vars, duration: duration, delay: delay);
    });
  }

  /// Backward compatibility method for [supremeFrom].
  @Deprecated('Use supremeFrom instead')
  dynamic gsapFrom(dynamic target, Map<String, dynamic> vars,
      {double? duration, double? delay}) {
    return supremeFrom(target, vars, duration: duration, delay: delay);
  }

  /// Creates a Supreme `fromTo` tween tracked within this State's lifecycle.
  dynamic supremeFromTo(dynamic target, Map<String, dynamic> fromVars,
      Map<String, dynamic> toVars,
      {double? duration, double? delay}) {
    return _supremeContext.run((ctx) {
      return supreme.fromTo(target, fromVars, toVars,
          duration: duration, delay: delay);
    });
  }

  /// Runs [fn] inside this State's context, so every animation it creates
  /// (tweens, timelines, `TextPlugin` effects, ...) is killed on dispose.
  ///
  /// ```dart
  /// supremeRun(() => TextPlugin.typewriter(caption, 'Hello'));
  /// ```
  R supremeRun<R>(R Function() fn) => _supremeContext.run((_) => fn());

  /// Creates a Supreme `timeline` tracked within this State's lifecycle.
  SupremeTimeline supremeTimeline([Map<String, dynamic> vars = const {}]) {
    return _supremeContext.run((ctx) {
      return supreme.timeline(vars);
    });
  }

  /// Backward compatibility method for [supremeTimeline].
  @Deprecated('Use supremeTimeline instead')
  SupremeTimeline gsapTimeline([Map<String, dynamic> vars = const {}]) {
    return supremeTimeline(vars);
  }
}

/// Backward compatibility typedef for [SupremeStateMixin].
@Deprecated('Use SupremeStateMixin instead')
typedef GsapStateMixin<T extends StatefulWidget> = SupremeStateMixin<T>;
