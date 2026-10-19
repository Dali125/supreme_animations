// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import '../easing/ease.dart';

enum SupremeEvent {
  onStart,
  onUpdate,
  onComplete,
  onReverseComplete,
  onRepeat,
}

/// Abstract base class for all tweens and timelines in Supreme Animations.
abstract class SupremeAnimation {
  /// Current time (in seconds) within the active iteration.
  double time = 0.0;

  /// Total elapsed time (in seconds) across all iterations and delays.
  double totalTime = 0.0;
  double _duration = 0.0;
  double _delay = 0.0;
  double _timeScale = 1.0;
  int _repeat = 0; // 0 = no repeat, -1 = infinite, >0 = count
  double _repeatDelay = 0.0;
  bool _yoyo = false;
  Ease? _yoyoEase;

  bool _paused = false;
  bool _reversed = false;
  bool _killed = false;
  bool _started = false;

  /// True once [render] has run, including suppressed (immediate) renders.
  bool _hasRendered = false;

  int _repeatIteration = 0;
  int _lastNotifiedIteration = 0;
  bool _didComplete = false;
  bool _didReverseComplete = false;

  /// True after playback parks at the start or end boundary.
  /// The root timeline uses this to drop finished tweens without
  /// dropping tweens the caller paused mid-way.
  bool _stoppedAtBoundary = false;

  final List<void Function()> _updateListeners = [];

  /// Parent timeline containing this animation, or null if root.
  SupremeAnimation? parent;

  /// Global hook invoked when animation requests playback wake.
  static void Function(SupremeAnimation anim)? onWake;

  void wake() {
    onWake?.call(this);
  }

  void _wake() => wake();

  // Callbacks
  void Function()? onStart;
  void Function()? onUpdate;
  void Function()? onComplete;
  void Function()? onReverseComplete;
  void Function()? onRepeat;

  Completer<void>? _completer;

  SupremeAnimation({
    double duration = 0.0,
    double delay = 0.0,
    double timeScale = 1.0,
    int repeat = 0,
    double repeatDelay = 0.0,
    bool yoyo = false,
    Ease? yoyoEase,
    bool paused = false,
    bool reversed = false,
    this.onStart,
    this.onUpdate,
    this.onComplete,
    this.onReverseComplete,
    this.onRepeat,
  })  : _duration = duration < 0.0 ? 0.0 : duration,
        _delay = delay < 0.0 ? 0.0 : delay,
        _timeScale = timeScale,
        _repeat = repeat,
        _repeatDelay = repeatDelay < 0.0 ? 0.0 : repeatDelay,
        _yoyo = yoyo,
        _yoyoEase = yoyoEase,
        _paused = paused,
        _reversed = reversed;

  /// Duration of a single iteration (in seconds).
  double get durationVal => _duration;

  /// Initial start delay (in seconds).
  double get delayVal => _delay;

  /// Playback speed multiplier.
  double get timeScaleVal => _timeScale;

  /// Number of repeats (-1 for infinite).
  int get repeatVal => _repeat;

  /// Pause between repeats (in seconds).
  double get repeatDelayVal => _repeatDelay;

  /// Whether alternating repeats alternate direction.
  bool get yoyoVal => _yoyo;

  /// Current iteration index (0 for first run).
  int get iteration => _repeatIteration;

  /// Whether playback has parked at the start or end boundary.
  bool get stoppedAtBoundary => _stoppedAtBoundary;

  /// Subscribes to render updates without replacing [onUpdate].
  void addUpdateListener(void Function() listener) {
    if (!_updateListeners.contains(listener)) {
      _updateListeners.add(listener);
    }
  }

  /// Removes a listener added with [addUpdateListener].
  void removeUpdateListener(void Function() listener) {
    _updateListeners.remove(listener);
  }

