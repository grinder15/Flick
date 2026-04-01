import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/utils/app_haptics.dart';
import 'package:flick/features/songs/widgets/song_card.dart';
import 'package:flick/models/song.dart';

class OrbitScrollController {
  void Function(int index, bool animate)? _jumpToIndex;

  void _attach(void Function(int index, bool animate) jumpToIndex) {
    _jumpToIndex = jumpToIndex;
  }

  void _detach() {
    _jumpToIndex = null;
  }

  void jumpToIndex(int index, {bool animate = true}) {
    _jumpToIndex?.call(index, animate);
  }
}

/// Orbital scrolling widget that displays songs in a curved arc.
class OrbitScroll extends StatefulWidget {
  final List<Song> songs;
  final int selectedIndex;
  final ValueChanged<int>? onSongActivated;
  final ValueChanged<int>? onSelectedIndexChanged;
  final ValueChanged<int>? onSongLongPressed;
  final ValueChanged<int>? onSongSwipedLeft;
  final ValueChanged<int>? onSongSwipedRight;
  final OrbitScrollController? controller;
  final String? currentSongId;

  const OrbitScroll({
    super.key,
    required this.songs,
    this.selectedIndex = 0,
    this.onSongActivated,
    this.onSelectedIndexChanged,
    this.onSongLongPressed,
    this.onSongSwipedLeft,
    this.onSongSwipedRight,
    this.controller,
    this.currentSongId,
  });

  @override
  State<OrbitScroll> createState() => _OrbitScrollState();
}

