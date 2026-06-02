import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/theme/adaptive_color_provider.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/core/utils/responsive.dart';
import 'package:flick/models/song.dart';
import 'package:flick/data/repositories/song_repository.dart';
import 'package:flick/features/artists/screens/artist_detail_screen.dart';
import 'package:flick/services/player_service.dart';
import 'package:flick/widgets/common/cached_image_widget.dart';
import 'package:flick/widgets/common/display_mode_wrapper.dart';

/// Artists screen with circular avatar cards.
class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final SongRepository _songRepository = SongRepository();
  final PlayerService _playerService = PlayerService();
  Map<String, List<Song>> _artists = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final artists = await _songRepository.getSongsByArtist();
    if (mounted) {
      setState(() {
        _artists = artists;
        _isLoading = false;
      });
    }
  }

  String? _getArtistArt(List<Song> songs) {
    for (final song in songs) {
      if (song.albumArt != null && song.albumArt!.isNotEmpty) {
        return song.albumArt;
      }
    }
    return null;
  }

  String? _getArtworkSourcePath(List<Song> songs) {
    for (final song in songs) {
      final filePath = song.filePath;
      if (filePath != null && filePath.isNotEmpty) {
        return filePath;
      }
    }
    return null;
  }

  String _getArtistInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  void _openArtistDetail(String artistName, List<Song> songs) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtistDetailScreen(
          artistName: artistName,
          songs: songs,
          artistArt: _getArtistArt(songs),
          artistArtSourcePath: _getArtworkSourcePath(songs),
          playerService: _playerService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DisplayModeWrapper(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _artists.isEmpty
                    ? _buildEmptyState()
                    : _buildArtistsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingMd,
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: context.adaptiveTextPrimary,
                size: context.responsiveIcon(AppConstants.iconSizeMd),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artists',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.adaptiveTextPrimary,
                  ),
                ),
                Text(
                  '${_artists.length} artists',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.adaptiveTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: context.adaptiveTextSecondary),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: context.responsiveIcon(AppConstants.containerSizeLg),
            color: context.adaptiveTextTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'No Artists Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: context.adaptiveTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Add music with artist tags to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.adaptiveTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsList() {
    final artistEntries = _artists.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: EdgeInsets.only(bottom: AppConstants.navBarHeight + 120),
      itemCount: artistEntries.length,
      itemBuilder: (context, index) {
        final entry = artistEntries[index];
        return _ArtistCard(
          artistName: entry.key,
          songs: entry.value,
          artistArt: _getArtistArt(entry.value),
          artistArtSourcePath: _getArtworkSourcePath(entry.value),
          initials: _getArtistInitials(entry.key),
          onTap: () => _openArtistDetail(entry.key, entry.value),
        );
      },
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final String artistName;
  final List<Song> songs;
  final String? artistArt;
  final String? artistArtSourcePath;
  final String initials;
  final VoidCallback onTap;

  const _ArtistCard({
    required this.artistName,
    required this.songs,
    required this.artistArt,
    required this.artistArtSourcePath,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueAlbums = songs.map((s) => s.album ?? 'Unknown').toSet().length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Row(
              children: [
                // Circular avatar
                Container(
                  width: context.scaleSize(56),
                  height: context.scaleSize(56),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.surfaceDark, width: 2),
                  ),
                  child: ClipOval(
                    child: CachedImageWidget(
                      imagePath: artistArt,
                      audioSourcePath: artistArtSourcePath,
                      fit: BoxFit.cover,
                      placeholder: _buildInitials(context),
                      errorWidget: _buildInitials(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                // Artist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artistName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.adaptiveTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} songs • $uniqueAlbums albums',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.adaptiveTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: context.adaptiveTextTertiary,
                  size: context.responsiveIcon(AppConstants.iconSizeMd),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: context.adaptiveTextSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


