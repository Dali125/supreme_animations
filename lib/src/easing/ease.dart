import 'dart:math' as math;

/// Function signature for an easing curve: takes a progress [t] in range `[0, 1]`
/// and returns the eased value.
typedef EaseFunction = double Function(double t);

/// Represents a configurable ease curve, compatible with Flutter's [Curve].
class Ease {
  final EaseFunction transform;

  const Ease(this.transform);

  double call(double t) => transform(t);

  // Linear / None
  static const Ease linear = Ease(_linear);
  static const Ease none = Ease(_linear);
  static double _linear(double t) => t;

  // Power 1 (Quadratic)
  static const Power1Ease power1 = Power1Ease();
  // Power 2 (Cubic)
  static const Power2Ease power2 = Power2Ease();
  // Power 3 (Quartic)
  static const Power3Ease power3 = Power3Ease();
  // Power 4 (Quintic)
  static const Power4Ease power4 = Power4Ease();

  // Sine
  static const SineEase sine = SineEase();
  // Expo
  static const ExpoEase expo = ExpoEase();
  // Circ
  static const CircEase circ = CircEase();

  // Back
  static const BackEase back = BackEase();
  // Elastic
  static const ElasticEase elastic = ElasticEase();
  // Bounce
  static const BounceEase bounce = BounceEase();

  // Stepped ease
  static Ease steps(int count, {bool jumpStart = false}) {
    assert(count > 0, 'Step count must be positive');
    return Ease((double t) {
      if (t <= 0.0) return 0.0;
      if (t >= 1.0) return 1.0;
      final step = jumpStart ? (t * count).floor() + 1 : (t * count).floor();
      return (step / count).clamp(0.0, 1.0);
    });
  }

  /// Parses an ease string like "power2.out", "back.out(1.7)", "elastic.out(1, 0.3)", "linear".
  static Ease fromString(String name) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed == 'none' || trimmed == 'linear') return linear;

    if (trimmed.startsWith('power1')) return _parsePower(power1, trimmed);
    if (trimmed.startsWith('power2')) return _parsePower(power2, trimmed);
    if (trimmed.startsWith('power3')) return _parsePower(power3, trimmed);
    if (trimmed.startsWith('power4')) return _parsePower(power4, trimmed);
    if (trimmed.startsWith('sine')) return _parseStandard(sine, trimmed);
    if (trimmed.startsWith('expo')) return _parseStandard(expo, trimmed);
    if (trimmed.startsWith('circ')) return _parseStandard(circ, trimmed);
    if (trimmed.startsWith('bounce')) return _parseStandard(bounce, trimmed);

    if (trimmed.startsWith('back')) {
      final args = _extractArgs(trimmed);
      final overshoot = args.isNotEmpty ? double.tryParse(args[0]) : null;
      if (trimmed.contains('.inout')) return back.customInOut(overshoot);
      if (trimmed.contains('.in')) return back.customIn(overshoot);
      return back.customOut(overshoot);
    }

    if (trimmed.startsWith('elastic')) {
      final args = _extractArgs(trimmed);
      final a = args.isNotEmpty ? double.tryParse(args[0]) : null;
      final p = args.length > 1 ? double.tryParse(args[1]) : null;
      if (trimmed.contains('.inout')) {
        return elastic.customInOut(amplitude: a, period: p);
      }
      if (trimmed.contains('.in')) {
        return elastic.customIn(amplitude: a, period: p);
      }
      return elastic.customOut(amplitude: a, period: p);
    }

    if (trimmed.startsWith('steps')) {
      final args = _extractArgs(trimmed);
      final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 10 : 10;
      return steps(count);
    }

    return power1.out;
  }

  static List<String> _extractArgs(String str) {
    final openParen = str.indexOf('(');
    final closeParen = str.lastIndexOf(')');
    if (openParen != -1 && closeParen != -1 && closeParen > openParen) {
      final argSub = str.substring(openParen + 1, closeParen);
      return argSub.split(',').map((e) => e.trim()).toList();
    }
    return const [];
  }

  static Ease _parsePower(dynamic powerEase, String str) {
    if (str.endsWith('.inout')) return powerEase.inOut;
    if (str.endsWith('.in')) return powerEase.easeIn;
    return powerEase.out;
  }

  static Ease _parseStandard(dynamic stdEase, String str) {
    if (str.endsWith('.inout')) return stdEase.inOut;
    if (str.endsWith('.in')) return stdEase.easeIn;
    return stdEase.out;
  }
}

