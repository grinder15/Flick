import 'dart:async';
import 'package:flutter/foundation.dart';
import 'library_scanner_service.dart';

/// Service for automatically syncing library changes in the background.
class AutoLibrarySyncService {
  final LibraryScannerService _scannerService;

  Timer? _syncTimer;
  bool _isRunning = false;
  bool _isSyncing = false;

  // Configurable sync interval (default: 5 minutes)
  Duration syncInterval = const Duration(minutes: 5);

  AutoLibrarySyncService({
    LibraryScannerService? scannerService,
  }) : _scannerService = scannerService ?? LibraryScannerService();

  /// Start automatic library syncing.
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint(
      'Auto library sync started (interval: ${syncInterval.inMinutes} minutes)',
    );

    _syncTimer = Timer.periodic(syncInterval, (_) => _performSync());
  }

  /// Stop automatic library syncing.
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
    debugPrint('Auto library sync stopped');
  }

  /// Manually trigger a sync.
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
