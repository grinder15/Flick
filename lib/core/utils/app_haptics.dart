import 'package:flutter/services.dart';

/// Centralized haptic patterns used across Flick interactions.
class AppHaptics {
  AppHaptics._();

  static void tap() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void confirm() {
    HapticFeedback.mediumImpact();
  }

  static void emphasis() {
    HapticFeedback.heavyImpact();
  }
}
