import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_animations_example/main.dart';

void main() {
  testWidgets('SupremeAnimationsExampleApp smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SupremeAnimationsExampleApp());
    expect(find.text('Supreme Animations Showcase'), findsOneWidget);
    expect(find.text('Tweens'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Timeline page reverse and restart gesture test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SupremeAnimationsExampleApp());
    // Tap on the Timeline tab
    await tester.tap(find.text('Timeline'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reverse'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);

    // Tap Reverse
    await tester.tap(find.text('Reverse'));
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Restart
    await tester.tap(find.text('Restart'));
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Reverse again at start
    await tester.tap(find.text('Reverse'));
    await tester.pump(const Duration(milliseconds: 50));

    // Clean up for test harness
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MotionPath page animation runs and moves flight icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SupremeAnimationsExampleApp());
    // Tap on the MotionPath tab
    await tester.tap(find.text('MotionPath'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.flight), findsOneWidget);

    // Get initial transform
    final transformFinder = find.byType(Transform);
    final initialTransform = tester.widget<Transform>(transformFinder.first);
    final initX = initialTransform.transform.getTranslation().x;
    final initY = initialTransform.transform.getTranslation().y;

    // Let 1 second pass
    await tester.pump(const Duration(milliseconds: 500));
    final midTransform = tester.widget<Transform>(transformFinder.first);
    final midX = midTransform.transform.getTranslation().x;
    final midY = midTransform.transform.getTranslation().y;

    await tester.pump(const Duration(milliseconds: 500));
    final afterTransform = tester.widget<Transform>(transformFinder.first);
    final afterX = afterTransform.transform.getTranslation().x;
    final afterY = afterTransform.transform.getTranslation().y;

    expect(
      midX != initX || midY != initY,
      isTrue,
      reason: 'Flight icon should move!',
    );
    expect(
      afterX != midX || afterY != midY,
      isTrue,
      reason: 'Flight icon should continue moving!',
    );

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'MotionPath page controls (path switching, pause, play) function properly',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SupremeAnimationsExampleApp());
      await tester.tap(find.text('MotionPath'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Curved'), findsOneWidget);
      expect(find.text('Loop'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);

      // Switch path to Loop
      await tester.tap(find.text('Loop'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Pause
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump(const Duration(milliseconds: 50));

      // Record position while paused
      final transformFinder = find.byType(Transform);
      final pausedPos = tester
          .widget<Transform>(transformFinder.first)
          .transform
          .getTranslation()
          .x;

      // Advance time - should stay paused
      await tester.pump(const Duration(milliseconds: 300));
      final stillPausedPos = tester
          .widget<Transform>(transformFinder.first)
          .transform
          .getTranslation()
          .x;
      expect(stillPausedPos, equals(pausedPos));

      // Tap Play
      await tester.tap(find.byTooltip('Play'));
      await tester.pump(const Duration(milliseconds: 200));
      final resumedPos = tester
          .widget<Transform>(transformFinder.first)
          .transform
          .getTranslation()
          .x;
      expect(resumedPos != pausedPos, isTrue);

      // Clean up
      await tester.pumpWidget(const SizedBox());
    },
  );
}
