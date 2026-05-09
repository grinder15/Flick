import 'dart:async';
import 'package:flutter/foundation.dart';
import 'music_folder_service.dart';
import '../data/repositories/song_repository.dart';
import '../data/entities/song_entity.dart';

class BackgroundMetadataService {
  final MusicFolderService _musicFolderService;
  final SongRepository _songRepository;

  bool _isRunning = false;
  Timer? _timer;

  BackgroundMetadataService({
    MusicFolderService? musicFolderService,
    SongRepository? songRepository,
  })  : _musicFolderService = musicFolderService ?? MusicFolderService(),
        _songRepository = songRepository ?? SongRepository();

  void startPeriodicExtraction({Duration interval = const Duration(minutes: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => extractPendingMetadata());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<int> extractPendingMetadata() async {
    if (_isRunning) return 0;
    _isRunning = true;

    try {
      final incomplete = await _songRepository.getIncompleteMetadataSongs();
      if (incomplete.isEmpty) return 0;

      const batchSize = 100;
      var totalUpdated = 0;

      for (var i = 0; i < incomplete.length; i += batchSize) {
        final batch = incomplete.sublist(
          i,
          (i + batchSize > incomplete.length) ? incomplete.length : i + batchSize,
        );

        final contentUris = batch
            .where((s) => s.filePath.startsWith('content://'))
            .map((s) => s.filePath)
            .toList();

        if (contentUris.isEmpty) {
          for (final song in batch) {
            song.metadataComplete = true;
          }
          await _songRepository.upsertSongs(batch);
          totalUpdated += batch.length;
          continue;
        }

        try {
          final metadataList = await _musicFolderService.fetchMetadata(contentUris);
          final metaByUri = <String, AudioFileInfo>{};
          for (final m in metadataList) {
            metaByUri[m.uri] = m;
          }

          final updateBatch = <SongEntity>[];
          for (final song in batch) {
            final meta = metaByUri[song.filePath];
            if (meta != null) {
              song.sampleRate = meta.sampleRate ?? song.sampleRate;
              song.bitDepth = meta.bitDepth ?? song.bitDepth;
              song.discNumber = meta.discNumber ?? song.discNumber;
              song.albumArtist = (meta.albumArtist?.trim().isNotEmpty ?? false)
                  ? meta.albumArtist!.trim()
                  : song.albumArtist;
            }
            song.metadataComplete = true;
            updateBatch.add(song);
          }

          await _songRepository.upsertSongs(updateBatch);
          totalUpdated += updateBatch.length;
        } catch (e) {
          debugPrint('BackgroundMetadataService batch failed: $e');
        }
      }

      return totalUpdated;
    } finally {
      _isRunning = false;
    }
  }
}