  /// Total duration across all repeats (returns [double.infinity] if infinite).
  double totalDuration() {
    if (_repeat < 0) return double.infinity;
    return _delay + _duration + (_repeat * (_duration + _repeatDelay));
  }

  /// Sets or gets current duration.
  double duration([double? value]) {
    if (value != null) {
      _duration = value < 0.0 ? 0.0 : value;
      // Only re-render something that has already been rendered (including an
      // immediateRender of from/fromTo/set). Rendering a fresh animation here
      // would record start values (and, for timelines, render children) at
      // build time instead of when playback reaches them.
      if (_duration.isFinite && _hasRendered) {
        render(time, suppressEvents: true);
      }
    }
    return _duration;
  }

  /// Sets or gets delay.
  double delay([double? value]) {
    if (value != null) {
      _delay = value < 0.0 ? 0.0 : value;
    }
    return _delay;
  }

  /// Sets or gets timeScale.
  double timeScale([double? scale]) {
    if (scale != null) {
      _timeScale = scale;
    }
    return _timeScale;
  }

  /// Sets or gets repeat count (-1 for infinite).
  int repeat([int? count]) {
    if (count != null) {
      _repeat = count;
    }
    return _repeat;
  }

  /// Sets or gets repeat delay.
  double repeatDelay([double? value]) {
    if (value != null) {
      _repeatDelay = value < 0.0 ? 0.0 : value;
    }
    return _repeatDelay;
  }

  /// Sets or gets yoyo behavior.
  bool yoyo([bool? value]) {
    if (value != null) {
      _yoyo = value;
    }
    return _yoyo;
  }

  /// Sets or gets yoyo ease.
  Ease? yoyoEase([Ease? ease]) {
    if (ease != null) {
      _yoyoEase = ease;
    }
    return _yoyoEase;
  }

  /// Sets or gets progress in range `[0, 1]` for current iteration.
  double progress([double? value, bool suppressEvents = false]) {
    if (value != null) {
      final clamped = value.clamp(0.0, 1.0).toDouble();
      final cycle = _duration + _repeatDelay;
      final iterationStart =
          _delay + _repeatIteration * (cycle > 0 ? cycle : 0.0);
      seek(
        iterationStart + clamped * (_duration.isFinite ? _duration : 0.0),
        suppressEvents: suppressEvents,
      );
    }
    return (_duration > 0 && _duration.isFinite)
        ? (time / _duration).clamp(0.0, 1.0)
        : 1.0;
  }

  /// Sets or gets total progress across repeats in range `[0, 1]`.
  double totalProgress([double? value, bool suppressEvents = false]) {
    final td = totalDuration();
    if (value != null) {
      if (td.isFinite && td > 0) {
        seek(value.clamp(0.0, 1.0) * td, suppressEvents: suppressEvents);
      }
    }
    if (!td.isFinite) return 0.0;
    return td > 0 ? (totalTime / td).clamp(0.0, 1.0) : 1.0;
  }

  /// Returns whether animation is currently playing (not paused and not complete).
  bool isActive() {
    if (_paused || _killed) return false;
    if (_reversed) {
      return totalTime > 0.0;
    }
    final td = totalDuration();
    return totalTime < td;
  }

  bool isPaused() => _paused;
  bool isReversed() => _reversed;
  bool isKilled() => _killed;

  /// Gets or sets whether animation is paused.
  bool paused([bool? value]) {
    if (value != null) {
      if (value) {
        pause();
      } else {
        resume();
      }
    }
    return _paused;
  }

  /// Gets or sets whether animation is reversed.
  bool reversed([bool? value]) {
    if (value != null) {
      _reversed = value;
    }
    return _reversed;
  }

  /// Plays forwards.
  SupremeAnimation play({double? from}) {
    _stoppedAtBoundary = false;
    if (from != null) seek(from);
    _reversed = false;
    _paused = false;
    _wake();
    return this;
  }

