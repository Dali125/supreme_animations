import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations/supreme_animations.dart';

void main() {
  group('SupremeTween Core Tests', () {
    test('Tween to interpolates numeric values correctly', () {
      final target = {'x': 0.0, 'y': 10.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': 100.0, 'y': 50.0},
        paused: true,
      );

      expect(target['x'], 0.0);
      expect(target['y'], 10.0);

      tween.seek(0.5);
      expect(target['x'], closeTo(50.0, 1e-4));
      expect(target['y'], closeTo(30.0, 1e-4));

      tween.seek(1.0);
      expect(target['x'], closeTo(100.0, 1e-4));
      expect(target['y'], closeTo(50.0, 1e-4));
    });

    test('Tween handles relative values (+=, -=, *=, /=)', () {
      final target = {'x': 100.0, 'y': 50.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': '+=50', 'y': '-=20'},
        paused: true,
      );

      tween.seek(1.0);
      expect(target['x'], closeTo(150.0, 1e-4));
      expect(target['y'], closeTo(30.0, 1e-4));
    });

    test(
        'Tween from sets initial value immediately and animates back to current',
        () {
      final target = {'x': 100.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.from,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': 0.0},
        paused: true,
      );

      // Should be set to from value immediately
      expect(target['x'], 0.0);

      tween.seek(0.5);
      expect(target['x'], closeTo(50.0, 1e-4));

      tween.seek(1.0);
      expect(target['x'], closeTo(100.0, 1e-4));
    });

    test('Tween fromTo explicitly sets start and end values', () {
      final target = {'x': 25.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.fromTo,
        duration: 1.0,
        ease: Ease.linear,
        fromVars: {'x': 200.0},
        vars: {'x': 500.0},
        paused: true,
      );

      expect(target['x'], 200.0);

      tween.seek(0.5);
      expect(target['x'], closeTo(350.0, 1e-4));

      tween.seek(1.0);
      expect(target['x'], closeTo(500.0, 1e-4));
    });

    test('Tween set updates property immediately with 0 duration', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.set,
        vars: {'x': 99.0},
      );

      expect(tween.durationVal, 0.0);
      expect(target['x'], 99.0);
    });

    test('Tween keyframes sequence multiple intermediate steps', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 2.0,
        ease: Ease.linear,
        vars: {
          'keyframes': [
            {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear},
            {'x': 300.0, 'duration': 1.0, 'ease': Ease.linear},
          ]
        },
        paused: true,
      );

      tween.seek(0.5);
      expect(target['x'], closeTo(50.0, 1e-4));

      tween.seek(1.0);
      expect(target['x'], closeTo(100.0, 1e-4));

      tween.seek(1.5);
      expect(target['x'], closeTo(200.0, 1e-4));

      tween.seek(2.0);
      expect(target['x'], closeTo(300.0, 1e-4));
    });

    test('Keyframe seek does not depend on the previous playhead', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 2.0,
        ease: Ease.linear,
        vars: {
          'keyframes': [
            {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear},
            {'x': 300.0, 'duration': 1.0, 'ease': Ease.linear},
          ]
        },
        paused: true,
      );

      tween.seek(1.5);
      expect(target['x'], closeTo(200.0, 1e-4));

      tween.seek(0.5);
      expect(target['x'], closeTo(50.0, 1e-4));
    });

    test('from() keeps onStart for the first real render', () {
      var starts = 0;
      final target = {'x': 100.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.from,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': 0.0},
        paused: true,
        onStart: () => starts++,
      );

      expect(target['x'], 0.0);
      expect(starts, 0);

      tween.seek(0.25);
      expect(starts, 1);
      tween.seek(0.75);
      expect(starts, 1);
    });

    test('yoyoEase is used on the return cycle while playing forward', () {
      final target = {'x': 0.0};
      final jump = Ease((double t) => t <= 0.0 ? 0.0 : 1.0);
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        yoyo: true,
        yoyoEase: jump,
        repeat: 1,
        vars: {'x': 100.0},
        paused: true,
      );

      tween.seek(1.5);
      expect(target['x'], closeTo(100.0, 1e-4));
    });

    test('Tween modifiers modify values on each tick (snap, clamp, wrap)', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {
          'x': 100.0,
          'modifiers': {
            'x': SupremeModifiers.snap(20.0),
          }
        },
        paused: true,
      );

      tween.seek(0.12);
      expect(target['x'], 20.0);

      tween.seek(0.53);
      expect(target['x'], 60.0);
    });

    test('Tween repeat and yoyo behavior', () {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        ease: Ease.linear,
        vars: {'x': 100.0},
        repeat: 1,
        yoyo: true,
        paused: true,
      );

      expect(tween.totalDuration(), 2.0);

      tween.seek(0.5);
      expect(target['x'], closeTo(50.0, 1e-4));

      tween.seek(1.0);
      expect(target['x'], closeTo(100.0, 1e-4));

      // Yoyo second cycle reverses back to 0
      tween.seek(1.5);
      expect(target['x'], closeTo(50.0, 1e-4));

      tween.seek(2.0);
      expect(target['x'], closeTo(0.0, 1e-4));
    });

    test('Tween event callbacks trigger at appropriate times', () {
      bool started = false;
      bool completed = false;
      int updateCount = 0;

      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 1.0,
        vars: {'x': 100.0},
        onStart: () => started = true,
        onUpdate: () => updateCount++,
        onComplete: () => completed = true,
      );

      tween.update(0.1);
      expect(started, isTrue);
      expect(updateCount, greaterThan(0));
      expect(completed, isFalse);

      tween.update(1.0);
      expect(completed, isTrue);
    });

    test('Tween then / awaitable completion', () async {
      final target = {'x': 0.0};
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 0.1,
        vars: {'x': 100.0},
      );

      bool awaited = false;
      final future = tween.then((_) {
        awaited = true;
      });

      tween.update(0.2);
      await future;
      expect(awaited, isTrue);
    });
  });

  group('SupremeTimeline Sequencer Tests', () {
    test('Timeline sequences child animations with position parameter', () {
      final target1 = {'x': 0.0};
      final target2 = {'y': 0.0};

      final tl = SupremeTimeline(paused: true);
      tl.to(target1, {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear});
      // Start 0.5s after previous ends
      tl.to(
          target2, {'y': 50.0, 'duration': 1.0, 'ease': Ease.linear}, '+=0.5');

      expect(tl.durationVal, 2.5);

      tl.seek(0.5);
      expect(target1['x'], closeTo(50.0, 1e-4));
      expect(target2['y'], 0.0);

      tl.seek(1.0);
      expect(target1['x'], closeTo(100.0, 1e-4));
      expect(target2['y'], 0.0); // target2 starts at 1.5

      tl.seek(2.0);
      expect(target1['x'], closeTo(100.0, 1e-4));
      expect(target2['y'], closeTo(25.0, 1e-4));

      tl.seek(2.5);
      expect(target2['y'], closeTo(50.0, 1e-4));
    });

    test('Timeline supports "<" (start of previous) and labels', () {
      final target1 = {'x': 0.0};
      final target2 = {'y': 0.0};
      final target3 = {'z': 0.0};

      final tl = SupremeTimeline(paused: true);
      tl.to(target1, {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear});
      expect(tl.parsePosition('<'), 0.0);

      tl.addLabel('myMark');
      // Starts at same time as target1
      tl.to(target2, {'y': 50.0, 'duration': 1.0, 'ease': Ease.linear}, '<');
      // Starts 0.2s after label myMark
      tl.to(target3, {'z': 30.0, 'duration': 1.0, 'ease': Ease.linear},
          'myMark+=0.2');

      expect(tl.parsePosition('myMark'), 1.0);
      expect(tl.parsePosition('myMark+=0.2'), 1.2);
    });

    test('+= is relative to the timeline end, and call() fires once', () {
      final a = {'x': 0.0};
      final b = {'x': 0.0};
      final c = {'x': 0.0};
      var calls = 0;

      final tl = SupremeTimeline(paused: true);
      tl.to(a, {'x': 10.0, 'duration': 2.0, 'ease': Ease.linear});
      tl.to(b, {'x': 10.0, 'duration': 0.5, 'ease': Ease.linear}, '<');
      tl.to(c, {'x': 10.0, 'duration': 1.0, 'ease': Ease.linear}, '+=0.5');
      tl.call(() => calls++);

      expect(tl.durationVal, closeTo(3.5, 1e-4));

      tl.seek(2.4);
      expect(c['x'], 0.0);
      expect(calls, 0);

      tl.seek(3.0);
      expect(c['x'], closeTo(5.0, 1e-4));
      expect(calls, 0);

      tl.seek(3.5);
      expect(c['x'], closeTo(10.0, 1e-4));
      expect(calls, 1);

      tl.seek(3.5);
      expect(calls, 1);

      tl.seek(0.0);
      tl.seek(3.5);
      expect(calls, 2);
    });

    test('Timeline inherits defaults', () {
      final target = {'x': 0.0};
      final tl = SupremeTimeline(
        defaults: {'duration': 2.5, 'ease': Ease.linear},
        paused: true,
      );

      tl.to(target, {'x': 100.0});
      expect(tl.children.first.durationVal, 2.5);
    });

    test('Nested timelines scrub and seek transparently', () {
      final childTl = SupremeTimeline(paused: true);
      final target = {'x': 0.0};
      childTl.to(target, {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear});

      final parentTl = SupremeTimeline(paused: true);
      parentTl.add(childTl, 2.0);

      expect(parentTl.durationVal, 3.0);

      parentTl.seek(2.5);
      expect(target['x'], closeTo(50.0, 1e-4));

      parentTl.seek(3.0);
      expect(target['x'], closeTo(100.0, 1e-4));
    });

    test(
        'Infinite repeating timeline and tween can be reversed at time 0 without throwing NaN/Infinity',
        () {
      final target = {'x': 0.0};
      final tl = SupremeTimeline(
        repeat: -1,
        repeatDelay: 0.5,
        yoyo: true,
        paused: true,
      );
      tl.to(target, {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear});

      expect(tl.totalDuration(), double.infinity);
      // Reversing at time 0 must not throw Unsupported operation: Infinity or NaN toInt
      expect(() => tl.reverse(), returnsNormally);
      expect(tl.reversed(), isTrue);

      // Seek with infinity or NaN should also be handled gracefully
      expect(() => tl.seek(double.infinity), returnsNormally);
      expect(() => tl.seek(double.nan), returnsNormally);

      // Infinite tween
      final tween = SupremeTween(
        target: target,
        type: TweenType.to,
        duration: 2.0,
        repeat: -1,
        vars: {'x': 50.0},
        paused: true,
      );
      expect(() => tween.reverse(), returnsNormally);
      expect(tween.reversed(), isTrue);
    });
  });

  group('Stagger Coordination Tests', () {
    test('1D Stagger calculates linear delays from start and center', () {
      const staggerStart = Stagger.each(0.1, from: StaggerFrom.start);
      final delaysStart = staggerStart.calculateDelays(4);
      expect(delaysStart,
          [0.0, closeTo(0.1, 1e-4), closeTo(0.2, 1e-4), closeTo(0.3, 1e-4)]);

      const staggerCenter = Stagger.amount(1.0, from: StaggerFrom.center);
      final delaysCenter = staggerCenter.calculateDelays(3);
      // Items: 0, 1, 2. Center is 1. Item 1 delay = 0, items 0 and 2 = 1.0
      expect(delaysCenter[1], 0.0);
      expect(delaysCenter[0], closeTo(1.0, 1e-4));
      expect(delaysCenter[2], closeTo(1.0, 1e-4));
    });

    test('2D Grid Stagger computes 2D coordinates and distances', () {
      const gridStagger =
          Stagger.each(0.1, grid: [2, 2], from: StaggerFrom.start);
      final delays = gridStagger.calculateDelays(4);
      expect(delays[0], 0.0); // (0,0)
      expect(delays[1], closeTo(0.1, 1e-4));
      expect(delays[3], closeTo(0.1 * math.sqrt2, 1e-3));
    });
  });

  group('Stagger playback', () {
    test('stagger offsets each target once and honors paused', () {
      final targets = [
        {'x': 0.0},
        {'x': 0.0},
      ];

      final tl = supreme.to(targets, {
        'x': 100.0,
        'duration': 1.0,
        'ease': Ease.linear,
        'stagger': 0.5,
        'paused': true,
      }) as SupremeTimeline;

      expect(tl.durationVal, closeTo(1.5, 1e-4));

      supreme.ticker.tick(1.0);
      expect(targets[0]['x'], 0.0);
      expect(targets[1]['x'], 0.0);

      tl.seek(0.5);
      expect(targets[0]['x'], closeTo(50.0, 1e-4));
      expect(targets[1]['x'], 0.0);

      tl.seek(1.0);
      expect(targets[0]['x'], closeTo(100.0, 1e-4));
      expect(targets[1]['x'], closeTo(50.0, 1e-4));

      tl.kill();
      supreme.ticker.sleep();
    });
  });
}
