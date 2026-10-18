import 'dart:math' as math;
import 'ease.dart';

/// SlowMo ease matches GSAP's SlowMo ease, providing slow-motion in the middle
/// with an optional yoyo effect.
class SlowMo extends Ease {
  final double linearRatio;
  final double power;
  final bool yoyo;

  SlowMo({
    this.linearRatio = 0.7,
    this.power = 0.7,
    this.yoyo = false,
  }) : super(_buildFunction(linearRatio, power, yoyo));

  static double _core(double t, double linearRatio, double power) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;

    final b = (1.0 - linearRatio) / 2.0;
    if (b <= 1e-8) return t;

    final double val;
    if (t < b) {
      val = (t / b) * linearRatio;
    } else if (t > 1.0 - b) {
      val = linearRatio + ((t - (1.0 - b)) / b) * (1.0 - linearRatio);
    } else {
      val = linearRatio;
    }

    final easePart = math.sin((val - 0.5) * math.pi) * 0.5 + 0.5;
    return t + (easePart - t) * power;
  }

  static EaseFunction _buildFunction(
      double linearRatio, double power, bool yoyo) {
    final lr = linearRatio.clamp(0.0, 1.0);
    final p = power.clamp(0.0, 1.0);

    return (double t) {
      if (!yoyo) return _core(t, lr, p);
      if (t <= 0.0 || t >= 1.0) return 0.0;
      final mapped = t <= 0.5 ? t * 2.0 : (1.0 - t) * 2.0;
      return _core(mapped, lr, p);
    };
  }
}
