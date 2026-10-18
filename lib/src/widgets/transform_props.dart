// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Alignment;

/// Holds 2D/3D transform, opacity, and filter properties for Flutter widgets,
/// matching GSAP's CSSPlugin transform capabilities.
class TransformProps extends ChangeNotifier {
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  double _scaleX = 1.0;
  double _scaleY = 1.0;

  double _rotation = 0.0; // Radians (z-axis)
  double _rotationX = 0.0; // Radians
  double _rotationY = 0.0; // Radians

  double _skewX = 0.0;
  double _skewY = 0.0;

  double _opacity = 1.0;
  double _blur = 0.0;

  Alignment _origin = Alignment.center;
  int _batchDepth = 0;
  bool _batchDirty = false;

  TransformProps({
    double x = 0.0,
    double y = 0.0,
    double z = 0.0,
    double scale = 1.0,
    double? scaleX,
    double? scaleY,
    double rotation = 0.0,
    double rotationX = 0.0,
    double rotationY = 0.0,
    double skewX = 0.0,
    double skewY = 0.0,
    double opacity = 1.0,
    double blur = 0.0,
    Alignment origin = Alignment.center,
  })  : _x = x,
        _y = y,
        _z = z,
        _scaleX = scaleX ?? scale,
        _scaleY = scaleY ?? scale,
        _rotation = rotation,
        _rotationX = rotationX,
        _rotationY = rotationY,
        _skewX = skewX,
        _skewY = skewY,
        _opacity = opacity,
        _blur = blur,
        _origin = origin;

  // Getters
  double get x => _x;
  double get y => _y;
  double get z => _z;

  double get scaleX => _scaleX;
  double get scaleY => _scaleY;
  double get scale => (_scaleX + _scaleY) / 2.0;

  double get rotation => _rotation;
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;

  double get skewX => _skewX;
  double get skewY => _skewY;

  double get opacity => _opacity;
  double get blur => _blur;
  Alignment get origin => _origin;

  /// Coalesces listener notifications across a multi-property write.
  void beginBatch() {
    _batchDepth++;
  }

  /// Emits at most one notification for the matching [beginBatch].
  void endBatch() {
    if (_batchDepth == 0) return;
    _batchDepth--;
    if (_batchDepth == 0 && _batchDirty) {
      _batchDirty = false;
      notifyListeners();
    }
  }

  void _touch() {
    if (_batchDepth > 0) {
      _batchDirty = true;
    } else {
      notifyListeners();
    }
  }

  // Setters with notifyListeners
  set x(double val) {
    if (_x != val) {
      _x = val;
      _touch();
    }
  }

  set y(double val) {
    if (_y != val) {
      _y = val;
      _touch();
    }
  }

  set z(double val) {
    if (_z != val) {
      _z = val;
      _touch();
    }
  }

  set scaleX(double val) {
    if (_scaleX != val) {
      _scaleX = val;
      _touch();
    }
  }

  set scaleY(double val) {
    if (_scaleY != val) {
      _scaleY = val;
      _touch();
    }
  }

  set scale(double val) {
    if (_scaleX != val || _scaleY != val) {
      _scaleX = val;
      _scaleY = val;
      _touch();
    }
  }

  set rotation(double val) {
    if (_rotation != val) {
      _rotation = val;
      _touch();
    }
  }

  set rotationX(double val) {
    if (_rotationX != val) {
      _rotationX = val;
      _touch();
    }
  }

  set rotationY(double val) {
    if (_rotationY != val) {
      _rotationY = val;
      _touch();
    }
  }

  /// Rotation in degrees around Z-axis.
  double get rotationDeg => _rotation * 180.0 / math.pi;
  set rotationDeg(double val) => rotation = val * math.pi / 180.0;

  /// 3D Rotation in degrees around X-axis.
  double get rotationXDeg => _rotationX * 180.0 / math.pi;
  set rotationXDeg(double val) => rotationX = val * math.pi / 180.0;

