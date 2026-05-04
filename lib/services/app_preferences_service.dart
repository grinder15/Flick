import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  final bool animationsEnabled;
  final bool hapticsEnabled;

  const AppPreferences({
    this.animationsEnabled = true,
    this.hapticsEnabled = true,
  });

  AppPreferences copyWith({
    bool? animationsEnabled,
    bool? hapticsEnabled,
  }) {
    return AppPreferences(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

class AppPreferencesService {
  static const _animationsKey = 'app_animations_enabled';
  static const _hapticsKey = 'app_haptics_enabled';

  Future<AppPreferences> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      animationsEnabled: prefs.getBool(_animationsKey) ?? true,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
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
}
