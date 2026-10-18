import 'dart:math' as math;
import 'ease.dart';

enum RoughTaper { none, start, end, both }

/// Generates a rough/jittery easing curve (flicker, earthquake, electricity, heartbeats),
/// matching GSAP's RoughEase plugin.
class RoughEase extends Ease {
  final int points;
  final double strength;
  final bool clamp;
  final Ease template;
  final RoughTaper taper;
  final bool randomize;

  RoughEase({
    this.points = 20,
    this.strength = 1.0,
    this.clamp = false,
    this.template = Ease.linear,
    this.taper = RoughTaper.none,
    this.randomize = true,
    int seed = 12345,
  }) : super(_buildFunction(
            points, strength, clamp, template, taper, randomize, seed));

  static EaseFunction _buildFunction(
    int points,
    double strength,
    bool clamp,
    Ease template,
    RoughTaper taper,
    bool randomize,
    int seed,
  ) {
    final rand = math.Random(seed);
    final offsets = List<double>.generate(points, (index) {
      if (randomize) {
        return (rand.nextDouble() * 2.0 - 1.0) * strength * 0.1;
      } else {
        return (index % 2 == 0 ? 1.0 : -1.0) * strength * 0.1;
      }
    });

    return (double t) {
      if (t <= 0.0) return 0.0;
      if (t >= 1.0) return 1.0;

      final base = template(t);
      final idx = ((t * points).floor()).clamp(0, points - 1);
      double jitter = offsets[idx];

      // Apply tapering
      switch (taper) {
        case RoughTaper.start:
          jitter *= t;
          break;
        case RoughTaper.end:
          jitter *= (1.0 - t);
          break;
        case RoughTaper.both:
          jitter *= math.sin(t * math.pi);
          break;
        case RoughTaper.none:
          break;
      }

      double result = base + jitter;
      if (clamp) {
        result = result.clamp(0.0, 1.0);
      }
      return result;
    };
  }
}
