## 1.0.0

* Initial release of Supreme Animations for Flutter.
* Core engine: `supreme.to()`, `supreme.from()`, `supreme.fromTo()`, `supreme.set()`.
* High-precision frame loop with `SupremeTicker` synced to Flutter's `SchedulerBinding`.
* Sequencing with `SupremeTimeline`, relative position parameters (`<`, `>`, `+=`, `-=`), and labels.
* Full suite of standard and configurable physics easings (`Ease.back`, `Ease.elastic`, `Ease.bounce`, `Ease.steps`, `CubicBezier`, `CustomEase`, `RoughEase`, `SlowMo`).
* Multi-dimensional stagger system (1D linear and 2D grid staggers).
* Reactive widget integration with `SupremeWidget`, `SupremeBuilder`, `SupremeStateMixin`, and `.supreme()` extension.
* Plugins: `ScrollTrigger`, `Flip`, `TextPlugin` (with `SplitText`), `MotionPathPlugin`, and `Draggable` with `Inertia`.
* Type-safe animation configuration with `SupremeVars`.
