import 'package:flutter/widgets.dart';
import '../../core/animation.dart';
import '../../core/ticker.dart';

enum ToggleAction {
  play,
  pause,
  resume,
  reverse,
  restart,
  reset,
  complete,
  none,
}

class ToggleActions {
  final ToggleAction onEnter;
  final ToggleAction onLeave;
  final ToggleAction onEnterBack;
  final ToggleAction onLeaveBack;

  const ToggleActions({
    this.onEnter = ToggleAction.play,
    this.onLeave = ToggleAction.none,
    this.onEnterBack = ToggleAction.none,
    this.onLeaveBack = ToggleAction.none,
  });

  /// Parses string like "play pause resume reverse" or "play none none reverse".
  static ToggleActions fromString(String str) {
    final parts = str.trim().split(RegExp(r'\s+'));
    ToggleAction parse(String? s) {
      if (s == null) return ToggleAction.none;
      switch (s.toLowerCase()) {
        case 'play':
          return ToggleAction.play;
        case 'pause':
          return ToggleAction.pause;
        case 'resume':
          return ToggleAction.resume;
        case 'reverse':
          return ToggleAction.reverse;
        case 'restart':
          return ToggleAction.restart;
        case 'reset':
          return ToggleAction.reset;
        case 'complete':
          return ToggleAction.complete;
        default:
          return ToggleAction.none;
      }
    }

    return ToggleActions(
      onEnter: parts.isNotEmpty ? parse(parts[0]) : ToggleAction.play,
      onLeave: parts.length > 1 ? parse(parts[1]) : ToggleAction.none,
      onEnterBack: parts.length > 2 ? parse(parts[2]) : ToggleAction.none,
      onLeaveBack: parts.length > 3 ? parse(parts[3]) : ToggleAction.none,
    );
  }
}

typedef ScrollTriggerUpdateCallback = void Function(
    double progress, int direction);

/// Controls scroll-driven animations in Supreme Animations.
class ScrollTrigger {
  final SupremeAnimation? animation;
  final GlobalKey? triggerKey;
  final dynamic start; // e.g. "top bottom", "top center", 100.0
  final dynamic end; // e.g. "bottom top", "+=500", 600.0
  final dynamic
      scrub; // bool (true/false) or double (smooth lag duration in seconds)
  final bool pin;
  final ToggleActions toggleActions;
  final bool markers;

  // Callbacks
  final VoidCallback? onEnter;
  final VoidCallback? onLeave;
  final VoidCallback? onEnterBack;
  final VoidCallback? onLeaveBack;
  final ScrollTriggerUpdateCallback? onUpdate;

  // Internal state
  double _startPixels = 0.0;
  double _endPixels = 1000.0;
  double _progress = 0.0;
  double _targetProgress = 0.0;
  int _direction = 1; // 1 = forwards (down), -1 = backwards (up)
  bool _isActive = false;
  bool _hasEntered = false;
  bool _leftForward = false;
  bool _scrubDriving = false;
  TickerCallback? _scrubCallback;
  double _previousScrollPixels = 0.0;

  ScrollTrigger({
    this.animation,
    this.triggerKey,
    this.start = 'top bottom',
    this.end = 'bottom top',
    this.scrub = false,
    this.pin = false,
    dynamic toggleActions = 'play none none none',
    this.markers = false,
    this.onEnter,
    this.onLeave,
    this.onEnterBack,
    this.onLeaveBack,
    this.onUpdate,
  }) : toggleActions = (toggleActions is ToggleActions)
            ? toggleActions
            : (toggleActions is String
                ? ToggleActions.fromString(toggleActions)
                : const ToggleActions()) {
    if (animation != null) {
      animation!.pause();
    }
  }

  double get startPixels => _startPixels;
  double get endPixels => _endPixels;
  double get progress => _progress;
  int get direction => _direction;
  bool get isActive => _isActive;

  /// Distance the pinned element should be translated while the trigger is active.
  double get pinOffset {
    if (!pin) return 0.0;
    if (_previousScrollPixels <= _startPixels) return 0.0;
    if (_previousScrollPixels >= _endPixels) return _endPixels - _startPixels;
    return _previousScrollPixels - _startPixels;
  }

