import 'package:flutter/material.dart';

import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/utils/app_haptics.dart';
import 'package:flick/models/song.dart';
import 'package:flick/widgets/common/cached_image_widget.dart';
import 'package:flick/widgets/common/marquee_widget.dart';

/// Song card widget for displaying in the orbit scroll.
class SongCard extends StatefulWidget {
  static double baseWidthForScreenWidth(double screenWidth) {
    return (screenWidth * 0.72).clamp(284.0, 520.0).toDouble();
  }

  static double baseHeightForScreenWidth(
    double screenWidth, {
    required bool isSelected,
  }) {
    final width = baseWidthForScreenWidth(screenWidth);
    final ratio = isSelected ? 0.44 : 0.4;
    final minHeight = isSelected ? 146.0 : 134.0;
    final maxHeight = isSelected ? 188.0 : 170.0;
    return (width * ratio).clamp(minHeight, maxHeight).toDouble();
  }

  /// Song data to display.
  final Song song;

  /// Scale factor based on position in orbit.
  final double scale;

  /// Opacity based on position in orbit.
  final double opacity;

  /// Whether this song is currently selected.
  final bool isSelected;

  /// Whether the song is the current active track.
  final bool isNowPlaying;

  /// Callback when a non-selected card should move into focus.
  final VoidCallback? onFocusRequested;

  /// Callback when the selected card should trigger playback/open.
  final VoidCallback? onActivate;

  /// Callback when the card is long pressed.
  final VoidCallback? onLongPress;

  /// Callback when the card is swiped left.
  final VoidCallback? onSwipeLeft;

  /// Callback when the card is swiped right.
  final VoidCallback? onSwipeRight;

