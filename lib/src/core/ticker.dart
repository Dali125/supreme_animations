import 'package:flutter/scheduler.dart';

typedef TickerCallback = void Function(double deltaSeconds, double totalTime);

/// High-precision ticker loop in Supreme Animations.
/// Automatically integrates with Flutter's [SchedulerBinding] during runtime
/// while supporting simulated / stepped ticks for testing or headless environments.
class SupremeTicker {
  static final SupremeTicker instance = SupremeTicker._();
  SupremeTicker._();

  final List<TickerCallback> _listeners = [];
  bool _active = false;
  Ticker? _flutterTicker;

  double _time = 0.0;
  int _frame = 0;
  double _fps = 0.0;
  int? _targetFps;

  // Lag smoothing
  int _lagThresholdMs = 500;
  int _lagAdjustedMs = 33;
  bool _lagSmoothingEnabled = true;

  DateTime _lastWallClock = DateTime.now();

  /// Total elapsed time in seconds.
  double get time => _time;

  /// Total frames processed.
  int get frame => _frame;

  /// Current measured FPS.
  double get fps => _fps;

  /// Listeners currently registered, including the global timeline driver.
  int get listenerCount => _listeners.length;

  /// Target FPS limit if throttled.
  int? get targetFps => _targetFps;

  /// Whether the ticker is currently running.
  bool get isActive => _active;

  /// Add a listener to be called every tick.
  void add(TickerCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Remove a ticker listener.
  void remove(TickerCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty && _active) {
      sleep();
    }
  }

  /// Lock or throttle the frame rate. Pass `null` or 0 for uncapped (screen refresh rate).
  void setFps(int? target) {
    _targetFps = (target != null && target > 0) ? target : null;
  }

  /// Configures lag smoothing to prevent animation jumps when frames are dropped.
  void lagSmoothing([int thresholdMs = 500, int adjustedLagMs = 33]) {
    if (thresholdMs <= 0) {
      _lagSmoothingEnabled = false;
    } else {
      _lagSmoothingEnabled = true;
      _lagThresholdMs = thresholdMs;
      _lagAdjustedMs = adjustedLagMs;
    }
  }

  Duration _lastElapsed = Duration.zero;
  double _pendingSeconds = 0.0;

  /// Starts the ticker.
  void wake() {
    if (_active) return;
    _active = true;
    _lastElapsed = Duration.zero;
    _lastWallClock = DateTime.now();

    try {
      _flutterTicker = Ticker(_onFlutterTick);
      _flutterTicker?.start();
    } catch (_) {
      // In non-Flutter test or CLI mode where SchedulerBinding is not initialized,
      // manual ticks can be driven with [tick].
    }
  }

  /// Stops the ticker.
  void sleep() {
    _active = false;
    _flutterTicker?.stop();
    _flutterTicker?.dispose();
    _flutterTicker = null;
    _lastElapsed = Duration.zero;
    _pendingSeconds = 0.0;
  }

  void _onFlutterTick(Duration elapsed) {
    if (!_active) return;

    final deltaUs = _lastElapsed == Duration.zero
        ? elapsed.inMicroseconds
        : elapsed.inMicroseconds - _lastElapsed.inMicroseconds;
    _lastElapsed = elapsed;

    var deltaMs = deltaUs / 1000.0;
    if (deltaMs <= 0) {
      final now = DateTime.now();
      deltaMs = now.difference(_lastWallClock).inMicroseconds / 1000.0;
    }
    _lastWallClock = DateTime.now();

    if (_lagSmoothingEnabled && deltaMs > _lagThresholdMs) {
      deltaMs = _lagAdjustedMs.toDouble();
    }

    // Keep skipped frame time. Dropping it makes an FPS cap play in slow motion,
    // because the next callback only sees the latest vsync gap.
    _pendingSeconds += deltaMs > 0 ? deltaMs / 1000.0 : 0.0;

    if (_targetFps != null) {
      final minInterval = 1.0 / _targetFps!;
      if (_pendingSeconds + 1e-9 < minInterval) return;
    }

    final step = _pendingSeconds;
    _pendingSeconds = 0.0;
    tick(step > 0 ? step : 0.016666);
  }

  /// Manually advances the ticker by [deltaSeconds].
  /// Extremely useful for unit tests, time-scrubbing, and offline rendering.
  void tick(double deltaSeconds) {
    _frame++;
    _time += deltaSeconds;
    if (deltaSeconds > 0) {
      _fps = (_fps * 0.9) + ((1.0 / deltaSeconds) * 0.1);
    }

    final list = List<TickerCallback>.from(_listeners);
    for (final callback in list) {
      callback(deltaSeconds, _time);
    }
  }

  /// Reset internal clock and counters.
  void reset() {
    _time = 0.0;
    _frame = 0;
    _fps = 0.0;
  }
}

/// Backward compatibility typedef for [SupremeTicker].
@Deprecated('Use SupremeTicker instead')
typedef GsapTicker = SupremeTicker;
