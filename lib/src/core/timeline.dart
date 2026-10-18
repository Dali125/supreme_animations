import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'animation.dart';
import 'tween.dart';
import 'ticker.dart';

/// Container for an animation placed on a timeline with an explicit start time.
class TimelineChild {
  final SupremeAnimation animation;
  double startTime;

  /// True after the playhead has reached this child at least once
  /// since the last time it rewound past [startTime].
  bool visited = false;

  TimelineChild({
    required this.animation,
    required this.startTime,
  });

  double get endTime => startTime + animation.totalDuration();
}

/// Advanced timeline sequencer matching Supreme Animations Timeline API with full position parameter,
/// labels, defaults inheritance, and nested timeline support.
class SupremeTimeline extends SupremeAnimation {
  final Map<String, dynamic> defaults;
  final List<TimelineChild> _children = [];
  final Map<String, double> _labels = {};
  TimelineChild? _recentChild;
  double _lastRenderedTime = 0.0;

  SupremeTimeline({
    this.defaults = const {},
    super.delay = 0.0,
    super.timeScale = 1.0,
    super.repeat = 0,
    super.repeatDelay = 0.0,
    super.yoyo = false,
    super.yoyoEase,
    super.paused = false,
    super.onStart,
    super.onUpdate,
    super.onComplete,
    super.onReverseComplete,
    super.onRepeat,
  }) : super(
          duration: 0.0,
        );

  /// Map of label names to timestamps in seconds.
  Map<String, double> get labels => Map.unmodifiable(_labels);

  /// Most recently added child animation.
  SupremeAnimation? get recent => _recentChild?.animation;

  /// All children in the timeline.
  List<SupremeAnimation> get children =>
      _children.map((c) => c.animation).toList(growable: false);

  /// Recalculates total duration based on all children.
  void _recomputeDuration() {
    double maxEnd = 0.0;
    for (final c in _children) {
      final end = c.endTime;
      if (end.isInfinite) {
        maxEnd = double.infinity;
        break;
      }
      if (end > maxEnd) {
        maxEnd = end;
      }
    }
    duration(maxEnd);
  }

  /// Resolves GSAP position parameters:
  /// - null: end of timeline (duration)
  /// - number: absolute time in seconds
  /// - "+=0.5" / "-=0.2": relative to the end of the timeline
  /// - "<": start of most recent child
  /// - "<0.2": start of most recent child + 0.2s
  /// - ">": end of most recent child
  /// - ">0.2": end of most recent child + 0.2s
  /// - "label": timestamp of named label
  /// - "label+=0.5" / "label-=0.2": relative to label timestamp
  double parsePosition(dynamic position) {
    if (position == null) {
      return durationVal;
    }
    if (position is num) {
      return math.max(0.0, position.toDouble());
    }
    if (position is String) {
      final str = position.trim();

      // Relative to current end: "+=X" or "-=X"
      if (str.startsWith('+=') || str.startsWith('-=')) {
        final sign = str.startsWith('+=') ? 1.0 : -1.0;
        final val = double.tryParse(str.substring(2)) ?? 0.0;
        return math.max(0.0, durationVal + sign * val);
      }

      // Start of recent child: "<" or "<X" or "<-X"
      if (str.startsWith('<')) {
        final base = _recentChild != null ? _recentChild!.startTime : 0.0;
        final remainder = str.substring(1).trim();
        if (remainder.isEmpty) return base;
        final offset = _parseOffset(remainder);
        return math.max(0.0, base + offset);
      }

      // End of recent child: ">" or ">X" or ">-X"
      if (str.startsWith('>')) {
        final base = _recentChild != null ? _recentChild!.endTime : durationVal;
        final remainder = str.substring(1).trim();
        if (remainder.isEmpty) return base;
        final offset = _parseOffset(remainder);
        return math.max(0.0, base + offset);
      }

      // Check labels
      if (_labels.containsKey(str)) {
        return _labels[str]!;
      }

      // Check label with offset: "myLabel+=0.5"
      if (str.contains('+=') || str.contains('-=')) {
        final isPlus = str.contains('+=');
        final parts = str.split(isPlus ? '+=' : '-=');
        final labelName = parts[0].trim();
        if (_labels.containsKey(labelName)) {
          final base = _labels[labelName]!;
          final val = double.tryParse(parts[1].trim()) ?? 0.0;
          return math.max(0.0, isPlus ? base + val : base - val);
        }
      }

      final parsed = double.tryParse(str);
      if (parsed != null) return math.max(0.0, parsed);
    }

    return durationVal;
  }

  double _parseOffset(String str) {
    if (str.startsWith('+')) {
      return double.tryParse(str.substring(1)) ?? 0.0;
    }
    if (str.startsWith('-')) {
      return -(double.tryParse(str.substring(1)) ?? 0.0);
    }
    return double.tryParse(str) ?? 0.0;
  }

