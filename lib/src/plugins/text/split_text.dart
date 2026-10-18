import 'package:flutter/widgets.dart';
import '../../core/supreme_core.dart';
import '../../core/timeline.dart';
import '../../widgets/transform_props.dart';
import '../../widgets/supreme_widget.dart';

enum SplitType { chars, words }

/// Splits text into individual characters or words for staggered animations in Supreme Animations.
class SplitTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final SplitType type;
  final bool animateOnMount;
  final Map<String, dynamic>? from;
  final Map<String, dynamic>? to;
  final dynamic stagger;
  final double duration;

  const SplitTextWidget({
    super.key,
    required this.text,
    this.style,
    this.type = SplitType.chars,
    this.animateOnMount = true,
    this.from = const {'y': 40.0, 'opacity': 0.0},
    this.to,
    this.stagger = 0.04,
    this.duration = 0.6,
  });

  @override
  State<SplitTextWidget> createState() => SplitTextWidgetState();
}

class SplitTextWidgetState extends State<SplitTextWidget> {
  final List<String> _tokens = [];
  final List<TransformProps> _props = [];
  SupremeTimeline? _timeline;

  List<TransformProps> get propsList => List.unmodifiable(_props);

  @override
  void initState() {
    super.initState();
    _splitText();
    if (widget.animateOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) play();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SplitTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.type != widget.type) {
      _splitText();
      if (widget.animateOnMount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) play();
        });
      }
    }
  }

  void _splitText() {
    _tokens.clear();
    for (final p in _props) {
      p.dispose();
    }
    _props.clear();

    if (widget.type == SplitType.chars) {
      for (int i = 0; i < widget.text.length; i++) {
        _tokens.add(widget.text[i]);
        _props.add(TransformProps());
      }
    } else {
      final words = widget.text.split(' ');
      for (int i = 0; i < words.length; i++) {
        _tokens.add(words[i] + (i < words.length - 1 ? ' ' : ''));
        _props.add(TransformProps());
      }
    }
  }

  /// Triggers the staggered reveal animation.
  SupremeTimeline play() {
    _timeline?.kill();
    _timeline = supreme.timeline();

    if (widget.from != null) {
      final cleanVars = Map<String, dynamic>.from(widget.from!);
      cleanVars['duration'] = widget.duration;
      cleanVars['stagger'] = widget.stagger;
      _timeline!.add(supreme.from(_props, cleanVars));
    } else if (widget.to != null) {
      final cleanVars = Map<String, dynamic>.from(widget.to!);
      cleanVars['duration'] = widget.duration;
      cleanVars['stagger'] = widget.stagger;
      _timeline!.add(supreme.to(_props, cleanVars));
    }

    return _timeline!;
  }

  @override
  void dispose() {
    _timeline?.kill();
    for (final p in _props) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(_tokens.length, (index) {
        final token = _tokens[index];
        final prop = _props[index];

        return SupremeWidget(
          transform: prop,
          child: Text(
            token,
            style: widget.style,
          ),
        );
      }),
    );
  }
}
