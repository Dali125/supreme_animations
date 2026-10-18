import 'ease.dart';

/// Represents a segment in a bezier curve from (x0, y0) to (x1, y1) with controls (cx0, cy0) and (cx1, cy1).
class BezierSegment {
  final double x0, y0;
  final double cx0, cy0;
  final double cx1, cy1;
  final double x1, y1;

  BezierSegment(
    this.x0,
    this.y0,
    this.cx0,
    this.cy0,
    this.cx1,
    this.cy1,
    this.x1,
    this.y1,
  );

  double sampleY(double targetX) {
    // Solve for t where x(t) == targetX using binary search
    double low = 0.0;
    double high = 1.0;
    double t = 0.5;

    for (int i = 0; i < 16; i++) {
      final u = 1.0 - t;
      final currentX = u * u * u * x0 +
          3 * u * u * t * cx0 +
          3 * u * t * t * cx1 +
          t * t * t * x1;
      if ((currentX - targetX).abs() < 1e-5) break;
      if (currentX < targetX) {
        low = t;
      } else {
        high = t;
      }
      t = (low + high) * 0.5;
    }

    final u = 1.0 - t;
    return u * u * u * y0 +
        3 * u * u * t * cy0 +
        3 * u * t * t * cy1 +
        t * t * t * y1;
  }
}

/// Allows creating any custom easing curve from SVG path data or points,
/// matching GSAP's CustomEase plugin.
class CustomEase extends Ease {
  final String? id;
  final List<BezierSegment> segments;

  static final Map<String, CustomEase> _registry = {};

  CustomEase._(this.segments, {this.id})
      : super((double t) {
          if (t <= 0.0) return 0.0;
          if (t >= 1.0) return 1.0;
          for (final seg in segments) {
            if (t >= seg.x0 && t <= seg.x1) {
              return seg.sampleY(t);
            }
          }
          if (t < segments.first.x0) return segments.first.y0;
          return segments.last.y1;
        });

  /// Creates and registers a custom ease from SVG path data (e.g. "M0,0 C0.2,0.5 0.3,1 1,1").
  static CustomEase create(String id, String pathData) {
    final segments = _parsePathData(pathData);
    final ease = CustomEase._(segments, id: id);
    _registry[id] = ease;
    return ease;
  }

  /// Retrieves a registered CustomEase by id.
  static CustomEase? get(String id) => _registry[id];

  static List<BezierSegment> _parsePathData(String pathData) {
    // Separate letters from numbers, remove commas, normalize spaces
    final cleaned = pathData
        .replaceAllMapped(RegExp(r'([a-zA-Z])'), (m) => ' ${m[1]} ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final tokens = cleaned.split(' ');
    final segments = <BezierSegment>[];

    double currentX = 0.0;
    double currentY = 0.0;

    int i = 0;
    while (i < tokens.length) {
      final cmd = tokens[i].toUpperCase();
      if (cmd == 'M') {
        currentX = double.parse(tokens[i + 1]);
        currentY = double.parse(tokens[i + 2]);
        i += 3;
      } else if (cmd == 'C') {
        final cx0 = double.parse(tokens[i + 1]);
        final cy0 = double.parse(tokens[i + 2]);
        final cx1 = double.parse(tokens[i + 3]);
        final cy1 = double.parse(tokens[i + 4]);
        final x1 = double.parse(tokens[i + 5]);
        final y1 = double.parse(tokens[i + 6]);

        segments
            .add(BezierSegment(currentX, currentY, cx0, cy0, cx1, cy1, x1, y1));
        currentX = x1;
        currentY = y1;
        i += 7;
      } else if (cmd == 'L') {
        final x1 = double.parse(tokens[i + 1]);
        final y1 = double.parse(tokens[i + 2]);
        segments.add(BezierSegment(
          currentX,
          currentY,
          (currentX * 2 + x1) / 3,
          (currentY * 2 + y1) / 3,
          (currentX + x1 * 2) / 3,
          (currentY + y1 * 2) / 3,
          x1,
          y1,
        ));
        currentX = x1;
        currentY = y1;
        i += 3;
      } else {
        // If it's a number without command, treat as continuation of previous C
        if (double.tryParse(cmd) != null && i + 5 < tokens.length) {
          final cx0 = double.parse(tokens[i]);
          final cy0 = double.parse(tokens[i + 1]);
          final cx1 = double.parse(tokens[i + 2]);
          final cy1 = double.parse(tokens[i + 3]);
          final x1 = double.parse(tokens[i + 4]);
          final y1 = double.parse(tokens[i + 5]);
          segments.add(
              BezierSegment(currentX, currentY, cx0, cy0, cx1, cy1, x1, y1));
          currentX = x1;
          currentY = y1;
          i += 6;
        } else {
          i++;
        }
      }
    }

    if (segments.isEmpty) {
      segments.add(BezierSegment(0, 0, 0.33, 0.33, 0.66, 0.66, 1, 1));
    }

    return segments;
  }
}
