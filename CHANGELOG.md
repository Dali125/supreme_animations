## 1.1.0 (unreleased)

Bug fixes. A few of them change behaviour that code may have relied on, hence
the minor version bump.

* **`to()` records start values lazily.** A `to` tween now reads its start
  values the first time it renders after its delay, instead of when it is
  created. `tl.to(v, {'value': 0}).to(v, {'value': 1})` now animates 0 → 1
  instead of snapping. A delayed tween no longer writes to its target during
  the delay. `invalidate()` makes the tween re-record on its next render.
  *Behaviour change:* code that changed a property between creating a `to`
  tween and playing it now animates from the new value.
* **Timelines render children last-to-first when the playhead moves
  backwards**, so scrubbing back over chained tweens on one property shows the
  right value.
* **Keyframe durations.** Without a total `duration`, a keyframed tween lasts
  the sum of its step durations plus step delays (steps without a duration get
  the default duration divided by the number of steps). With a total, untimed
  steps share what is left over, otherwise everything is scaled to fit (the
  old behaviour). A timeline's `defaults` duration no longer squashes keyframe
  steps. Step `delay` is now supported. *Behaviour change:* keyframed tweens
  whose steps have durations and no explicit total now last the sum instead of
  0.5s.
* **`immediateRender` option.** `supreme.from/fromTo(..., paused: true)` and
  paused staggered groups no longer apply their from-values at creation, and
  timeline `from`/`fromTo`/`set` children only render at creation when they
  sit at time 0 of the timeline. Pass `'immediateRender': true/false` to
  choose. Playing standalone `from`/`fromTo`/`set` and the low-level
  `SupremeTween` constructor still render immediately by default.
  *Behaviour change* for paused or later-placed from/fromTo/set.
* **`fromTo` + `keyframes`** now starts the first keyframe from the from-values
  (they were ignored).
* **`SupremeContext` no longer grows forever.** Killed animations are dropped,
  and finished ones (or ones owned by another timeline) are held weakly, so
  `revert()` still kills them while your code references them. New
  `trackedCount`, `finishedCount` and `sweep()`.
* **`TextPlugin` joins the active context.** `typewriter`/`scramble` register
  with the current `SupremeContext` and accept `paused: true` for use with
  `tl.add()`. `SupremeStateMixin` gains `supremeRun()` and `supremeFromTo()`.
* `duration(value)` no longer renders an animation that has not rendered yet
  (timelines were rendering their first children while being built).
* **README:** every sample now matches the real API (`Ease.back(1.7)`,
  `Ease.back.customOut(...)`, `Ease.elastic.customOut(amplitude:, period:)`;
  there is no `supreme.stagger`), with new Easing, Keyframes, start-value and
  cleanup sections. `test/readme_snippets_test.dart` mirrors every sample so
  `flutter analyze` type-checks it, and fails if the README drifts.

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
