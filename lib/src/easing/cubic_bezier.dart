import 'ease.dart';

/// Implements cubic bezier easing identical to CSS cubic-bezier(x1, y1, x2, y2).
class CubicBezier extends Ease {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  CubicBezier(this.x1, this.y1, this.x2, this.y2)
      : assert(x1 >= 0.0 && x1 <= 1.0, 'x1 must be within [0.0, 1.0]'),
        assert(x2 >= 0.0 && x2 <= 1.0, 'x2 must be within [0.0, 1.0]'),
        super((t) => _solve(t, x1, y1, x2, y2));

  static double _sampleCurveX(double t, double x1, double x2) {
    // ((1 - 3*x2 + 3*x1)*t + (3*x2 - 6*x1))*t + 3*x1
    return (((1.0 - 3.0 * x2 + 3.0 * x1) * t + (3.0 * x2 - 6.0 * x1)) * t +
            3.0 * x1) *
        t;
  }

  static double _sampleCurveY(double t, double y1, double y2) {
    return (((1.0 - 3.0 * y2 + 3.0 * y1) * t + (3.0 * y2 - 6.0 * y1)) * t +
            3.0 * y1) *
        t;
  }

  static double _sampleCurveDerivativeX(double t, double x1, double x2) {
    return (3.0 * (1.0 - 3.0 * x2 + 3.0 * x1) * t +
                2.0 * (3.0 * x2 - 6.0 * x1)) *
            t +
        3.0 * x1;
  }

  static double _solve(double x, double x1, double y1, double x2, double y2) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;

    // Newton-Raphson iteration
    double t = x;
    for (int i = 0; i < 8; i++) {
      final currentX = _sampleCurveX(t, x1, x2) - x;
      if (currentX.abs() < 1e-6) {
        return _sampleCurveY(t, y1, y2);
      }
      final currentSlope = _sampleCurveDerivativeX(t, x1, x2);
      if (currentSlope.abs() < 1e-6) break;
      t -= currentX / currentSlope;
    }

    // Fallback: Bisection method
    double t0 = 0.0;
    double t1 = 1.0;
    t = x;

    for (int i = 0; i < 52 && t0 < t1; i++) {
      final currentX = _sampleCurveX(t, x1, x2);
      if ((currentX - x).abs() < 1e-6) {
        return _sampleCurveY(t, y1, y2);
      }
      if (x > currentX) {
        t0 = t;
      } else {
        t1 = t;
      }
      final next = (t1 + t0) * 0.5;
      if (next == t) break;
      t = next;
    }

    return _sampleCurveY(t, y1, y2);
  }
}