  /// Pauses the animation.
  SupremeAnimation pause({double? at}) {
    if (at != null) seek(at);
    _paused = true;
    return this;
  }

  /// Resumes playback.
  SupremeAnimation resume() {
    _stoppedAtBoundary = false;
    _paused = false;
    _wake();
    return this;
  }

  /// Plays in reverse.
  SupremeAnimation reverse({double? from}) {
    _stoppedAtBoundary = false;
    _reversed = true;
    if (from != null) {
      seek(from);
    } else if (totalTime <= 0.0 || !totalTime.isFinite) {
      final td = totalDuration();
      final target =
          td.isFinite ? td : (_delay + (_duration.isFinite ? _duration : 0.0));
      seek(target);
    }
    _paused = false;
    _wake();
    return this;
  }

  /// Restarts from the beginning.
  SupremeAnimation restart({bool includeDelay = false}) {
    _reversed = false;
    _paused = false;
    _stoppedAtBoundary = false;
    _started = false;
    _didComplete = false;
    _didReverseComplete = false;
    _lastNotifiedIteration = 0;
    seek(includeDelay ? 0.0 : _delay);
    _wake();
    return this;
  }

  /// Snaps the playhead to the pre-start state without firing callbacks.
  /// Timelines use this when the playhead scrubs back before a child.
  void rewindBeforeStart() {
    if (totalTime == 0 &&
        time == 0 &&
        !_started &&
        !_didComplete &&
        _repeatIteration == 0) {
      return;
    }
    totalTime = 0;
    time = 0;
    _repeatIteration = 0;
    _lastNotifiedIteration = 0;
    _started = false;
    _didComplete = false;
    _didReverseComplete = false;
    _stoppedAtBoundary = false;
    render(0.0, suppressEvents: true);
  }

  /// Seeks to a specific total time in seconds.
  SupremeAnimation seek(double targetTotalTime, {bool suppressEvents = false}) {
    if (targetTotalTime.isNaN) targetTotalTime = 0.0;
    final td = totalDuration();
    if (!targetTotalTime.isFinite) {
      targetTotalTime =
          td.isFinite ? td : (_delay + (_duration.isFinite ? _duration : 0.0));
    }
    totalTime = targetTotalTime.clamp(0.0, td.isFinite ? td : double.infinity);

    // Compute iteration and iteration time
    if (totalTime < _delay) {
      _repeatIteration = 0;
      time = 0.0;
    } else {
      final activeTime = totalTime - _delay;
      final cycleDuration = _duration + _repeatDelay;

      if (cycleDuration <= 0 ||
          !cycleDuration.isFinite ||
          !activeTime.isFinite) {
        _repeatIteration = (_repeat >= 0) ? _repeat : 0;
        time = _duration.isFinite ? _duration : 0.0;
      } else {
        final rawIteration = activeTime / cycleDuration;
        if (!rawIteration.isFinite) {
          _repeatIteration = (_repeat >= 0) ? _repeat : 0;
          time = _duration.isFinite ? _duration : 0.0;
        } else {
          _repeatIteration = rawIteration.floor();
          if (_repeat >= 0 && _repeatIteration > _repeat) {
            _repeatIteration = _repeat;
          }

          final timeInCycle = activeTime - (_repeatIteration * cycleDuration);
          time = timeInCycle.clamp(0.0, _duration.isFinite ? _duration : 0.0);
        }
      }
    }

    render(time, suppressEvents: suppressEvents);
    return this;
  }

  /// Advance animation by delta seconds.
  void update(double deltaSeconds) {
    if (_paused || _killed) return;

    final effectiveDelta = deltaSeconds * _timeScale * (_reversed ? -1.0 : 1.0);
    final newTotalTime = totalTime + effectiveDelta;
    final td = totalDuration();

    // Park at the ends so a later frame cannot repeat onComplete.
    if (effectiveDelta > 0) {
      if (newTotalTime >= td && td.isFinite) {
        seek(td);
        _paused = true;
        _stoppedAtBoundary = true;
        return;
      }
    } else if (effectiveDelta < 0) {
      if (newTotalTime <= 0.0) {
        seek(0.0);
        _paused = true;
        _stoppedAtBoundary = true;
        return;
      }
    }

    _stoppedAtBoundary = false;
    seek(newTotalTime);
  }

