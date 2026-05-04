import 'package:flutter/services.dart';

/// Centralized haptic patterns used across Flick interactions.
class AppHaptics {
  AppHaptics._();

  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static void tap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  static void confirm() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void emphasis() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
