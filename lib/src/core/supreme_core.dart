import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../easing/ease.dart';
import 'animation.dart';
import 'tween.dart';
import 'timeline.dart';
import 'stagger.dart';
import 'ticker.dart';
import 'context.dart';
import 'quick_to.dart';
import '../plugins/motion_path/motion_path.dart';

/// The central Supreme Animations interface.
class Supreme {
  static final Supreme _instance = Supreme._();
  static Supreme get instance => _instance;

  final SupremeRootTimeline globalTimeline = SupremeRootTimeline();
  final SupremeTicker ticker = SupremeTicker.instance;
  final List<dynamic> _registeredPlugins = [];

  Supreme._() {
    // Setup onWake hook for standalone animations
    SupremeAnimation.onWake = (anim) {
      if (anim.parent == null || identical(anim.parent, globalTimeline)) {
        globalTimeline.add(anim);
        ticker.wake();
      }
    };

    // Connect ticker to drive global timeline
    ticker.add((double dt, double total) {
      if (!globalTimeline.isPaused()) {
        globalTimeline.update(dt);
      }
      // Stay awake while plugins (scrub smoothing, for example) are listening.
      if (!globalTimeline.isActive() && ticker.listenerCount <= 1) {
        ticker.sleep();
      }
    });
  }

  /// Register custom plugins.
  void registerPlugin(dynamic plugin) {
    if (!_registeredPlugins.contains(plugin)) {
      _registeredPlugins.add(plugin);
    }
  }

  /// Creates a scoped context for tracking animations: `supreme.context((self) { ... })`.
  SupremeContext context(void Function(SupremeContext ctx) scope) {
    final ctx = SupremeContext();
    ctx.run(scope);
    return ctx;
  }

  /// Creates an animation tweening target(s) TO the destination values.
  SupremeAnimation to(
    dynamic target,
    Map<String, dynamic> vars, {
    double? duration,
    double? delay,
    Ease? ease,
    bool? paused,
    dynamic position,
  }) {
    return _createTween(TweenType.to, target, vars,
        duration: duration, delay: delay, ease: ease, paused: paused);
  }

  /// Creates an animation tweening target(s) FROM the specified values to current state.
  SupremeAnimation from(
    dynamic target,
    Map<String, dynamic> vars, {
    double? duration,
    double? delay,
    Ease? ease,
    bool? paused,
  }) {
    return _createTween(TweenType.from, target, vars,
        duration: duration, delay: delay, ease: ease, paused: paused);
  }

  /// Creates an animation tweening target(s) FROM start values TO end values.
  SupremeAnimation fromTo(
    dynamic target,
    Map<String, dynamic> fromVars,
    Map<String, dynamic> toVars, {
    double? duration,
    double? delay,
    Ease? ease,
    bool? paused,
  }) {
    return _createTween(TweenType.fromTo, target, toVars,
        fromVars: fromVars,
        duration: duration,
        delay: delay,
        ease: ease,
        paused: paused);
  }

  /// Immediately sets target properties without animation (0 duration).
  SupremeAnimation set(dynamic target, Map<String, dynamic> vars) {
    return _createTween(TweenType.set, target, vars, duration: 0.0);
  }

  /// Creates a new timeline container for sequencing animations.
  SupremeTimeline timeline([Map<String, dynamic> vars = const {}]) {
    final defaults = (vars['defaults'] as Map<String, dynamic>?) ?? const {};
    final tl = SupremeTimeline(
      defaults: defaults,
      delay: (vars['delay'] as num?)?.toDouble() ?? 0.0,
      timeScale: (vars['timeScale'] as num?)?.toDouble() ?? 1.0,
      repeat: (vars['repeat'] as num?)?.toInt() ?? 0,
      repeatDelay: (vars['repeatDelay'] as num?)?.toDouble() ?? 0.0,
      yoyo: (vars['yoyo'] as bool?) ?? false,
      paused: (vars['paused'] as bool?) ?? false,
      onStart: vars['onStart'] as VoidCallback?,
      onUpdate: vars['onUpdate'] as VoidCallback?,
      onComplete: vars['onComplete'] as VoidCallback?,
      onReverseComplete: vars['onReverseComplete'] as VoidCallback?,
      onRepeat: vars['onRepeat'] as VoidCallback?,
    );

    // Register with active context if any
    SupremeContextScope.current?.add(tl);

    // If not paused, add to global timeline for automatic playback
    if (!tl.isPaused()) {
      globalTimeline.add(tl);
      ticker.wake();
    }

    return tl;
  }

  /// Creates a quickTo function for performance-critical real-time updates.
  QuickToFunction quickTo(
    dynamic target,
    String property, {
    double duration = 0.5,
    Ease? ease,
  }) {
    return SupremeQuick.quickTo(target, property,
        duration: duration, ease: ease);
  }

  /// Creates a quickSetter function for instantaneous property modifications.
  QuickSetterFunction quickSetter(
    dynamic target,
    String property,
  ) {
    return SupremeQuick.quickSetter(target, property);
  }

  /// Kills all tweens and timeline children affecting [target].
  void killTweensOf(dynamic target) {
    final tweens = getTweensOf(target);
    for (final t in tweens) {
      t.kill();
    }
  }

  /// Returns a list of all active tweens currently affecting [target].
  List<SupremeTween> getTweensOf(dynamic target) {
    final list = <SupremeTween>[];
    for (final child in globalTimeline.children) {
      if (child is SupremeTween &&
          child.target == target &&
          !child.isKilled()) {
        list.add(child);
      } else if (child is SupremeTimeline) {
        _collectTweensOf(child, target, list);
      }
    }
    return list;
  }

