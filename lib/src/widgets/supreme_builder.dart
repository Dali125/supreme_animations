import 'package:flutter/widgets.dart';
import '../core/animation.dart';

typedef SupremeWidgetBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

/// A widget that rebuilds whenever a [SupremeAnimation] ticks.
class SupremeBuilder extends StatefulWidget {
  final SupremeAnimation animation;
  final SupremeWidgetBuilder builder;
  final Widget? child;

  const SupremeBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  State<SupremeBuilder> createState() => _SupremeBuilderState();
}

class _SupremeBuilderState extends State<SupremeBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addUpdateListener(_handleUpdate);
  }

  @override
  void didUpdateWidget(covariant SupremeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.animation, widget.animation)) {
      oldWidget.animation.removeUpdateListener(_handleUpdate);
      widget.animation.addUpdateListener(_handleUpdate);
    }
  }

  @override
  void dispose() {
    widget.animation.removeUpdateListener(_handleUpdate);
    super.dispose();
  }

  void _handleUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}

/// Backward compatibility typedef for [SupremeWidgetBuilder].
@Deprecated('Use SupremeWidgetBuilder instead')
typedef GsapWidgetBuilder = SupremeWidgetBuilder;

/// Backward compatibility typedef for [SupremeBuilder].
@Deprecated('Use SupremeBuilder instead')
typedef GsapBuilder = SupremeBuilder;