  /// Adds an animation (tween or timeline) at [position].
  SupremeTimeline add(SupremeAnimation animation, [dynamic position]) {
    final previousParent = animation.parent;
    if (previousParent is SupremeRootTimeline &&
        !identical(previousParent, this)) {
      previousParent.remove(animation);
    }
    animation.parent = this;
    final startTime = parsePosition(position);
    final child = TimelineChild(animation: animation, startTime: startTime);
    _children.add(child);
    _recentChild = child;
    _recomputeDuration();
    return this;
  }

  /// Adds a label at the specified position.
  SupremeTimeline addLabel(String name, [dynamic position]) {
    final time = parsePosition(position);
    _labels[name] = time;
    return this;
  }

  /// Removes a label.
  SupremeTimeline removeLabel(String name) {
    _labels.remove(name);
    return this;
  }

  /// Adds a callback function to be called at [position].
  SupremeTimeline call(VoidCallback callback, [dynamic position]) {
    final t = SupremeTween(
      target: Object(),
      type: TweenType.set,
      duration: 0.0,
      vars: const {},
      onStart: callback,
    );
    return add(t, position);
  }

  Map<String, dynamic> _mergeWithDefaults(Map<String, dynamic> vars) {
    if (defaults.isEmpty) return Map<String, dynamic>.from(vars);
    final merged = Map<String, dynamic>.from(defaults);
    // A default duration must not squash keyframe step durations; it is
    // passed to the tween as the per-step fallback instead.
    if (vars['keyframes'] is List) merged.remove('duration');
    merged.addAll(vars);
    return merged;
  }

  double? _keyframeDefault(Map<String, dynamic> vars) =>
      vars['keyframes'] is List && !vars.containsKey('duration')
          ? (defaults['duration'] as num?)?.toDouble()
          : null;

  /// from/fromTo/set children render their from-values at creation only when
  /// they sit at the start of the timeline (or `immediateRender` says so).
  bool _immediateRenderFor(Map<String, dynamic> vars, double startTime) =>
      (vars['immediateRender'] as bool?) ?? startTime <= 0.0;

  /// Adds a `to` tween to the timeline.
  SupremeTimeline to(dynamic target, Map<String, dynamic> vars,
      [dynamic position]) {
    final merged = _mergeWithDefaults(vars);
    final tween = SupremeTween(
      target: target,
      type: TweenType.to,
      vars: merged,
      paused: true, // Controlled by timeline
      keyframeDefaultDuration: _keyframeDefault(vars),
    );
    return add(tween, position);
  }

  /// Adds a `from` tween to the timeline.
  ///
  /// Its from-values are applied at creation only when it starts at time 0
  /// of this timeline, unless `immediateRender` is set in [vars].
  SupremeTimeline from(dynamic target, Map<String, dynamic> vars,
      [dynamic position]) {
    final merged = _mergeWithDefaults(vars);
    final startTime = parsePosition(position);
    final tween = SupremeTween(
      target: target,
      type: TweenType.from,
      vars: merged,
      paused: true,
      immediateRender: _immediateRenderFor(vars, startTime),
      keyframeDefaultDuration: _keyframeDefault(vars),
    );
    return add(tween, startTime);
  }

  /// Adds a `fromTo` tween to the timeline.
  ///
  /// Its from-values are applied at creation only when it starts at time 0
  /// of this timeline, unless `immediateRender` is set in [toVars].
  SupremeTimeline fromTo(
    dynamic target,
    Map<String, dynamic> fromVars,
    Map<String, dynamic> toVars, [
    dynamic position,
  ]) {
    final merged = _mergeWithDefaults(toVars);
    final startTime = parsePosition(position);
    final tween = SupremeTween(
      target: target,
      type: TweenType.fromTo,
      fromVars: fromVars,
      vars: merged,
      paused: true,
      immediateRender: _immediateRenderFor(toVars, startTime),
      keyframeDefaultDuration: _keyframeDefault(toVars),
    );
    return add(tween, startTime);
  }

  /// Adds a `set` immediate tween to the timeline.
  ///
  /// It is applied at creation only when it sits at time 0 of this timeline;
  /// otherwise it is applied when the playhead reaches it.
  SupremeTimeline set(dynamic target, Map<String, dynamic> vars,
      [dynamic position]) {
    final startTime = parsePosition(position);
    final tween = SupremeTween(
      target: target,
      type: TweenType.set,
      vars: vars,
      duration: 0.0,
      paused: true,
      immediateRender: _immediateRenderFor(vars, startTime),
    );
    return add(tween, startTime);
  }