  const SongCard({
    super.key,
    required this.song,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.isSelected = false,
    this.isNowPlaying = false,
    this.onFocusRequested,
    this.onActivate,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  static const double _maxSwipeReveal = 128;
  static const double _actionThreshold = 84;

  double _dragDx = 0;
  bool _queuedFlash = false;
  bool _favoriteFlash = false;
  bool _queueThresholdReached = false;
  bool _favoriteThresholdReached = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = SongCard.baseWidthForScreenWidth(screenWidth);
    final cardHeight = SongCard.baseHeightForScreenWidth(
      screenWidth,
      isSelected: widget.isSelected,
    );
    final queueRevealProgress = (-_dragDx / _maxSwipeReveal)
        .clamp(0.0, 1.0)
        .toDouble();
    final favoriteRevealProgress = (_dragDx / _maxSwipeReveal)
        .clamp(0.0, 1.0)
        .toDouble();

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${widget.song.title} by ${widget.song.artist}',
        hint: widget.isSelected
            ? 'Double tap to play. Swipe left to queue. Swipe right to favorite.'
            : 'Double tap to focus this song.',
        onTap: _handleTap,
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onHorizontalDragCancel: _resetSwipeState,
          child: AnimatedOpacity(
            duration: AppConstants.animationNormal,
            opacity: widget.opacity,
            child: Transform.scale(
              scale: widget.scale,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildSwipeBackdrop(
                        queueRevealProgress: queueRevealProgress,
                        favoriteRevealProgress: favoriteRevealProgress,
                      ),
                    ),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      offset: Offset(_dragDx / cardWidth, 0),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: (_queuedFlash || _favoriteFlash) ? 0.99 : 1,
                        child: _buildCardShell(
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (widget.isSelected) {
      widget.onActivate?.call();
      return;
    }

    AppHaptics.tap();
    widget.onFocusRequested?.call();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final nextDx = (_dragDx + details.delta.dx)
        .clamp(-_maxSwipeReveal, _maxSwipeReveal)
        .toDouble();
    if (nextDx == _dragDx) {
      return;
    }

    _updateSwipeThresholdFeedback(nextDx);
    setState(() {
      _dragDx = nextDx;
    });
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final shouldFavorite =
        _dragDx >= _actionThreshold ||
        (details.primaryVelocity != null && details.primaryVelocity! > 400);
    final shouldQueue =
        _dragDx <= -_actionThreshold ||
        (details.primaryVelocity != null && details.primaryVelocity! < -400);

    if (shouldFavorite) {
      await _triggerSwipeAction(isFavorite: true);
      return;
    }

    if (shouldQueue) {
      await _triggerSwipeAction(isFavorite: false);
      return;
    }

    _resetSwipeState();
  }

  Future<void> _triggerSwipeAction({required bool isFavorite}) async {
    setState(() {
      _dragDx = 0;
      _queuedFlash = !isFavorite;
      _favoriteFlash = isFavorite;
      _queueThresholdReached = false;
      _favoriteThresholdReached = false;
    });

    if (isFavorite) {
      widget.onSwipeRight?.call();
    } else {
      widget.onSwipeLeft?.call();
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }

    setState(() {
      _queuedFlash = false;
      _favoriteFlash = false;
    });
  }

  void _updateSwipeThresholdFeedback(double nextDx) {
    final nextQueueThreshold = nextDx <= -_actionThreshold;
    final nextFavoriteThreshold = nextDx >= _actionThreshold;

    if (nextQueueThreshold != _queueThresholdReached ||
        nextFavoriteThreshold != _favoriteThresholdReached) {
      if (nextQueueThreshold || nextFavoriteThreshold) {
        AppHaptics.selection();
      }

      _queueThresholdReached = nextQueueThreshold;
      _favoriteThresholdReached = nextFavoriteThreshold;
    }
  }

  void _resetSwipeState() {
    if (_dragDx == 0 &&
        !_queueThresholdReached &&
        !_favoriteThresholdReached &&
        !_queuedFlash &&
        !_favoriteFlash) {
      return;
    }

    setState(() {
      _dragDx = 0;
      _queueThresholdReached = false;
      _favoriteThresholdReached = false;
    });
  }

  Widget _buildCardShell({
    required double cardWidth,
    required double cardHeight,
  }) {
    final borderColor = widget.isSelected
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    final compact = cardWidth < 320;
    final artExtent = (cardHeight - (compact ? 22 : 24))
        .clamp(92.0, 134.0)
        .toDouble();
    final album = widget.song.album?.trim();
    final resolution = _resolutionLabel();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusXl + 4),
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: widget.isSelected ? 0.1 : 0.06),
            AppColors.surfaceLight.withValues(
              alpha: widget.isSelected ? 0.96 : 0.9,
            ),
            AppColors.surface.withValues(alpha: 0.98),
          ],
          stops: const [0.0, 0.28, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isSelected ? 0.34 : 0.2,
            ),
            blurRadius: widget.isSelected ? 30 : 20,
            offset: const Offset(0, 12),
          ),
          if (_queuedFlash || _favoriteFlash)
            BoxShadow(
              color: (_favoriteFlash ? Colors.redAccent : AppColors.accent)
                  .withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXl + 4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -36,
              top: -28,
              child: IgnorePointer(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -42,
              bottom: -44,
              child: IgnorePointer(
                child: Container(
                  width: 164,
                  height: 164,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(
                          alpha: widget.isSelected ? 0.12 : 0.05,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 10 : AppConstants.spacingSm),
              child: Row(
                children: [
                  _buildArtworkPanel(artExtent),
                  SizedBox(width: compact ? 10 : AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusPill(),
                            const Spacer(),
                            _buildTrailingIndicator(),
                          ],
                        ),
                        SizedBox(
                          height: widget.isSelected
                              ? AppConstants.spacingSm
                              : AppConstants.spacingXs,
                        ),
                        _buildTitle(),
                        const SizedBox(height: AppConstants.spacingXxs),
                        Text(
                          widget.song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        if (album != null && album.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            album,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.56),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Wrap(
                          spacing: AppConstants.spacingXs,
                          runSpacing: AppConstants.spacingXs,
                          children: [
                            _buildMetadataChip(
                              widget.song.fileType.toUpperCase(),
                              prominent: true,
                            ),
                            _buildMetadataChip(widget.song.formattedDuration),
                            if (resolution != null)
                              _buildMetadataChip(resolution),
                            if (widget.song.trackNumber != null)
                              _buildMetadataChip(
                                'T${widget.song.trackNumber!.toString().padLeft(2, '0')}',
                              ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(
                          widget.isSelected
                              ? 'Tap selected card to play. Swipe to queue or save.'
                              : 'Tap to focus this song.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.66),
                            letterSpacing: 0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolutionLabel() {
    final resolution = widget.song.resolution?.trim();
    if (resolution != null &&
        resolution.isNotEmpty &&
        resolution.toLowerCase() != 'unknown') {
      return resolution;
    }

    if (widget.song.sampleRate == null && widget.song.bitDepth == null) {
      return null;
    }

    final parts = <String>[];
    if (widget.song.bitDepth != null) {
      parts.add('${widget.song.bitDepth}-bit');
    }
    if (widget.song.sampleRate != null) {
      final khz = (widget.song.sampleRate! / 1000).toStringAsFixed(
        widget.song.sampleRate! % 1000 == 0 ? 0 : 1,
      );
      parts.add('${khz}kHz');
    }

    return parts.isEmpty ? null : parts.join('/');
  }

  Widget _buildSwipeBackdrop({
    required double queueRevealProgress,
    required double favoriteRevealProgress,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusXl + 4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.redAccent.withValues(
              alpha: 0.12 + (favoriteRevealProgress * 0.16),
            ),
            AppColors.surface,
            AppColors.accent.withValues(
              alpha: 0.12 + (queueRevealProgress * 0.16),
            ),
          ],
        ),
        border: Border.all(
          color: Color.lerp(
            AppColors.accent.withValues(
              alpha: 0.16 + (queueRevealProgress * 0.24),
            ),
            Colors.redAccent.withValues(
              alpha: 0.16 + (favoriteRevealProgress * 0.24),
            ),
            favoriteRevealProgress,
          )!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
        child: Row(
          children: [
            Opacity(
              opacity: favoriteRevealProgress,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacingXs),
                  Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Opacity(
              opacity: queueRevealProgress,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingXs),
                  Icon(
                    Icons.queue_music_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkPanel(double artExtent) {
    return Container(
      width: artExtent,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              imagePath: widget.song.albumArt ?? '',
              audioSourcePath: widget.song.filePath,
              fit: BoxFit.cover,
              placeholder: _buildPlaceholderArt(),
              errorWidget: _buildPlaceholderArt(),
              useThumbnail: true,
              thumbnailWidth: (artExtent * 2).round(),
              thumbnailHeight: (artExtent * 2).round(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.46),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppConstants.spacingXs,
              right: AppConstants.spacingXs,
              bottom: AppConstants.spacingXs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXs,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isNowPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.album_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Expanded(
                      child: Text(
                        widget.isNowPlaying ? 'Playing' : 'Artwork',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.88),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceLight, AppColors.surface],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.textTertiary,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    final label = widget.isNowPlaying
        ? 'Now Playing'
        : widget.isSelected
        ? 'Focused'
        : 'Orbit';
    final icon = widget.isNowPlaying
        ? Icons.graphic_eq_rounded
        : widget.isSelected
        ? Icons.adjust_rounded
        : Icons.track_changes_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: widget.isSelected || widget.isNowPlaying ? 0.1 : 0.05,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.88),
              letterSpacing: 0.28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIndicator() {
    final icon = widget.isNowPlaying
        ? Icons.graphic_eq_rounded
        : widget.isSelected
        ? Icons.play_arrow_rounded
        : Icons.chevron_right_rounded;

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(
          alpha: widget.isSelected || widget.isNowPlaying ? 0.11 : 0.05,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.82)),
    );
  }

  Widget _buildTitle() {
    if (widget.isSelected) {
      return SizedBox(
        height: 24,
        child: MarqueeWidget(
          child: Text(
            widget.song.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.15,
            ),
          ),
        ),
      );
    }

    return Text(
      widget.song.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
    );
  }

  Widget _buildMetadataChip(String text, {bool prominent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: prominent
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: prominent ? FontWeight.w700 : FontWeight.w600,
          color: Colors.white.withValues(alpha: prominent ? 0.92 : 0.78),
          letterSpacing: 0.18,
        ),
      ),
    );
  }
}
