import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/core/theme/adaptive_color_provider.dart';
import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/utils/responsive.dart';
import 'package:flick/models/song.dart';
import 'package:flick/widgets/common/cached_image_widget.dart';
import 'package:flick/widgets/common/glassmorphism_container.dart';

class OrbitSelectionDeck extends StatelessWidget {
  static double reserveHeightForContext(BuildContext context) {
    return context.responsive(232.0, 224.0, 214.0, 218.0);
  }

  final Song song;
  final int selectedIndex;
  final int totalSongs;
  final bool isNowPlaying;
  final VoidCallback onPlay;
  final VoidCallback onQueue;
  final VoidCallback onFavorite;
  final VoidCallback onMore;

  const OrbitSelectionDeck({
    super.key,
    required this.song,
    required this.selectedIndex,
    required this.totalSongs,
    required this.isNowPlaying,
    required this.onPlay,
    required this.onQueue,
    required this.onFavorite,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final metadataTheme = Theme.of(context).textTheme;
    final resolution = _resolutionLabel(song);
    final album = song.album?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackedActions = constraints.maxWidth < 410;
        final compact = constraints.maxWidth < 360;
        final borderRadius = BorderRadius.circular(AppConstants.radiusXl);

        return GlassmorphismContainerStrong(
          borderRadius: borderRadius,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          AppColors.surfaceLight.withValues(alpha: 0.76),
                          AppColors.surface.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.34, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -44,
                  right: -20,
                  child: IgnorePointer(
                    child: Container(
                      width: 148,
                      height: 148,
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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : AppConstants.spacingMd,
                    compact ? 14 : AppConstants.spacingMd,
                    compact ? 14 : AppConstants.spacingMd,
                    compact ? 12 : AppConstants.spacingMd,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildArtworkThumb(size: compact ? 62 : 70),
                          const SizedBox(width: AppConstants.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppConstants.spacingXs,
                                  runSpacing: AppConstants.spacingXs,
                                  children: [
                                    _DeckPill(
                                      icon: isNowPlaying
                                          ? LucideIcons.audioLines
                                          : LucideIcons.disc3,
                                      label: isNowPlaying
                                          ? 'Now Playing'
                                          : 'Orbital Focus',
                                      foregroundColor:
                                          context.adaptiveTextPrimary,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderColor: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                    _DeckPill(
                                      icon: LucideIcons.hand,
                                      label: 'Tap to play',
                                      foregroundColor:
                                          context.adaptiveTextSecondary,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderColor: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.spacingSm),
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: metadataTheme.titleMedium?.copyWith(
                                    color: context.adaptiveTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.15,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingXxs),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: metadataTheme.bodyMedium?.copyWith(
                                    color: context.adaptiveTextSecondary,
                                  ),
                                ),
                                if (album != null && album.isNotEmpty) ...[
                                  const SizedBox(
                                    height: AppConstants.spacingXxs,
                                  ),
                                  Text(
                                    album,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: metadataTheme.bodySmall?.copyWith(
                                      color: context.adaptiveTextTertiary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppConstants.spacingXs),
                                Wrap(
                                  spacing: AppConstants.spacingXs,
                                  runSpacing: AppConstants.spacingXs,
                                  children: [
                                    _DeckMetaChip(
                                      label: song.fileType.toUpperCase(),
                                    ),
                                    _DeckMetaChip(
                                      label: song.formattedDuration,
                                    ),
                                    if (resolution != null)
                                      _DeckMetaChip(label: resolution),
                                    if (song.trackNumber != null)
                                      _DeckMetaChip(
                                        label:
                                            'Track ${song.trackNumber!.toString().padLeft(2, '0')}',
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          _buildIndexDial(context),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      if (stackedActions) ...[
                        SizedBox(
                          width: double.infinity,
                          child: _OrbitDeckActionButton(
                            icon: isNowPlaying
                                ? LucideIcons.audioLines
                                : LucideIcons.play,
                            label: isNowPlaying
                                ? 'Open Player'
                                : 'Play Selected',
                            onPressed: onPlay,
                            emphasized: true,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: _OrbitDeckActionButton(
                                icon: LucideIcons.listPlus,
                                label: 'Queue',
                                onPressed: onQueue,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _OrbitDeckActionButton(
                                icon: LucideIcons.heart,
                                label: 'Save',
                                onPressed: onFavorite,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            _OrbitDeckIconButton(
                              icon: LucideIcons.ellipsis,
                              onPressed: onMore,
                            ),
                          ],
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _OrbitDeckActionButton(
                                icon: isNowPlaying
                                    ? LucideIcons.audioLines
                                    : LucideIcons.play,
                                label: isNowPlaying
                                    ? 'Open Player'
                                    : 'Play Selected',
                                onPressed: onPlay,
                                emphasized: true,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _OrbitDeckActionButton(
                                icon: LucideIcons.listPlus,
                                label: 'Queue',
                                onPressed: onQueue,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _OrbitDeckActionButton(
                                icon: LucideIcons.heart,
                                label: 'Save',
                                onPressed: onFavorite,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            _OrbitDeckIconButton(
                              icon: LucideIcons.ellipsis,
                              onPressed: onMore,
                            ),
                          ],
                        ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingSm,
                          vertical: AppConstants.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusLg,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 14,
                              color: context.adaptiveTextSecondary,
                            ),
                            const SizedBox(width: AppConstants.spacingXs),
                            Expanded(
                              child: Text(
                                'Tap any card to play it. Swipe a card to queue or save, or use the deck controls below.',
                                style: metadataTheme.bodySmall?.copyWith(
                                  color: context.adaptiveTextTertiary,
                                  height: 1.3,
                                ),
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
      },
    );
  }

  String? _resolutionLabel(Song song) {
    final resolution = song.resolution?.trim();
    if (resolution != null &&
        resolution.isNotEmpty &&
        resolution.toLowerCase() != 'unknown') {
      return resolution;
    }

    if (song.sampleRate == null && song.bitDepth == null) {
      return null;
    }

    final parts = <String>[];
    if (song.bitDepth != null) {
      parts.add('${song.bitDepth}-bit');
    }
    if (song.sampleRate != null) {
      final khz = (song.sampleRate! / 1000).toStringAsFixed(
        song.sampleRate! % 1000 == 0 ? 0 : 1,
      );
      parts.add('${khz}kHz');
    }

    return parts.isEmpty ? null : parts.join('/');
  }

  Widget _buildArtworkThumb({double size = 68}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              imagePath: song.albumArt,
              audioSourcePath: song.filePath,
              fit: BoxFit.cover,
              useThumbnail: true,
              thumbnailWidth: (size * 2).round(),
              thumbnailHeight: (size * 2).round(),
              placeholder: const ColoredBox(
                color: AppColors.surface,
                child: Icon(
                  LucideIcons.music4,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ),
              errorWidget: const ColoredBox(
                color: AppColors.surface,
                child: Icon(
                  LucideIcons.music4,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexDial(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${selectedIndex + 1}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.adaptiveTextPrimary,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/$totalSongs',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.adaptiveTextTertiary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitDeckActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool emphasized;

  const _OrbitDeckActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = emphasized
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.05);
    final border = emphasized
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Ink(
          height: context.responsive(48.0, 50.0, 52.0),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: context.adaptiveTextPrimary),
              const SizedBox(width: AppConstants.spacingXs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.adaptiveTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitDeckIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OrbitDeckIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Ink(
          width: context.responsive(48.0, 50.0, 52.0),
          height: context.responsive(48.0, 50.0, 52.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 18, color: context.adaptiveTextPrimary),
        ),
      ),
    );
  }
}

class _DeckPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  const _DeckPill({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckMetaChip extends StatelessWidget {
  final String label;

  const _DeckMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.adaptiveTextSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
