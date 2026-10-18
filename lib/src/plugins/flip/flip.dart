import 'package:flutter/widgets.dart';
import '../../core/supreme_core.dart';
import '../../core/timeline.dart';
import '../../core/stagger.dart';
import '../../easing/ease.dart';
import '../../widgets/transform_props.dart';
import 'flip_state.dart';

/// Implements FLIP (First, Last, Invert, Play) animation technique for Flutter.
class Flip {
  /// Captures initial geometry of targets before a state mutation.
  static FlipState getState(List<GlobalKey> targets) {
    return FlipState.getState(targets);
  }

  /// Calculates the delta between [state] and current layout, and animates
  /// smoothly to the new layout without jumpiness.
  static SupremeTimeline from(
    FlipState state, {
    double duration = 0.5,
    Ease? ease,
    dynamic stagger,
    Map<dynamic, TransformProps>? transformPropsMap,
    VoidCallback? onComplete,
  }) {
    final tl = supreme.timeline({'paused': true});
    final staggerObj = Stagger.fromDynamic(stagger);
    final targetList = state.targets.toList();
    final delays = staggerObj?.calculateDelays(targetList.length) ??
        List.filled(targetList.length, 0.0);

    for (int i = 0; i < targetList.length; i++) {
      final key = targetList[i];
      if (key is! GlobalKey) continue;

      final oldGeom = state.get(key);
      if (oldGeom == null) continue;

      final context = key.currentContext;
      if (context == null) continue;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;

      final newPos = renderBox.localToGlobal(Offset.zero);
      final newW = renderBox.size.width;
      final newH = renderBox.size.height;

      // Invert delta
      final dx = oldGeom.x - newPos.dx;
      final dy = oldGeom.y - newPos.dy;
      final sx = newW > 0 ? (oldGeom.width / newW) : 1.0;
      final sy = newH > 0 ? (oldGeom.height / newH) : 1.0;

      final props = transformPropsMap?[key];
      if (props != null) {
        // Set to inverted start state
        props.x = dx;
        props.y = dy;
        props.scaleX = sx;
        props.scaleY = sy;

        // Animate to identity (0, 0, 1, 1)
        tl.to(
          props,
          {
            'x': 0.0,
            'y': 0.0,
            'scaleX': 1.0,
            'scaleY': 1.0,
            'duration': duration,
            'ease': ease ?? Ease.power2.out,
          },
          delays[i],
        );
      }
    }

    if (onComplete != null) {
      tl.onComplete = onComplete;
    }

    tl.play();
    return tl;
  }
}
