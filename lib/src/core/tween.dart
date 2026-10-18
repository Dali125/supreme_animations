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
  /// Share of the tween's duration this step animates for.
  final double durationFraction;

  /// Share of the tween's duration the step waits (holding the previous
  /// values) before it starts animating.
  final double delayFraction;
  final Ease? ease;
  final Map<String, dynamic> props;

  KeyframeStep({
    required this.durationFraction,
    this.delayFraction = 0.0,
    this.ease,
    required this.props,
  });
}

/// Absolute timing of a keyframe list, see [SupremeTween] for the rules.
class _KeyframePlan {
  final double total;
  final List<double> durations;
  final List<double> delays;

  const _KeyframePlan(this.total, this.durations, this.delays);
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
  late final bool _immediateRender;

  /// The default length of a tween when no `duration` is given.
  static const double defaultDuration = 0.5;

  /// Creates a tween.
  ///
  /// Start values of a `to` tween (and the end values of a `from` tween) are
  /// recorded the first time the tween renders after its delay, not when it
  /// is created, so tweens queued in a timeline pick up the values earlier
  /// tweens leave behind. [invalidate] makes the tween record them again.
  ///
  /// [immediateRender] applies the from-values of a `from`, `fromTo` or `set`
  /// tween as soon as it is created. It defaults to true here; the
  /// `supreme.from/fromTo` helpers default it to `!paused`, and timelines
  /// default it to true only for children placed at the timeline's start.
  ///
  /// Keyframe timing: when `keyframes` is given and no total `duration` is set
  /// (here or in `vars`), the tween lasts the sum of the step durations plus
  /// step delays. A step without a `duration` lasts [keyframeDefaultDuration]
  /// (or [defaultDuration]) divided by the number of steps, so a list with no
  /// step durations keeps the old total. With an explicit total, steps without
  /// a duration share whatever the timed steps leave over; if nothing is left
  /// over, every step and delay is scaled to fit the total.
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
    bool? immediateRender,
    double? keyframeDefaultDuration,
  }) : super(
          duration:
              _resolveDuration(type, duration, vars, keyframeDefaultDuration),
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

    _immediateRender = type == TweenType.to
        ? false
        : (immediateRender ?? (vars['immediateRender'] as bool?) ?? true);

    _setupKeyframes(
      duration ?? (vars['duration'] as num?)?.toDouble(),
      keyframeDefaultDuration ?? defaultDuration,
    );
    _initProps();
  }

  static double _resolveDuration(TweenType type, double? duration,
      Map<String, dynamic> vars, double? keyframeDefaultDuration) {
    if (type == TweenType.set) return 0.0;
    final explicit = duration ?? (vars['duration'] as num?)?.toDouble();
    final kf = vars['keyframes'];
    if (kf is List && kf.whereType<Map>().isNotEmpty) {
      return _planKeyframes(
              kf, explicit, keyframeDefaultDuration ?? defaultDuration)
          .total;
    }
    return explicit ?? keyframeDefaultDuration ?? defaultDuration;
  }

  static double _nonNegative(dynamic v) {
    final d = (v as num?)?.toDouble() ?? 0.0;
    return d.isFinite && d > 0 ? d : 0.0;
  }

  static _KeyframePlan _planKeyframes(
      List kfList, double? explicitTotal, double base) {
    final steps = kfList.whereType<Map>().toList();
    final n = steps.length;
    final specified = [
      for (final s in steps)
        s['duration'] is num ? _nonNegative(s['duration']) : null,
    ];
    final delays = [for (final s in steps) _nonNegative(s['delay'])];
    final delaySum = delays.fold(0.0, (a, b) => a + b);

    if (explicitTotal == null) {
      final perStep = n > 0 ? base / n : 0.0;
      final durations = [for (final d in specified) d ?? perStep];
      final total = durations.fold(0.0, (a, b) => a + b) + delaySum;
      return _KeyframePlan(total, durations, delays);
    }

    final total = explicitTotal < 0 ? 0.0 : explicitTotal;
    final timedSum = specified.fold(0.0, (a, d) => a + (d ?? 0.0)) + delaySum;
    final untimed = specified.where((d) => d == null).length;
    if (untimed > 0 && timedSum < total) {
      final share = (total - timedSum) / untimed;
      return _KeyframePlan(
          total, [for (final d in specified) d ?? share], delays);
    }
    // Nothing left over: scale every step and delay to fit the total.
    if (timedSum <= 0) {
      return _KeyframePlan(
          total, List.filled(n, n > 0 ? total / n : 0.0), List.filled(n, 0.0));
    }
    final k = total / timedSum;
    return _KeyframePlan(
      total,
      [for (final d in specified) (d ?? 0.0) * k],
      [for (final d in delays) d * k],
    );
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
    'immediateRender',
  };

  void _setupKeyframes(double? explicitTotal, double base) {
    if (vars['keyframes'] is! List) return;
    final kfList = (vars['keyframes'] as List).whereType<Map>().toList();
    if (kfList.isEmpty) return;

    final plan = _planKeyframes(kfList, explicitTotal, base);
    final total = plan.total;
    final n = kfList.length;

    _keyframeSteps = [];
    for (var i = 0; i < n; i++) {
      final kf = kfList[i];
      final frac = total > 0 ? plan.durations[i] / total : 1.0 / n;
      final delayFrac = total > 0 ? plan.delays[i] / total : 0.0;
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
        delayFraction: delayFrac,
        ease: kfEase,
        props: stepProps,
      ));
    }
  }

  void _initProps() {
    _props.clear();
    vars.forEach((k, v) {
      if (!_reservedKeys.contains(k)) {
        _props.add(_PropertyTween(
          key: k,
          targetValueRaw: v,
          modifier: _modifiers[k],
        ));
      }
    });

    // Start/end values are recorded lazily on the first render, except when
    // a from/fromTo/set tween is asked to show its from-values right away.
    if (_immediateRender) {
      _lazyInit();
      render(0.0, suppressEvents: true);
    }
  }

  /// Whether start/end values have been recorded.
  bool get isInitialized => _initialized;

  void _lazyInit() {
    if (_initialized) return;
    final fv = fromVars ?? const <String, dynamic>{};
    for (final pt in _props) {
      if (type == TweenType.fromTo) {
        final startVal = fv[pt.key] ?? _getTargetProp(pt.key);
        pt.startValue = startVal;
        pt.endValue = (startVal is num)
            ? PropertyInterpolation.resolveRelativeDouble(
                startVal.toDouble(), pt.targetValueRaw)
            : pt.targetValueRaw;
      } else {
        pt.initialize(_getTargetProp(pt.key), type);
      }
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

    // A fromTo tween starts its first keyframes from the from-values.
    final cursor = <String, dynamic>{
      if (type == TweenType.fromTo && fromVars != null)
        for (final e in fromVars!.entries)
          if (!_reservedKeys.contains(e.key)) e.key: e.value,
    };
    final spans = <_KeyframeSpan>[];
    var accumulated = 0.0;

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final start = accumulated + step.delayFraction;
      var end = start + step.durationFraction;
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

  /// Forgets the recorded start values; they are recorded again on the
  /// next render.
  @override
  void invalidate() {
    super.invalidate();
    _initialized = false;
  }

  @override
  void renderProgress(double rawProgress) {
    if (!_initialized) {
      // Nothing to write until the delay is over; the values are recorded
      // when the tween actually starts.
      if (totalTime < delayVal) return;
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
