import 'package:flutter/foundation.dart';
import '../easing/ease.dart';
import 'animation.dart';
import 'property.dart';
import '../widgets/transform_props.dart';

enum TweenType { to, from, fromTo, set }

/// Represents an individual property transition.
class _PropertyTween {
  final String key;
  dynamic startValue;
  dynamic endValue;
  dynamic targetValueRaw;
  dynamic Function(dynamic)? modifier;

  _PropertyTween({
    required this.key,
    required this.targetValueRaw,
    this.startValue,
    this.endValue,
    this.modifier,
  });

  void initialize(dynamic currentVal, TweenType type) {
    if (type == TweenType.to || type == TweenType.set) {
      startValue = currentVal;
      if (currentVal is num) {
        endValue = PropertyInterpolation.resolveRelativeDouble(
            currentVal.toDouble(), targetValueRaw);
      } else {
        endValue = targetValueRaw;
      }
    } else if (type == TweenType.from) {
      endValue = currentVal;
      if (currentVal is num) {
        startValue = PropertyInterpolation.resolveRelativeDouble(
            currentVal.toDouble(), targetValueRaw);
      } else {
        startValue = targetValueRaw;
      }
    }
  }

  dynamic evaluate(double progress) {
    dynamic val = PropertyInterpolation.lerp(startValue, endValue, progress);
    if (modifier != null) {
      val = modifier!(val);
    }
    return val;
  }
}

/// Represents a single keyframe step within a keyframed tween.
class KeyframeStep {
  final double durationFraction;
  final Ease? ease;
  final Map<String, dynamic> props;

  KeyframeStep({
    required this.durationFraction,
    this.ease,
    required this.props,
  });
}

class _KeyframeProp {
  final String key;
  final dynamic startValue;
  final dynamic endValue;
  final dynamic Function(dynamic)? modifier;

  _KeyframeProp({
    required this.key,
    required this.startValue,
    required this.endValue,
    this.modifier,
  });
}

class _KeyframeSpan {
  final double start;
  final double end;
  final Ease? ease;
  final List<_KeyframeProp> props;

  _KeyframeSpan({
    required this.start,
    required this.end,
    required this.ease,
    required this.props,
  });
}

/// Main Tween class matching `supreme.to()`, `supreme.from()`, `supreme.fromTo()`, `supreme.set()`.
class SupremeTween extends SupremeAnimation {
  final dynamic target;
  final TweenType type;
  final Map<String, dynamic> vars;
  final Map<String, dynamic>? fromVars;

  Ease ease = Ease.power1.out;
  final List<_PropertyTween> _props = [];
  final Map<String, dynamic Function(dynamic)> _modifiers = {};
  List<KeyframeStep>? _keyframeSteps;
  List<_KeyframeSpan>? _keyframeSpans;
  bool _initialized = false;
  Map<String, dynamic>? _batchedMap;

  SupremeTween({
    required this.target,
    this.type = TweenType.to,
    required this.vars,
    this.fromVars,
    double? duration,
    double? delay,
    Ease? ease,
    int? repeat,
    double? repeatDelay,
    bool? yoyo,
    Ease? yoyoEase,
    bool? paused,
    VoidCallback? onStart,
    VoidCallback? onUpdate,
    VoidCallback? onComplete,
    VoidCallback? onReverseComplete,
    VoidCallback? onRepeat,
  }) : super(
          duration: (type == TweenType.set)
              ? 0.0
              : (duration ?? (vars['duration'] as num?)?.toDouble() ?? 0.5),
          delay: delay ?? (vars['delay'] as num?)?.toDouble() ?? 0.0,
          repeat: repeat ?? (vars['repeat'] as num?)?.toInt() ?? 0,
          repeatDelay:
              repeatDelay ?? (vars['repeatDelay'] as num?)?.toDouble() ?? 0.0,
          yoyo: yoyo ?? (vars['yoyo'] as bool?) ?? false,
          yoyoEase: yoyoEase ??
              (vars['yoyoEase'] is Ease
                  ? vars['yoyoEase'] as Ease
                  : (vars['yoyoEase'] is String
                      ? Ease.fromString(vars['yoyoEase'] as String)
                      : null)),
          paused: paused ?? (vars['paused'] as bool?) ?? false,
          onStart: onStart ?? (vars['onStart'] as VoidCallback?),
          onUpdate: onUpdate ?? (vars['onUpdate'] as VoidCallback?),
          onComplete: onComplete ?? (vars['onComplete'] as VoidCallback?),
          onReverseComplete:
              onReverseComplete ?? (vars['onReverseComplete'] as VoidCallback?),
          onRepeat: onRepeat ?? (vars['onRepeat'] as VoidCallback?),
        ) {
    // Resolve ease
    final rawEase = ease ?? vars['ease'];
    if (rawEase is Ease) {
      this.ease = rawEase;
    } else if (rawEase is String) {
      this.ease = Ease.fromString(rawEase);
    }

    // Resolve modifiers
    if (vars['modifiers'] is Map) {
      final mods = vars['modifiers'] as Map;
      mods.forEach((k, v) {
        if (v is Function) {
          _modifiers[k.toString()] = (dynamic val) => (v as dynamic)(val);
        }
      });
    }

    _setupKeyframes();
    _initProps();
  }

