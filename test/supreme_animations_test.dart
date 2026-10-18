import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations/supreme_animations.dart';

void main() {
  test('Supreme Animations primary facade smoke test', () {
    expect(supreme, isNotNull);
    expect(supreme.ticker, isNotNull);
    expect(supreme.globalTimeline, isNotNull);

    final target = {'x': 0.0};
    final tween =
        supreme.to(target, {'x': 100.0, 'duration': 1.0, 'paused': true});
    expect(tween, isA<SupremeTween>());

    final tl = supreme.timeline({'paused': true});
    expect(tl, isA<SupremeTimeline>());
  });

  test('Backward compatibility aliases (gsap, GsapTween, GsapTimeline)', () {
    // ignore: deprecated_member_use_from_same_package
    expect(gsap, same(supreme));
    final target = {'x': 0.0};
    // ignore: deprecated_member_use_from_same_package
    final GsapTween tween = gsap
        .to(target, {'x': 100.0, 'duration': 1.0, 'paused': true}) as GsapTween;
    expect(tween, isA<SupremeTween>());

    // ignore: deprecated_member_use_from_same_package
    final GsapTimeline tl = gsap.timeline({'paused': true});
    expect(tl, isA<SupremeTimeline>());
  });

  testWidgets('Live supreme.to animates over time with ticker',
      (WidgetTester tester) async {
    final target = {'x': 0.0};
    final tween =
        supreme.to(target, {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear})
            as SupremeTween;

    expect(target['x'], 0.0);

    supreme.ticker.tick(0.5);
    expect(target['x'], closeTo(50.0, 1e-4));

    supreme.ticker.tick(0.5);
    expect(target['x'], closeTo(100.0, 1e-4));

    tween.kill();
    supreme.ticker.sleep();
  });

  test(
      'Completed tweens leave the global timeline and quickTo does not stack speed',
      () {
    final target = {'x': 0.0};
    supreme.to(target, {'x': 100.0, 'duration': 1.0, 'ease': Ease.linear});
    supreme.ticker.tick(1.0);
    expect(target['x'], closeTo(100.0, 1e-4));
    expect(supreme.getTweensOf(target), isEmpty);

    final live = {'x': 0.0};
    final tween = supreme.to(live, {
      'x': 100.0,
      'duration': 1.0,
      'ease': Ease.linear,
    }) as SupremeTween;
    supreme.ticker.tick(0.25);
    tween.pause();
    supreme.ticker.tick(0.5);
    expect(live['x'], closeTo(25.0, 1e-4));
    expect(supreme.getTweensOf(live), isNotEmpty);
    tween.kill();
    supreme.ticker.tick(0.0);

    final quickTarget = {'x': 0.0};
    final quick =
        supreme.quickTo(quickTarget, 'x', duration: 1.0, ease: Ease.linear);
    quick(100.0);
    supreme.ticker.tick(0.5);
    expect(quickTarget['x'], closeTo(50.0, 1e-4));
    quick(100.0);
    supreme.ticker.tick(0.5);
    expect(quickTarget['x'], closeTo(75.0, 1e-4));

    supreme.killTweensOf(quickTarget);
    supreme.ticker.tick(0.0);
    supreme.ticker.sleep();
  });
}
