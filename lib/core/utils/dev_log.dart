import 'package:flutter/foundation.dart';
import 'package:flick/services/uac2_preferences_service.dart';

void devLog(String message) {
  if (Uac2PreferencesService.isDeveloperModeEnabledSync) {
    debugPrint(message);
  }
}
