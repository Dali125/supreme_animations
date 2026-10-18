typedef ModifierFunction<T> = T Function(T value);

/// Utility functions for value modification in Supreme Animations.
class SupremeModifiers {
  /// Snaps a numeric value to the nearest [step].
  static ModifierFunction<double> snap(double step) {
    assert(step > 0, 'Snap step must be positive');
    return (double val) => (val / step).round() * step;
  }

  /// Clamps a numeric value between [min] and [max].
  static ModifierFunction<double> clamp(double min, double max) {
    return (double val) => val.clamp(min, max);
  }

  /// Wraps a numeric value within the range [[min], [max]).
  static ModifierFunction<double> wrap(double min, double max) {
    final range = max - min;
    return (double val) {
      if (range == 0) return min;
      var result = (val - min) % range;
      if (result < 0) result += range;
      return min + result;
    };
  }

  /// Pipes multiple modifiers in sequence.
  static ModifierFunction<T> pipe<T>(List<ModifierFunction<T>> funcs) {
    return (T initial) {
      T current = initial;
      for (final f in funcs) {
        current = f(current);
      }
      return current;
    };
  }
}

/// Backward compatibility typedef for [SupremeModifiers].
@Deprecated('Use SupremeModifiers instead')
typedef GsapModifiers = SupremeModifiers;