  /// Renders internal properties for current iteration [time].
  void render(double iterationTime, {bool suppressEvents = false}) {
    if (_killed) return;
    _hasRendered = true;

    // Suppressed renders (from/set immediate placement) must not consume onStart.
    if (!_started &&
        !suppressEvents &&
        totalTime >= _delay &&
        iterationTime >= 0.0) {
      _started = true;
      onStart?.call();
    }

    // Determine current progression
    double rawProgress = (_duration > 0 && _duration.isFinite)
        ? (iterationTime / _duration).clamp(0.0, 1.0)
        : 1.0;

    // Yoyo check
    final isYoyoCycle = _yoyo && (_repeatIteration % 2 == 1);
    if (isYoyoCycle) {
      rawProgress = 1.0 - rawProgress;
    }

    renderProgress(rawProgress);

    if (!suppressEvents) {
      onUpdate?.call();
      if (_updateListeners.isNotEmpty) {
        for (final listener in List<void Function()>.from(_updateListeners)) {
          listener();
        }
      }
    }

    _emitRepeat(suppressEvents);
    _emitBoundary(suppressEvents);
  }

  void _emitRepeat(bool suppressEvents) {
    if (_repeatIteration == _lastNotifiedIteration) return;
    final previous = _lastNotifiedIteration;
    _lastNotifiedIteration = _repeatIteration;
    if (suppressEvents) return;
    var crossings = (_repeatIteration - previous).abs();
    if (crossings > 32) crossings = 32;
    for (var i = 0; i < crossings; i++) {
      onRepeat?.call();
    }
  }

  void _emitBoundary(bool suppressEvents) {
    if (_killed) return;
    final td = totalDuration();
    final atEnd = !_reversed && td.isFinite && totalTime >= td;
    final atReverseStart = _reversed && totalTime <= 0.0;

    if (atEnd) {
      if (!suppressEvents && !_didComplete) {
        _didComplete = true;
        _notifyComplete();
      }
    } else if (!suppressEvents) {
      _didComplete = false;
    }

    if (atReverseStart) {
      if (!suppressEvents && !_didReverseComplete && _started) {
        _didReverseComplete = true;
        _notifyReverseComplete();
      }
    } else if (!suppressEvents) {
      _didReverseComplete = false;
    }
  }

  /// Subclasses implement to apply values according to [progress] in `[0, 1]`.
  void renderProgress(double progress);

  /// Destroys the animation.
  void kill() {
    _killed = true;
    _paused = true;
    _stoppedAtBoundary = true;
    final pending = _completer;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }

  /// Resets cached values.
  void invalidate() {
    _started = false;
  }

  void _notifyComplete() {
    onComplete?.call();
    final pending = _completer;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }

  void _notifyReverseComplete() {
    onReverseComplete?.call();
  }

  /// Makes the animation awaitable: `await supreme.to(...)`.
  Future<void> then(FutureOr<void> Function(void) onValue) {
    _completer ??= Completer<void>();
    final td = totalDuration();
    if (!_completer!.isCompleted &&
        !isActive() &&
        td.isFinite &&
        totalTime >= td) {
      _completer!.complete();
    }
    return _completer!.future.then(onValue);
  }
}

/// Backward compatibility typedef for [SupremeAnimation].
@Deprecated('Use SupremeAnimation instead')
typedef GsapAnimation = SupremeAnimation;

/// Backward compatibility typedef for [SupremeEvent].
@Deprecated('Use SupremeEvent instead')
typedef GsapEvent = SupremeEvent;
