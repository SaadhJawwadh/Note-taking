---
name: Media-Converter-Expert
description: Specialist in the Media Conversion (Fiber Converter) module, handling FFmpeg integration, batch processing, media compression presets, and Android/iOS intent handling.
---

# Media Converter Expert

Use this skill when modifying the file compression screen, FFmpeg commands, sharing targets, or platform integrations.

## 1. Native Lite vs. FFmpeg Modes
* **Hybrid Execution**: Support both native platform compression (Lite Mode) and advanced FFmpeg binary execution (FFmpeg Mode).
* **Presets & Formats**: Map image scaling and JPEG quality settings in Lite Mode, and custom video format configurations (mp4, mkv, gif, webp) in FFmpeg Mode.
* **Process Cleanup**: Ensure `FfmpegService.instance.cancelAll()` is invoked on screen disposal to clear background processes.

## 2. Simulation & Extensions Fallbacks
* **Simulation Mode**: If FFmpeg binaries are missing or fail to download, fall back to a simulation that copies inputs to target paths and fires periodic `onProgress` callbacks.
* **Mismatched Extensions**: During simulation, if the input file extension differs from the output file extension, do not copy the raw input bytes. Instead, write descriptive placeholder text (documenting simulated settings and format changes) to prevent target apps from crashing when opening files with invalid headers.

## 3. Screen Navigation & Picker Safety
* **Picker Lock Bypass**: Call `AppLockScreen.ignoreNextResumeLock()` immediately before invoking native file/image pickers to prevent the background-pause state from locking the screen and unmounting the converter view state upon return.
* **Inline Preferences**: House all detailed preferences (formats, metadata options, FFmpeg installer) inside a local settings bottom sheet in `FileConverterScreen`. Keep only the main switch in global settings.
