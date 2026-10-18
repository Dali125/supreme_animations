import 'dart:ui' show Offset, Path;
import 'package:flutter/foundation.dart';
import '../../core/supreme_core.dart';
import '../../core/tween.dart';
import '../../easing/ease.dart';
import '../../widgets/transform_props.dart';
import 'bezier_path.dart';

/// Compound 2D motion path curve supporting piecewise Bezier segments.
class MotionPath {
  final List<PathSegment> segments;
  final List<Offset>? waypoints;
  late final double totalLength;
  late final List<double> _segmentOffsets;

  MotionPath(this.segments, {this.waypoints}) {
    double acc = 0.0;
    _segmentOffsets = [];
    for (final seg in segments) {
      _segmentOffsets.add(acc);
      acc += seg.length;
    }
    totalLength = acc > 0 ? acc : 1.0;
  }

  /// Factory for a single cubic bezier segment.
  factory MotionPath.cubic(Offset p0, Offset p1, Offset p2, Offset p3) {
    return MotionPath([CubicBezierSegment(p0, p1, p2, p3)],
        waypoints: [p0, p3]);
  }

  /// Factory for a single quadratic bezier segment.
  factory MotionPath.quadratic(Offset p0, Offset p1, Offset p2) {
    return MotionPath([QuadraticBezierSegment(p0, p1, p2)],
        waypoints: [p0, p2]);
  }

  /// Factory for a polygonal linear path connecting points.
  factory MotionPath.polygon(List<Offset> points) {
    assert(points.length >= 2, 'Polygon path requires at least 2 points');
    final segs = <PathSegment>[];
    for (int i = 0; i < points.length - 1; i++) {
      segs.add(LineSegment(points[i], points[i + 1]));
    }
    return MotionPath(segs, waypoints: points);
  }

