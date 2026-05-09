import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flick/services/app_preferences_service.dart';

final appPreferencesServiceProvider = Provider<AppPreferencesService>((ref) {
  return AppPreferencesService();
});

class AppPreferencesNotifier extends Notifier<AppPreferences> {
  bool _initialized = false;

  @override
  AppPreferences build() {
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadPreferences);
    }
    return const AppPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await ref
        .read(appPreferencesServiceProvider)
        .getPreferences();
    if (ref.mounted) {
      state = preferences;
    }
  }

  Future<void> setAnimationsEnabled(bool value) async {
    if (state.animationsEnabled == value) return;
    state = state.copyWith(animationsEnabled: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setAnimationsEnabled(value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (state.hapticsEnabled == value) return;
    state = state.copyWith(hapticsEnabled: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setHapticsEnabled(value);
  }

  Future<void> setShowSmartMixes(bool value) async {
    if (state.showSmartMixes == value) return;
    state = state.copyWith(showSmartMixes: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setShowSmartMixes(value);
  }

  Future<void> setShowRecentArtists(bool value) async {
    if (state.showRecentArtists == value) return;
    state = state.copyWith(showRecentArtists: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setShowRecentArtists(value);
  }

  Future<void> setShowRecentTracks(bool value) async {
    if (state.showRecentTracks == value) return;
    state = state.copyWith(showRecentTracks: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setShowRecentTracks(value);
  }

  Future<void> setShowPlaylistPreviews(bool value) async {
    if (state.showPlaylistPreviews == value) return;
    state = state.copyWith(showPlaylistPreviews: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setShowPlaylistPreviews(value);
  }

  Future<void> setShowBrowseMore(bool value) async {
    if (state.showBrowseMore == value) return;
    state = state.copyWith(showBrowseMore: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setShowBrowseMore(value);
  }

  Future<void> setShowQuickAccess(bool value) async {
    if (state.showQuickAccess == value) return;
    state = state.copyWith(showQuickAccess: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setShowQuickAccess(value);
  }

  Future<void> setCrossfadeEnabled(bool value) async {
    if (state.crossfadeEnabled == value) return;
    state = state.copyWith(crossfadeEnabled: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setCrossfadeEnabled(value);
  }

  Future<void> setCrossfadeDurationSecs(double value) async {
    if (state.crossfadeDurationSecs == value) return;
    state = state.copyWith(crossfadeDurationSecs: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setCrossfadeDurationSecs(value);
  }

  Future<void> setCrossfadeCurveIndex(int value) async {
    if (state.crossfadeCurveIndex == value) return;
    state = state.copyWith(crossfadeCurveIndex: value);
    await ref
        .read(appPreferencesServiceProvider)
        .setCrossfadeCurveIndex(value);
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferences>(
      AppPreferencesNotifier.new,
    );
