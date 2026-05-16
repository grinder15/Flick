import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/app_preferences_service.dart';

class WidgetSyncService {
  WidgetSyncService._();
  static final WidgetSyncService instance = WidgetSyncService._();

  static const String _appGroup = 'group.com.mossapps.flick.widgets';

  static const String miniPlayerProvider = 'com.mossapps.flick.widgets.MiniPlayerWidgetProvider';

  static const String keySongId = 'flick_widget_song_id';
  static const String keyTitle = 'flick_widget_title';
  static const String keyArtist = 'flick_widget_artist';
  static const String keyAlbumArt = 'flick_widget_album_art';
  static const String keyIsPlaying = 'flick_widget_is_playing';
  static const String keyHasSong = 'flick_widget_has_song';

  static const String keyBgOpacity = 'flick_widget_bg_opacity';
  static const String keyShowAlbumArt = 'flick_widget_show_album_art';
  static const String keyShowArtist = 'flick_widget_show_artist';
  static const String keyAccentColor = 'flick_widget_accent_color';

  bool _initialized = false;
  Timer? _debounce;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await HomeWidget.setAppGroupId(_appGroup);
  }

  void schedulePush(PlayerState state) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_push(state));
    });
  }

  Future<void> _push(PlayerState state) async {
    try {
      await _ensureInit();
      final Song? song = state.currentSong;
      await HomeWidget.saveWidgetData<bool>(keyHasSong, song != null);
      await HomeWidget.saveWidgetData<bool>(keyIsPlaying, state.isPlaying);
      await HomeWidget.saveWidgetData<String>(keySongId, song?.id ?? '');
      await HomeWidget.saveWidgetData<String>(keyTitle, song?.title ?? '');
      await HomeWidget.saveWidgetData<String>(keyArtist, song?.artist ?? '');
      await HomeWidget.saveWidgetData<String>(
        keyAlbumArt,
        _resolveLocalArt(song?.albumArt),
      );

      await Future.wait<void>([
        HomeWidget.updateWidget(
          qualifiedAndroidName: miniPlayerProvider,
        ),
      ]);
    } catch (e, st) {
      debugPrint('WidgetSyncService push failed: $e\n$st');
    }
  }

  Future<void> pushPaused() async {
    try {
      await _ensureInit();
      await HomeWidget.saveWidgetData<bool>(keyIsPlaying, false);
      await Future.wait<void>([
        HomeWidget.updateWidget(
          qualifiedAndroidName: miniPlayerProvider,
        ),
      ]);
    } catch (e, st) {
      debugPrint('WidgetSyncService pushPaused failed: $e\n$st');
    }
  }

  Future<void> pushCustomization(AppPreferences prefs) async {
    try {
      await _ensureInit();
      await HomeWidget.saveWidgetData<int>(keyBgOpacity, prefs.widgetBgOpacity);
      await HomeWidget.saveWidgetData<bool>(
        keyShowAlbumArt,
        prefs.widgetShowAlbumArt,
      );
      await HomeWidget.saveWidgetData<bool>(
        keyShowArtist,
        prefs.widgetShowArtist,
      );
      await HomeWidget.saveWidgetData<String>(
        keyAccentColor,
        prefs.widgetAccentColor,
      );

      await Future.wait<void>([
        HomeWidget.updateWidget(
          qualifiedAndroidName: miniPlayerProvider,
        ),
      ]);
    } catch (e, st) {
      debugPrint('WidgetSyncService pushCustomization failed: $e\n$st');
    }
  }

  Future<void> pushInitialCustomization() async {
    try {
      await _ensureInit();
      final prefs = await _loadPrefsFromAppPrefs();
      await pushCustomization(prefs);
    } catch (_) {}
  }

  Future<AppPreferences> _loadPrefsFromAppPrefs() async {
    try {
      final prefsService = AppPreferencesService();
      return await prefsService.getPreferences();
    } catch (_) {
      return const AppPreferences();
    }
  }

  String _resolveLocalArt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return '';
    final cleaned = raw.startsWith('file://') ? raw.substring(7) : raw;
    if (!File(cleaned).existsSync()) return '';
    return cleaned;
  }
}

ProviderSubscription<PlayerState> installWidgetSync(WidgetRef ref) {
  unawaited(WidgetSyncService.instance.pushInitialCustomization());
  return ref.listenManual<PlayerState>(
    playerProvider,
    (prev, next) => WidgetSyncService.instance.schedulePush(next),
    fireImmediately: true,
  );
}
