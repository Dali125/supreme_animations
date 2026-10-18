import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'transform_props.dart';
import '../core/animation.dart';
import '../core/supreme_core.dart';
import '../core/tween.dart';

/// A widget that applies 2D/3D transformations, opacity, and blur driven by [TransformProps].
/// This is the primary bridge between Supreme animations and Flutter's widget tree.
class SupremeWidget extends StatefulWidget {
  final Widget child;
  final TransformProps? transform;
  final Alignment origin;
  final Map<String, dynamic>? toVars;
  final Map<String, dynamic>? fromVars;
  final bool autoPlay;
  final void Function(SupremeAnimation animation)? onCreated;

  const SupremeWidget({
    super.key,
    required this.child,
    this.transform,
    this.origin = Alignment.center,
    this.toVars,
    this.fromVars,
    this.autoPlay = true,
    this.onCreated,
  });

  @override
  State<SupremeWidget> createState() => SupremeWidgetState();
}

class SupremeWidgetState extends State<SupremeWidget> {
  late TransformProps _props;
  bool _internalProps = false;
  SupremeAnimation? _activeAnimation;

  TransformProps get props => _props;
  SupremeAnimation? get animation => _activeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.transform != null) {
      _props = widget.transform!;
    } else {
      _props = TransformProps(origin: widget.origin);
      _internalProps = true;
    }

    _initAnimation();
  }

  void _initAnimation() {
    _activeAnimation?.kill();
    if (widget.fromVars != null && widget.toVars != null) {
      _activeAnimation = supreme.fromTo(
        _props,
        widget.fromVars!,
        widget.toVars!,
        paused: !widget.autoPlay,
      );
    } else if (widget.fromVars != null) {
      _activeAnimation = supreme.from(
        _props,
        widget.fromVars!,
        paused: !widget.autoPlay,
      );
    } else if (widget.toVars != null) {
      _activeAnimation = supreme.to(
        _props,
        widget.toVars!,
        paused: !widget.autoPlay,
      );
    }

    if (_activeAnimation != null) {
      widget.onCreated?.call(_activeAnimation!);
    }
  }

  @override
  void didUpdateWidget(covariant SupremeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transform != null && widget.transform != _props) {
      if (_internalProps) {
        _props.dispose();
        _internalProps = false;
      }
      _props = widget.transform!;
    }
  }

  @override
  void dispose() {
    _activeAnimation?.kill();
    if (_internalProps) {
      _props.dispose();
    }
    super.dispose();
  }

  /// Helper to trigger a Supreme `to` tween directly on this widget's transform props.
  SupremeTween to(Map<String, dynamic> vars) {
    return supreme.to(_props, vars) as SupremeTween;
  }

  /// Helper to trigger a Supreme `from` tween directly on this widget's transform props.
  SupremeTween from(Map<String, dynamic> vars) {
    return supreme.from(_props, vars) as SupremeTween;
  }

  /// Helper to trigger a Supreme `fromTo` tween directly on this widget's transform props.
  SupremeTween fromTo(
      Map<String, dynamic> fromVars, Map<String, dynamic> toVars) {
    return supreme.fromTo(_props, fromVars, toVars) as SupremeTween;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _props,
      builder: (context, child) {
        final matrix = vmath.Matrix4.identity();

        // Translation, then rotation, skew, and scale. vector_math post-multiplies,
        // so the vertex sees scale first and translation last.
        if (_props.x != 0.0 || _props.y != 0.0 || _props.z != 0.0) {
          matrix
              .translateByVector3(vmath.Vector3(_props.x, _props.y, _props.z));
        }

        if (_props.rotationX != 0.0) {
          matrix.rotateX(_props.rotationX);
        }
        if (_props.rotationY != 0.0) {
          matrix.rotateY(_props.rotationY);
        }
        if (_props.rotation != 0.0) {
          matrix.rotateZ(_props.rotation);
        }

        if (_props.skewX != 0.0 || _props.skewY != 0.0) {
          final skewMatrix = vmath.Matrix4.identity();
          skewMatrix.setEntry(0, 1, math.tan(_props.skewX));
          skewMatrix.setEntry(1, 0, math.tan(_props.skewY));
          matrix.multiply(skewMatrix);
        }

        if (_props.scaleX != 1.0 || _props.scaleY != 1.0) {
          matrix
              .scaleByVector3(vmath.Vector3(_props.scaleX, _props.scaleY, 1.0));
        }

        final needsPerspective = _props.rotationX != 0.0 ||
            _props.rotationY != 0.0 ||
            _props.z != 0.0;
        final vmath.Matrix4 transform;
        if (needsPerspective) {
          transform = vmath.Matrix4.identity()..setEntry(3, 2, 0.001);
          transform.multiply(matrix);
        } else {
          transform = matrix;
        }

        Widget current = Transform(
          transform: transform,
          alignment: _props.origin,
          child: child,
        );

        // Opacity
        if (_props.opacity < 1.0) {
          current = Opacity(
            opacity: _props.opacity.clamp(0.0, 1.0),
            child: current,
          );
        }

        // Blur filter
        if (_props.blur > 0.0) {
          current = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _props.blur,
              sigmaY: _props.blur,
            ),
            child: current,
          );
        }

        return current;
      },
      child: widget.child,
    );
  }
}

/// Extension method to quickly wrap and animate any Widget with Supreme Animations.
extension SupremeWidgetExtension on Widget {
  /// Animates this widget with Supreme transforms, opacity, and filters.
  ///
  /// Example:
  /// ```dart
  /// MyCard().supreme(
  ///   from: SupremeVars(y: 40, opacity: 0, duration: 0.8, ease: Ease.back.out),
  /// )
  /// ```
  SupremeWidget supreme({
    Key? key,
    Map<String, dynamic>? to,
    Map<String, dynamic>? from,
    Map<String, dynamic>? toVars,
    Map<String, dynamic>? fromVars,
    TransformProps? transform,
    Alignment origin = Alignment.center,
    bool autoPlay = true,
    void Function(SupremeAnimation animation)? onCreated,
  }) {
    return SupremeWidget(
      key: key,
      transform: transform,
      origin: origin,
      toVars: to ?? toVars,
      fromVars: from ?? fromVars,
      autoPlay: autoPlay,
      onCreated: onCreated,
      child: this,
    );
  }

  /// Backward compatibility extension method.
  @Deprecated('Use .supreme() instead')
  SupremeWidget gsap({
    Key? key,
    Map<String, dynamic>? to,
    Map<String, dynamic>? from,
    Map<String, dynamic>? toVars,
    Map<String, dynamic>? fromVars,
    TransformProps? transform,
    Alignment origin = Alignment.center,
    bool autoPlay = true,
    void Function(SupremeAnimation animation)? onCreated,
  }) {
    return supreme(
      key: key,
      to: to,
      from: from,
      toVars: toVars,
      fromVars: fromVars,
      transform: transform,
      origin: origin,
      autoPlay: autoPlay,
      onCreated: onCreated,
    );
  }
}

/// Backward compatibility typedef for [SupremeWidget].
@Deprecated('Use SupremeWidget instead')
typedef GsapWidget = SupremeWidget;

/// Backward compatibility typedef for [SupremeWidgetState].
@Deprecated('Use SupremeWidgetState instead')
typedef GsapWidgetState = SupremeWidgetState;