  /// Creates a smooth curved spline through a sequence of waypoints.
  factory MotionPath.curved(List<Offset> points, {double curvature = 0.25}) {
    if (points.isEmpty) {
      return MotionPath([LineSegment(Offset.zero, Offset.zero)],
          waypoints: points);
    }
    if (points.length == 1) {
      return MotionPath([LineSegment(points[0], points[0])], waypoints: points);
    }
    if (points.length == 2) {
      return MotionPath([LineSegment(points[0], points[1])], waypoints: points);
    }

    final segs = <PathSegment>[];
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p3 = points[i + 1];

      // Estimate tangent handles
      final prev = i > 0 ? points[i - 1] : p0;
      final next = i + 2 < points.length ? points[i + 2] : p3;

      final p1 = p0 + (p3 - prev) * curvature;
      final p2 = p3 - (next - p0) * curvature;

      segs.add(CubicBezierSegment(p0, p1, p2, p3));
    }
    return MotionPath(segs, waypoints: points);
  }

  /// Samples position and tangent angle at progress [t] in `[0, 1]`.
  PathSample sample(double t) {
    if (segments.isEmpty) {
      return const PathSample(position: Offset.zero, angle: 0.0);
    }

    final clampedT = t.clamp(0.0, 1.0);
    final targetDist = clampedT * totalLength;

    for (int i = 0; i < segments.length; i++) {
      final segStart = _segmentOffsets[i];
      final segLen = segments[i].length;
      final segEnd = segStart + segLen;

      if (targetDist <= segEnd || i == segments.length - 1) {
        final localT = segLen > 0
            ? ((targetDist - segStart) / segLen).clamp(0.0, 1.0)
            : 0.0;
        return segments[i].sample(localT);
      }
    }

    return segments.last.sample(1.0);
  }

  /// Converts this MotionPath into a Flutter [Path] for rendering in CustomPainter or Canvas.
  Path toPath() {
    final path = Path();
    if (segments.isEmpty) return path;

    final start = segments.first.sample(0.0).position;
    path.moveTo(start.dx, start.dy);

    for (final seg in segments) {
      if (seg is CubicBezierSegment) {
        path.cubicTo(
            seg.p1.dx, seg.p1.dy, seg.p2.dx, seg.p2.dy, seg.p3.dx, seg.p3.dy);
      } else if (seg is QuadraticBezierSegment) {
        path.quadraticBezierTo(seg.p1.dx, seg.p1.dy, seg.p2.dx, seg.p2.dy);
      } else if (seg is LineSegment) {
        path.lineTo(seg.p1.dx, seg.p1.dy);
      } else {
        const steps = 16;
        for (int i = 1; i <= steps; i++) {
          final pt = seg.sample(i / steps).position;
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }
    return path;
  }
}

/// Tween that drives a target (e.g. [TransformProps]) along a [MotionPath] curve in Supreme Animations.
class MotionPathTween extends SupremeTween {
  final MotionPath path;
  final bool autoRotate;
  final double autoRotateOffset; // Radians offset
  final Offset alignOrigin;

  MotionPathTween({
    required super.target,
    required this.path,
    this.autoRotate = false,
    this.autoRotateOffset = 0.0,
    this.alignOrigin = Offset.zero,
    super.duration,
    super.delay,
    super.ease,
    super.repeat,
    super.repeatDelay,
    super.yoyo,
    super.yoyoEase,
    super.paused,
    super.onStart,
    super.onUpdate,
    super.onComplete,
    super.onReverseComplete,
    super.onRepeat,
  }) : super(
          vars: const {},
        ) {
    // Render initial start point immediately
    render(0.0, suppressEvents: true);
    if (!isPaused()) {
      wake();
    }
  }

  @override
  void renderProgress(double rawProgress) {
    final activeEase = (yoyoVal && iteration % 2 == 1 && yoyoEase() != null)
        ? yoyoEase()!
        : ease;
    final eased = activeEase(rawProgress);
    final sample = path.sample(eased);

    final x = sample.position.dx - alignOrigin.dx;
    final y = sample.position.dy - alignOrigin.dy;
    final rotation = autoRotate ? (sample.angle + autoRotateOffset) : null;

    if (target is TransformProps) {
      final tp = target as TransformProps;
      tp.beginBatch();
      tp.x = x;
      tp.y = y;
      if (rotation != null) {
        tp.rotation = rotation;
      }
      tp.endBatch();
    } else if (target is Map) {
      final map = target as Map;
      map['x'] = x;
      map['y'] = y;
      if (rotation != null) {
        map['rotation'] = rotation;
      }
    } else if (target is ValueNotifier) {
      final vn = target as ValueNotifier;
      if (vn.value is PathSample) {
        vn.value = sample;
      } else if (vn.value is Offset) {
        vn.value = Offset(x, y);
      } else if (vn.value is Map) {
        final m = Map<String, dynamic>.from(vn.value as Map);
        m['x'] = x;
        m['y'] = y;
        if (rotation != null) {
          m['rotation'] = rotation;
        }
        vn.value = m;
      }
    } else if (target is Function) {
      try {
        (target as Function)(Offset(x, y), sample.angle);
      } catch (_) {
        try {
          (target as Function)(sample);
        } catch (_) {}
      }
    }
  }
}

/// Standalone MotionPathPlugin providing GSAP API parity.
class MotionPathPlugin {
  static const String name = 'motionPath';

  /// Animates [target] along [path] matching GSAP's MotionPathPlugin.
  static MotionPathTween to(
    dynamic target, {
    required dynamic path,
    bool autoRotate = false,
    double autoRotateOffset = 0.0,
    Offset alignOrigin = Offset.zero,
    double? duration,
    double? delay,
    Ease? ease,
    int? repeat,
    double? repeatDelay,
    bool? yoyo,
    Ease? yoyoEase,
    bool? paused,
    VoidCallback? onStart,
    VoidCallback? onUpdate,
    VoidCallback? onComplete,
    VoidCallback? onReverseComplete,
    VoidCallback? onRepeat,
  }) {
    MotionPath motionPath;
    if (path is MotionPath) {
      motionPath = path;
    } else if (path is List<Offset>) {
      motionPath = MotionPath.curved(path);
    } else {
      throw ArgumentError('path must be a MotionPath or List<Offset>');
    }

    final tween = MotionPathTween(
      target: target,
      path: motionPath,
      autoRotate: autoRotate,
      autoRotateOffset: autoRotateOffset,
      alignOrigin: alignOrigin,
      duration: duration,
      delay: delay,
      ease: ease,
      repeat: repeat,
      repeatDelay: repeatDelay,
      yoyo: yoyo,
      yoyoEase: yoyoEase,
      paused: paused,
      onStart: onStart,
      onUpdate: onUpdate,
      onComplete: onComplete,
      onReverseComplete: onReverseComplete,
      onRepeat: onRepeat,
    );

    if (!tween.isPaused()) {
      supreme.globalTimeline.add(tween);
      supreme.ticker.wake();
    }

    return tween;
  }
}
