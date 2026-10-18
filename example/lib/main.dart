import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supreme_animations/supreme_animations.dart';

void main([List<String>? args]) {
  int initialPage = 0;
  if (args != null && args.isNotEmpty) {
    initialPage = int.tryParse(args[0]) ?? 0;
  }
  runApp(SupremeAnimationsExampleApp(initialIndex: initialPage));
}

class SupremeAnimationsExampleApp extends StatelessWidget {
  final int initialIndex;
  const SupremeAnimationsExampleApp({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supreme Animations Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00E676),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      home: SupremeShowcaseHome(initialIndex: initialIndex),
    );
  }
}

/// Backward compatibility typedef for [SupremeAnimationsExampleApp].
@Deprecated('Use SupremeAnimationsExampleApp instead')
typedef GsapExampleApp = SupremeAnimationsExampleApp;

class SupremeShowcaseHome extends StatefulWidget {
  final int initialIndex;
  const SupremeShowcaseHome({super.key, this.initialIndex = 0});

  @override
  State<SupremeShowcaseHome> createState() => _SupremeShowcaseHomeState();
}

class _SupremeShowcaseHomeState extends State<SupremeShowcaseHome> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 7);
  }

  final List<Widget> _pages = const [
    TweensAndControlsPage(),
    TimelinePage(),
    StaggerPage(),
    ScrollTriggerPage(),
    FlipLayoutPage(),
    TextEffectsPage(),
    MotionPathPage(),
    DraggablePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supreme Animations Showcase'),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            label: 'Tweens',
          ),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Stagger'),
          NavigationDestination(
            icon: Icon(Icons.swap_vert),
            label: 'ScrollTrigger',
          ),
          NavigationDestination(icon: Icon(Icons.flip_to_front), label: 'FLIP'),
          NavigationDestination(icon: Icon(Icons.text_fields), label: 'Text'),
          NavigationDestination(
            icon: Icon(Icons.alt_route),
            label: 'MotionPath',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app),
            label: 'Draggable',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. TWEENS & CONTROLS PAGE
// -------------------------------------------------------------
class TweensAndControlsPage extends StatefulWidget {
  const TweensAndControlsPage({super.key});

  @override
  State<TweensAndControlsPage> createState() => _TweensAndControlsPageState();
}