  /// Shifts all child start times by [amount].
  SupremeTimeline shiftChildren(double amount) {
    for (final c in _children) {
      c.startTime = math.max(0.0, c.startTime + amount);
    }
    _recomputeDuration();
    return this;
  }

  /// Removes all animations and labels from timeline.
  SupremeTimeline clear() {
    for (final c in _children) {
      if (identical(c.animation.parent, this)) {
        c.animation.parent = null;
      }
    }
    _children.clear();
    _labels.clear();
    _recentChild = null;
    _recomputeDuration();
    return this;
  }

  @override
  void invalidate() {
    super.invalidate();
    for (final c in _children) {
      c.animation.invalidate();
    }
  }

  @override
  void kill() {
    super.kill();
    for (final c in _children) {
      c.animation.kill();
      if (identical(c.animation.parent, this)) {
        c.animation.parent = null;
      }
    }
    _children.clear();
  }

  @override
  void renderProgress(double rawProgress) {
    // Current timeline time in iteration
    final currentTimelineTime =
        durationVal.isFinite ? rawProgress * durationVal : time;

    // When the playhead moves backwards, render children last-to-first so an
    // earlier child has the final say over a later child that rewinds past
    // its start on the same property.
    final backwards = currentTimelineTime < _lastRenderedTime;
    _lastRenderedTime = currentTimelineTime;
    final ordered = backwards ? _children.reversed : _children;

    for (final c in ordered) {
      final anim = c.animation;
      final childStart = c.startTime;
      final childEnd = c.endTime;

      if (currentTimelineTime < childStart) {
        if (c.visited) {
          c.visited = false;
          anim.rewindBeforeStart();
        }
      } else if (currentTimelineTime >= childEnd) {
        final td = anim.totalDuration();
        final seekTarget = td.isFinite
            ? td
            : (anim.delay() +
                (anim.duration().isFinite ? anim.duration() : 0.0));
        // Zero-duration children (labels, call()) have start == end, so they
        // never fall in the active branch. Visit them once when the playhead arrives.
        if (!c.visited || anim.totalTime < seekTarget) {
          c.visited = true;
          anim.seek(seekTarget);
        }
      } else {
        c.visited = true;
        final localTime = currentTimelineTime - childStart;
        anim.seek(localTime);
      }
    }
  }
}

/// Root timeline driving global animations in Supreme Animations.
/// Unlike standard choreograph timelines, the root timeline drives all independent
/// top-level animations each frame via delta time updates.
class SupremeRootTimeline extends SupremeTimeline {
  bool autoRemoveChildren;

  SupremeRootTimeline({this.autoRemoveChildren = true}) : super(paused: false);

  @override
  double totalDuration() => double.infinity;

  @override
  bool isActive() => _children.any((c) => c.animation.isActive());

  @override
  SupremeTimeline add(SupremeAnimation animation, [dynamic position]) {
    for (final c in _children) {
      if (identical(c.animation, animation)) return this;
    }
    animation.parent = this;
    final child = TimelineChild(animation: animation, startTime: 0.0);
    _children.add(child);
    _recentChild = child;
    if (!animation.isPaused()) {
      SupremeTicker.instance.wake();
    }
    return this;
  }

  void remove(SupremeAnimation animation) {
    _children.removeWhere((c) => identical(c.animation, animation));
    if (identical(animation.parent, this)) {
      animation.parent = null;
    }
  }

  @override
  void update(double deltaSeconds) {
    if (isPaused() || isKilled()) return;

    final effectiveDelta =
        deltaSeconds * timeScale() * (reversed() ? -1.0 : 1.0);
    totalTime += effectiveDelta;
    time += effectiveDelta;

    final toRemove = <TimelineChild>[];
    for (final c in List<TimelineChild>.from(_children)) {
      final anim = c.animation;
      if (anim.isKilled()) {
        toRemove.add(c);
        continue;
      }
      if (!anim.isPaused()) {
        anim.update(effectiveDelta);
      }
      // Drop finished tweens. A caller-paused tween has not parked on a
      // boundary, so it stays registered and can resume.
      if (autoRemoveChildren && anim.stoppedAtBoundary) {
        toRemove.add(c);
      }
    }

    if (toRemove.isNotEmpty) {
      for (final r in toRemove) {
        _children.remove(r);
        if (identical(r.animation.parent, this)) {
          r.animation.parent = null;
        }
      }
    }

    onUpdate?.call();
  }

  @override
  void renderProgress(double rawProgress) {
    // Root timeline does not scrub children on a fixed track
  }
}

/// Backward compatibility typedef for [SupremeTimeline].
@Deprecated('Use SupremeTimeline instead')
typedef GsapTimeline = SupremeTimeline;

/// Backward compatibility typedef for [SupremeRootTimeline].
@Deprecated('Use SupremeRootTimeline instead')
typedef GsapRootTimeline = SupremeRootTimeline;