  static const _reservedKeys = {
    'duration',
    'delay',
    'ease',
    'repeat',
    'repeatDelay',
    'yoyo',
    'yoyoEase',
    'paused',
    'onStart',
    'onUpdate',
    'onComplete',
    'onReverseComplete',
    'onRepeat',
    'modifiers',
    'keyframes',
    'stagger',
  };

  void _setupKeyframes() {
    if (vars['keyframes'] is! List) return;
    final kfList = vars['keyframes'] as List;
    if (kfList.isEmpty) return;

    double totalDur = 0.0;
    for (final kf in kfList) {
      if (kf is Map) {
        totalDur += (kf['duration'] as num?)?.toDouble() ?? 1.0;
      }
    }

    _keyframeSteps = [];
    for (final kf in kfList) {
      if (kf is Map) {
        final d = (kf['duration'] as num?)?.toDouble() ?? 1.0;
        final frac = totalDur > 0 ? (d / totalDur) : (1.0 / kfList.length);
        final kfEase = kf['ease'] is Ease
            ? kf['ease'] as Ease
            : (kf['ease'] is String
                ? Ease.fromString(kf['ease'] as String)
                : null);

        final stepProps = <String, dynamic>{};
        kf.forEach((k, v) {
          if (!_reservedKeys.contains(k)) {
            stepProps[k.toString()] = v;
          }
        });

        _keyframeSteps!.add(KeyframeStep(
          durationFraction: frac,
          ease: kfEase,
          props: stepProps,
        ));
      }
    }
  }

  void _initProps() {
    _props.clear();

    if (type == TweenType.fromTo) {
      final fv = fromVars ?? const {};
      vars.forEach((k, endVal) {
        if (!_reservedKeys.contains(k)) {
          final startVal = fv[k] ?? _getTargetProp(k);
          _props.add(_PropertyTween(
            key: k,
            targetValueRaw: endVal,
            startValue: startVal,
            endValue: (startVal is num)
                ? PropertyInterpolation.resolveRelativeDouble(
                    startVal.toDouble(), endVal)
                : endVal,
            modifier: _modifiers[k],
          ));
        }
      });
      _buildKeyframeSpans();
      _initialized = true;
      // If immediate render is desired for from/fromTo
      render(0.0, suppressEvents: true);
      return;
    }

    vars.forEach((k, v) {
      if (!_reservedKeys.contains(k)) {
        _props.add(_PropertyTween(
          key: k,
          targetValueRaw: v,
          modifier: _modifiers[k],
        ));
      }
    });

    // If target has immediate state, initialize property start values now
    _lazyInit();

    if (type == TweenType.from || type == TweenType.set) {
      // Set target immediately
      render(0.0, suppressEvents: true);
    }
  }

  void _lazyInit() {
    if (_initialized) return;
    for (final pt in _props) {
      final current = _getTargetProp(pt.key);
      pt.initialize(current, type);
    }
    _buildKeyframeSpans();
    _initialized = true;
  }

