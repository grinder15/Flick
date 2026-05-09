import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auto_library_sync_service.dart';
import '../services/mediastore_observer_service.dart';
import '../services/background_metadata_service.dart';

final autoLibrarySyncServiceProvider = Provider<AutoLibrarySyncService>((ref) {
  final observerService = Platform.isAndroid ? MediaStoreObserverService() : null;
  final backgroundMetadataService = Platform.isAndroid ? BackgroundMetadataService() : null;
  final service = AutoLibrarySyncService(
    observerService: observerService,
    backgroundMetadataService: backgroundMetadataService,
  );

  ref.onDispose(() {
    service.stop();
  });

  return service;
});

/// Notifier for auto sync enabled state.
class AutoSyncEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// Notifier for auto sync interval in minutes.
class AutoSyncIntervalNotifier extends Notifier<int> {
  @override
  int build() => 5;

  void setInterval(int minutes) => state = minutes;
}

/// Provider for auto sync enabled state.
final autoSyncEnabledProvider = NotifierProvider<AutoSyncEnabledNotifier, bool>(
  AutoSyncEnabledNotifier.new,
);

/// Provider for auto sync interval in minutes.
final autoSyncIntervalProvider = NotifierProvider<AutoSyncIntervalNotifier, int>(
  AutoSyncIntervalNotifier.new,
);

