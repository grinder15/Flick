import 'package:flick/data/repositories/song_repository.dart';
import 'package:flick/models/song.dart';
import 'package:flick/src/rust/api/metadata_editor.dart' as rust_metadata;

/// Outcome of a metadata write attempt.
enum MetadataWriteOutcome {
  /// Tags written to the file, read back, and confirmed to match the intent.
  verified,

  /// Tags reported written but the read-back could not confirm them. The DB
  /// was still updated to the intended values; a rescan will reconcile.
  unverified,

  /// Nothing was written.
  failed,
}

class MetadataWriteResult {
  final MetadataWriteOutcome outcome;
  final String? message;

  const MetadataWriteResult(this.outcome, {this.message});

  bool get saved => outcome != MetadataWriteOutcome.failed;
  bool get verified => outcome == MetadataWriteOutcome.verified;
}

class MetadataEditorService {
  MetadataEditorService._();
  static final MetadataEditorService instance = MetadataEditorService._();

  Future<rust_metadata.TagReadResult?> readTags(String filePath) async {
    try {
      return await rust_metadata.readTags(path: filePath);
    } catch (_) {
      return null;
    }
  }

  /// Writes [fields] to the actual audio file, verifies them by reading the
  /// tags back, then mirrors the result into the local DB. The read-back is
  /// the integrity guard: it confirms the on-disk file actually holds what we
  /// asked for instead of trusting the write call blindly.
  Future<MetadataWriteResult> writeTags(
    Song song,
    rust_metadata.TagEditFields fields,
  ) async {
    if (song.filePath == null) {
      return const MetadataWriteResult(
        MetadataWriteOutcome.failed,
        message: 'This song has no file path and cannot be edited.',
      );
    }
    if (song.startOffsetMs != null) {
      return const MetadataWriteResult(
        MetadataWriteOutcome.failed,
        message: 'CUE sheet tracks cannot be edited.',
      );
    }
    if (song.isExternal) {
      return const MetadataWriteResult(
        MetadataWriteOutcome.failed,
        message: 'External songs cannot be edited.',
      );
    }

    try {
      final write = await rust_metadata.writeTags(
        path: song.filePath!,
        fields: fields,
      );
      if (!write.success) {
        return MetadataWriteResult(
          MetadataWriteOutcome.failed,
          message: write.error ?? 'Failed to write tags to the file.',
        );
      }

      final readBack = await readTags(song.filePath!);
      final verified = _verifyReadback(readBack, fields);

      await SongRepository().updateSongMetadata(
        song.filePath!,
        title: fields.title,
        artist: fields.artist,
        album: fields.album,
        albumArtist: fields.albumArtist,
        trackNumber: fields.trackNumber,
        discNumber: fields.discNumber,
        year: fields.year,
        genre: fields.genre,
      );

      return verified
          ? const MetadataWriteResult(MetadataWriteOutcome.verified)
          : const MetadataWriteResult(
              MetadataWriteOutcome.unverified,
              message: 'Tags were written but could not be confirmed by '
                  're-reading the file. A library rescan will reconcile '
                  'any difference.',
            );
    } catch (e) {
      return MetadataWriteResult(
        MetadataWriteOutcome.failed,
        message: 'Failed to save metadata: $e',
      );
    }
  }

  /// Compares the freshly read tags against the fields we intended to set.
  /// Only fields with a concrete intent (non-null) are checked; null fields
  /// mean "leave untouched" and are skipped. String compares are normalized so
  /// cosmetic differences (case/whitespace) don't produce false mismatches.
  // ponytail: case-insensitive compare keeps the guard honest without
  // flagging format-specific normalization as corruption.
  bool _verifyReadback(
    rust_metadata.TagReadResult? read,
    rust_metadata.TagEditFields want,
  ) {
    if (read == null) return false;
    return _strMatches(want.title, read.title) &&
        _strMatches(want.artist, read.artist) &&
        _strMatches(want.album, read.album) &&
        _strMatches(want.albumArtist, read.albumArtist) &&
        _strMatches(want.genre, read.genre) &&
        _numMatches(want.year, read.year) &&
        _numMatches(want.trackNumber, read.trackNumber) &&
        _numMatches(want.discNumber, read.discNumber);
  }

  bool _strMatches(String? want, String? got) {
    if (want == null) return true;
    return want.trim().toLowerCase() == (got ?? '').trim().toLowerCase();
  }

  bool _numMatches(int? want, int? got) {
    if (want == null) return true;
    return want == got;
  }
}
