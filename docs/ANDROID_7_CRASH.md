# Android 7/7.1 (API 24/25) Crash

## Symptom

App crashes immediately on Android 7.0 (API 24) and 7.1 (API 25) devices.

## Root Cause

The app's Gradle build targets Java 17 (`sourceCompatibility` / `targetCompatibility = VERSION_17`), but **core library desugaring was not enabled**. Android 7.x lacks native support for Java 8+ library APIs (`java.time`, `java.util.stream`, `java.util.function`, etc.). Without desugaring, any code path touching these APIs throws `NoClassDefFoundError` at runtime.

Additionally, Impeller is force-enabled (`AndroidManifest.xml`:
`io.flutter.embedding.android.EnableImpeller = true`). Older GPU drivers on
Android 7 devices have known compatibility issues with Impeller's rendering
pipeline.

## Fix

Raised `minSdkVersion` from `21` (Android 5.0) to `26` (Android 8.0).

Android 8.0 natively includes all Java 8 library APIs, so the Java 17 compile
target works without desugaring. This one-line change cleanly avoids the crash
without introducing untested desugaring configuration.

### Change

`android/app/build.gradle.kts`:
```kotlin
// Before
minSdk = flutter.minSdkVersion  // 21

// After
minSdk = 26
```

### Why not add desugaring?

- No Android 7 devices available for testing
- Desugaring can have incomplete backports and subtle edge cases
- Raising minSdk is deterministic — no runtime surprises

## Impact

- Devices running Android 5.0–7.1 (API 21–25) can no longer install Flick
- All devices running Android 8.0+ (API 26+) are unaffected
