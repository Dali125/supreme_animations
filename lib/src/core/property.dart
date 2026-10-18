import 'dart:ui' show Color, Offset, Size, Rect, lerpDouble;
import 'package:flutter/painting.dart' show BorderRadius, EdgeInsets;
import 'package:flutter/widgets.dart' show TextStyle;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Utility to interpolate and resolve dynamic animation properties.
class PropertyInterpolation {
  /// Resolves relative value syntax (e.g. "+=50", "-=20", "*=2", "/=2").
  static double resolveRelativeDouble(double current, dynamic target) {
    if (target is num) {
      return target.toDouble();
    }
    if (target is String) {
      final trimmed = target.trim();
      if (trimmed.startsWith('+=')) {
        final val = double.tryParse(trimmed.substring(2)) ?? 0.0;
        return current + val;
      }
      if (trimmed.startsWith('-=')) {
        final val = double.tryParse(trimmed.substring(2)) ?? 0.0;
        return current - val;
      }
      if (trimmed.startsWith('*=')) {
        final val = double.tryParse(trimmed.substring(2)) ?? 1.0;
        return current * val;
      }
      if (trimmed.startsWith('/=')) {
        final val = double.tryParse(trimmed.substring(2)) ?? 1.0;
        return val != 0 ? current / val : current;
      }
      final parsed = double.tryParse(trimmed);
      if (parsed != null) return parsed;
    }
    return current;
  }

  /// General-purpose interpolation between start and end values given progress [t] in `[0, 1]`.
  static dynamic lerp(dynamic start, dynamic end, double t) {
    if (start == null && end == null) return null;
    if (start == null) return end;
    if (end == null) return start;

    if (start is num && end is num) {
      return lerpDouble(start.toDouble(), end.toDouble(), t) ?? end;
    }

    if (start is Color && end is Color) {
      return Color.lerp(start, end, t) ?? end;
    }

    if (start is Offset && end is Offset) {
      return Offset.lerp(start, end, t) ?? end;
    }

    if (start is Size && end is Size) {
      return Size.lerp(start, end, t) ?? end;
    }

    if (start is Rect && end is Rect) {
      return Rect.lerp(start, end, t) ?? end;
    }

    if (start is BorderRadius && end is BorderRadius) {
      return BorderRadius.lerp(start, end, t) ?? end;
    }

    if (start is EdgeInsets && end is EdgeInsets) {
      return EdgeInsets.lerp(start, end, t) ?? end;
    }

    if (start is TextStyle && end is TextStyle) {
      return TextStyle.lerp(start, end, t) ?? end;
    }

    if (start is Matrix4 && end is Matrix4) {
      return _lerpMatrix4(start, end, t);
    }

    // Fallback: stepped switch at 50%
    return t < 0.5 ? start : end;
  }

  static Matrix4 _lerpMatrix4(Matrix4 a, Matrix4 b, double t) {
    final result = Matrix4.zero();
    final aStorage = a.storage;
    final bStorage = b.storage;
    final rStorage = result.storage;
    for (int i = 0; i < 16; i++) {
      rStorage[i] = (lerpDouble(aStorage[i], bStorage[i], t) ?? bStorage[i]);
    }
    return result;
  }
}
