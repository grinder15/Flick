import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  final bool animationsEnabled;
  final bool hapticsEnabled;
  final bool showSmartMixes;
  final bool showRecentArtists;
  final bool showRecentTracks;
  final bool showPlaylistPreviews;
  final bool showBrowseMore;
  final bool showQuickAccess;
  final bool crossfadeEnabled;
  final double crossfadeDurationSecs;
  final int crossfadeCurveIndex;

  const AppPreferences({
    this.animationsEnabled = true,
    this.hapticsEnabled = true,
    this.showSmartMixes = true,
    this.showRecentArtists = true,
    this.showRecentTracks = true,
    this.showPlaylistPreviews = true,
    this.showBrowseMore = true,
    this.showQuickAccess = true,
    this.crossfadeEnabled = false,
    this.crossfadeDurationSecs = 3.0,
    this.crossfadeCurveIndex = 0,
  });

  AppPreferences copyWith({
    bool? animationsEnabled,
    bool? hapticsEnabled,
    bool? showSmartMixes,
    bool? showRecentArtists,
    bool? showRecentTracks,
    bool? showPlaylistPreviews,
    bool? showBrowseMore,
    bool? showQuickAccess,
    bool? crossfadeEnabled,
    double? crossfadeDurationSecs,
    int? crossfadeCurveIndex,
  }) {
    return AppPreferences(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      showSmartMixes: showSmartMixes ?? this.showSmartMixes,
      showRecentArtists: showRecentArtists ?? this.showRecentArtists,
      showRecentTracks: showRecentTracks ?? this.showRecentTracks,
      showPlaylistPreviews: showPlaylistPreviews ?? this.showPlaylistPreviews,
      showBrowseMore: showBrowseMore ?? this.showBrowseMore,
      showQuickAccess: showQuickAccess ?? this.showQuickAccess,
      crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
      crossfadeDurationSecs: crossfadeDurationSecs ?? this.crossfadeDurationSecs,
      crossfadeCurveIndex: crossfadeCurveIndex ?? this.crossfadeCurveIndex,
    );
  }
}

class AppPreferencesService {
  static const _animationsKey = 'app_animations_enabled';
  static const _hapticsKey = 'app_haptics_enabled';
  static const _showSmartMixesKey = 'menu_show_smart_mixes';
  static const _showRecentArtistsKey = 'menu_show_recent_artists';
  static const _showRecentTracksKey = 'menu_show_recent_tracks';
  static const _showPlaylistPreviewsKey = 'menu_show_playlist_previews';
  static const _showBrowseMoreKey = 'menu_show_browse_more';
  static const _showQuickAccessKey = 'menu_show_quick_access';
  static const _crossfadeEnabledKey = 'audio_crossfade_enabled';
  static const _crossfadeDurationKey = 'audio_crossfade_duration_secs';
  static const _crossfadeCurveKey = 'audio_crossfade_curve_index';

  Future<AppPreferences> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      animationsEnabled: prefs.getBool(_animationsKey) ?? true,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
      showSmartMixes: prefs.getBool(_showSmartMixesKey) ?? true,
      showRecentArtists: prefs.getBool(_showRecentArtistsKey) ?? true,
      showRecentTracks: prefs.getBool(_showRecentTracksKey) ?? true,
      showPlaylistPreviews: prefs.getBool(_showPlaylistPreviewsKey) ?? true,
      showBrowseMore: prefs.getBool(_showBrowseMoreKey) ?? true,
      showQuickAccess: prefs.getBool(_showQuickAccessKey) ?? true,
      crossfadeEnabled: prefs.getBool(_crossfadeEnabledKey) ?? false,
      crossfadeDurationSecs: prefs.getDouble(_crossfadeDurationKey) ?? 3.0,
      crossfadeCurveIndex: prefs.getInt(_crossfadeCurveKey) ?? 0,
    );
  }

  Future<bool> getAnimationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_animationsKey) ?? true;
  }

  Future<void> setAnimationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsKey, value);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticsKey) ?? true;
  }

  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }

  Future<bool> getShowSmartMixes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showSmartMixesKey) ?? true;
  }

  Future<void> setShowSmartMixes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSmartMixesKey, value);
  }

  Future<bool> getShowRecentArtists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showRecentArtistsKey) ?? true;
  }

  Future<void> setShowRecentArtists(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRecentArtistsKey, value);
  }

  Future<bool> getShowRecentTracks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showRecentTracksKey) ?? true;
  }

  Future<void> setShowRecentTracks(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRecentTracksKey, value);
  }

  Future<bool> getShowPlaylistPreviews() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showPlaylistPreviewsKey) ?? true;
  }

  Future<void> setShowPlaylistPreviews(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPlaylistPreviewsKey, value);
  }

  Future<bool> getShowBrowseMore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showBrowseMoreKey) ?? true;
  }

  Future<void> setShowBrowseMore(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showBrowseMoreKey, value);
  }

  Future<bool> getShowQuickAccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showQuickAccessKey) ?? true;
  }

  Future<void> setShowQuickAccess(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showQuickAccessKey, value);
  }

  Future<bool> getCrossfadeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_crossfadeEnabledKey) ?? false;
  }

  Future<void> setCrossfadeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crossfadeEnabledKey, value);
  }

  Future<double> getCrossfadeDurationSecs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_crossfadeDurationKey) ?? 3.0;
  }

  Future<void> setCrossfadeDurationSecs(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_crossfadeDurationKey, value);
  }

  Future<int> getCrossfadeCurveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_crossfadeCurveKey) ?? 0;
  }

  Future<void> setCrossfadeCurveIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_crossfadeCurveKey, value);
  }
}
