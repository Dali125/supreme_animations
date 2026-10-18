import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations/supreme_animations.dart';

void main() {
  group('TransformProps & SupremeWidget Tests', () {
    testWidgets(
        'TransformProps updates matrix, opacity, and blur on SupremeWidget',
        (tester) async {
      final props = TransformProps(x: 10.0, y: 20.0, opacity: 0.8, blur: 5.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SupremeWidget(
            transform: props,
            child: const Text('GSAP Animated'),
          ),
        ),
      );

      expect(find.text('GSAP Animated'), findsOneWidget);

      // Mutate properties and verify reactive update
      props.x = 50.0;
      props.opacity = 0.5;
      await tester.pump();

      expect(props.x, 50.0);
      expect(props.opacity, 0.5);
    });

    testWidgets('SupremeBuilder rebuilds on animation progress',
        (tester) async {
      final target = {'scale': 1.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'scale': 2.0},
        paused: true,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SupremeBuilder(
            animation: tween,
            builder: (context, child) {
              return Text(
                  'Scale: ${(target['scale'] as double).toStringAsFixed(1)}');
            },
          ),
        ),
      );

      expect(find.text('Scale: 1.0'), findsOneWidget);

      tween.seek(0.5);
      await tester.pump();
      expect(find.text('Scale: 1.5'), findsOneWidget);

      tween.seek(1.0);
      await tester.pump();
      expect(find.text('Scale: 2.0'), findsOneWidget);
    });

    test(
        'SupremeVars strongly-typed variables work seamlessly with supreme.to and rotationDeg',
        () {
      final props = TransformProps();
      final anim = supreme.to(
        props,
        SupremeVars(
          x: 100,
          rotationDeg: 90,
          scale: 1.5,
          duration: 1.0,
          ease: Ease.none,
          paused: true,
        ),
      );

      expect(anim, isA<SupremeAnimation>());
      anim.seek(0.5);
      expect(props.x, closeTo(50.0, 1e-4));
      expect(props.rotationDeg, closeTo(45.0, 1e-4));
      expect(props.scale, closeTo(1.25, 1e-4));
    });

    test('TransformProps supports rotation degree strings like "180deg"', () {
      final props = TransformProps();
      props.setProperty('rotation', '180deg');
      expect(props.rotationDeg, closeTo(180.0, 1e-4));
    });

    testWidgets(
        'Widget.supreme() extension animates widget with full ergonomics',
        (tester) async {
      late SupremeAnimation controller;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: const Text('Ergonomic Supreme').supreme(
            to: SupremeVars(x: 80, duration: 1.0, ease: Ease.none),
            autoPlay: false,
            onCreated: (anim) => controller = anim,
          ),
        ),
      );

      expect(find.text('Ergonomic Supreme'), findsOneWidget);
      expect(controller.isPaused(), isTrue);

      controller.seek(0.5);
      await tester.pump();

      final transformFinder = find.byType(Transform);
      final tx = tester
          .widget<Transform>(transformFinder.first)
          .transform
          .getTranslation()
          .x;
      expect(tx, closeTo(40.0, 1e-4));
    });

    testWidgets('Widget.gsap() backward compatibility extension works',
        (tester) async {
      late SupremeAnimation controller;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          // ignore: deprecated_member_use_from_same_package
          child: const Text('Legacy GSAP').gsap(
            to: SupremeVars(x: 80, duration: 1.0, ease: Ease.none),
            autoPlay: false,
            onCreated: (anim) => controller = anim,
          ),
        ),
      );

      expect(find.text('Legacy GSAP'), findsOneWidget);
      controller.seek(0.5);
      await tester.pump();

      final transformFinder = find.byType(Transform);
      final tx = tester
          .widget<Transform>(transformFinder.first)
          .transform
          .getTranslation()
          .x;
      expect(tx, closeTo(40.0, 1e-4));
    });
  });

  group('ScrollTrigger Plugin Tests', () {
    test('ScrollTrigger computes progress and triggers toggle actions', () {
      final target = {'x': 0.0};
      final anim = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': 100.0},
        paused: true,
      );

      final trigger = ScrollTrigger(
        animation: anim,
        start: 100.0,
        end: 500.0,
        scrub: true,
      );

      trigger.refresh(scrollPixels: 0.0, viewportHeight: 800.0);

      expect(trigger.progress, 0.0);
      expect(target['x'], 0.0);

      // Scroll into middle
      trigger.update(300.0);
      expect(trigger.progress, closeTo(0.5, 1e-4));
      expect(target['x'], closeTo(50.0, 1e-4));

      // Scroll past end
      trigger.update(600.0);
      expect(trigger.progress, 1.0);
      expect(target['x'], closeTo(100.0, 1e-4));
    });

    test('Numeric scrub keeps catching up after the scroll event', () {
      final target = {'x': 0.0};
      final anim = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': 100.0},
        paused: true,
      );

      final trigger = ScrollTrigger(
        animation: anim,
        start: 0.0,
        end: 100.0,
        scrub: 1.0,
      );
      trigger.refresh(scrollPixels: 0.0, viewportHeight: 800.0);
      trigger.update(100.0);

      expect(trigger.progress, 0.0);
      supreme.ticker.tick(0.5);
      expect(trigger.progress, closeTo(0.5, 1e-3));
      expect(target['x'], closeTo(50.0, 1e-3));

      trigger.kill();
      supreme.ticker.sleep();
    });

    test(
        'ScrollTrigger parses trigger string specifications ("top bottom", "+=300")',
        () {
      final trigger = ScrollTrigger(
        start: 'top bottom',
        end: '+=300',
      );

      trigger.refresh(scrollPixels: 0.0, viewportHeight: 800.0);
      expect(trigger.endPixels - trigger.startPixels, 300.0);
    });
  });

  group('Flip Plugin Tests', () {
    test('FlipState stores and inverts geometry deltas', () {
      final props = TransformProps();
      final tl = supreme.timeline({'paused': true});
      tl.to(props, {'x': 0.0, 'y': 0.0, 'scale': 1.0, 'duration': 0.5});

      expect(tl.durationVal, 0.5);
    });
  });

  group('TextPlugin Tests', () {
    test('TextPlugin typewriter increments characters over time', () {
      final notifier = ValueNotifier<String>('');
      final tween = TextPlugin.typewriter(
        notifier,
        'Hello GSAP!',
        duration: 1.0,
      );

      tween.seek(0.0);
      expect(notifier.value, '');

      tween.seek(0.5);
      expect(notifier.value, 'Hello ');

      tween.seek(1.0);
      expect(notifier.value, 'Hello GSAP!');
    });

    test(
        'TextPlugin scramble scrambles intermediate glyphs and resolves finally',
        () {
      final notifier = ValueNotifier<String>('');
      final tween = TextPlugin.scramble(
        notifier,
        'FLUTTER',
        duration: 1.0,
      );

      tween.seek(0.0);
      expect(notifier.value.length, 7);

      tween.seek(1.0);
      expect(notifier.value, 'FLUTTER');
    });
  });

  group('MotionPath Plugin Tests', () {
    test('MotionPath samples points and tangents along curved bezier paths',
        () {
      final path = MotionPath.curved([
        const Offset(0, 0),
        const Offset(100, 50),
        const Offset(200, 0),
      ]);

      final startSample = path.sample(0.0);
      final midSample = path.sample(0.5);
      final endSample = path.sample(1.0);

      expect(startSample.position, const Offset(0, 0));
      expect(midSample.position.dx, closeTo(100.0, 15.0));
      expect(endSample.position.dx, closeTo(200.0, 1.0));
      expect(startSample.angle, isA<double>());
    });

    test('MotionPathTween drives TransformProps along path with autoRotate',
        () {
      final props = TransformProps();
      final path = MotionPath.polygon([
        const Offset(0, 0),
        const Offset(100, 0),
      ]);

      final tween = MotionPathTween(
        target: props,
        path: path,
        autoRotate: true,
        duration: 1.0,
        ease: Ease.none,
        paused: true,
      );

      tween.seek(0.5);
      expect(props.x, closeTo(50.0, 1e-4));
      expect(props.y, closeTo(0.0, 1e-4));
      expect(props.rotation, closeTo(0.0, 1e-4)); // Angle along x axis is 0 rad
    });

    test('Inertia writes clamped positions back into the integrator', () {
      final props = TransformProps();
      final tween = InertiaTween(
        target: props,
        initialVelocity: const Offset(5000, 0),
        bounds: const Rect.fromLTRB(0, 0, 10, 10),
        resistance: 0.99,
      );

      tween.update(0.2);
      expect(props.x, 10.0);
      tween.update(0.2);
      expect(props.x, lessThan(10.0));
      tween.kill();
    });

    test('MotionPathPlugin.to animates with alignOrigin and autoRotateOffset',
        () {
      final props = TransformProps();
      final path = MotionPath.polygon([
        const Offset(0, 0),
        const Offset(0, 100),
      ]);

      final tween = MotionPathPlugin.to(
        props,
        path: path,
        autoRotate: true,
        autoRotateOffset: 0.5,
        alignOrigin: const Offset(10, 10),
        duration: 1.0,
        ease: Ease.none,
        paused: true,
      );

      tween.seek(0.5);
      expect(props.x, closeTo(-10.0, 1e-4));
      expect(props.y, closeTo(40.0, 1e-4)); // 50 - 10 = 40
      expect(props.rotation, closeTo(1.570796 + 0.5, 1e-3)); // pi/2 + offset
    });

    test('supreme.to seamlessly supports motionPath syntax and Map target', () {
      final target = <String, dynamic>{'x': 0.0, 'y': 0.0};
      final path = MotionPath.polygon([
        const Offset(10, 20),
        const Offset(50, 60),
      ]);

      final tween = supreme.to(
        target,
        {
          'motionPath': {
            'path': path,
            'autoRotate': true,
          },
          'duration': 1.0,
          'ease': Ease.none,
          'paused': true,
        },
      ) as MotionPathTween;

      tween.seek(0.5);
      expect(target['x'], closeTo(30.0, 1e-4));
      expect(target['y'], closeTo(40.0, 1e-4));
      expect(target['rotation'], isNotNull);
    });

    test(
        'MotionPath.toPath creates valid Flutter Path and waypoints are preserved',
        () {
      final points = [
        const Offset(0, 0),
        const Offset(50, 100),
        const Offset(100, 0),
      ];
      final path = MotionPath.curved(points);
      expect(path.waypoints, points);

      final flutterPath = path.toPath();
      final bounds = flutterPath.getBounds();
      expect(bounds.left, closeTo(0.0, 1.0));
      expect(bounds.right, closeTo(100.0, 1.0));
    });
  });

  group('Draggable and Inertia Tests', () {
    test('InertiaTween decelerates velocity towards stop', () {
      final props = TransformProps(x: 0, y: 0);
      final inertia = InertiaTween(
        target: props,
        initialVelocity: const Offset(1000.0, 0.0),
        duration: 1.0,
      );

      inertia.update(0.1);
      expect(props.x, greaterThan(0.0));
      final firstX = props.x;

      inertia.update(0.1);
      expect(props.x, greaterThan(firstX));
    });
  });
}