/// Power1 (quadratic) easing family.
class Power1Ease {
  const Power1Ease();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) => t * t;
  static double _out(double t) => t * (2 - t);
  static double _inOut(double t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}

/// Power2 (cubic) easing family.
class Power2Ease {
  const Power2Ease();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) => t * t * t;
  static double _out(double t) {
    final d = t - 1;
    return d * d * d + 1;
  }

  static double _inOut(double t) =>
      t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
}

/// Power3 (quartic) easing family.
class Power3Ease {
  const Power3Ease();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) => t * t * t * t;
  static double _out(double t) {
    final d = t - 1;
    return 1 - d * d * d * d;
  }

  static double _inOut(double t) =>
      t < 0.5 ? 8 * t * t * t * t : 1 - 8 * math.pow(t - 1, 4).toDouble();
}

/// Power4 (quintic) easing family.
class Power4Ease {
  const Power4Ease();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) => t * t * t * t * t;
  static double _out(double t) {
    final d = t - 1;
    return 1 + d * d * d * d * d;
  }

  static double _inOut(double t) => t < 0.5
      ? 16 * math.pow(t, 5).toDouble()
      : 1 + 16 * math.pow(t - 1, 5).toDouble();
}

/// Sine easing family.
class SineEase {
  const SineEase();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) => 1 - math.cos((t * math.pi) / 2);
  static double _out(double t) => math.sin((t * math.pi) / 2);
  static double _inOut(double t) => -(math.cos(math.pi * t) - 1) / 2;
}

/// Exponential easing family.
class ExpoEase {
  const ExpoEase();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) =>
      t == 0 ? 0 : math.pow(2, 10 * (t - 1)).toDouble();
  static double _out(double t) =>
      t == 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble();
  static double _inOut(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    if (t < 0.5) return math.pow(2, 20 * t - 10).toDouble() / 2;
    return (2 - math.pow(2, -20 * t + 10).toDouble()) / 2;
  }
}

/// Circular easing family.
class CircEase {
  const CircEase();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _in(double t) => 1 - math.sqrt(1 - math.pow(t, 2).toDouble());
  static double _out(double t) => math.sqrt(1 - math.pow(t - 1, 2).toDouble());
  static double _inOut(double t) => t < 0.5
      ? (1 - math.sqrt(1 - math.pow(2 * t, 2).toDouble())) / 2
      : (math.sqrt(1 - math.pow(-2 * t + 2, 2).toDouble()) + 1) / 2;
}

/// Back overshoot easing family.
class BackEase {
  static const double defaultOvershoot = 1.70158;
  const BackEase();

  Ease get easeIn => const Ease(_defaultIn);
  Ease get out => const Ease(_defaultOut);
  Ease get inOut => const Ease(_defaultInOut);

  Ease customIn([double? overshoot]) {
    final s = overshoot ?? defaultOvershoot;
    return Ease((t) => t * t * ((s + 1) * t - s));
  }

  Ease customOut([double? overshoot]) {
    final s = overshoot ?? defaultOvershoot;
    return Ease((t) {
      final d = t - 1;
      return d * d * ((s + 1) * d + s) + 1;
    });
  }

  Ease customInOut([double? overshoot]) {
    final s = (overshoot ?? defaultOvershoot) * 1.525;
    return Ease((t) {
      if (t < 0.5) {
        return (math.pow(2 * t, 2) * ((s + 1) * 2 * t - s)) / 2;
      }
      final d = 2 * t - 2;
      return (math.pow(d, 2) * ((s + 1) * d + s) + 2) / 2;
    });
  }

  Ease call([double? overshoot]) => customOut(overshoot);

  static double _defaultIn(double t) =>
      t * t * ((defaultOvershoot + 1) * t - defaultOvershoot);
  static double _defaultOut(double t) {
    final d = t - 1;
    return d * d * ((defaultOvershoot + 1) * d + defaultOvershoot) + 1;
  }

