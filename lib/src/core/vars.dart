import 'dart:collection';

/// Strongly-typed builder for Supreme Animations configuration variables.
///
/// Implements [MapBase<String, dynamic>] so it is 100% compatible with all
/// existing methods expecting `Map<String, dynamic> vars`, while providing
/// compile-time type safety, IDE code completion, and inline documentation.
///
/// Example:
/// ```dart
/// supreme.to(myBox, SupremeVars(
///   x: 100,
///   rotationDeg: 180,
///   scale: 1.2,
///   duration: 1.0,
///   ease: Ease.back.out,
///   repeat: -1,
///   yoyo: true,
/// ));
/// ```
class SupremeVars extends MapBase<String, dynamic> {
  final Map<String, dynamic> _data = {};

  SupremeVars({
    // Transform coordinates
    double? x,
    double? y,
    double? z,

    // Scale
    double? scale,
    double? scaleX,
    double? scaleY,

    // Rotation in Radians
    double? rotation,
    double? rotationX,
    double? rotationY,

    // Rotation in Degrees (converts to radians automatically)
    double? rotationDeg,
    double? rotationXDeg,
    double? rotationYDeg,

    // Skew
    double? skewX,
    double? skewY,

    // Visual styles
    double? opacity,
    double? blur,

    // Timing & Physics
    double? duration,
    double? delay,
    dynamic ease,
    int? repeat,
    double? repeatDelay,
    bool? yoyo,
    dynamic yoyoEase,
    bool? paused,

    // Staggers & Keyframes
    dynamic stagger,
    List<Map<String, dynamic>>? keyframes,
    Map<String, dynamic Function(dynamic)>? modifiers,

    // MotionPath
    dynamic motionPath,

    // Lifecycle Callbacks
    void Function()? onStart,
    void Function()? onUpdate,
    void Function()? onComplete,
    void Function()? onReverseComplete,
    void Function()? onRepeat,

    // Arbitrary custom properties (e.g. for Map / custom targets)
    Map<String, dynamic>? custom,
  }) {
    if (x != null) _data['x'] = x;
    if (y != null) _data['y'] = y;
    if (z != null) _data['z'] = z;

    if (scale != null) _data['scale'] = scale;
    if (scaleX != null) _data['scaleX'] = scaleX;
    if (scaleY != null) _data['scaleY'] = scaleY;

    if (rotation != null) _data['rotation'] = rotation;
    if (rotationX != null) _data['rotationX'] = rotationX;
    if (rotationY != null) _data['rotationY'] = rotationY;

    if (rotationDeg != null) _data['rotationDeg'] = rotationDeg;
    if (rotationXDeg != null) _data['rotationXDeg'] = rotationXDeg;
    if (rotationYDeg != null) _data['rotationYDeg'] = rotationYDeg;

    if (skewX != null) _data['skewX'] = skewX;
    if (skewY != null) _data['skewY'] = skewY;

    if (opacity != null) _data['opacity'] = opacity;
    if (blur != null) _data['blur'] = blur;

    if (duration != null) _data['duration'] = duration;
    if (delay != null) _data['delay'] = delay;
    if (ease != null) _data['ease'] = ease;
    if (repeat != null) _data['repeat'] = repeat;
    if (repeatDelay != null) _data['repeatDelay'] = repeatDelay;
    if (yoyo != null) _data['yoyo'] = yoyo;
    if (yoyoEase != null) _data['yoyoEase'] = yoyoEase;
    if (paused != null) _data['paused'] = paused;

    if (stagger != null) _data['stagger'] = stagger;
    if (keyframes != null) _data['keyframes'] = keyframes;
    if (modifiers != null) _data['modifiers'] = modifiers;
    if (motionPath != null) _data['motionPath'] = motionPath;

    if (onStart != null) _data['onStart'] = onStart;
    if (onUpdate != null) _data['onUpdate'] = onUpdate;
    if (onComplete != null) _data['onComplete'] = onComplete;
    if (onReverseComplete != null) {
      _data['onReverseComplete'] = onReverseComplete;
    }
    if (onRepeat != null) _data['onRepeat'] = onRepeat;

    if (custom != null) {
      _data.addAll(custom);
    }
  }

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, dynamic value) => _data[key] = value;

  @override
  void clear() => _data.clear();

  @override
  Iterable<String> get keys => _data.keys;

  @override
  dynamic remove(Object? key) => _data.remove(key);
}

/// Backward compatibility typedef for [SupremeVars].
@Deprecated('Use SupremeVars instead')
typedef GsapVars = SupremeVars;
