import 'dart:math' as math;
import '../easing/ease.dart';

enum StaggerFromType {
  start,
  end,
  center,
  edges,
  random,
  targetIndex,
}

class StaggerFrom {
  final StaggerFromType type;
  final int? targetIndex;

  const StaggerFrom._(this.type, [this.targetIndex]);

  static const StaggerFrom start = StaggerFrom._(StaggerFromType.start);
  static const StaggerFrom end = StaggerFrom._(StaggerFromType.end);
  static const StaggerFrom center = StaggerFrom._(StaggerFromType.center);
  static const StaggerFrom edges = StaggerFrom._(StaggerFromType.edges);
  static const StaggerFrom random = StaggerFrom._(StaggerFromType.random);

  static StaggerFrom index(int idx) =>
      StaggerFrom._(StaggerFromType.targetIndex, idx);

  static StaggerFrom parse(dynamic val) {
    if (val is StaggerFrom) return val;
    if (val is int) return StaggerFrom.index(val);
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'end') return StaggerFrom.end;
      if (s == 'center') return StaggerFrom.center;
      if (s == 'edges') return StaggerFrom.edges;
      if (s == 'random') return StaggerFrom.random;
      final parsedInt = int.tryParse(s);
      if (parsedInt != null) return StaggerFrom.index(parsedInt);
    }
    return StaggerFrom.start;
  }
}

/// Advanced stagger coordination matching GSAP's stagger engine.
class Stagger {
  final double? each;
  final double? amount;
  final StaggerFrom from;
  final List<int>? grid; // [rows, cols]
  final String? axis; // 'x', 'y'
  final Ease? ease;

  const Stagger({
    this.each,
    this.amount,
    this.from = StaggerFrom.start,
    this.grid,
    this.axis,
    this.ease,
  }) : assert(each != null || amount != null,
            'Either each or amount must be specified');

  const Stagger.each(
    double eachVal, {
    this.from = StaggerFrom.start,
    this.grid,
    this.axis,
    this.ease,
  })  : each = eachVal,
        amount = null;

  const Stagger.amount(
    double amountVal, {
    this.from = StaggerFrom.start,
    this.grid,
    this.axis,
    this.ease,
  })  : amount = amountVal,
        each = null;

  /// Helper factory to create from dynamic value (e.g. double, Stagger instance, or map).
  static Stagger? fromDynamic(dynamic val) {
    if (val == null) return null;
    if (val is Stagger) return val;
    if (val is num) return Stagger.each(val.toDouble());
    if (val is Map) {
      return Stagger(
        each: (val['each'] as num?)?.toDouble(),
        amount: (val['amount'] as num?)?.toDouble(),
        from: StaggerFrom.parse(val['from']),
        grid: (val['grid'] as List?)?.map((e) => (e as num).toInt()).toList(),
        axis: val['axis'] as String?,
        ease: val['ease'] is Ease
            ? val['ease'] as Ease
            : (val['ease'] is String
                ? Ease.fromString(val['ease'] as String)
                : null),
      );
    }
    return null;
  }

  /// Calculates individual start delay times for [count] elements.
  List<double> calculateDelays(int count) {
    if (count <= 0) return const [];
    if (count == 1) return const [0.0];

    final rawDistances = List<double>.filled(count, 0.0);

    if (grid != null && grid!.length >= 2) {
      final rows = grid![0];
      final cols = grid![1];
      _calculate2dDistances(rawDistances, count, rows, cols);
    } else {
      _calculate1dDistances(rawDistances, count);
    }

    double maxDist = 0.0;
    for (final d in rawDistances) {
      if (d > maxDist) maxDist = d;
    }

    // `amount` spreads the whole stagger across the normalized distance.
    // `each` is the delay per distance unit, so a grid neighbour is `each`
    // seconds later and the far corner is `each * diagonal`.
    final delays = <double>[];

    for (int i = 0; i < count; i++) {
      if (amount != null) {
        var norm = maxDist > 0 ? (rawDistances[i] / maxDist) : 0.0;
        if (ease != null) {
          norm = ease!(norm);
        }
        delays.add(norm * amount!);
      } else if (ease != null && maxDist > 0) {
        final eased = ease!(rawDistances[i] / maxDist);
        delays.add(eased * maxDist * (each ?? 0.0));
      } else {
        delays.add(rawDistances[i] * (each ?? 0.0));
      }
    }

    return delays;
  }

  void _calculate1dDistances(List<double> out, int count) {
    final rand = math.Random();
    switch (from.type) {
      case StaggerFromType.start:
        for (int i = 0; i < count; i++) {
          out[i] = i.toDouble();
        }
        break;
      case StaggerFromType.end:
        for (int i = 0; i < count; i++) {
          out[i] = (count - 1 - i).toDouble();
        }
        break;
      case StaggerFromType.center:
        final mid = (count - 1) / 2.0;
        for (int i = 0; i < count; i++) {
          out[i] = (i - mid).abs();
        }
        break;
      case StaggerFromType.edges:
        final mid = (count - 1) / 2.0;
        for (int i = 0; i < count; i++) {
          out[i] = mid - (i - mid).abs();
        }
        break;
      case StaggerFromType.random:
        for (int i = 0; i < count; i++) {
          out[i] = rand.nextDouble() * count;
        }
        break;
      case StaggerFromType.targetIndex:
        final idx = (from.targetIndex ?? 0).clamp(0, count - 1);
        for (int i = 0; i < count; i++) {
          out[i] = (i - idx).abs().toDouble();
        }
        break;
    }
  }

  void _calculate2dDistances(List<double> out, int count, int rows, int cols) {
    final rand = math.Random();
    double originR = 0;
    double originC = 0;

    switch (from.type) {
      case StaggerFromType.start:
        originR = 0;
        originC = 0;
        break;
      case StaggerFromType.end:
        originR = (rows - 1).toDouble();
        originC = (cols - 1).toDouble();
        break;
      case StaggerFromType.center:
        originR = (rows - 1) / 2.0;
        originC = (cols - 1) / 2.0;
        break;
      case StaggerFromType.edges:
        // Distance to closest edge
        for (int i = 0; i < count; i++) {
          final r = i ~/ cols;
          final c = i % cols;
          final distEdgeR = math.min(r, rows - 1 - r).toDouble();
          final distEdgeC = math.min(c, cols - 1 - c).toDouble();
          out[i] = math.min(distEdgeR, distEdgeC);
        }
        return;
      case StaggerFromType.random:
        for (int i = 0; i < count; i++) {
          out[i] = rand.nextDouble() * (rows + cols);
        }
        return;
      case StaggerFromType.targetIndex:
        final idx = (from.targetIndex ?? 0).clamp(0, count - 1);
        originR = (idx ~/ cols).toDouble();
        originC = (idx % cols).toDouble();
        break;
    }

    for (int i = 0; i < count; i++) {
      final r = (i ~/ cols).toDouble();
      final c = (i % cols).toDouble();

      final dr = (r - originR).abs();
      final dc = (c - originC).abs();

      if (axis == 'x') {
        out[i] = dc;
      } else if (axis == 'y') {
        out[i] = dr;
      } else {
        // Euclidean distance
        out[i] = math.sqrt(dr * dr + dc * dc);
      }
    }
  }
}
