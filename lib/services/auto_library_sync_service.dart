import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'library_scanner_service.dart';
import 'mediastore_observer_service.dart';
import 'background_metadata_service.dart';

class AutoLibrarySyncService {
  final LibraryScannerService _scannerService;
  final MediaStoreObserverService? _observerService;
  final BackgroundMetadataService? _backgroundMetadataService;

  Timer? _syncTimer;
  bool _isRunning = false;
  bool _isSyncing = false;

  Duration syncInterval = const Duration(minutes: 30);

  AutoLibrarySyncService({
    LibraryScannerService? scannerService,
    MediaStoreObserverService? observerService,
    BackgroundMetadataService? backgroundMetadataService,
  })  : _scannerService = scannerService ?? LibraryScannerService(),
        _observerService = observerService,
        _backgroundMetadataService = backgroundMetadataService;

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint(
      'Auto library sync started (interval: ${syncInterval.inMinutes} minutes)',
    );

    if (Platform.isAndroid && _observerService != null) {
      _observerService.start();
    }

    _backgroundMetadataService?.startPeriodicExtraction();

    _syncTimer = Timer.periodic(syncInterval, (_) => _performSync());
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _observerService?.stop();
    _backgroundMetadataService?.stop();
    _isRunning = false;
    debugPrint('Auto library sync stopped');
  }

  Future<void> syncNow() async {
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;
    debugPrint('Starting automatic library sync...');

    try {
      await _scannerService.refreshDeletions();
      debugPrint('Sync complete: checked for deleted files');
    } catch (e) {
      debugPrint('Error during automatic sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  bool get isRunning => _isRunning;
  bool get isSyncing => _isSyncing;
}
