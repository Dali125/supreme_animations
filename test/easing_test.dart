import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations/supreme_animations.dart';

void main() {
  group('Easing Engine Tests', () {
    test('Standard Easings return correct boundaries at 0.0 and 1.0', () {
      final eases = [
        Ease.linear,
        Ease.power1.easeIn,
        Ease.power1.out,
        Ease.power1.inOut,
        Ease.power2.easeIn,
        Ease.power2.out,
        Ease.power2.inOut,
        Ease.power3.easeIn,
        Ease.power3.out,
        Ease.power3.inOut,
        Ease.power4.easeIn,
        Ease.power4.out,
        Ease.power4.inOut,
        Ease.sine.easeIn,
        Ease.sine.out,
        Ease.sine.inOut,
        Ease.expo.easeIn,
        Ease.expo.out,
        Ease.expo.inOut,
        Ease.circ.easeIn,
        Ease.circ.out,
        Ease.circ.inOut,
        Ease.back.easeIn,
        Ease.back.out,
        Ease.back.inOut,
        Ease.elastic.easeIn,
        Ease.elastic.out,
        Ease.elastic.inOut,
        Ease.bounce.easeIn,
        Ease.bounce.out,
        Ease.bounce.inOut,
      ];

      for (final ease in eases) {
        expect(ease(0.0), closeTo(0.0, 1e-4));
        expect(ease(1.0), closeTo(1.0, 1e-4));
      }
    });

    test('Steps ease produces discrete steps', () {
      final step5 = Ease.steps(5);
      expect(step5(0.0), 0.0);
      expect(step5(0.1), closeTo(0.0, 1e-4));
      expect(step5(0.25), closeTo(0.2, 1e-4));
      expect(step5(0.5), closeTo(0.4, 1e-4));
      expect(step5(0.85), closeTo(0.8, 1e-4));
      expect(step5(1.0), 1.0);
    });

    test('Ease.fromString parses string names with optional arguments', () {
      expect(Ease.fromString('none'), equals(Ease.linear));
      expect(Ease.fromString('power2.out')(0.5),
          closeTo(Ease.power2.out(0.5), 1e-4));
      expect(Ease.fromString('power2.in')(0.5),
          closeTo(Ease.power2.easeIn(0.5), 1e-4));
      expect(Ease.fromString('power2.inout')(0.5),
          closeTo(Ease.power2.inOut(0.5), 1e-4));
      expect(Ease.fromString('sine.in')(0.5),
          closeTo(Ease.sine.easeIn(0.5), 1e-4));
      expect(Ease.fromString('sine.inout')(0.5),
          closeTo(Ease.sine.inOut(0.5), 1e-4));
      expect(
          () => Ease.elastic.customOut(amplitude: 0.2)(0.4), returnsNormally);
      expect(Ease.fromString('back.out(2.5)')(0.5), isA<double>());
      expect(Ease.fromString('elastic.out(1.2, 0.4)')(0.5), isA<double>());
      expect(Ease.fromString('steps(4)')(0.6), closeTo(0.5, 1e-4));
    });

    test('CubicBezier solver calculates accurate bezier curves', () {
      final bezier = CubicBezier(0.25, 0.1, 0.25, 1.0);
      expect(bezier(0.0), closeTo(0.0, 1e-4));
      expect(bezier(1.0), closeTo(1.0, 1e-4));
      expect(bezier(0.5), greaterThan(0.5)); // Ease out character
    });

    test('CustomEase parses SVG path data', () {
      final custom =
          CustomEase.create('customBounce', 'M0,0 C0.2,0.8 0.4,1.2 1,1');
      expect(custom(0.0), closeTo(0.0, 1e-4));
      expect(custom(1.0), closeTo(1.0, 1e-4));
      expect(CustomEase.get('customBounce'), equals(custom));
    });

    test('RoughEase creates bounded jitter with tapering', () {
      final rough = RoughEase(points: 10, strength: 1.0, clamp: true);
      final v1 = rough(0.3);
      final v2 = rough(0.7);
      expect(v1, inInclusiveRange(0.0, 1.0));
      expect(v2, inInclusiveRange(0.0, 1.0));
    });

    test('SlowMo provides slow motion in the middle and yoyo', () {
      final slow = SlowMo(linearRatio: 0.8, power: 0.8, yoyo: false);
      expect(slow(0.0), closeTo(0.0, 1e-4));
      expect(slow(1.0), closeTo(1.0, 1e-4));

      final slowYoyo = SlowMo(yoyo: true);
      expect(slowYoyo(0.0), closeTo(0.0, 1e-4));
      expect(slowYoyo(0.5), greaterThan(0.8));
      expect(slowYoyo(1.0), closeTo(0.0, 1e-4));
    });
  });
}
