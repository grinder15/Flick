import 'package:flutter/foundation.dart';
import 'package:flick/models/audio_engine_type.dart';

enum AudioPathManagement {
  androidManagedShared,
  androidManagedLowLatency,
  directUsbExperimental,
}

@immutable
class AudioCapabilityFlags {
  const AudioCapabilityFlags({
    required this.supportsExclusiveUsbOwnership,
    required this.supportsDirectSampleRateSwitching,
    required this.supportsVerifiedBitPerfect,
    required this.supportsAndroidManagedHighResOnly,
    required this.supportsInternalDapPathOnly,
  });

  final bool supportsExclusiveUsbOwnership;
  final bool supportsDirectSampleRateSwitching;
  final bool supportsVerifiedBitPerfect;
  final bool supportsAndroidManagedHighResOnly;
  final bool supportsInternalDapPathOnly;
}

@immutable
class AudioOutputDiagnostics {
  const AudioOutputDiagnostics({
    required this.selectedMode,
    required this.initializedMode,
    required this.pathManagement,
    required this.capabilityStateLabel,
    required this.backendDescription,
    required this.routeType,
    required this.routeLabel,
    required this.outputDeviceLabel,
    required this.isMixerManaged,
    required this.audioFocusHeld,
    required this.directUsbRegistered,
    required this.usbInterfaceClaimed,
    required this.usbStreamStable,
    required this.trackSampleRate,
    required this.requestedOutputSampleRate,
    required this.reportedOutputSampleRate,
    required this.activeOutputSignature,
    required this.fallbackReason,
    required this.capabilityFlags,
  });

  final AudioEngineType selectedMode;
  final AudioEngineType? initializedMode;
  final AudioPathManagement pathManagement;
  final String capabilityStateLabel;
  final String backendDescription;
  final String routeType;
  final String routeLabel;
  final String outputDeviceLabel;
  final bool isMixerManaged;
  final bool audioFocusHeld;
  final bool directUsbRegistered;
  final bool usbInterfaceClaimed;
  final bool usbStreamStable;
  final int? trackSampleRate;
  final int? requestedOutputSampleRate;
  final int? reportedOutputSampleRate;
  final String? activeOutputSignature;
  final String? fallbackReason;
  final AudioCapabilityFlags capabilityFlags;
}
