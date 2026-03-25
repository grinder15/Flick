import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
// Import will be available after running: flutter_rust_bridge_codegen generate
// ignore: depend_on_referenced_packages, uri_does_not_exist
import 'package:rust_lib_flick_player/src/rust/api/alac_converter_api.dart'
    as alac_api;

/// Service for converting ALAC/M4A files to WAV/PCM format
///
/// This service provides both one-shot and streaming conversion modes:
/// - One-shot: Convert entire file to WAV in memory (for small files)
/// - Streaming: Decode chunks progressively (for large files)
class AlacConverterService {
  /// Convert ALAC/M4A file to WAV and save to temporary file
  ///
  /// Returns the path to the converted WAV file
  static Future<String> convertToWavFile(String sourcePath) async {
    return compute(_convertToWavFileIsolate, sourcePath);
  }

  /// Isolate function for converting to WAV file
  static Future<String> _convertToWavFileIsolate(String sourcePath) async {
    // Read source file
    final sourceFile = File(sourcePath);
    final fileBytes = await sourceFile.readAsBytes();

    // Convert to WAV
    final wavBytes = await alac_api.alacConvertToWav(fileBytes: fileBytes);

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final fileName = sourcePath.split('/').last.replaceAll(RegExp(r'\.(alac|m4a)$', caseSensitive: false), '.wav');
    final wavPath = '${tempDir.path}/$fileName';
    final wavFile = File(wavPath);
    await wavFile.writeAsBytes(wavBytes);

    return wavPath;
  }

  /// Probe ALAC/M4A file metadata without converting
  static Future<alac_api.AlacAudioMetadata> probeMetadata(String filePath) async {
    return compute(_probeMetadataIsolate, filePath);
  }

  /// Isolate function for probing metadata
  static Future<alac_api.AlacAudioMetadata> _probeMetadataIsolate(String filePath) async {
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();
    return alac_api.alacProbeMetadata(fileBytes: fileBytes);
  }

  /// Check if a file is ALAC or M4A format
  static bool isAlacOrM4a(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return extension == 'alac' || extension == 'm4a';
  }
}

/// Streaming ALAC converter for large files
///
/// Usage:
/// ```dart
/// final converter = StreamingAlacConverter();
/// await converter.open(filePath);
/// final stream = converter.streamPcm();
/// await for (final chunk in stream) {
///   // Process PCM chunk
/// }
/// await converter.close();
/// ```
class StreamingAlacConverter {
  int? _sessionId;
  alac_api.AlacAudioMetadata? _metadata;

  /// Open a file for streaming conversion
  Future<void> open(String filePath) async {
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();

    _sessionId = await alac_api.alacCreateSession(fileBytes: fileBytes);
    _metadata = await alac_api.alacGetMetadata(sessionId: _sessionId!);
  }

  /// Get audio metadata
  alac_api.AlacAudioMetadata? get metadata => _metadata;

  /// Get WAV header bytes
  Future<Uint8List> getWavHeader() async {
    if (_sessionId == null) {
      throw StateError('Session not opened');
    }
    final header = await alac_api.alacGetWavHeader(sessionId: _sessionId!);
    return Uint8List.fromList(header);
  }

  /// Stream PCM chunks
  Stream<Uint8List> streamPcm() async* {
    if (_sessionId == null) {
      throw StateError('Session not opened');
    }

    while (true) {
      final chunk = await alac_api.alacDecodeNextChunk(sessionId: _sessionId!);
      if (chunk == null) {
        break;
      }
      yield Uint8List.fromList(chunk);
    }
  }

  /// Seek to a specific time position
  Future<void> seek(double timeSeconds) async {
    if (_sessionId == null) {
      throw StateError('Session not opened');
    }
    await alac_api.alacSeek(sessionId: _sessionId!, timeSeconds: timeSeconds);
  }

  /// Close the conversion session
  Future<void> close() async {
    if (_sessionId != null) {
      await alac_api.alacCloseSession(sessionId: _sessionId!);
      _sessionId = null;
      _metadata = null;
    }
  }

  /// Convert to WAV file using streaming (memory efficient)
  Future<String> convertToWavFile(String sourcePath) async {
    await open(sourcePath);

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = sourcePath
          .split('/')
          .last
          .replaceAll(RegExp(r'\.(alac|m4a)$', caseSensitive: false), '.wav');
      final wavPath = '${tempDir.path}/$fileName';
      final wavFile = File(wavPath);

      // Write WAV header
      final header = await getWavHeader();
      await wavFile.writeAsBytes(header, mode: FileMode.write);

      // Stream and append PCM data
      await for (final chunk in streamPcm()) {
        await wavFile.writeAsBytes(chunk, mode: FileMode.append);
      }

      return wavPath;
    } finally {
      await close();
    }
  }
}

/// Custom audio source for just_audio that converts ALAC on-the-fly
///
/// This allows playing ALAC files through just_audio by converting them
/// to WAV format transparently.
class AlacAudioSource {
  final String sourcePath;
  String? _convertedPath;

  AlacAudioSource(this.sourcePath);

  /// Get the playable audio path (converts if needed)
  Future<String> getPlayablePath() async {
    if (_convertedPath != null) {
      return _convertedPath!;
    }

    if (AlacConverterService.isAlacOrM4a(sourcePath)) {
      _convertedPath = await AlacConverterService.convertToWavFile(sourcePath);
      return _convertedPath!;
    }

    return sourcePath;
  }

  /// Clean up converted file
  Future<void> dispose() async {
    if (_convertedPath != null) {
      try {
        final file = File(_convertedPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete converted file: $e');
      }
      _convertedPath = null;
    }
  }
}