  static double _defaultInOut(double t) {
    final s = defaultOvershoot * 1.525;
    if (t < 0.5) {
      return (math.pow(2 * t, 2) * ((s + 1) * 2 * t - s)) / 2;
    }
    final d = 2 * t - 2;
    return (math.pow(d, 2) * ((s + 1) * d + s) + 2) / 2;
  }
}

class ElasticEase {
  static const double defaultAmplitude = 1.0;
  static const double defaultPeriod = 0.3;
  const ElasticEase();

  Ease get easeIn => const Ease(_defaultIn);
  Ease get out => const Ease(_defaultOut);
  Ease get inOut => const Ease(_defaultInOut);

  Ease customIn({double? amplitude, double? period}) {
    final a = _safeAmplitude(amplitude);
    final p = _safePeriod(period, defaultPeriod);
    return Ease((t) {
      if (t == 0) return 0;
      if (t == 1) return 1;
      final s = p / (2 * math.pi) * math.asin(1 / a);
      final d = t - 1;
      return -(a * math.pow(2, 10 * d) * math.sin((d - s) * (2 * math.pi) / p));
    });
  }

  Ease customOut({double? amplitude, double? period}) {
    final a = _safeAmplitude(amplitude);
    final p = _safePeriod(period, defaultPeriod);
    return Ease((t) {
      if (t == 0) return 0;
      if (t == 1) return 1;
      final s = p / (2 * math.pi) * math.asin(1 / a);
      return a * math.pow(2, -10 * t) * math.sin((t - s) * (2 * math.pi) / p) +
          1;
    });
  }

  Ease customInOut({double? amplitude, double? period}) {
    final a = _safeAmplitude(amplitude);
    final p = _safePeriod(period, defaultPeriod * 1.5);
    return Ease((t) {
      if (t == 0) return 0;
      if (t == 1) return 1;
      final s = p / (2 * math.pi) * math.asin(1 / a);
      if (t < 0.5) {
        final d = 2 * t - 1;
        return -0.5 *
            (a * math.pow(2, 10 * d) * math.sin((d - s) * (2 * math.pi) / p));
      }
      final d = 2 * t - 1;
      return a *
              math.pow(2, -10 * d) *
              math.sin((d - s) * (2 * math.pi) / p) *
              0.5 +
          1;
    });
  }

  static double _safeAmplitude(double? amplitude) {
    final a = (amplitude ?? defaultAmplitude).abs();
    return a < 1.0 ? 1.0 : a;
  }

  static double _safePeriod(double? period, double fallback) {
    if (period == null || period == 0) return fallback;
    final value = period.abs();
    return value == 0 ? fallback : value;
  }

  static double _defaultIn(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    return -(math.pow(2, 10 * (t - 1)) *
        math.sin(
            (t - 1 - (defaultPeriod / 4)) * (2 * math.pi) / defaultPeriod));
  }

  static double _defaultOut(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    return math.pow(2, -10 * t) *
            math.sin(
                (t - (defaultPeriod / 4)) * (2 * math.pi) / defaultPeriod) +
        1;
  }

  static double _defaultInOut(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    final p = defaultPeriod * 1.5;
    if (t < 0.5) {
      return -0.5 *
          (math.pow(2, 20 * t - 10) *
              math.sin((20 * t - 11.125) * (2 * math.pi) / p));
    }
    return math.pow(2, -20 * t + 10) *
            math.sin((20 * t - 11.125) * (2 * math.pi) / p) *
            0.5 +
        1;
  }
}

class BounceEase {
  const BounceEase();
  Ease get easeIn => const Ease(_in);
  Ease get out => const Ease(_out);
  Ease get inOut => const Ease(_inOut);

  static double _out(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      final t2 = t - (1.5 / d1);
      return n1 * t2 * t2 + 0.75;
    } else if (t < 2.5 / d1) {
      final t2 = t - (2.25 / d1);
      return n1 * t2 * t2 + 0.9375;
    } else {
      final t2 = t - (2.625 / d1);
      return n1 * t2 * t2 + 0.984375;
    }
  }

  static double _in(double t) => 1 - _out(1 - t);

  static double _inOut(double t) =>
      t < 0.5 ? (1 - _out(1 - 2 * t)) / 2 : (1 + _out(2 * t - 1)) / 2;
}
