// Every ```dart block in README.md is mirrored here, so `flutter analyze`
// type-checks the README samples against the real API and the test below
// fails when the README and this file drift apart.
//
// When you edit a README sample, paste the same code here (indentation does
// not matter).
// ignore_for_file: unused_local_variable, avoid_print

// dart format off
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations/supreme_animations.dart';

// Stand-ins for the app widgets and state the README refers to.
class MyCard extends StatelessWidget {
  const MyCard({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class FeaturedProductCard extends MyCard {
  const FeaturedProductCard({super.key});
}

class FloatingActionCard extends MyCard {
  const FloatingActionCard({super.key});
}

final headerProps = TransformProps();
final cardProps = TransformProps();
final btn1Props = TransformProps();
final btn2Props = TransformProps();
final planeProps = TransformProps();
final props = TransformProps();

void readmeBasicTweening() {
  final props = TransformProps();

  // Tween TO destination values
  supreme.to(props, {
    'x': 100.0,
    'rotation': 3.14159,
    'scale': 1.5,
    'duration': 1.2,
    'ease': Ease.elastic.out,
    'repeat': -1,
    'yoyo': true,
  });

  // Bind to widget
  final card = SupremeWidget(
    transform: props,
    child: MyCard(),
  );
}

Widget readmeSupremeVars() =>
    MyCard().supreme(
      to: SupremeVars(
        x: 100,
        rotationDeg: 180,
        scale: 1.2,
        duration: 1.0,
        ease: Ease.back.out,
      ),
    );

void readmeTimeline() {
  final tl = supreme.timeline({
    'defaults': {'duration': 0.8, 'ease': Ease.power2.out},
  });

  tl.to(headerProps, {'y': 0.0, 'opacity': 1.0})
    .to(cardProps, {'scale': 1.0, 'opacity': 1.0}, '<0.2') // Starts 0.2s after header starts
    .addLabel('buttons')
    .to(btn1Props, {'x': 0.0}, 'buttons')
    .to(btn2Props, {'x': 0.0}, 'buttons+=0.1');

  // Playback controls
  tl.pause();
  tl.resume();
  tl.reverse();
  tl.seek(1.5);
  tl.timeScale(2.0); // 2x playback speed
}

void readmeGridStagger() {
  final List<TransformProps> items = List.generate(16, (_) => TransformProps());

  supreme.fromTo(
    items,
    {'scale': 0.0, 'opacity': 0.0},
    {
      'scale': 1.0,
      'opacity': 1.0,
      'duration': 0.6,
      'ease': Ease.back.out,
      'stagger': {
        'amount': 0.8,
        'from': 'center',
        'grid': [4, 4],
      },
    },
  );
}

Widget readmeScrollTrigger() =>
    ScrollTriggerScope(
      child: ScrollTriggerMarkersOverlay(
        child: ListView(
          children: [
            ScrollTriggerWidget(
              start: 'top 80%',
              end: 'center 30%',
              scrub: 1.0, // 1-second lag smoothed scrub
              markers: true, // Display visual debug markers
              from: {
                'y': 100.0,
                'scale': 0.7,
                'opacity': 0.0,
              },
              child: FeaturedProductCard(),
            ),
          ],
        ),
      ),
    );

class FlipDemo extends StatefulWidget {
  const FlipDemo({super.key});
  @override
  State<FlipDemo> createState() => _FlipDemoState();
}

class _FlipDemoState extends State<FlipDemo> {
  final cardKeys = List.generate(4, (_) => GlobalKey());
  late final cardProps = {for (final k in cardKeys) k: TransformProps()};
  bool isGrid = true;

  void toggleLayout() {
    // 1. Record geometry
    final state = Flip.getState(cardKeys);

    // 2. Change state (e.g. grid to list)
    setState(() {
      isGrid = !isGrid;
    });

    // 3. Smoothly animate between disparate layout states
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flip.from(
        state,
        transformPropsMap: cardProps,
        duration: 0.6,
        ease: Ease.power3.out,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class TextDemo extends StatefulWidget {
  const TextDemo({super.key});
  @override
  State<TextDemo> createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> with SupremeStateMixin<TextDemo> {
  void readmeText() {
    // Typewriter
    final titleNotifier = ValueNotifier<String>('');
    TextPlugin.typewriter(titleNotifier, 'Welcome to Supreme Animations!', duration: 2.0);

    // Scramble text
    final codeNotifier = ValueNotifier<String>('XXXXXXXX');
    TextPlugin.scramble(codeNotifier, 'SECRET_KEY', duration: 1.5);

    // SplitText staggered character reveal
    final title = SplitTextWidget(
      text: 'HOLLYWOOD GRADE',
      type: SplitType.chars,
      stagger: 0.04,
      duration: 0.8,
      from: {'y': 50.0, 'opacity': 0.0},
    );

    supremeRun(() => TextPlugin.typewriter(titleNotifier, 'Hello!'));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void readmeMotionPath() {
  final path = MotionPath.curved([
    const Offset(0, 0),
    const Offset(150, 80),
    const Offset(300, 20),
  ]);

  final tween = MotionPathTween(
    target: planeProps,
    path: path,
    autoRotate: true,
    duration: 3.0,
    ease: Ease.power2.inOut,
  );
}

Widget readmeDraggable() =>
    SupremeDraggable(
      inertia: true, // Decelerates with physics momentum
      bounds: const Rect.fromLTWH(-100, -100, 200, 200),
      snapStep: const Offset(50, 50), // Optional grid snapping
      child: FloatingActionCard(),
    );

void readmeEasing() {
  supreme.to(props, {'x': 100.0, 'ease': Ease.power2.inOut});
  supreme.to(props, {'x': 100.0, 'ease': Ease.back.out}); // default overshoot
  supreme.to(props, {'x': 100.0, 'ease': Ease.back(2.5)}); // custom overshoot
  supreme.to(props, {'x': 100.0, 'ease': Ease.back.customInOut(1.2)});
  supreme.to(props, {
    'x': 100.0,
    'ease': Ease.elastic.customOut(amplitude: 1.2, period: 0.4),
  });
  supreme.to(props, {'x': 100.0, 'ease': Ease.bounce.out});
  supreme.to(props, {'x': 100.0, 'ease': Ease.steps(5)});
  supreme.to(props, {'x': 100.0, 'ease': CubicBezier(0.68, -0.55, 0.27, 1.55)});
  supreme.to(props, {'x': 100.0, 'ease': RoughEase(points: 20, strength: 1.5)});
  supreme.to(props, {'x': 100.0, 'ease': SlowMo(linearRatio: 0.5, power: 0.7)});
  supreme.to(props, {'x': 100.0, 'ease': 'power3.out'}); // strings work too
}

void readmeKeyframes() {
  supreme.to(props, {
    'keyframes': [
      {'y': -40.0, 'duration': 0.3, 'ease': Ease.power2.out},
      {'y': 0.0, 'duration': 0.5, 'ease': Ease.bounce.out},
      {'scale': 1.2, 'duration': 0.2, 'delay': 0.4}, // holds 0.4s first
    ],
  }); // lasts 0.3 + 0.5 + 0.4 + 0.2 = 1.4s
}

void readmeStartValues() {
  final tl = supreme.timeline();
  tl.to(props, {'x': 100.0}).to(props, {'x': 0.0}); // 0 -> 100 -> 0

  supreme.fromTo(props, {'opacity': 0.0}, {'opacity': 1.0, 'immediateRender': false});
  tl.from(props, {'y': 40.0, 'immediateRender': true}, 1.0);
}

class PulseCard extends StatefulWidget {
  const PulseCard({super.key});
  @override
  State<PulseCard> createState() => _PulseCardState();
}

class _PulseCardState extends State<PulseCard>
    with SupremeStateMixin<PulseCard> {
  final props = TransformProps();

  @override
  void initState() {
    super.initState();
    supremeTo(props, {'y': -6.0, 'repeat': -1, 'yoyo': true});
  }

  void celebrate() {
    // Everything created inside supremeRun is killed on dispose.
    supremeRun(() {
      supreme.timeline().to(props, {'scale': 1.2}).to(props, {'scale': 1.0});
    });
  }

  @override
  Widget build(BuildContext context) =>
      SupremeWidget(transform: props, child: const SizedBox());
}

String _normalize(String code) => code
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .join('\n');

void main() {
  test('every README dart sample is mirrored in this file', () {
    final readme = File('README.md').readAsStringSync();
    final mirror = _normalize(
        File('test/readme_snippets_test.dart').readAsStringSync());
    final blocks = RegExp(r'```dart\n([\s\S]*?)```')
        .allMatches(readme)
        .map((m) => m.group(1)!)
        .toList();
    expect(blocks, isNotEmpty);
    for (final block in blocks) {
      expect(mirror.contains(_normalize(block)), isTrue,
          reason: 'README sample not mirrored (or changed):\n$block');
    }
  });

  test('the non-widget README samples run without throwing', () {
    readmeBasicTweening();
    readmeTimeline();
    readmeGridStagger();
    readmeMotionPath();
    readmeEasing();
    readmeKeyframes();
    readmeStartValues();
    for (var i = 0; i < 30; i++) {
      supreme.ticker.tick(0.1);
    }
    for (final t in [headerProps, cardProps, btn1Props, btn2Props, props]) {
      supreme.killTweensOf(t);
    }
    supreme.globalTimeline.clear();
  });

  testWidgets('the widget README samples build', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          SizedBox(height: 100, child: readmeScrollTrigger()),
          readmeSupremeVars(),
          readmeDraggable(),
          const PulseCard(),
          const TextDemo(),
          const FlipDemo(),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
  });
}
