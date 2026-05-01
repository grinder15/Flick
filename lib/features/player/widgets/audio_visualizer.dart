import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flick/services/player_service.dart';
import 'package:flick/services/visualizer_service.dart';

class AudioVisualizer extends StatefulWidget {
  final PlayerService playerService;

  const AudioVisualizer({super.key, required this.playerService});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  static const int _barCount = 48;
  static const double _minHeight = 0.04;
  static const double _spring = 0.28;
  static const double _damping = 0.72;

  late AnimationController _controller;
  late VisualizerService _visualizerService;

  // Simulated fallback state
  final List<double> _currentHeights = List.filled(_barCount, _minHeight);
  final List<double> _targetHeights = List.filled(_barCount, _minHeight);
  final List<double> _velocities = List.filled(_barCount, 0.0);

  bool _isPlaying = false;
  bool _useRealData = false;
  int _frameCount = 0;
  int _songSeed = 0;
  double _songDurationSec = 180.0;

  @override
  void initState() {
    super.initState();
    _visualizerService = VisualizerService();
    _visualizerService.barHeightsNotifier.addListener(_onRealDataChanged);

    _isPlaying = widget.playerService.isPlayingNotifier.value;
    _updateSongSeed();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.addListener(_onFrame);
    _controller.repeat();

    widget.playerService.isPlayingNotifier.addListener(_onPlayingChanged);
    widget.playerService.positionNotifier.addListener(_onPositionChanged);
    widget.playerService.currentSongNotifier.addListener(_onSongChanged);
    widget.playerService.usingRustBackendNotifier.addListener(
      _onBackendChanged,
    );

    _syncVisualizerAttachment();
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerService != widget.playerService) {
      oldWidget.playerService.isPlayingNotifier.removeListener(
        _onPlayingChanged,
      );
      oldWidget.playerService.positionNotifier.removeListener(
        _onPositionChanged,
      );
      oldWidget.playerService.currentSongNotifier.removeListener(
        _onSongChanged,
      );
      oldWidget.playerService.usingRustBackendNotifier.removeListener(
        _onBackendChanged,
      );
      widget.playerService.isPlayingNotifier.addListener(_onPlayingChanged);
      widget.playerService.positionNotifier.addListener(_onPositionChanged);
      widget.playerService.currentSongNotifier.addListener(_onSongChanged);
      widget.playerService.usingRustBackendNotifier.addListener(
        _onBackendChanged,
      );
      _isPlaying = widget.playerService.isPlayingNotifier.value;
      _updateSongSeed();
      _syncVisualizerAttachment();
    }
  }

  void _onRealDataChanged() {
    final real = _visualizerService.barHeightsNotifier.value;
    if (mounted) {
      setState(() {
        _useRealData = real != null && real.length == _barCount;
      });
    }
  }

  void _onBackendChanged() => _syncVisualizerAttachment();

  void _syncVisualizerAttachment() {
    final usingRust = widget.playerService.usingRustBackendNotifier.value;
    final sessionId = widget.playerService.androidAudioSessionId;

    if (!Platform.isAndroid || usingRust || sessionId == null || sessionId <= 0) {
      _visualizerService.detach();
      return;
    }

    if (_isPlaying) {
      _visualizerService.attach(sessionId);
    } else {
      _visualizerService.detach();
    }
  }

  void _onSongChanged() {
    _updateSongSeed();
  }

  void _updateSongSeed() {
    final song = widget.playerService.currentSongNotifier.value;
    if (song == null) return;
    final path = song.filePath ?? song.id;
    var hash = 0x811c9dc5;
    for (var i = 0; i < path.length; i++) {
      hash ^= path.codeUnitAt(i);
      hash = _imul(hash, 0x01000193);
    }
    hash ^= song.duration.inMilliseconds;
    hash = _imul(hash, 0x01000193);
    _songSeed = hash;
    _songDurationSec = math.max(10.0, song.duration.inMilliseconds / 1000.0);
  }

  static int _imul(int a, int b) {
    final ah = (a >> 16) & 0xffff;
    final al = a & 0xffff;
    final bh = (b >> 16) & 0xffff;
    final bl = b & 0xffff;
    return ((al * bl) + (((ah * bl + al * bh) << 16) >> 0)) | 0;
  }

  double _frand(int n) {
    var x = _songSeed ^ n;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = (x >> 16) ^ x;
    return (x & 0x7fffffff) / 0x7fffffff;
  }

  double _noise2D(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    final n00 = _frand(ix * 73856093 ^ iy * 19349663);
    final n10 = _frand((ix + 1) * 73856093 ^ iy * 19349663);
    final n01 = _frand(ix * 73856093 ^ (iy + 1) * 19349663);
    final n11 = _frand((ix + 1) * 73856093 ^ (iy + 1) * 19349663);

    final u = fx * fx * (3.0 - 2.0 * fx);
    final v = fy * fy * (3.0 - 2.0 * fy);

    return n00 * (1 - u) * (1 - v) +
        n10 * u * (1 - v) +
        n01 * (1 - u) * v +
        n11 * u * v;
  }

  double _fbm(double x, double y, int octaves) {
    var value = 0.0;
    var amplitude = 0.5;
    var frequency = 1.0;
    for (var i = 0; i < octaves; i++) {
      value += amplitude * _noise2D(x * frequency, y * frequency);
      amplitude *= 0.5;
      frequency *= 2.0;
    }
    return value;
  }

  double _songEnergy(double t) {
    final progress = t / _songDurationSec;
    final sectionNoise = _fbm(progress * 8.0, _songSeed * 0.1, 3);

    double energy;
    if (progress < 0.08) {
      energy = 0.2 + progress * 3.75;
    } else if (progress < 0.35) {
      energy = 0.5 + sectionNoise * 0.2;
    } else if (progress < 0.55) {
      energy = 0.75 + sectionNoise * 0.2;
    } else if (progress < 0.72) {
      energy = 0.55 + sectionNoise * 0.15;
    } else if (progress < 0.88) {
      energy = 0.85 + sectionNoise * 0.15;
    } else {
      energy = 0.6 * (1.0 - (progress - 0.88) / 0.12);
    }

    final swell = math.sin(progress * math.pi * 6.0 + _songSeed) * 0.08 +
        math.sin(progress * math.pi * 14.0 + _songSeed * 2.0) * 0.04;

    return (energy + swell).clamp(0.1, 1.0);
  }

  void _computeSimulatedTargets(int positionMs) {
    final t = positionMs / 1000.0;
    final energy = _songEnergy(t);

    final beatPhase = (t * (_frand(1) * 2.0 + 1.8)) % 1.0;
    final isBeat = beatPhase < 0.12;
    final beatStrength = isBeat ? (1.0 - beatPhase / 0.12) : 0.0;

    final fastBeatPhase = (t * (_frand(2) * 4.0 + 4.0)) % 1.0;
    final isFastBeat = fastBeatPhase < 0.08;
    final fastBeatStrength = isFastBeat ? (1.0 - fastBeatPhase / 0.08) * 0.4 : 0.0;

    for (int i = 0; i < _barCount; i++) {
      final x = i / (_barCount - 1);

      final freqFactor = x < 0.25
          ? 0.4
          : x < 0.5
              ? 0.8
              : x < 0.75
                  ? 1.3
                  : 1.8;

      final barSeed = i * 7919 + _songSeed;
      final charOffset = _frand(barSeed) * 2.0 - 1.0;

      final noiseTime = t * freqFactor * (0.8 + _frand(barSeed + 1) * 0.6);
      final noiseFreq = x * 12.0 + charOffset * 3.0;
      final organic = _fbm(noiseTime, noiseFreq, 4);

      final bassEnv = math.exp(-x * 5.0);
      final midEnv = math.exp(-((x - 0.35) * 6.0).abs());
      final trebleEnv = math.exp(-((x - 0.75) * 8.0).abs());

      final bassMovement = organic * bassEnv * 0.9;
      final midMovement = organic * midEnv * 0.7;
      final trebleMovement = organic * trebleEnv * 0.5;

      final bassBeat = beatStrength * bassEnv * 0.5;
      final midBeat = beatStrength * midEnv * 0.3;
      final trebleFastBeat = fastBeatStrength * trebleEnv * 0.4;

      var height = (bassMovement + midMovement + trebleMovement + bassBeat + midBeat + trebleFastBeat) * energy;

      final transientChance = _frand((t * 30.0).floor() * 97 + barSeed);
      if (transientChance > 0.985) {
        height += _frand((t * 30.0).floor() * 53 + barSeed) * 0.35 * energy;
      }

      height = (height * 1.1 + 0.05).clamp(_minHeight, 1.0);
      _targetHeights[i] = height;
    }
  }

  void _onPositionChanged() {
    if (!_isPlaying || _useRealData) return;
    final ms = widget.playerService.positionNotifier.value.inMilliseconds;
    _computeSimulatedTargets(ms);
  }

  void _onPlayingChanged() {
    final playing = widget.playerService.isPlayingNotifier.value;
    if (playing == _isPlaying) return;
    _isPlaying = playing;
    _syncVisualizerAttachment();
    if (!_isPlaying && !_useRealData) {
      for (int i = 0; i < _barCount; i++) {
        _targetHeights[i] = _minHeight + _frand(i * 97) * 0.06;
      }
    }
  }

  void _onFrame() {
    if (!mounted) return;
    _frameCount++;

    if (_useRealData) {
      // Real data drives the display directly; no spring physics needed
      // because the native capture already runs at ~33fps.
      return;
    }

    for (int i = 0; i < _barCount; i++) {
      final diff = _targetHeights[i] - _currentHeights[i];
      _velocities[i] = _velocities[i] * _damping + diff * _spring;
      _currentHeights[i] =
          (_currentHeights[i] + _velocities[i]).clamp(_minHeight, 1.0);
    }

    if (_isPlaying && _frameCount % 2 == 0) {
      final ms = widget.playerService.positionNotifier.value.inMilliseconds;
      _computeSimulatedTargets(ms);
    }
  }

  List<double> get _displayHeights {
    if (_useRealData) {
      return _visualizerService.barHeightsNotifier.value ?? _currentHeights;
    }
    return _currentHeights;
  }

  @override
  void dispose() {
    widget.playerService.isPlayingNotifier.removeListener(_onPlayingChanged);
    widget.playerService.positionNotifier.removeListener(_onPositionChanged);
    widget.playerService.currentSongNotifier.removeListener(_onSongChanged);
    widget.playerService.usingRustBackendNotifier.removeListener(
      _onBackendChanged,
    );
    _visualizerService.barHeightsNotifier.removeListener(_onRealDataChanged);
    _visualizerService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _VisualizerBarPainter(
              barHeights: _displayHeights,
              repaint: _controller,
            ),
          );
        },
      ),
    );
  }
}

class _VisualizerBarPainter extends CustomPainter {
  final List<double> barHeights;

  _VisualizerBarPainter({
    required this.barHeights,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final barCount = barHeights.length;
    const spacing = 2.5;
    final totalSpacing = (barCount - 1) * spacing;
    final barWidth = (size.width - totalSpacing) / barCount;
    final maxBarHeight = size.height * 0.88;

    for (int i = 0; i < barCount; i++) {
      final height = barHeights[i] * maxBarHeight;
      final t = barCount > 1 ? i / (barCount - 1) : 0.0;

      final brightness = 1.0 - t * 0.55;
      final color = Color.fromRGBO(
        (255 * brightness).round(),
        (255 * brightness).round(),
        (255 * brightness).round(),
        1.0,
      );

      final x = i * (barWidth + spacing);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        const Radius.circular(2.0),
      );

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rect, glowPaint);

      final barPaint = Paint()..color = color.withValues(alpha: 0.82);
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerBarPainter oldDelegate) => true;
}