  void _collectTweensOf(
      SupremeTimeline tl, dynamic target, List<SupremeTween> out) {
    for (final child in tl.children) {
      if (child is SupremeTween &&
          child.target == target &&
          !child.isKilled()) {
        out.add(child);
      } else if (child is SupremeTimeline) {
        _collectTweensOf(child, target, out);
      }
    }
  }

  SupremeAnimation _createTween(
    TweenType type,
    dynamic target,
    Map<String, dynamic> vars, {
    Map<String, dynamic>? fromVars,
    double? duration,
    double? delay,
    Ease? ease,
    bool? paused,
  }) {
    // If target is an iterable, create a staggered collection of tweens in a timeline
    if (target is Iterable && target is! Map) {
      final list = target.toList();
      final stagger = Stagger.fromDynamic(vars['stagger']);
      final delays = stagger?.calculateDelays(list.length) ??
          List.filled(list.length, 0.0);

      final groupPaused = paused ?? (vars['paused'] as bool?) ?? false;
      final groupTl = SupremeTimeline(paused: groupPaused);
      final cleanVars = Map<String, dynamic>.from(vars)..remove('stagger');

      for (int i = 0; i < list.length; i++) {
        final itemTarget = list[i];
        final itemVars = Map<String, dynamic>.from(cleanVars);
        final userDelay =
            delay ?? (itemVars['delay'] as num?)?.toDouble() ?? 0.0;
        itemVars.remove('delay');

        final tween = SupremeTween(
          target: itemTarget,
          type: type,
          fromVars: fromVars,
          vars: itemVars,
          duration: duration,
          delay: userDelay,
          ease: ease,
          paused: true,
        );
        // Stagger offsets the timeline position. The tween delay stays the
        // caller's delay, otherwise every item waits twice as long.
        groupTl.add(tween, delays[i]);
      }

      SupremeContextScope.current?.add(groupTl);
      if (!groupPaused) {
        globalTimeline.add(groupTl);
        ticker.wake();
      }
      return groupTl;
    }

    // Handle motionPath plugin parameter
    if (vars.containsKey('motionPath')) {
      final mpConfig = vars['motionPath'];
      MotionPath? motionPath;
      bool autoRotate = false;
      double autoRotateOffset = 0.0;
      Offset alignOrigin = Offset.zero;

      if (mpConfig is MotionPath) {
        motionPath = mpConfig;
      } else if (mpConfig is List<Offset>) {
        motionPath = MotionPath.curved(mpConfig);
      } else if (mpConfig is Map) {
        final p = mpConfig['path'];
        if (p is MotionPath) {
          motionPath = p;
        } else if (p is List<Offset>) {
          motionPath = MotionPath.curved(p);
        }
        autoRotate = (mpConfig['autoRotate'] as bool?) ?? false;
        autoRotateOffset =
            (mpConfig['autoRotateOffset'] as num?)?.toDouble() ?? 0.0;
        if (mpConfig['alignOrigin'] is Offset) {
          alignOrigin = mpConfig['alignOrigin'] as Offset;
        }
      }

      if (motionPath != null) {
        final mpTween = MotionPathTween(
          target: target,
          path: motionPath,
          autoRotate: autoRotate,
          autoRotateOffset: autoRotateOffset,
          alignOrigin: alignOrigin,
          duration: duration ?? (vars['duration'] as num?)?.toDouble() ?? 1.0,
          delay: delay ?? (vars['delay'] as num?)?.toDouble() ?? 0.0,
          ease: ease ??
              (vars['ease'] is Ease
                  ? vars['ease'] as Ease
                  : (vars['ease'] is String
                      ? Ease.fromString(vars['ease'] as String)
                      : null)),
          repeat: (vars['repeat'] as num?)?.toInt() ?? 0,
          repeatDelay: (vars['repeatDelay'] as num?)?.toDouble() ?? 0.0,
          yoyo: (vars['yoyo'] as bool?) ?? false,
          yoyoEase: vars['yoyoEase'] is Ease
              ? vars['yoyoEase'] as Ease
              : (vars['yoyoEase'] is String
                  ? Ease.fromString(vars['yoyoEase'] as String)
                  : null),
          paused: paused ?? (vars['paused'] as bool?) ?? false,
          onStart: vars['onStart'] as VoidCallback?,
          onUpdate: vars['onUpdate'] as VoidCallback?,
          onComplete: vars['onComplete'] as VoidCallback?,
          onReverseComplete: vars['onReverseComplete'] as VoidCallback?,
          onRepeat: vars['onRepeat'] as VoidCallback?,
        );

        SupremeContextScope.current?.add(mpTween);
        if (!mpTween.isPaused()) {
          globalTimeline.add(mpTween);
          ticker.wake();
        }
        return mpTween;
      }
    }

    // Single target
    final tween = SupremeTween(
      target: target,
      type: type,
      fromVars: fromVars,
      vars: vars,
      duration: duration,
      delay: delay,
      ease: ease,
      paused: paused ?? (vars['paused'] as bool?) ?? false,
    );

    SupremeContextScope.current?.add(tween);

    if (!tween.isPaused()) {
      globalTimeline.add(tween);
      ticker.wake();
    }

    return tween;
  }
}

/// The global Supreme Animations instance.
final Supreme supreme = Supreme.instance;

/// Backward compatibility alias for [supreme].
@Deprecated('Use supreme instead')
final Supreme gsap = supreme;

/// Backward compatibility typedef for [Supreme].
@Deprecated('Use Supreme instead')
typedef Gsap = Supreme;
