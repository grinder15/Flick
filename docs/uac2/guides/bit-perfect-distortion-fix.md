# Bit-Perfect USB Audio Distortion Fix

## Problem

When using direct USB audio (UAC2) with bit-perfect mode enabled on the MOONDROP Dawn Pro DAC, audio would experience distortion and playback issues.

## Root Cause

The distortion was caused by two related issues:

1. **Incorrect Audio Focus Management**: The `updateDirectUsbAudioFocus()` method was not properly requesting `AUDIOFOCUS_GAIN` when direct USB playback became active. This caused the Android audio system to not properly prioritize the direct USB audio stream.

2. **Volume Control Conflicts**: When direct USB was active but the DAC didn't expose UAC2 Feature Unit volume controls (hardware volume unavailable), the system would fall back to trying to control Android's system volume mixer, which doesn't affect direct USB audio paths. This could cause unexpected behavior.

## Solution (Commit 661ebe7)

### 1. Audio Focus Fix (`MainActivity.kt`)

Changed `updateDirectUsbAudioFocus()` to properly request `AUDIOFOCUS_GAIN` when `directUsbPlaybackActive` is true:

```kotlin
private fun updateDirectUsbAudioFocus() {
    if (directUsbPlaybackActive) {
        if (directUsbFocusGain == null) {
            Log.i("UAC2", "[USB] Requesting audio focus for direct USB playback")
            requestDirectUsbAudioFocus(AudioManager.AUDIOFOCUS_GAIN)
        }
    } else {
        if (directUsbFocusGain != null || directUsbAudioFocusRequest != null) {
            Log.i("UAC2", "[USB] Releasing direct USB audio focus")
        }
        abandonDirectUsbAudioFocus()
    }
}
```

### 2. Hardware Volume Integration (`MainActivity.kt` + `lib.rs`)

Added native JNI methods to bridge Android with Rust's UAC2 volume control:

**Kotlin (MainActivity.kt):**
- `nativeHasRustDirectUsbHardwareVolume()` - Check if DAC has hardware volume
- `nativeGetRustDirectUsbHardwareVolume()` - Get current hardware volume
- `nativeSetRustDirectUsbHardwareVolume(volume)` - Set hardware volume
- `nativeGetRustDirectUsbHardwareMute()` - Get mute state
- `nativeSetRustDirectUsbHardwareMute(muted)` - Set mute state

**Rust (lib.rs):**
```rust
pub extern "system" fn Java_com_ultraelectronica_flick_MainActivity_nativeHasRustDirectUsbHardwareVolume(...) -> jboolean {
    if crate::uac2::android_direct_has_hardware_volume_control() {
        1
    } else {
        0
    }
}
```

### 3. Volume Mode Tracking (`MainActivity.kt`)

Added proper volume mode detection in `getRouteStatus()`:

```kotlin
val hasDirectUsbHardwareVolume =
    directUsbRegistered && nativeHasRustDirectUsbHardwareVolume()
val hasVolumeControl = if (directUsbRegistered) {
    hasDirectUsbHardwareVolume
} else {
    hasDirectUsbHardwareVolume || hasSystemVolumeControl
}
baseRoute["volumeMode"] = when {
    hasDirectUsbHardwareVolume -> "hardware"
    hasVolumeControl -> "system"
    else -> "unavailable"
}
```

### 4. Player Service Synchronization (`player_service.dart`)

Added volume sync when in bit-perfect mode with hardware volume:

```dart
bool _hasBitPerfectUsbHardwareVolumeControl() {
    final routeStatus = _uac2Service.currentDeviceStatus;
    return Platform.isAndroid &&
        currentEngineType == AudioEngineType.usbDacExperimental &&
        isBitPerfectModeEnabled &&
        routeStatus?.hasVolumeControl == true &&
        routeStatus?.volumeMode == Uac2VolumeMode.hardware;
}
```

## Key Insight

The MOONDROP Dawn Pro DAC (and many other UAC2 devices) don't expose UAC2 Feature Unit volume controls, so hardware volume is unavailable. By properly managing audio focus and not claiming volume control availability when it doesn't exist, the audio path remains clean and bit-perfect.

## Files Modified

- `android/app/src/main/kotlin/com/ultraelectronica/flick/MainActivity.kt` - Audio focus + volume JNI
- `rust/src/lib.rs` - Native method implementations
- `lib/services/player_service.dart` - Volume synchronization logic