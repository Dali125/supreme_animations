import 'package:flutter/widgets.dart';

/// Captures the geometry of a single element for FLIP animations.
class ElementGeometry {
  final Rect bounds;

  const ElementGeometry({required this.bounds});

  double get x => bounds.left;
  double get y => bounds.top;
  double get width => bounds.width;
  double get height => bounds.height;
}

/// Holds the recorded state of elements before a layout change.
class FlipState {
  final Map<dynamic, ElementGeometry> _targets = {};

  FlipState();

  /// Captures current positions and dimensions of targets.
  static FlipState getState(List<GlobalKey> targets) {
    final state = FlipState();
    for (final key in targets) {
      final context = key.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final pos = renderBox.localToGlobal(Offset.zero);
          state._targets[key] = ElementGeometry(
            bounds: Rect.fromLTWH(
              pos.dx,
              pos.dy,
              renderBox.size.width,
              renderBox.size.height,
            ),
          );
        }
      }
    }
    return state;
  }

  ElementGeometry? get(dynamic target) => _targets[target];
  Iterable<dynamic> get targets => _targets.keys;
}