class _OrbitScrollState extends State<OrbitScroll>
    with SingleTickerProviderStateMixin {
  static const double _dragItemExtent = 96.0;

  late final AnimationController _controller;
  double _scrollOffset = 0.0;
  bool _isScrolling = false;
  DateTime _lastScrollTime = DateTime.now();
  final Map<int, _Position> _positionCache = {};
  final Map<int, _ItemTransform> _transformCache = {};
  Size? _lastLayoutSize;
  int? _lastReportedIndex;
  bool _animationTraversalHapticsEnabled = false;
  bool _animationSettleHapticEnabled = false;

  @override
  void initState() {
    super.initState();
    _scrollOffset = widget.selectedIndex.toDouble();
    _lastReportedIndex = widget.selectedIndex;
    _controller = AnimationController.unbounded(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(_onPhysicsTick);
    widget.controller?._attach(_jumpToIndex);
  }

  @override
  void didUpdateWidget(covariant OrbitScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_jumpToIndex);
    }

    if (oldWidget.songs.length != widget.songs.length) {
      _positionCache.clear();
      _transformCache.clear();
      _lastReportedIndex = widget.selectedIndex
          .clamp(0, math.max(widget.songs.length - 1, 0))
          .toInt();
    }

    if (widget.selectedIndex != oldWidget.selectedIndex &&
        (widget.selectedIndex.toDouble() - _scrollOffset).abs() > 0.05) {
      _animateTo(
        widget.selectedIndex.toDouble(),
        traversalHaptics: false,
        settleHaptic: false,
      );
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _controller.dispose();
    super.dispose();
  }

  void _jumpToIndex(int index, bool animate) {
    if (widget.songs.isEmpty) {
      return;
    }

    final clampedIndex = index.clamp(0, widget.songs.length - 1).toInt();
    if (animate) {
      _animateTo(
        clampedIndex.toDouble(),
        traversalHaptics: false,
        settleHaptic: false,
      );
      return;
    }

    _controller.stop();
    _clearAnimationHapticFlags();
    _applyScrollOffset(
      clampedIndex.toDouble(),
      haptic: false,
      isScrolling: false,
    );
  }

  void _onPhysicsTick() {
    if (_controller.isAnimating) {
      _applyScrollOffset(
        _controller.value,
        haptic: _animationTraversalHapticsEnabled,
      );
      return;
    }

    if (_isScrolling &&
        DateTime.now().difference(_lastScrollTime).inMilliseconds > 100) {
      setState(() {
        _isScrolling = false;
      });
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _controller.stop();
    _clearAnimationHapticFlags();
    _lastScrollTime = DateTime.now();
    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.songs.isEmpty) {
      return;
    }

    final delta = details.primaryDelta ?? 0.0;
    if (delta == 0) {
      return;
    }

    final direction = delta > 0
        ? ScrollDirection.forward
        : ScrollDirection.reverse;

    UserScrollNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: widget.songs.length.toDouble(),
        pixels: _scrollOffset,
        viewportDimension: 100,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1.0,
      ),
      context: context,
      direction: direction,
    ).dispatch(context);

    var itemDelta = -(delta / _dragItemExtent);
    double nextOffset = _scrollOffset + itemDelta;
    if (nextOffset < -0.5 || nextOffset > widget.songs.length - 0.5) {
      itemDelta *= 0.38;
      nextOffset = _scrollOffset + itemDelta;
    }

    _applyScrollOffset(nextOffset, haptic: true);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.songs.isEmpty) {
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;

    UserScrollNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: widget.songs.length.toDouble(),
        pixels: _scrollOffset,
        viewportDimension: 100,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1.0,
      ),
      context: context,
      direction: ScrollDirection.idle,
    ).dispatch(context);

    final velocityItemsPerSecond = -velocity / _dragItemExtent;
    final simulation = FrictionSimulation(
      0.15,
      _scrollOffset,
      velocityItemsPerSecond,
    );
    final projectedOffset = simulation.x(2.0);
    final targetIndex = projectedOffset
        .round()
        .clamp(0, widget.songs.length - 1)
        .toInt();

    _animateTo(
      targetIndex.toDouble(),
      velocity: velocityItemsPerSecond,
      traversalHaptics: false,
      settleHaptic: true,
    );
  }

  void _animateTo(
    double target, {
    double velocity = 0.0,
    bool traversalHaptics = false,
    bool settleHaptic = false,
  }) {
    if (widget.songs.isEmpty) {
      return;
    }

    _animationTraversalHapticsEnabled = traversalHaptics;
    _animationSettleHapticEnabled = settleHaptic;

    final simulation = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 120.0,
        ratio: 1.0,
      ),
      _scrollOffset,
      target,
      velocity,
    );

    _controller.animateWith(simulation).whenComplete(() {
      _applyScrollOffset(
        target,
        haptic: _animationSettleHapticEnabled,
        isScrolling: false,
      );
      _clearAnimationHapticFlags();
    });
  }

  void _clearAnimationHapticFlags() {
    _animationTraversalHapticsEnabled = false;
    _animationSettleHapticEnabled = false;
  }

  void _applyScrollOffset(
    double nextOffset, {
    bool haptic = false,
    bool isScrolling = true,
  }) {
    if (widget.songs.isEmpty) {
      return;
    }

    final clampedOffset = nextOffset
        .clamp(-0.5, widget.songs.length - 0.5)
        .toDouble();
    final didChange =
        (clampedOffset - _scrollOffset).abs() > 0.001 ||
        _isScrolling != isScrolling;

    if (didChange) {
      setState(() {
        _scrollOffset = clampedOffset;
        _isScrolling = isScrolling;
        _lastScrollTime = DateTime.now();
      });
    }

    _notifySelectionIfNeeded(haptic: haptic);
  }

  void _notifySelectionIfNeeded({bool haptic = false}) {
    if (widget.songs.isEmpty) {
      return;
    }

    final nextIndex = _scrollOffset
        .round()
        .clamp(0, widget.songs.length - 1)
        .toInt();
    if (nextIndex == _lastReportedIndex) {
      return;
    }

    _lastReportedIndex = nextIndex;
    if (haptic) {
      AppHaptics.selection();
    }
    widget.onSelectedIndexChanged?.call(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _refreshGeometryCache(size);
        final metrics = _OrbitLayoutMetrics(size);

        return GestureDetector(
          onVerticalDragStart: _onVerticalDragStart,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: ColoredBox(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildSelectionAura(metrics),
                _buildFocusCradle(metrics),
                _buildOrbitPath(metrics),
                ..._buildSongItems(metrics),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshGeometryCache(Size size) {
    if (_lastLayoutSize == size) {
      return;
    }

    _lastLayoutSize = size;
    _positionCache.clear();
    _transformCache.clear();
  }

  Widget _buildSelectionAura(_OrbitLayoutMetrics metrics) {
    return Positioned(
      left: metrics.focusX - (metrics.auraWidth / 2),
      top: metrics.focusY - (metrics.auraHeight / 2),
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            width: metrics.auraWidth,
            height: metrics.auraHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.38, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusCradle(_OrbitLayoutMetrics metrics) {
    return Positioned.fromRect(
      rect: metrics.stageRect,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(metrics.stageRect.height / 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: metrics.stageRect.width * 0.72,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitPath(_OrbitLayoutMetrics metrics) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _OrbitPathPainter(metrics: metrics),
      ),
    );
  }

  List<Widget> _buildSongItems(_OrbitLayoutMetrics metrics) {
    final items = <Widget>[];
    final visibleRange = _isScrolling
        ? (metrics.visibleItemCount ~/ 2) + 1
        : metrics.visibleItemCount ~/ 2;
    final orderedIndices = List.generate(
      (visibleRange * 2) + 1,
      (index) => index - visibleRange,
    )..sort((a, b) => b.abs().compareTo(a.abs()));

    final centerIndex = _scrollOffset.round();
    final useCache = !_isScrolling;

    for (final relativeIndex in orderedIndices) {
      final actualIndex = centerIndex + relativeIndex;
      if (actualIndex < 0 || actualIndex >= widget.songs.length) {
        continue;
      }

      final diff = actualIndex.toDouble() - _scrollOffset;
      _ItemTransform? transform;
      if (useCache) {
        transform = _transformCache[(diff * 100).toInt()];
      }

      if (transform == null) {
        transform = _buildTransform(
          diff: diff,
          metrics: metrics,
          cacheResult: useCache,
        );
        if (transform == null) {
          continue;
        }
      }

      items.add(
        Positioned(
          left: transform.position.x,
          top: transform.position.y,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Transform.rotate(
              angle: transform.rotation,
              child: RepaintBoundary(
                child: SongCard(
                  song: widget.songs[actualIndex],
                  scale: transform.scale,
                  opacity: transform.opacity,
                  isSelected: transform.isSelected,
                  isNowPlaying:
                      widget.currentSongId == widget.songs[actualIndex].id,
                  onFocusRequested: () {
                    _animateTo(
                      actualIndex.toDouble(),
                      traversalHaptics: false,
                      settleHaptic: false,
                    );
                  },
                  onActivate: () => widget.onSongActivated?.call(actualIndex),
                  onLongPress: () {
                    _animateTo(
                      actualIndex.toDouble(),
                      traversalHaptics: false,
                      settleHaptic: false,
                    );
                    widget.onSongLongPressed?.call(actualIndex);
                  },
                  onSwipeLeft: () => widget.onSongSwipedLeft?.call(actualIndex),
                  onSwipeRight: () =>
                      widget.onSongSwipedRight?.call(actualIndex),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return items;
  }

  _ItemTransform? _buildTransform({
    required double diff,
    required _OrbitLayoutMetrics metrics,
    required bool cacheResult,
  }) {
    final distanceFromCenter = diff.abs();
    final position = _calculateItemPosition(diff, metrics);

    double scale;
    if (distanceFromCenter < 1.0) {
      scale =
          metrics.selectedScale -
          (metrics.selectedScale - metrics.adjacentScale) * distanceFromCenter;
    } else if (distanceFromCenter < 2.4) {
      scale =
          metrics.adjacentScale -
          (metrics.adjacentScale - metrics.distantScale) *
              ((distanceFromCenter - 1.0) / 1.4);
    } else {
      scale = metrics.distantScale - (distanceFromCenter - 2.4) * 0.1;
    }

    scale = scale.clamp(0.0, metrics.selectedScale).toDouble();
    if (scale < 0.14) {
      return null;
    }

    final focusProgress =
        (1 - (distanceFromCenter / metrics.maxVisibleDistance))
            .clamp(0.0, 1.0)
            .toDouble();

    final transform = _ItemTransform(
      position: _Position(
        position.x + (focusProgress * 4),
        position.y - (focusProgress * 6),
      ),
      scale: scale,
      opacity: (0.18 + (focusProgress * 0.82)).clamp(0.0, 1.0).toDouble(),
      rotation: (diff * 0.055).clamp(-0.1, 0.1).toDouble(),
      isSelected: distanceFromCenter < 0.34,
    );

    if (cacheResult) {
      _transformCache[(diff * 100).toInt()] = transform;
    }

    return transform;
  }

  _Position _calculateItemPosition(
    double relativeIndex,
    _OrbitLayoutMetrics metrics,
  ) {
    final cacheKey = (relativeIndex * 100).toInt();
    final cached = _positionCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    var adjustedIndex = relativeIndex;
    adjustedIndex +=
        relativeIndex.sign * 0.34 * math.min(relativeIndex.abs(), 1.0);
    final angle = adjustedIndex * metrics.itemAngleSpacing;
    final position = _Position(
      metrics.centerX + (metrics.radiusX * math.cos(angle)),
      metrics.centerY + (metrics.radiusY * math.sin(angle)),
    );

    if (!_isScrolling) {
      _positionCache[cacheKey] = position;
    }

    return position;
  }
}

class _Position {
  final double x;
  final double y;

  const _Position(this.x, this.y);
}

class _ItemTransform {
  final _Position position;
  final double scale;
  final double opacity;
  final double rotation;
  final bool isSelected;

  const _ItemTransform({
    required this.position,
    required this.scale,
    required this.opacity,
    required this.rotation,
    required this.isSelected,
  });
}

class _OrbitPathPainter extends CustomPainter {
  final _OrbitLayoutMetrics metrics;

  const _OrbitPathPainter({required this.metrics});

  @override
  void paint(Canvas canvas, Size size) {
    final orbitRect = Rect.fromCenter(
      center: Offset(metrics.centerX, metrics.centerY),
      width: metrics.radiusX * 2,
      height: metrics.radiusY * 2,
    );
    final innerRect = Rect.fromCenter(
      center: Offset(metrics.centerX, metrics.centerY),
      width: (metrics.radiusX - 18) * 2,
      height: (metrics.radiusY - 14) * 2,
    );

    final basePaint = Paint()
      ..color = AppColors.glassBorder.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final focusPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(orbitRect, -1.1, 2.2, false, basePaint);
    canvas.drawArc(innerRect, -1.05, 2.1, false, innerPaint);
    canvas.drawArc(innerRect, -0.26, 0.52, false, focusPaint);

    for (final angle in <double>[-0.52, -0.26, 0.0, 0.26, 0.52]) {
      final start = Offset(
        metrics.centerX + (metrics.radiusX - 12) * math.cos(angle),
        metrics.centerY + (metrics.radiusY - 10) * math.sin(angle),
      );
      final end = Offset(
        metrics.centerX + (metrics.radiusX + 8) * math.cos(angle),
        metrics.centerY + (metrics.radiusY + 6) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    canvas.drawCircle(
      Offset(metrics.focusX, metrics.focusY),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPathPainter oldDelegate) {
    return oldDelegate.metrics != metrics;
  }
}

class _OrbitLayoutMetrics {
  final Size size;

  const _OrbitLayoutMetrics(this.size);

  bool get isCompact => size.width < 360;
  bool get isTablet => size.width >= 600;

  double get focusX =>
      size.width *
      (isTablet
          ? 0.58
          : isCompact
          ? 0.56
          : 0.54);
  double get focusY =>
      size.height *
      (isTablet
          ? 0.47
          : isCompact
          ? 0.44
          : 0.45);
  double get radiusX => size.width * (isTablet ? 0.92 : 0.88);
  double get radiusY =>
      (size.height * (isTablet ? 0.68 : 0.62)).clamp(152.0, 252.0).toDouble();
  double get centerX => focusX - radiusX;
  double get centerY => focusY;

  double get itemAngleSpacing => isTablet
      ? 0.24
      : isCompact
      ? 0.29
      : 0.27;
  int get visibleItemCount => isTablet ? 7 : 5;
  double get selectedScale => isTablet ? 1.12 : 1.08;
  double get adjacentScale => isTablet ? 0.82 : 0.72;
  double get distantScale => isTablet ? 0.58 : 0.48;
  double get maxVisibleDistance => (visibleItemCount / 2) + 0.6;

  Rect get stageRect => Rect.fromCenter(
    center: Offset(focusX, focusY + 4),
    width: (SongCard.baseWidthForScreenWidth(size.width) + 64)
        .clamp(320.0, 584.0)
        .toDouble(),
    height:
        (SongCard.baseHeightForScreenWidth(size.width, isSelected: true) + 46)
            .clamp(180.0, 240.0)
            .toDouble(),
  );

  double get auraWidth => stageRect.width + 140;
  double get auraHeight => stageRect.height + 92;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OrbitLayoutMetrics &&
          runtimeType == other.runtimeType &&
          other.size == size;

  @override
  int get hashCode => size.hashCode;
}
