import 'package:flutter/widgets.dart';
import '../../core/animation.dart';
import '../../core/supreme_core.dart';
import '../../widgets/transform_props.dart';
import '../../widgets/supreme_widget.dart';
import 'scroll_trigger.dart';
import 'scroll_trigger_scope.dart';

typedef ScrollTriggerBuilder = Widget Function(
  BuildContext context,
  double progress,
  Widget? child,
);

/// A convenient declarative widget that animates as it scrolls through the viewport.
class ScrollTriggerWidget extends StatefulWidget {
  final Widget? child;
  final ScrollTriggerBuilder? builder;
  final SupremeAnimation? animation;
  final Map<String, dynamic>? to;
  final Map<String, dynamic>? from;
  final dynamic start;
  final dynamic end;
  final dynamic scrub;
  final bool pin;
  final dynamic toggleActions;
  final bool markers;

  const ScrollTriggerWidget({
    super.key,
    this.child,
    this.builder,
    this.animation,
    this.to,
    this.from,
    this.start = 'top bottom',
    this.end = 'bottom top',
    this.scrub = true,
    this.pin = false,
    this.toggleActions = 'play none none none',
    this.markers = false,
  });

  @override
  State<ScrollTriggerWidget> createState() => _ScrollTriggerWidgetState();
}

class _ScrollTriggerWidgetState extends State<ScrollTriggerWidget> {
  final GlobalKey _elementKey = GlobalKey();
  final TransformProps _props = TransformProps();
  ScrollTrigger? _trigger;
  SupremeAnimation? _ownedAnimation;
  ScrollTriggerScopeState? _scope;
  double _progress = 0.0;
  double _pinOffset = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newScope = ScrollTriggerScope.of(context);
    if (newScope != _scope) {
      if (_trigger != null) {
        _scope?.unregister(_trigger!);
      }
      _scope = newScope;
      _initTrigger();
    }
  }

  void _initTrigger() {
    _trigger?.kill();
    _ownedAnimation?.kill();
    _ownedAnimation = null;

    SupremeAnimation? targetAnim = widget.animation;

    if (targetAnim == null && widget.to != null) {
      targetAnim = supreme.to(_props, widget.to!, paused: true);
      _ownedAnimation = targetAnim;
    } else if (targetAnim == null && widget.from != null) {
      targetAnim = supreme.from(_props, widget.from!, paused: true);
      _ownedAnimation = targetAnim;
    }

    _trigger = ScrollTrigger(
      animation: targetAnim,
      triggerKey: _elementKey,
      start: widget.start,
      end: widget.end,
      scrub: widget.scrub,
      pin: widget.pin,
      toggleActions: widget.toggleActions,
      markers: widget.markers,
      onUpdate: (prog, dir) {
        if (mounted) {
          setState(() {
            _progress = prog;
            _pinOffset = _trigger?.pinOffset ?? 0.0;
          });
        }
      },
    );

    _scope?.register(_trigger!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scope?.refreshAll();
      }
    });
  }

  @override
  void dispose() {
    if (_trigger != null) {
      _scope?.unregister(_trigger!);
      _trigger!.kill();
    }
    _ownedAnimation?.kill();
    _props.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.builder != null) {
      content = widget.builder!(context, _progress, widget.child);
    } else if (widget.child != null) {
      content = SupremeWidget(
        transform: _props,
        child: widget.child!,
      );
    } else {
      content = const SizedBox.shrink();
    }

    if (widget.pin && _pinOffset != 0.0) {
      content = Transform.translate(
        offset: Offset(0, _pinOffset),
        child: content,
      );
    }

    return Container(
      key: _elementKey,
      child: content,
    );
  }
}