  /// Bakes each keyframe against the value the previous step ends on,
  /// so seeking or scrubbing does not lerp from whatever the property
  /// happens to hold at that moment.
  void _buildKeyframeSpans() {
    final steps = _keyframeSteps;
    if (steps == null || steps.isEmpty) {
      _keyframeSpans = null;
      return;
    }

    final cursor = <String, dynamic>{};
    final spans = <_KeyframeSpan>[];
    var accumulated = 0.0;

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final start = accumulated;
      var end = accumulated + step.durationFraction;
      if (i == steps.length - 1) end = 1.0;
      accumulated = end;

      final props = <_KeyframeProp>[];
      step.props.forEach((key, targetVal) {
        final startVal =
            cursor.containsKey(key) ? cursor[key] : _getTargetProp(key);
        final endVal = startVal is num
            ? PropertyInterpolation.resolveRelativeDouble(
                startVal.toDouble(), targetVal)
            : targetVal;
        cursor[key] = endVal;
        props.add(_KeyframeProp(
          key: key,
          startValue: startVal,
          endValue: endVal,
          modifier: _modifiers[key],
        ));
      });

      spans.add(_KeyframeSpan(
        start: start,
        end: end,
        ease: step.ease,
        props: props,
      ));
    }

    _keyframeSpans = spans;
  }

  dynamic _getTargetProp(String key) {
    if (target is TransformProps) {
      return (target as TransformProps).getProperty(key);
    }
    if (target is ValueNotifier) {
      final val = (target as ValueNotifier).value;
      if (val is Map) return val[key];
      return val;
    }
    if (target is Map) {
      return (target as Map)[key];
    }
    return null;
  }

  void _beginWrite() {
    if (target is TransformProps) {
      (target as TransformProps).beginBatch();
    }
  }

  void _setTargetProp(String key, dynamic value) {
    if (target is TransformProps) {
      (target as TransformProps).setProperty(key, value);
    } else if (target is ValueNotifier) {
      final notifier = target as ValueNotifier;
      if (notifier.value is Map) {
        _batchedMap ??= Map<String, dynamic>.from(notifier.value as Map);
        _batchedMap![key] = value;
      } else {
        notifier.value = value;
      }
    } else if (target is Map) {
      (target as Map)[key] = value;
    }
  }

  void _endWrite() {
    if (_batchedMap != null && target is ValueNotifier) {
      (target as ValueNotifier).value = _batchedMap;
      _batchedMap = null;
    }
    if (target is TransformProps) {
      (target as TransformProps).endBatch();
    }
  }

  @override
  void invalidate() {
    super.invalidate();
    _initialized = false;
    _lazyInit();
  }

  @override
  void renderProgress(double rawProgress) {
    if (!_initialized) {
      _lazyInit();
    }

    _beginWrite();
    try {
      if (_keyframeSpans != null && _keyframeSpans!.isNotEmpty) {
        _renderKeyframes(rawProgress);
        return;
      }

      // yoyoEase replaces the ease on alternate cycles in either playback direction.
      final activeEase = (yoyoVal && iteration % 2 == 1 && yoyoEase() != null)
          ? yoyoEase()!
          : ease;
      final eased = activeEase(rawProgress);

      for (final pt in _props) {
        final val = pt.evaluate(eased);
        _setTargetProp(pt.key, val);
      }
    } finally {
      _endWrite();
    }
  }

  void _renderKeyframes(double rawProgress) {
    final spans = _keyframeSpans!;
    for (var i = 0; i < spans.length; i++) {
      final span = spans[i];
      final isLast = i == spans.length - 1;
      if (!isLast && rawProgress >= span.end) {
        _applySpan(span, 1.0);
        continue;
      }

      final denom = span.end - span.start;
      final localT = denom > 0
          ? ((rawProgress - span.start) / denom).clamp(0.0, 1.0)
          : 1.0;
      final eased = (span.ease ?? ease)(localT);
      _applySpan(span, eased);
      break;
    }
  }

  void _applySpan(_KeyframeSpan span, double eased) {
    for (final prop in span.props) {
      var value =
          PropertyInterpolation.lerp(prop.startValue, prop.endValue, eased);
      if (prop.modifier != null) {
        value = prop.modifier!(value);
      }
      _setTargetProp(prop.key, value);
    }
  }
}

/// Backward compatibility typedef for [SupremeTween].
@Deprecated('Use SupremeTween instead')
typedef GsapTween = SupremeTween;
