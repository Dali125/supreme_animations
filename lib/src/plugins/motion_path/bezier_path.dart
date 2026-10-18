import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Represents a point and tangent angle on a 2D path.
class PathSample {
  final Offset position;
  final double angle; // Radians

  const PathSample({
    required this.position,
    required this.angle,
  });
}

/// Abstract curve segment for MotionPath.
abstract class PathSegment {
  PathSample sample(double t);
  double get length;
}

/// Quadratic Bezier segment (p0, p1, p2).
class QuadraticBezierSegment implements PathSegment {
  final Offset p0, p1, p2;

  QuadraticBezierSegment(this.p0, this.p1, this.p2);

  @override
  PathSample sample(double t) {
    final u = 1.0 - t;
    final pos = p0 * (u * u) + p1 * (2.0 * u * t) + p2 * (t * t);

    // Derivative: 2*(1-t)*(p1-p0) + 2*t*(p2-p1)
    final d = (p1 - p0) * (2.0 * u) + (p2 - p1) * (2.0 * t);
    final angle = math.atan2(d.dy, d.dx);

    return PathSample(position: pos, angle: angle);
  }

  @override
  double get length {
    // Approximate length with 10 steps
    double len = 0.0;
    Offset prev = p0;
    for (int i = 1; i <= 10; i++) {
      final cur = sample(i / 10.0).position;
      len += (cur - prev).distance;
      prev = cur;
    }
    return len;
  }
}

/// Cubic Bezier segment (p0, p1, p2, p3).
class CubicBezierSegment implements PathSegment {
  final Offset p0, p1, p2, p3;

  CubicBezierSegment(this.p0, this.p1, this.p2, this.p3);

  @override
  PathSample sample(double t) {
    final u = 1.0 - t;
    final pos = p0 * (u * u * u) +
        p1 * (3.0 * u * u * t) +
        p2 * (3.0 * u * t * t) +
        p3 * (t * t * t);

    // Derivative: 3*(1-t)^2*(p1-p0) + 6*(1-t)*t*(p2-p1) + 3*t^2*(p3-p2)
    final d = (p1 - p0) * (3.0 * u * u) +
        (p2 - p1) * (6.0 * u * t) +
        (p3 - p2) * (3.0 * t * t);
    final angle = math.atan2(d.dy, d.dx);

    return PathSample(position: pos, angle: angle);
  }

  @override
  double get length {
    double len = 0.0;
    Offset prev = p0;
    for (int i = 1; i <= 16; i++) {
      final cur = sample(i / 16.0).position;
      len += (cur - prev).distance;
      prev = cur;
    }
    return len;
  }
}

/// Linear segment between two points.
class LineSegment implements PathSegment {
  final Offset p0, p1;

  LineSegment(this.p0, this.p1);

  @override
  PathSample sample(double t) {
    final pos = Offset.lerp(p0, p1, t) ?? p1;
    final d = p1 - p0;
    final angle = math.atan2(d.dy, d.dx);
    return PathSample(position: pos, angle: angle);
  }

  @override
  double get length => (p1 - p0).distance;
}
