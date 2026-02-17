import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flick/providers/equalizer_provider.dart';
import 'package:flick/services/player_service.dart';
import 'package:flick/src/rust/api/audio_api.dart' as rust_audio;

const MethodChannel _androidEqualizerChannel = MethodChannel(
  'com.ultraelectronica.flick/equalizer',
);

/// Log Android equalizer failure only once to avoid log spam.
bool _androidEqualizerErrorLogged = false;

/// Applies equalizer state to the active audio backend.
/// Rust engine (desktop): graphic EQ is applied via Rust.
/// Android: uses native AudioEffect API with just_audio's audio session ID.
Future<void> applyEqualizer(EqualizerState state) async {
  final useGraphic = state.mode == EqMode.graphic;
  final gains = useGraphic
      ? state.graphicGainsDb
      : _parametricToGraphicGains(state.parametricBands);

  if (gains.length != 10) {
    debugPrint('applyEqualizer: Invalid gains length: ${gains.length}');
    return;
  }

  // Android: use native AudioEffect API with session ID from just_audio
  if (Platform.isAndroid) {
    final sessionId = PlayerService().androidAudioSessionId;
    if (sessionId == null && state.enabled) {
      if (!_androidEqualizerErrorLogged) {
        _androidEqualizerErrorLogged = true;
        debugPrint(
          'applyEqualizer: Android audio session not ready (start playback first)',
        );
      }
      return;
    }
    try {
      await _androidEqualizerChannel.invokeMethod('setEqualizer', {
        'enabled': state.enabled,
        'gainsDb': gains,
        'audioSessionId': sessionId,
      });
      if (state.enabled) {
        debugPrint(
          'applyEqualizer: Successfully applied Android equalizer settings',
        );
      }
      _androidEqualizerErrorLogged = false;
    } catch (e) {
      if (!_androidEqualizerErrorLogged) {
        _androidEqualizerErrorLogged = true;
        debugPrint('applyEqualizer: Android equalizer failed: $e');
      }
    }
    return;
  }

  // Desktop: use Rust audio engine
  final isAvailable = rust_audio.audioIsNativeAvailable();
  final isInitialized = rust_audio.audioIsInitialized();

  debugPrint(
    'applyEqualizer: available=$isAvailable, initialized=$isInitialized, enabled=${state.enabled}',
  );

  if (!isAvailable || !isInitialized) {
    debugPrint(
      'applyEqualizer: Skipping - Rust audio engine not available or not initialized',
    );
    return;
  }

  debugPrint('applyEqualizer: Applying EQ with gains: $gains');

  try {
    rust_audio.audioSetEqualizer(
      enabled: state.enabled,
      gainsDb: List<double>.from(gains),
    );
    debugPrint('applyEqualizer: Successfully applied Rust equalizer settings');
  } catch (e) {
    debugPrint('applyEqualizer: Rust equalizer failed: $e');
  }
}

/// Map parametric bands to 10-band gains for Rust engine (graphic-only).
List<double> _parametricToGraphicGains(List<ParametricBand> bands) {
  final out = List<double>.filled(10, 0.0, growable: false);
  final freqs = EqualizerState.defaultGraphicFrequenciesHz;
  for (var i = 0; i < 10; i++) {
    final f = freqs[i];
    for (final b in bands) {
      if (!b.enabled) continue;
      final dist = (b.frequencyHz - f).abs();
      final bw = b.frequencyHz / b.q;
      if (dist < bw) {
        final t = dist / bw;
        out[i] = out[i] + b.gainDb * (1.0 - t);
      }
    }
  }
  return out;
}