  /// 3D Rotation in degrees around Y-axis.
  double get rotationYDeg => _rotationY * 180.0 / math.pi;
  set rotationYDeg(double val) => rotationY = val * math.pi / 180.0;

  set skewX(double val) {
    if (_skewX != val) {
      _skewX = val;
      _touch();
    }
  }

  set skewY(double val) {
    if (_skewY != val) {
      _skewY = val;
      _touch();
    }
  }

  set opacity(double val) {
    final clamped = val.clamp(0.0, 1.0);
    if (_opacity != clamped) {
      _opacity = clamped;
      _touch();
    }
  }

  set blur(double val) {
    final clamped = val < 0.0 ? 0.0 : val;
    if (_blur != clamped) {
      _blur = clamped;
      _touch();
    }
  }

  set origin(Alignment val) {
    if (_origin != val) {
      _origin = val;
      _touch();
    }
  }

  dynamic getProperty(String name) {
    switch (name) {
      case 'x':
        return _x;
      case 'y':
        return _y;
      case 'z':
        return _z;
      case 'scale':
        return scale;
      case 'scaleX':
        return _scaleX;
      case 'scaleY':
        return _scaleY;
      case 'rotation':
      case 'rotate':
        return _rotation;
      case 'rotationDeg':
      case 'rotateDeg':
        return rotationDeg;
      case 'rotationX':
        return _rotationX;
      case 'rotationXDeg':
        return rotationXDeg;
      case 'rotationY':
        return _rotationY;
      case 'rotationYDeg':
        return rotationYDeg;
      case 'skewX':
        return _skewX;
      case 'skewY':
        return _skewY;
      case 'opacity':
      case 'alpha':
        return _opacity;
      case 'blur':
        return _blur;
      case 'origin':
        return _origin;
      default:
        return null;
    }
  }

  void setProperty(String name, dynamic value) {
    if (value == null) return;
    switch (name) {
      case 'x':
        x = (value as num).toDouble();
        break;
      case 'y':
        y = (value as num).toDouble();
        break;
      case 'z':
        z = (value as num).toDouble();
        break;
      case 'scale':
        scale = (value as num).toDouble();
        break;
      case 'scaleX':
        scaleX = (value as num).toDouble();
        break;
      case 'scaleY':
        scaleY = (value as num).toDouble();
        break;
      case 'rotation':
      case 'rotate':
        if (value is String && value.trim().endsWith('deg')) {
          final deg =
              double.tryParse(value.trim().replaceAll('deg', '').trim()) ?? 0.0;
          rotationDeg = deg;
        } else {
          rotation = (value as num).toDouble();
        }
        break;
      case 'rotationDeg':
      case 'rotateDeg':
        rotationDeg = (value as num).toDouble();
        break;
      case 'rotationX':
        rotationX = (value as num).toDouble();
        break;
      case 'rotationXDeg':
        rotationXDeg = (value as num).toDouble();
        break;
      case 'rotationY':
        rotationY = (value as num).toDouble();
        break;
      case 'rotationYDeg':
        rotationYDeg = (value as num).toDouble();
        break;
      case 'skewX':
        skewX = (value as num).toDouble();
        break;
      case 'skewY':
        skewY = (value as num).toDouble();
        break;
      case 'opacity':
      case 'alpha':
        opacity = (value as num).toDouble();
        break;
      case 'blur':
        blur = (value as num).toDouble();
        break;
      case 'origin':
        if (value is Alignment) origin = value;
        break;
    }
  }

  /// Clones current values.
  TransformProps clone() {
    return TransformProps(
      x: _x,
      y: _y,
      z: _z,
      scaleX: _scaleX,
      scaleY: _scaleY,
      rotation: _rotation,
      rotationX: _rotationX,
      rotationY: _rotationY,
      skewX: _skewX,
      skewY: _skewY,
      opacity: _opacity,
      blur: _blur,
      origin: _origin,
    );
  }
}
