import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations/supreme_animations.dart';

void main() {
  group('Fix 1: to() records start values lazily', () {
    test('chained to() on the same property animates from the previous end',
        () {
      final v = ValueNotifier<double>(1.0);
      final tl = supreme.timeline({'paused': true});
      tl.to(v, {'value': 0.0, 'duration': 1.0, 'ease': Ease.linear}).to(
          v, {'value': 1.0, 'duration': 1.0, 'ease': Ease.linear});

      tl.seek(0.5);
      expect(v.value, closeTo(0.5, 1e-6));
      tl.seek(1.0);
      expect(v.value, closeTo(0.0, 1e-6));
      tl.seek(1.5);
      expect(v.value, closeTo(0.5, 1e-6)); // was 1.0 (snapped)
      tl.seek(2.0);
      expect(v.value, closeTo(1.0, 1e-6));

      // Scrubbing back keeps the recorded start values.
      tl.seek(1.25);
      expect(v.value, closeTo(0.25, 1e-6));
      tl.seek(0.25);
      expect(v.value, closeTo(0.75, 1e-6));
      tl.kill();
    });

    test('to() records the value present when it starts, not when created', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        vars: {'x': 100.0},
        duration: 1.0,
        ease: Ease.linear,
        paused: true,
      );
      target['x'] = 50.0; // changed after creation, before playback
      tween.seek(0.5);
      expect(target['x'], closeTo(75.0, 1e-6));
    });

    test('a delayed to() does not write during its delay', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        vars: {'x': 100.0},
        duration: 1.0,
        delay: 1.0,
        ease: Ease.linear,
        paused: true,
      );
      tween.seek(0.5);
      target['x'] = 40.0; // someone else moves it during the delay
      tween.seek(0.9);
      expect(target['x'], 40.0);
      tween.seek(1.5);
      expect(target['x'], closeTo(70.0, 1e-6));
    });

    test('repeat, yoyo and restart reuse the recorded start values', () {
      final target = {'x': 10.0};
      final tween = SupremeTween(
        target: target,
        vars: {'x': 20.0},
        duration: 1.0,
        repeat: 1,
        yoyo: true,
        ease: Ease.linear,
        paused: true,
      );
      tween.seek(0.5);
      expect(target['x'], closeTo(15.0, 1e-6));
      tween.seek(1.0);
      expect(target['x'], closeTo(20.0, 1e-6));
      tween.seek(1.5); // yoyo leg
      expect(target['x'], closeTo(15.0, 1e-6));
      tween.seek(2.0);
      expect(target['x'], closeTo(10.0, 1e-6));
      tween.restart();
      tween.pause();
      tween.seek(0.5);
      expect(target['x'], closeTo(15.0, 1e-6));
    });

    test('chained to() plays correctly on the ticker, including repeats', () {
      final v = ValueNotifier<double>(1.0);
      final tl = supreme.timeline({'repeat': 1});
      tl.to(v, {'value': 0.0, 'duration': 1.0, 'ease': Ease.linear}).to(
          v, {'value': 1.0, 'duration': 1.0, 'ease': Ease.linear});
      final samples = <double>[];
      for (var i = 0; i < 16; i++) {
        supreme.ticker.tick(0.25);
        samples.add(v.value);
      }
      // 0.75 0.5 0.25 0 | 0.25 0.5 0.75 1 | repeat
      expect(samples[5], closeTo(0.5, 1e-6));
      expect(samples[9], closeTo(0.5, 1e-6));
      expect(samples[13], closeTo(0.5, 1e-6));
      expect(samples.last, closeTo(1.0, 1e-6));
      tl.kill();
    });

    test('invalidate() re-records start values on the next render', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        vars: {'x': 100.0},
        duration: 1.0,
        ease: Ease.linear,
        paused: true,
      );
      tween.seek(1.0);
      expect(target['x'], 100.0);
      target['x'] = 50.0;
      tween.invalidate();
      tween.seek(0.5);
      expect(target['x'], closeTo(75.0, 1e-6));
    });
  });

  group('Fix 2: keyframe durations', () {
    test('total is the sum of step durations when no duration is given', () {
      final target = {'x': 0.0};
      final tween = supreme.to(target, {
        'keyframes': [
          {'x': 10.0, 'duration': 1.0, 'ease': Ease.linear},
          {'x': 30.0, 'duration': 2.0, 'ease': Ease.linear},
        ],
        'paused': true,
      });
      expect(tween.duration(), closeTo(3.0, 1e-9)); // was 0.5
      tween.seek(0.5);
      expect(target['x'], closeTo(5.0, 1e-6));
      tween.seek(2.0);
      expect(target['x'], closeTo(20.0, 1e-6));
      tween.kill();
    });

    test('timeline default duration does not override step durations', () {
      final target = {'x': 0.0};
      final tl = supreme.timeline({
        'paused': true,
        'defaults': {'duration': 0.3},
      });
      tl.to(target, {
        'keyframes': [
          {'x': 10.0, 'duration': 1.0},
          {'x': 0.0, 'duration': 1.0},
        ],
      });
      expect(tl.duration(), closeTo(2.0, 1e-9)); // was 0.3
      tl.kill();
    });

    test('step delays add hold time to the total', () {
      final target = {'x': 0.0};
      final tween = supreme.to(target, {
        'keyframes': [
          {'x': 10.0, 'duration': 1.0, 'ease': Ease.linear},
          {'x': 20.0, 'duration': 1.0, 'delay': 1.0, 'ease': Ease.linear},
        ],
        'paused': true,
      });
      expect(tween.duration(), closeTo(3.0, 1e-9));
      tween.seek(1.5); // holding
      expect(target['x'], closeTo(10.0, 1e-6));
      tween.seek(2.5);
      expect(target['x'], closeTo(15.0, 1e-6));
      tween.kill();
    });

    test('explicit duration scales the steps to fit (legacy behaviour)', () {
      final target = {'x': 0.0};
      final tween = supreme.to(target, {
        'keyframes': [
          {'x': 10.0, 'duration': 1.0, 'ease': Ease.linear},
          {'x': 30.0, 'duration': 3.0, 'ease': Ease.linear},
        ],
        'duration': 2.0,
        'paused': true,
      });
      expect(tween.duration(), 2.0);
      tween.seek(0.5); // end of step 1 (1/4 of 2s)
      expect(target['x'], closeTo(10.0, 1e-6));
      tween.kill();
    });

    test('steps without a duration share the remainder of an explicit total',
        () {
      final target = {'x': 0.0};
      final tween = supreme.to(target, {
        'keyframes': [
          {'x': 10.0, 'duration': 1.0, 'ease': Ease.linear},
          {'x': 20.0, 'ease': Ease.linear},
          {'x': 30.0, 'ease': Ease.linear},
        ],
        'duration': 3.0,
        'paused': true,
      });
      tween.seek(1.0);
      expect(target['x'], closeTo(10.0, 1e-6));
      tween.seek(2.0);
      expect(target['x'], closeTo(20.0, 1e-6));
      tween.kill();
    });

    test('steps without any duration keep the old default total', () {
      final target = {'x': 0.0};
      final tween = supreme.to(target, {
        'keyframes': [
          {'x': 10.0},
          {'x': 20.0},
        ],
        'paused': true,
      });
      expect(tween.duration(), closeTo(0.5, 1e-9));
      tween.kill();
    });
  });

  group('Fix 3: fromTo/from immediateRender', () {
    test('fromTo placed later in a timeline does not render at creation', () {
      final target = {'x': 5.0, 'y': 5.0};
      final tl = supreme.timeline({'paused': true});
      tl.to(target, {'x': 10.0, 'duration': 1.0, 'ease': Ease.linear});
      tl.fromTo(target, {'y': 100.0}, {'y': 200.0, 'duration': 1.0});
      expect(target['y'], 5.0); // was 100.0
      tl.seek(0.5);
      expect(target['y'], 5.0);
      tl.seek(1.0);
      expect(target['y'], closeTo(100.0, 1e-6));
      tl.kill();
    });

    test('paused standalone fromTo does not render at creation', () {
      final target = {'x': 5.0};
      final t =
          supreme.fromTo(target, {'x': 100.0}, {'x': 200.0}, paused: true);
      expect(target['x'], 5.0); // was 100.0
      t.seek(0.0);
      expect(target['x'], 100.0);
      t.kill();
    });

    test('playing standalone fromTo and from still render immediately', () {
      final a = {'x': 5.0};
      final b = {'x': 5.0};
      final t1 = supreme.fromTo(a, {'x': 100.0}, {'x': 200.0});
      final t2 = supreme.from(b, {'x': 50.0});
      expect(a['x'], 100.0);
      expect(b['x'], 50.0);
      t1.kill();
      t2.kill();
    });

    test('immediateRender can be forced either way', () {
      final a = {'x': 5.0};
      final b = {'x': 5.0};
      final t1 = supreme
          .fromTo(a, {'x': 100.0}, {'x': 200.0, 'immediateRender': false});
      final t2 = supreme.fromTo(
          b, {'x': 100.0}, {'x': 200.0, 'immediateRender': true},
          paused: true);
      expect(a['x'], 5.0);
      expect(b['x'], 100.0);
      t1.kill();
      t2.kill();
    });

    test('staggered paused fromTo groups do not render at creation', () {
      final items = List.generate(3, (_) => TransformProps());
      final g = supreme.fromTo(
          items,
          {'opacity': 0.0},
          {
            'opacity': 1.0,
            'stagger': 0.1,
          },
          paused: true);
      for (final p in items) {
        expect(p.opacity, 1.0);
      }
      g.kill();
    });

    test('later timeline set() waits for the playhead', () {
      final target = {'x': 0.0, 'y': 0.0};
      final tl = supreme.timeline({'paused': true});
      tl.to(target, {'x': 1.0, 'duration': 1.0});
      tl.set(target, {'y': 99.0});
      expect(target['y'], 0.0); // was 99.0
      tl.seek(1.0);
      expect(target['y'], 99.0);
      tl.kill();
    });
  });

  group('Review follow-ups', () {
    test('duration() re-renders a tween that rendered immediately', () {
      final a = {'x': 5.0};
      final t = SupremeTween(
        target: a,
        type: TweenType.from,
        vars: {'x': 50.0},
        duration: 1.0,
        paused: true,
      );
      expect(a['x'], 50.0);
      t.duration(0.0); // zero length: shows the end state, as in 1.0.0
      expect(a['x'], 5.0);
    });

    test('duration() still does not render a fresh to() or timeline', () {
      final a = {'x': 0.0};
      final t = SupremeTween(
          target: a, vars: {'x': 10.0}, duration: 1.0, paused: true);
      t.duration(0.0);
      a['x'] = 3.0;
      t.seek(0.0);
      expect(a['x'], 10.0); // start recorded at first render (3 -> 10, 0s)
      final b = {'y': 0.0};
      final tl = supreme.timeline({'paused': true});
      tl.to(b, {'y': 1.0, 'duration': 1.0, 'ease': Ease.linear});
      b['y'] = 0.5;
      tl.seek(0.5);
      expect(b['y'], closeTo(0.75, 1e-6));
      tl.kill();
    });

    test('delayed immediateRender from/fromTo show their from-state at once',
        () {
      final a = {'x': 5.0};
      final b = {'x': 5.0};
      final c = {'x': 5.0};
      final t1 = supreme.from(a, {'x': 50.0, 'delay': 1.0});
      final t2 = supreme.fromTo(b, {'x': 100.0}, {'x': 200.0, 'delay': 1.0});
      final tl = supreme.timeline({'paused': true});
      tl.to({'y': 0.0}, {'y': 1.0, 'duration': 1.0});
      tl.fromTo(
          c, {'x': 70.0}, {'x': 80.0, 'delay': 0.5, 'immediateRender': true});
      expect(a['x'], 50.0);
      expect(b['x'], 100.0);
      expect(c['x'], 70.0);
      supreme.ticker.tick(0.5); // still inside the delay
      expect(a['x'], 50.0);
      expect(b['x'], 100.0);
      t1.kill();
      t2.kill();
      tl.kill();
    });
  });

  group('Fix 4: fromTo with keyframes', () {
    test('from values are the start of the first keyframe', () {
      final target = {'x': 0.0};
      final t = supreme.fromTo(target, {
        'x': 100.0
      }, {
        'keyframes': [
          {'x': 200.0, 'duration': 1.0, 'ease': Ease.linear},
          {'x': 300.0, 'duration': 1.0, 'ease': Ease.linear},
        ],
        'paused': true,
      });
      t.seek(0.0);
      expect(target['x'], 100.0); // was 0.0
      t.seek(0.5);
      expect(target['x'], closeTo(150.0, 1e-6)); // was 100.0
      t.seek(1.5);
      expect(target['x'], closeTo(250.0, 1e-6));
      t.kill();
    });
  });

  group('Fix 6: SupremeContext stays bounded', () {
    test('finished tweens are not held strongly', () {
      final ctx = SupremeContext();
      for (var i = 0; i < 500; i++) {
        ctx.run((_) => supreme.to({'x': 0.0}, {'x': 1.0, 'duration': 0.01}));
        supreme.ticker.tick(0.02); // completes it
      }
      ctx.sweep();
      expect(ctx.trackedCount, 0);
      expect(ctx.trackedCount + ctx.finishedCount, lessThanOrEqualTo(500));
      ctx.revert();
    });

    test('tracked count stays bounded while a live loop keeps running', () {
      final ctx = SupremeContext();
      final loop =
          ctx.run((_) => supreme.to({'x': 0.0}, {'x': 1.0, 'repeat': -1}));
      var maxTracked = 0;
      for (var i = 0; i < 500; i++) {
        ctx.run((_) => supreme.to({'x': 0.0}, {'x': 1.0, 'duration': 0.01}));
        supreme.ticker.tick(0.02);
        if (ctx.trackedCount > maxTracked) maxTracked = ctx.trackedCount;
      }
      expect(maxTracked, lessThan(40)); // was 501
      ctx.revert();
      expect(loop.isKilled(), isTrue);
    });

    test('revert still kills a finished tween the caller restarts', () {
      final ctx = SupremeContext();
      final t =
          ctx.run((_) => supreme.to({'x': 0.0}, {'x': 1.0, 'duration': 0.01}));
      supreme.ticker.tick(0.02);
      for (var i = 0; i < 40; i++) {
        ctx.run((_) => supreme.to({'x': 0.0}, {'x': 1.0, 'duration': 0.01}));
        supreme.ticker.tick(0.02);
      }
      ctx.sweep();
      t.restart();
      expect(t.isActive(), isTrue);
      ctx.revert();
      expect(t.isKilled(), isTrue);
    });

    test('paused tweens added to a timeline do not pile up', () {
      final ctx = SupremeContext();
      for (var i = 0; i < 200; i++) {
        ctx.run((_) {
          final tl = supreme.timeline();
          tl.add(supreme
              .to({'x': 0.0}, {'x': 1.0, 'duration': 0.01}, paused: true));
        });
        supreme.ticker.tick(0.02);
      }
      ctx.sweep();
      expect(ctx.trackedCount, 0);
      ctx.revert();
    });
  });

  group('Fix 7: TextPlugin joins the active context', () {
    test('context revert kills typewriter and scramble tweens', () {
      final a = ValueNotifier<String>('');
      final b = ValueNotifier<String>('');
      final ctx = SupremeContext();
      late SupremeTween t1, t2;
      ctx.run((_) {
        t1 = TextPlugin.typewriter(a, 'Hello', duration: 1.0);
        t2 = TextPlugin.scramble(b, 'World', duration: 1.0);
      });
      supreme.ticker.tick(0.2);
      ctx.revert();
      expect(t1.isKilled(), isTrue);
      expect(t2.isKilled(), isTrue);
      final before = a.value;
      supreme.ticker.tick(0.5);
      expect(a.value, before);
    });

    test('paused text tweens can be placed in a timeline', () {
      final a = ValueNotifier<String>('');
      final t = TextPlugin.typewriter(a, 'abcd', duration: 1.0, paused: true);
      final tl = supreme.timeline({'paused': true});
      tl.add(t, 1.0);
      tl.seek(1.5);
      expect(a.value, 'ab');
      tl.kill();
    });

    testWidgets('SupremeStateMixin kills text tweens on dispose',
        (tester) async {
      final caption = ValueNotifier<String>('');
      final key = GlobalKey<_TypingState>();
      await tester.pumpWidget(_Typing(key: key, caption: caption));
      key.currentState!.type('Hello there');
      await tester.pump(const Duration(milliseconds: 100));
      final tween = key.currentState!.tween!;
      await tester.pumpWidget(const SizedBox());
      expect(tween.isKilled(), isTrue);
    });
  });
}

class _Typing extends StatefulWidget {
  const _Typing({super.key, required this.caption});
  final ValueNotifier<String> caption;
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SupremeStateMixin<_Typing> {
  SupremeTween? tween;
  void type(String text) {
    tween = supremeRun(() => TextPlugin.typewriter(widget.caption, text));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
