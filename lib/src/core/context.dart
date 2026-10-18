import 'animation.dart';

/// Context for scoping and automatically recording tweens/timelines.
/// Essential for clean Flutter state lifecycle cleanup.
class SupremeContext {
  final List<SupremeAnimation> _animations = [];
  final List<void Function()> _cleanups = [];
  bool _reverted = false;

  bool get isReverted => _reverted;

  /// Registers an animation in this context.
  void add(SupremeAnimation anim) {
    if (_reverted) {
      anim.kill();
      return;
    }
    _animations.add(anim);
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
