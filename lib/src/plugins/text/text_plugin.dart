import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/supreme_core.dart';
import '../../core/tween.dart';
import '../../easing/ease.dart';

/// Text animation helper in Supreme Animations (typewriter effect, scramble text).
class TextPlugin {
  static const String _defaultScrambleChars =
      'abcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';

  /// Animates a [ValueNotifier<String>] typewriter-style to [newText].
  static SupremeTween typewriter(
    ValueNotifier<String> target,
    String newText, {
    double duration = 1.0,
    double delay = 0.0,
    Ease? ease,
    VoidCallback? onComplete,
  }) {
    final tween = _CustomTextTween(
      target: target,
      newText: newText,
      duration: duration,
      delay: delay,
      ease: ease ?? Ease.linear,
      onComplete: onComplete,
    );
    supreme.globalTimeline.add(tween);
    supreme.ticker.wake();
    return tween;
  }

  /// Scrambles random characters before resolving each character of [newText].
  static SupremeTween scramble(
    ValueNotifier<String> target,
    String newText, {
    double duration = 1.5,
    double delay = 0.0,
    String chars = _defaultScrambleChars,
    Ease? ease,
    VoidCallback? onComplete,
  }) {
    final tween = _ScrambleTextTween(
      target: target,
      newText: newText,
      chars: chars,
      duration: duration,
      delay: delay,
      ease: ease ?? Ease.linear,
      onComplete: onComplete,
    );
    supreme.globalTimeline.add(tween);
    supreme.ticker.wake();
    return tween;
  }
}

class _CustomTextTween extends SupremeTween {
  final String newText;

  _CustomTextTween({
    required ValueNotifier<String> super.target,
    required this.newText,
    required super.duration,
    super.delay,
    super.ease,
    super.onComplete,
  }) : super(
          vars: const {},
        );

  @override
  void renderProgress(double progress) {
    final p = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    final count = (p * newText.length).round().clamp(0, newText.length);
    (target as ValueNotifier<String>).value = newText.substring(0, count);
  }
}

class _ScrambleTextTween extends SupremeTween {
  final String newText;
  final String chars;
  final math.Random _random = math.Random();

  _ScrambleTextTween({
    required ValueNotifier<String> super.target,
    required this.newText,
    required this.chars,
    required super.duration,
    super.delay,
    super.ease,
    super.onComplete,
  }) : super(
          vars: const {},
        );

  @override
  void renderProgress(double progress) {
    final p = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    final resolvedCount = (p * newText.length).floor().clamp(0, newText.length);
    final buffer = StringBuffer();

    for (int i = 0; i < newText.length; i++) {
      if (i < resolvedCount) {
        buffer.write(newText[i]);
      } else {
        if (newText[i] == ' ') {
          buffer.write(' ');
        } else {
          final charIdx = _random.nextInt(chars.length);
          buffer.write(chars[charIdx]);
        }
      }
    }

    (target as ValueNotifier<String>).value = buffer.toString();
  }
}