class _TweensAndControlsPageState extends State<TweensAndControlsPage>
    with SupremeStateMixin {
  final TransformProps _boxProps = TransformProps();
  SupremeTween? _activeTween;
  double _timeScale = 1.0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _activeTween?.kill();
    _activeTween = supreme.to(_boxProps, {
      'x': 120.0,
      'rotation': 3.14159,
      'scale': 1.3,
      'duration': 1.8,
      'ease': Ease.elastic.out,
      'repeat': -1,
      'yoyo': true,
      'repeatDelay': 0.3,
      'onUpdate': () {
        if (mounted) {
          setState(() {
            _progress = _activeTween?.progress() ?? 0.0;
          });
        }
      },
    }) as SupremeTween;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SupremeWidget(
                transform: _boxProps,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.electric_bolt,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _activeTween?.play(),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.pause),
                        onPressed: () => _activeTween?.pause(),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.restart_alt),
                        onPressed: () => _activeTween?.restart(),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.fast_rewind),
                        onPressed: () => _activeTween?.reverse(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Progress:'),
                      Expanded(
                        child: Slider(
                          value: _progress,
                          onChanged: (val) {
                            _activeTween?.pause();
                            _activeTween?.progress(val);
                            setState(() => _progress = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Speed (${_timeScale.toStringAsFixed(1)}x):'),
                      Expanded(
                        child: Slider(
                          value: _timeScale,
                          min: 0.2,
                          max: 3.0,
                          onChanged: (val) {
                            setState(() => _timeScale = val);
                            _activeTween?.timeScale(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _activeTween?.kill();
    _boxProps.dispose();
    super.dispose();
  }
}

// -------------------------------------------------------------
// 2. TIMELINE PAGE
// -------------------------------------------------------------
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final TransformProps _circle1 = TransformProps();
  final TransformProps _circle2 = TransformProps();
  final TransformProps _circle3 = TransformProps();
  SupremeTimeline? _timeline;
  double _tlProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _buildTimeline();
  }

  void _buildTimeline() {
    _timeline?.kill();
    _timeline = supreme.timeline({
      'repeat': -1,
      'repeatDelay': 0.5,
      'yoyo': true,
      'onUpdate': () {
        if (mounted) {
          setState(() {
            _tlProgress = _timeline?.progress() ?? 0.0;
          });
        }
      },
    });

    _timeline!
        .to(_circle1, {
          'y': -60.0,
          'scale': 1.4,
          'duration': 0.6,
          'ease': Ease.power2.out,
        })
        .to(_circle2, {
          'y': -60.0,
          'scale': 1.4,
          'duration': 0.6,
          'ease': Ease.power2.out,
        }, '<0.15')
        .to(_circle3, {
          'y': -60.0,
          'scale': 1.4,
          'duration': 0.6,
          'ease': Ease.power2.out,
        }, '<0.15')
        .addLabel('spin')
        .to(_circle1, {
          'rotation': 3.14,
          'duration': 0.8,
          'ease': Ease.back.out,
        }, 'spin')
        .to(_circle2, {
          'rotation': 3.14,
          'duration': 0.8,
          'ease': Ease.back.out,
        }, 'spin+=0.1')
        .to(_circle3, {
          'rotation': 3.14,
          'duration': 0.8,
          'ease': Ease.back.out,
        }, 'spin+=0.2');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOrb(_circle1, const Color(0xFFFF5252)),
                const SizedBox(width: 24),
                _buildOrb(_circle2, const Color(0xFFFFD740)),
                const SizedBox(width: 24),
                _buildOrb(_circle3, const Color(0xFF69F0AE)),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Timeline Duration: ${_timeline?.durationVal.toStringAsFixed(1)}s',
                ),
                Slider(
                  value: _tlProgress,
                  onChanged: (val) {
                    _timeline?.pause();
                    _timeline?.progress(val);
                    setState(() => _tlProgress = val);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _timeline?.restart(),
                      child: const Text('Restart'),
                    ),
                    ElevatedButton(
                      onPressed: () => _timeline?.reverse(),
                      child: const Text('Reverse'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrb(TransformProps props, Color color) {
    return SupremeWidget(
      transform: props,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeline?.kill();
    _circle1.dispose();
    _circle2.dispose();
    _circle3.dispose();
    super.dispose();
  }
}

// -------------------------------------------------------------
// 3. STAGGER PAGE
// -------------------------------------------------------------
class StaggerPage extends StatefulWidget {
  const StaggerPage({super.key});

  @override
  State<StaggerPage> createState() => _StaggerPageState();
}

class _StaggerPageState extends State<StaggerPage> {
  final List<TransformProps> _gridProps = List.generate(
    16,
    (_) => TransformProps(),
  );
  String _staggerFrom = 'center';

  void _triggerStagger() {
    supreme.fromTo(
      _gridProps,
      {'scale': 0.0, 'opacity': 0.0, 'rotation': -1.5},
      {
        'scale': 1.0,
        'opacity': 1.0,
        'rotation': 0.0,
        'duration': 0.8,
        'ease': Ease.back.out,
        'stagger': {
          'amount': 0.8,
          'from': _staggerFrom,
          'grid': [4, 4],
        },
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerStagger());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'center', label: Text('Center')),
            ButtonSegment(value: 'edges', label: Text('Edges')),
            ButtonSegment(value: 'start', label: Text('Start')),
            ButtonSegment(value: 'random', label: Text('Random')),
          ],
          selected: {_staggerFrom},
          onSelectionChanged: (val) {
            setState(() => _staggerFrom = val.first);
            _triggerStagger();
          },
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  return SupremeWidget(
                    transform: _gridProps[index],
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            Colors.primaries[index % Colors.primaries.length],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _triggerStagger,
          icon: const Icon(Icons.refresh),
          label: const Text('Re-trigger Stagger'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// -------------------------------------------------------------
// 4. SCROLLTRIGGER PAGE
// -------------------------------------------------------------
class ScrollTriggerPage extends StatelessWidget {
  const ScrollTriggerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollTriggerScope(
      child: ScrollTriggerMarkersOverlay(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const Center(
              child: Text(
                'Scroll down to observe ScrollTrigger in action',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 300),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ScrollTriggerWidget(
                  start: 'top 80%',
                  end: 'center 40%',
                  scrub: 1.0,
                  markers: true,
                  from: {'scale': 0.5, 'opacity': 0.2, 'y': 80.0},
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.primaries[index * 2 % Colors.primaries.length],
                          Colors.primaries[(index * 2 + 1) %
                              Colors.primaries.length],
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Card #${index + 1}\n(Scrub Smooth 1.0s)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 300),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. FLIP LAYOUT PAGE
// -------------------------------------------------------------
class FlipLayoutPage extends StatefulWidget {
  const FlipLayoutPage({super.key});

  @override
  State<FlipLayoutPage> createState() => _FlipLayoutPageState();
}

class _FlipLayoutPageState extends State<FlipLayoutPage> {
  bool _isGrid = true;
  final List<GlobalKey> _keys = List.generate(6, (_) => GlobalKey());
  final Map<GlobalKey, TransformProps> _props = {};

  @override
  void initState() {
    super.initState();
    for (final k in _keys) {
      _props[k] = TransformProps();
    }
  }

  void _toggleLayout() {
    final state = Flip.getState(_keys);
    setState(() {
      _isGrid = !_isGrid;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flip.from(
        state,
        transformPropsMap: _props,
        duration: 0.7,
        ease: Ease.power3.out,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _toggleLayout,
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            label: Text(_isGrid ? 'Switch to List' : 'Switch to Grid'),
          ),
        ),
        Expanded(
          child: _isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, i) => _buildItem(i),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(height: 90, child: _buildItem(i)),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildItem(int i) {
    return Container(
      key: _keys[i],
      child: SupremeWidget(
        transform: _props[_keys[i]],
        child: Container(
          decoration: BoxDecoration(
            color: Colors.teal[(i + 3) * 100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Item ${i + 1}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 6. TEXT EFFECTS PAGE
// -------------------------------------------------------------
class TextEffectsPage extends StatefulWidget {
  const TextEffectsPage({super.key});

  @override
  State<TextEffectsPage> createState() => _TextEffectsPageState();
}

class _TextEffectsPageState extends State<TextEffectsPage> {
  final ValueNotifier<String> _typewriterText = ValueNotifier<String>('');
  final ValueNotifier<String> _scrambleText = ValueNotifier<String>(
    'CYBERSECURITY',
  );
  final GlobalKey<SplitTextWidgetState> _splitKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _runEffects();
  }

  void _runEffects() {
    TextPlugin.typewriter(
      _typewriterText,
      'Supreme Animations brings Hollywood-grade animations to cross-platform apps.',
      duration: 3.0,
      ease: Ease.linear,
    );

    TextPlugin.scramble(_scrambleText, 'SUPREME ANIMATIONS', duration: 2.0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Typewriter Effect:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: _typewriterText,
            builder: (context, text, _) {
              return Text(
                text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00E676),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            'Scramble Text Effect:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: _scrambleText,
            builder: (context, text, _) {
              return Text(
                text,
                style: const TextStyle(
                  fontSize: 26,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B0FF),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            'SplitText Stagger Reveal:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SplitTextWidget(
            key: _splitKey,
            text: 'SMOOTH SEQUENCING',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            stagger: 0.05,
            duration: 0.7,
          ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _runEffects();
                _splitKey.currentState?.play();
              },
              icon: const Icon(Icons.replay),
              label: const Text('Replay Text Effects'),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 7. MOTIONPATH PAGE
// -------------------------------------------------------------
enum PathType { curved, loop, polygon }

class MotionPathPage extends StatefulWidget {
  const MotionPathPage({super.key});

  @override
  State<MotionPathPage> createState() => _MotionPathPageState();
}

class _MotionPathPageState extends State<MotionPathPage> {
  final TransformProps _planeProps = TransformProps();
  MotionPathTween? _tween;
  MotionPath? _activePath;
  PathType _selectedType = PathType.curved;
  bool _autoRotate = true;
  double _timeScale = 1.0;
  double _progress = 0.0;
  Size? _lastSize;

  @override
  void dispose() {
    _tween?.kill();
    super.dispose();
  }

  void _buildAndPlayPath(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _lastSize = size;
    final w = size.width;
    final h = size.height;

    MotionPath path;
    switch (_selectedType) {
      case PathType.curved:
        path = MotionPath.curved([
          Offset(w * 0.1, h * 0.7),
          Offset(w * 0.35, h * 0.2),
          Offset(w * 0.65, h * 0.8),
          Offset(w * 0.9, h * 0.3),
        ]);
        break;
      case PathType.loop:
        path = MotionPath.curved([
          Offset(w * 0.2, h * 0.5),
          Offset(w * 0.4, h * 0.2),
          Offset(w * 0.6, h * 0.8),
          Offset(w * 0.8, h * 0.5),
          Offset(w * 0.6, h * 0.2),
          Offset(w * 0.4, h * 0.8),
          Offset(w * 0.2, h * 0.5),
        ]);
        break;
      case PathType.polygon:
        path = MotionPath.polygon([
          Offset(w * 0.15, h * 0.25),
          Offset(w * 0.85, h * 0.25),
          Offset(w * 0.85, h * 0.75),
          Offset(w * 0.15, h * 0.75),
          Offset(w * 0.15, h * 0.25),
        ]);
        break;
    }

    _activePath = path;
    _tween?.kill();

    _tween = MotionPathPlugin.to(
      _planeProps,
      path: path,
      autoRotate: _autoRotate,
      autoRotateOffset: math.pi / 4,
      alignOrigin: const Offset(20, 20),
      duration: 4.0,
      repeat: -1,
      yoyo: _selectedType != PathType.polygon,
      ease: Ease.power2.inOut,
      onUpdate: () {
        if (mounted) {
          setState(() {
            _progress = _tween?.progress() ?? 0.0;
          });
        }
      },
    );
    _tween?.timeScale(_timeScale);
  }

  void _onPathTypeChanged(PathType type) {
    setState(() {
      _selectedType = type;
    });
    if (_lastSize != null) {
      _buildAndPlayPath(_lastSize!);
    }
  }

  void _toggleAutoRotate(bool val) {
    setState(() {
      _autoRotate = val;
    });
    if (_lastSize != null) {
      _buildAndPlayPath(_lastSize!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls header
        Container(
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Path:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Curved'),
                    selected: _selectedType == PathType.curved,
                    onSelected: (_) => _onPathTypeChanged(PathType.curved),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Loop'),
                    selected: _selectedType == PathType.loop,
                    onSelected: (_) => _onPathTypeChanged(PathType.loop),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Track'),
                    selected: _selectedType == PathType.polygon,
                    onSelected: (_) => _onPathTypeChanged(PathType.polygon),
                  ),
                  const Spacer(),
                  const Text('Auto-Rotate:', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _autoRotate,
                    onChanged: _toggleAutoRotate,
                    activeThumbColor: const Color(0xFF00E676),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Play',
                    onPressed: () => _tween?.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.pause),
                    tooltip: 'Pause',
                    onPressed: () => _tween?.pause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay),
                    tooltip: 'Restart',
                    onPressed: () => _tween?.restart(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fast_rewind),
                    tooltip: 'Reverse',
                    onPressed: () => _tween?.reverse(),
                  ),
                  Expanded(
                    child: Slider(
                      value: _progress.clamp(0.0, 1.0),
                      onChanged: (val) {
                        _tween?.pause();
                        _tween?.progress(val);
                        setState(() => _progress = val);
                      },
                      onChangeEnd: (_) => _tween?.resume(),
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Speed:', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _timeScale,
                      min: 0.2,
                      max: 3.0,
                      onChanged: (val) {
                        setState(() => _timeScale = val);
                        _tween?.timeScale(val);
                      },
                    ),
                  ),
                  Text(
                    '${_timeScale.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Interactive Flight Canvas
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (_lastSize == null ||
                  (_lastSize!.width - size.width).abs() > 10 ||
                  (_lastSize!.height - size.height).abs() > 10) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _buildAndPlayPath(size);
                });
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_activePath != null)
                    CustomPaint(
                      size: size,
                      painter: _MotionPathCanvasPainter(path: _activePath!),
                    ),
                  SupremeWidget(
                    transform: _planeProps,
                    child: const Icon(
                      Icons.flight,
                      size: 40,
                      color: Color(0xFF00E676),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MotionPathCanvasPainter extends CustomPainter {
  final MotionPath path;

  _MotionPathCanvasPainter({required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Glow stroke
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(path.toPath(), glowPaint);

    // 2. Trajectory line
    final strokePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path.toPath(), strokePaint);

    // 3. Waypoint Pins
    if (path.waypoints != null) {
      final pinBg = Paint()..color = const Color(0xFF0F172A);
      final pinBorder = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      for (int i = 0; i < path.waypoints!.length; i++) {
        final pt = path.waypoints![i];
        canvas.drawCircle(pt, 10, pinBg);
        canvas.drawCircle(pt, 10, pinBorder);

        textPainter.text = TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pt.dx - textPainter.width / 2, pt.dy - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MotionPathCanvasPainter oldDelegate) =>
      oldDelegate.path != path;
}

// -------------------------------------------------------------
// 8. DRAGGABLE & INERTIA PAGE
// -------------------------------------------------------------
class DraggablePage extends StatelessWidget {
  const DraggablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Fling the card! It decelerates with momentum resistance.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 60),
          SupremeDraggable(
            inertia: true,
            bounds: const Rect.fromLTWH(-150, -200, 300, 400),
            child: Container(
              width: 220,
              height: 280,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Throw Me!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Inertia + Physics Bounds',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