  /// Stops lag smoothing. Does not kill a caller-supplied animation.
  void kill() {
    _stopScrubDriver();
  }

  /// Recalculates start and end scroll offsets relative to viewport and trigger widget.
  void refresh({
    required double scrollPixels,
    required double viewportHeight,
  }) {
    if (triggerKey != null && triggerKey!.currentContext != null) {
      final renderBox =
          triggerKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final elementTop = scrollPixels + position.dy;
        final elementHeight = renderBox.size.height;

        _startPixels = _parseTriggerPoint(
            start, elementTop, elementHeight, viewportHeight);
        _endPixels = _parseEndPoint(
            end, elementTop, elementHeight, _startPixels, viewportHeight);
        return;
      }
    }

    // Fallback: absolute pixel boundaries
    if (start is num) {
      _startPixels = (start as num).toDouble();
    } else {
      _startPixels = 0.0;
    }

    if (end is num) {
      _endPixels = (end as num).toDouble();
    } else if (end is String && (end as String).startsWith('+=')) {
      final delta = double.tryParse((end as String).substring(2)) ?? 500.0;
      _endPixels = _startPixels + delta;
    } else {
      _endPixels = _startPixels + 500.0;
    }
  }

  double _parseTriggerPoint(
    dynamic triggerSpec,
    double elementTop,
    double elementHeight,
    double viewportHeight,
  ) {
    if (triggerSpec is num) return triggerSpec.toDouble();
    if (triggerSpec is! String) return elementTop;

    final parts = triggerSpec.trim().toLowerCase().split(RegExp(r'\s+'));
    final elementPos = parts.isNotEmpty ? parts[0] : 'top';
    final scrollerPos = parts.length > 1 ? parts[1] : 'bottom';
    final elemOffset = _elementOffset(elementPos, elementTop, elementHeight);
    final scrollerOffset =
        _scrollerOffset(scrollerPos, viewportHeight, viewportHeight);
    return elemOffset - scrollerOffset;
  }

  double _elementOffset(
      String elementPos, double elementTop, double elementHeight) {
    if (elementPos == 'center') return elementTop + elementHeight / 2.0;
    if (elementPos == 'bottom') return elementTop + elementHeight;
    if (elementPos.endsWith('%')) {
      final pct = double.tryParse(elementPos.replaceAll('%', '')) ?? 0.0;
      return elementTop + elementHeight * (pct / 100.0);
    }
    return elementTop;
  }

  double _scrollerOffset(
      String scrollerPos, double viewportHeight, double fallback) {
    if (scrollerPos == 'top') return 0.0;
    if (scrollerPos == 'bottom') return viewportHeight;
    if (scrollerPos == 'center') return viewportHeight / 2.0;
    if (scrollerPos.endsWith('%')) {
      final pct = double.tryParse(scrollerPos.replaceAll('%', '')) ?? 100.0;
      return viewportHeight * (pct / 100.0);
    }
    if (scrollerPos.endsWith('px')) {
      return double.tryParse(scrollerPos.replaceAll('px', '')) ?? fallback;
    }
    return fallback;
  }

  double _parseEndPoint(
    dynamic endSpec,
    double elementTop,
    double elementHeight,
    double startPx,
    double viewportHeight,
  ) {
    if (endSpec is num) return endSpec.toDouble();
    if (endSpec is! String) return startPx + elementHeight;

    final str = endSpec.trim().toLowerCase();
    if (str.startsWith('+=')) {
      final delta = double.tryParse(str.substring(2)) ?? 500.0;
      return startPx + delta;
    }

    final parts = str.split(RegExp(r'\s+'));
    final elementPos = parts.isNotEmpty ? parts[0] : 'bottom';
    final scrollerPos = parts.length > 1 ? parts[1] : 'top';
    final elemOffset = _elementOffset(elementPos, elementTop, elementHeight);
    final scrollerOffset = _scrollerOffset(scrollerPos, viewportHeight, 0.0);
    return elemOffset - scrollerOffset;
  }

  /// Updates scroll progress based on new scroll position.
  void update(double currentScrollPixels, {double deltaSeconds = 0.016}) {
    if (currentScrollPixels > _previousScrollPixels) {
      _direction = 1;
    } else if (currentScrollPixels < _previousScrollPixels) {
      _direction = -1;
    }
    _previousScrollPixels = currentScrollPixels;

    final range = _endPixels - _startPixels;
    if (range <= 0) return;

    final rawProgress =
        ((currentScrollPixels - _startPixels) / range).clamp(0.0, 1.0);
    _targetProgress = rawProgress;

    final isScrub = scrub == true || (scrub is num && (scrub as num) >= 0);
    final smoothScrub = scrub is num && (scrub as num) > 0;
    if (isScrub) {
      if (smoothScrub) {
        // Scroll events stop when the finger lifts. A ticker finishes the lag
        // so `scrub: 1` actually takes a second to catch the playhead.
        _ensureScrubDriver();
      } else {
        _progress = _targetProgress;
        _stopScrubDriver();
        animation?.pause();
        animation?.progress(_progress);
      }
    } else {
      _progress = _targetProgress;
    }

    final wasActive = _isActive;
    _isActive = currentScrollPixels >= _startPixels &&
        currentScrollPixels <= _endPixels;

    if (!_hasEntered &&
        currentScrollPixels >= _startPixels &&
        _direction == 1) {
      _hasEntered = true;
      onEnter?.call();
      if (!isScrub) _executeAction(toggleActions.onEnter);
    }

    if (_hasEntered &&
        !_leftForward &&
        currentScrollPixels > _endPixels &&
        _direction == 1) {
      _leftForward = true;
      onLeave?.call();
      if (!isScrub) _executeAction(toggleActions.onLeave);
    }
    if (currentScrollPixels <= _endPixels) {
      _leftForward = false;
    }

    if (_hasEntered && !wasActive && _isActive && _direction == -1) {
      onEnterBack?.call();
      if (!isScrub) _executeAction(toggleActions.onEnterBack);
    }

    if (_hasEntered && currentScrollPixels < _startPixels && _direction == -1) {
      _hasEntered = false;
      onLeaveBack?.call();
      if (!isScrub) _executeAction(toggleActions.onLeaveBack);
    }

    if (!smoothScrub) {
      onUpdate?.call(_progress, _direction);
    }
  }

  void _ensureScrubDriver() {
    if (_scrubDriving) return;
    _scrubDriving = true;
    _scrubCallback ??= _onScrubTick;
    SupremeTicker.instance.add(_scrubCallback!);
    SupremeTicker.instance.wake();
  }

  void _stopScrubDriver() {
    if (!_scrubDriving) return;
    _scrubDriving = false;
    final callback = _scrubCallback;
    if (callback != null) {
      SupremeTicker.instance.remove(callback);
    }
  }

  void _onScrubTick(double deltaSeconds, double totalTime) {
    final duration = scrub is num ? (scrub as num).toDouble() : 0.0;
    if (duration <= 0) {
      _progress = _targetProgress;
    } else {
      final factor = (deltaSeconds / duration).clamp(0.0, 1.0);
      _progress += (_targetProgress - _progress) * factor;
      if ((_targetProgress - _progress).abs() < 0.0005) {
        _progress = _targetProgress;
      }
    }

    animation?.pause();
    animation?.progress(_progress);
    onUpdate?.call(_progress, _direction);

    if (_progress == _targetProgress) {
      _stopScrubDriver();
    }
  }

  void _executeAction(ToggleAction action) {
    if (animation == null) return;
    switch (action) {
      case ToggleAction.play:
        animation!.play();
        break;
      case ToggleAction.pause:
        animation!.pause();
        break;
      case ToggleAction.resume:
        animation!.resume();
        break;
      case ToggleAction.reverse:
        animation!.reverse();
        break;
      case ToggleAction.restart:
        animation!.restart();
        break;
      case ToggleAction.reset:
        animation!.seek(0.0);
        animation!.pause();
        break;
      case ToggleAction.complete:
        animation!.seek(animation!.totalDuration());
        animation!.pause();
        break;
      case ToggleAction.none:
        break;
    }
  }
}
