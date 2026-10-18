import 'package:flutter/widgets.dart';
import 'scroll_trigger.dart';

/// Wraps any Flutter scrollable (ListView, CustomScrollView, SingleChildScrollView)
/// and coordinates all registered [ScrollTrigger] instances.
class ScrollTriggerScope extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;

  const ScrollTriggerScope({
    super.key,
    required this.child,
    this.controller,
  });

  static ScrollTriggerScopeState? of(BuildContext context) {
    return context.findAncestorStateOfType<ScrollTriggerScopeState>();
  }

  @override
  State<ScrollTriggerScope> createState() => ScrollTriggerScopeState();
}

class ScrollTriggerScopeState extends State<ScrollTriggerScope> {
  final List<ScrollTrigger> _triggers = [];
  double _currentPixels = 0.0;
  double _viewportHeight = 800.0;

  double get currentPixels => _currentPixels;
  double get viewportHeight => _viewportHeight;
  List<ScrollTrigger> get triggers => List.unmodifiable(_triggers);

  void register(ScrollTrigger trigger) {
    if (!_triggers.contains(trigger)) {
      _triggers.add(trigger);
      trigger.refresh(
        scrollPixels: _currentPixels,
        viewportHeight: _viewportHeight,
      );
    }
  }

  void unregister(ScrollTrigger trigger) {
    _triggers.remove(trigger);
    trigger.kill();
  }

  void refreshAll() {
    for (final t in _triggers) {
      t.refresh(
        scrollPixels: _currentPixels,
        viewportHeight: _viewportHeight,
      );
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    _currentPixels = notification.metrics.pixels;
    _viewportHeight = notification.metrics.viewportDimension;

    for (final trigger in _triggers) {
      trigger.update(_currentPixels);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: widget.child,
    );
  }
}
