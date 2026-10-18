import 'package:flutter/widgets.dart';
import 'scroll_trigger.dart';
import 'scroll_trigger_scope.dart';

/// Overlay widget that renders visual debugging markers matching GSAP ScrollTrigger's `markers: true`.
class ScrollTriggerMarkersOverlay extends StatelessWidget {
  final Widget child;

  const ScrollTriggerMarkersOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scope = ScrollTriggerScope.of(context);
    final triggers = scope?.triggers.where((t) => t.markers).toList() ?? [];

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (triggers.isNotEmpty && scope != null)
          IgnorePointer(
            child: CustomPaint(
              painter: _MarkerPainter(
                triggers: triggers,
                scrollPixels: scope.currentPixels,
                viewportHeight: scope.viewportHeight,
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkerPainter extends CustomPainter {
  final List<ScrollTrigger> triggers;
  final double scrollPixels;
  final double viewportHeight;

  _MarkerPainter({
    required this.triggers,
    required this.scrollPixels,
    required this.viewportHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2.0;

    final endPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..strokeWidth = 2.0;

    for (final t in triggers) {
      final startScreenY = t.startPixels - scrollPixels;
      final endScreenY = t.endPixels - scrollPixels;

      if (startScreenY >= -50 && startScreenY <= size.height + 50) {
        canvas.drawLine(
          Offset(0, startScreenY),
          Offset(size.width, startScreenY),
          startPaint,
        );
      }

      if (endScreenY >= -50 && endScreenY <= size.height + 50) {
        canvas.drawLine(
          Offset(0, endScreenY),
          Offset(size.width, endScreenY),
          endPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) {
    return oldDelegate.scrollPixels != scrollPixels ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.triggers != triggers;
  }
}
