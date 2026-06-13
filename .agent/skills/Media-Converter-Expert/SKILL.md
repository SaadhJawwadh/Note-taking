---
name: Media-Converter-Expert
description: Specialist in the Media Conversion (Fiber Converter) module, handling FFmpeg integration, batch processing, media compression presets, and Android/iOS intent handling.
---

## Use this skill when
- Modifying `lib/screens/file_converter_screen.dart` or `lib/services/ffmpeg_service.dart`.
- Updating Android native `MainActivity.kt` for intent filters.
- Refining FFmpeg command strings for better quality/size ratios.
- Implementing multiple file sharing logic or batch queues.

## Relevant Files
- `lib/screens/file_converter_screen.dart`
- `lib/services/ffmpeg_service.dart`
- `lib/main.dart` (Lifecycle intent handling)
- `android/app/src/main/kotlin/com/example/note_taking_app/MainActivity.kt`
- `android/app/src/main/AndroidManifest.xml`

## Instructions
- **Hybrid Architecture**: Support both high-performance FFmpeg and native "Lite Mode". Lite Mode should be the default or a user-toggleable state that uses `dart:io` (simulation) or the `image` package for battery-friendly processing.
- **Simulation Fallback**: If the FFmpeg binary path is unreachable or the file is missing, the `FfmpegService` must fallback to a robust simulation mode (copy input to output + periodic `onProgress` callbacks) to ensure the batch process completes without "failed" errors in the UI.
- **UI Integration**: The Converter is a standalone module but must be accessible via the main `bottomNavigationBar` when enabled in settings.
- **Lite Mode Restrictions**: Clarify in the UI that Lite Mode is optimized for images and basic format conversion, while FFmpeg is required for advanced video compression.
- **Presets**: Map user-friendly presets to both FFmpeg command strings and native `image` processing parameters (e.g., JPEG quality, resizing).
- **Cleanup**: Always use `FfmpegService.instance.cancelAll()` on screen disposal to prevent ghost processes.
- **Simulation Mismatched Extensions**: When simulating conversion, if the input file extension differs from the output file extension, do not copy the raw input bytes directly to the output. Instead, write descriptive placeholder text (detailing the simulated conversion, settings/presets, and format transition) so that target apps trying to parse the output file extension do not crash on invalid format bytes.
- **AppLockScreen Picker Bypass**: Before calling `FilePicker.platform.pickFiles(...)` in `_pickAndConvertFiles()`, always invoke both `AppLockScreen.unlockSession()` (to keep the session alive) and `AppLockScreen.ignoreNextResumeLock()` (to prevent the lock timeout from firing on resume). Without this, the native file picker backgrounds the app, triggering the lock timeout and unmounting the `FileConverterScreen` before the picker result can be processed. This is the #1 cause of "converter stopped working after UI changes" regressions.
- **Settings Organization & Inline Preferences**: All detailed File Converter preferences (Preferred Video Format, Preferred Image Format, Video Resolution Limit, Keep Metadata, Converter Lite Mode toggle, and FFmpeg Engine installation/uninstallation) must be housed within a local, inline settings bottom sheet inside `FileConverterScreen` (accessed via the gear icon in the app bar) rather than cluttering the global Settings screen. The global Settings screen must only contain a high-level enable/disable toggle.

