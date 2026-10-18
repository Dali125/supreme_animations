import 'animation.dart';
import 'timeline.dart';

/// Context for scoping and automatically recording tweens/timelines.
/// Essential for clean Flutter state lifecycle cleanup.
///
/// The context only holds live animations strongly. Animations that have
/// finished (parked at their end, or at their start when reversed), and
/// animations that were placed inside another timeline, are moved to a weak
/// list: if your code still holds one, for example to `restart()` it
/// later, [revert] still kills it; if nothing else references it, it can be
/// garbage collected. Killed animations are dropped. This keeps a long-lived
/// context, such as the one in `SupremeStateMixin`, from growing with every
/// tween it ever created.
class SupremeContext {
  final List<SupremeAnimation> _animations = [];
  final List<WeakReference<SupremeAnimation>> _finished = [];
  final List<void Function()> _cleanups = [];
  bool _reverted = false;
  int _nextSweepAt = _minSweepThreshold;

  static const int _minSweepThreshold = 16;

  bool get isReverted => _reverted;

  /// Number of animations held strongly (live or not yet played).
  int get trackedCount => _animations.length;

  /// Number of finished animations still referenced weakly.
  int get finishedCount => _finished.length;

  /// Registers an animation in this context.
  void add(SupremeAnimation anim) {
    if (_reverted) {
      anim.kill();
      return;
    }
    _animations.add(anim);
    if (_animations.length >= _nextSweepAt) {
      sweep();
    }
  }

  /// Finished, or placed inside another timeline (which then owns it and
  /// keeps it alive for as long as it needs it).
  static bool _canHoldWeakly(SupremeAnimation a) {
    final parent = a.parent;
    if (parent is SupremeTimeline && parent is! SupremeRootTimeline) {
      return true;
    }
    return a.stoppedAtBoundary && !a.isActive();
  }

  /// Drops killed animations and moves finished ones to the weak list.
  /// Called automatically as animations are added; safe to call any time.
  void sweep() {
    _finished.removeWhere((ref) {
      final a = ref.target;
      return a == null || a.isKilled();
    });
    final live = <SupremeAnimation>[];
    for (final a in _animations) {
      if (a.isKilled()) continue;
      if (_canHoldWeakly(a)) {
        _finished.add(WeakReference(a));
      } else {
        live.add(a);
      }
    }
    _animations
      ..clear()
      ..addAll(live);
    // Amortise: sweep again once the live list has doubled.
    final size = _animations.length;
    _nextSweepAt =
        size * 2 > _minSweepThreshold ? size * 2 : _minSweepThreshold;
  }

  /// Adds a custom cleanup callback.
  void addCleanup(void Function() cleanup) {
    _cleanups.add(cleanup);
  }

  /// Reverts and kills all animations and executes cleanups recorded in this context.
  void revert() {
    if (_reverted) return;
    _reverted = true;
    for (final anim in _animations) {
      anim.kill();
    }
    _animations.clear();
    for (final ref in _finished) {
      ref.target?.kill();
    }
    _finished.clear();

    for (final cleanup in _cleanups) {
      cleanup();
    }
    _cleanups.clear();
  }

  /// Runs [fn] within this context, auto-capturing all created animations.
  T run<T>(T Function(SupremeContext ctx) fn) {
    final prev = SupremeContextScope.current;
    SupremeContextScope._current = this;
    try {
      return fn(this);
    } finally {
      SupremeContextScope._current = prev;
    }
  }
}

class SupremeContextScope {
  static SupremeContext? _current;
  static SupremeContext? get current => _current;
}

/// Backward compatibility typedef for [SupremeContext].
@Deprecated('Use SupremeContext instead')
typedef GsapContext = SupremeContext;

/// Backward compatibility typedef for [SupremeContextScope].
@Deprecated('Use SupremeContextScope instead')
typedef GsapContextScope = SupremeContextScope;
