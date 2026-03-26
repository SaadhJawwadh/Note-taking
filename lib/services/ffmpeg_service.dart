import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../data/settings_provider.dart';

// ──────────────────────────────────────────────
//  Conversion Presets — filtered by media type
// ──────────────────────────────────────────────
enum MediaType { video, image, audio, gif }

enum ConversionPreset {
  // ─── Video ───
  socialVideo720p,
  socialVideoCompress,
  videoToGif,
  // ─── Gif ───
  gifToVideo,
  gifCompress,
  // ─── Audio ───
  audioExtract,
  audioCompressMP3,
  // ─── Image ───
  imageCompress,
  imageResizeSocial,
}

extension ConversionPresetExtension on ConversionPreset {
  String get label {
    switch (this) {
      case ConversionPreset.socialVideo720p:
        return 'Social Media 720p';
      case ConversionPreset.socialVideoCompress:
        return 'Compress (keep resolution)';
      case ConversionPreset.videoToGif:
        return 'Convert to GIF';
      case ConversionPreset.gifToVideo:
        return 'Convert to Video (MP4)';
      case ConversionPreset.gifCompress:
        return 'Compress GIF';
      case ConversionPreset.audioExtract:
        return 'Extract Audio (AAC)';
      case ConversionPreset.audioCompressMP3:
        return 'Compress Audio (MP3)';
      case ConversionPreset.imageCompress:
        return 'Compress (JPEG 80%)';
      case ConversionPreset.imageResizeSocial:
        return 'Social Media (1080px)';
    }
  }

  String get icon {
    switch (this) {
      case ConversionPreset.socialVideo720p:
        return '📱';
      case ConversionPreset.socialVideoCompress:
        return '🗜️';
      case ConversionPreset.videoToGif:
        return '🎞️';
      case ConversionPreset.gifToVideo:
        return '🎬';
      case ConversionPreset.gifCompress:
        return '📉';
      case ConversionPreset.audioExtract:
        return '🎵';
      case ConversionPreset.audioCompressMP3:
        return '🎧';
      case ConversionPreset.imageCompress:
        return '🖼️';
      case ConversionPreset.imageResizeSocial:
        return '📐';
    }
  }

  String get subtitle {
    switch (this) {
      case ConversionPreset.socialVideo720p:
        return 'H.264, CRF 28, 720p + strip metadata';
      case ConversionPreset.socialVideoCompress:
        return 'H.264, CRF 32, original res + strip metadata';
      case ConversionPreset.videoToGif:
        return 'Animated GIF, 10fps, 480px wide';
      case ConversionPreset.gifToVideo:
        return 'MP4 Loop, high compatibility';
      case ConversionPreset.gifCompress:
        return 'Reduce colors, original size';
      case ConversionPreset.audioExtract:
        return 'AAC 128kbps, no video';
      case ConversionPreset.audioCompressMP3:
        return 'MP3 128kbps, strip tags';
      case ConversionPreset.imageCompress:
        return 'JPEG quality 80%, strip EXIF';
      case ConversionPreset.imageResizeSocial:
        return 'Resize to 1080px, JPEG 85%';
    }
  }

  MediaType get mediaType {
    switch (this) {
      case ConversionPreset.socialVideo720p:
      case ConversionPreset.socialVideoCompress:
      case ConversionPreset.videoToGif:
        return MediaType.video;
      case ConversionPreset.gifToVideo:
      case ConversionPreset.gifCompress:
        return MediaType.gif;
      case ConversionPreset.audioExtract:
      case ConversionPreset.audioCompressMP3:
        return MediaType.audio;
      case ConversionPreset.imageCompress:
      case ConversionPreset.imageResizeSocial:
        return MediaType.image;
    }
  }
}

// ──────────────────────────────────────────────
//  Conversion Result — carries size delta info
// ──────────────────────────────────────────────
class ConversionResult {
  final String outputPath;
  final int originalSizeBytes;
  final int compressedSizeBytes;

  ConversionResult({
    required this.outputPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  double get reductionPercent {
    if (originalSizeBytes == 0) return 0;
    return ((originalSizeBytes - compressedSizeBytes) / originalSizeBytes) * 100;
  }

  String get originalSizeFormatted => formatBytes(originalSizeBytes);
  String get compressedSizeFormatted => formatBytes(compressedSizeBytes);

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ──────────────────────────────────────────────
//  FFmpeg Service — FFShare-style engine
// ──────────────────────────────────────────────
class FfmpegService {
  static final FfmpegService instance = FfmpegService._init();
  FfmpegService._init();

  /// Detect media type from file extension.
  MediaType detectMediaType(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.gif') {
      return MediaType.gif;
    }
    if (['.mp4', '.mkv', '.mov', '.avi', '.webm', '.3gp', '.flv', '.ts'].contains(ext)) {
      return MediaType.video;
    }
    if (['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.heic', '.heif'].contains(ext)) {
      return MediaType.image;
    }
    if (['.mp3', '.aac', '.m4a', '.ogg', '.flac', '.wav', '.opus', '.wma'].contains(ext)) {
      return MediaType.audio;
    }
    // Default to video for unknown
    return MediaType.video;
  }

  /// Returns only the presets applicable to the given input file type.
  List<ConversionPreset> presetsForFile(String path) {
    final type = detectMediaType(path);
    // Audio extract is also valid for video files
    return ConversionPreset.values.where((preset) {
      if (type == MediaType.video) {
        return preset.mediaType == MediaType.video || preset == ConversionPreset.audioExtract;
      }
      return preset.mediaType == type;
    }).toList();
  }

  Future<String> _getOutputPath(
    String inputPath,
    ConversionPreset preset,
    SettingsProvider settings,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = p.basenameWithoutExtension(inputPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    String ext;
    switch (preset) {
      case ConversionPreset.socialVideo720p:
      case ConversionPreset.socialVideoCompress:
      case ConversionPreset.gifToVideo:
        ext = '.${settings.preferredVideoFormat}';
        break;
      case ConversionPreset.videoToGif:
      case ConversionPreset.gifCompress:
        ext = '.gif';
        break;
      case ConversionPreset.audioExtract:
        ext = '.m4a';
        break;
      case ConversionPreset.audioCompressMP3:
        ext = '.mp3';
        break;
      case ConversionPreset.imageCompress:
      case ConversionPreset.imageResizeSocial:
        ext = '.${settings.preferredImageFormat}';
        break;
    }

    return p.join(tempDir.path, '${fileName}_${timestamp}_compressed$ext');
  }

  /// Build FFmpeg command.
  List<String> _buildArgs({
    required String inputPath,
    required String outputPath,
    required ConversionPreset preset,
    required SettingsProvider settings,
  }) {
    final List<String> args = ['-y', '-i', inputPath];

    // Metadata handling
    if (!settings.keepMetadata) {
      args.addAll(['-map_metadata', '-1']);
    }

    // Resolution handling (if set by user)
    String? resScale;
    if (preset.mediaType == MediaType.video || preset == ConversionPreset.gifToVideo) {
      switch (settings.videoResolutionLimit) {
        case '1080p':
          resScale = 'scale=iw*min(1,1080/ih):ih*min(1,1080/ih):force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2';
          break;
        case '720p':
          resScale = 'scale=iw*min(1,720/ih):ih*min(1,720/ih):force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2';
          break;
        case '480p':
          resScale = 'scale=iw*min(1,480/ih):ih*min(1,480/ih):force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2';
          break;
      }
    }

    switch (preset) {
      case ConversionPreset.socialVideo720p:
        args.addAll([
          '-vf', resScale ?? 'scale=-2:720',
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '28',
          '-c:a', 'aac', '-b:a', '128k',
        ]);
        break;
      case ConversionPreset.socialVideoCompress:
        if (resScale != null) args.addAll(['-vf', resScale]);
        args.addAll([
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '32',
          '-c:a', 'aac', '-b:a', '96k',
        ]);
        break;
      case ConversionPreset.videoToGif:
        args.addAll(['-vf', 'fps=10,scale=480:-1:flags=lanczos']);
        break;
      case ConversionPreset.gifToVideo:
        final filter = resScale != null ? '$resScale,' : '';
        args.addAll([
          '-vf', '${filter}format=yuv420p',
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '26',
        ]);
        break;
      case ConversionPreset.gifCompress:
        args.addAll(['-vf', 'scale=iw*0.8:ih*0.8']);
        break;
      case ConversionPreset.audioExtract:
        args.addAll(['-vn', '-c:a', 'aac', '-b:a', '128k']);
        break;
      case ConversionPreset.audioCompressMP3:
        args.addAll(['-vn', '-c:a', 'libmp3lame', '-b:a', '128k']);
        break;
      case ConversionPreset.imageCompress:
        args.addAll(['-frames:v', '1', '-q:v', '6']);
        break;
      case ConversionPreset.imageResizeSocial:
        args.addAll(['-frames:v', '1', '-vf', 'scale=1080:-2', '-q:v', '4']);
        break;
    }
    args.add(outputPath);
    return args;
  }

  /// Executes conversion with either FFmpeg or Lite mode.
  Future<ConversionResult?> convertFile({
    required String inputPath,
    required ConversionPreset preset,
    required SettingsProvider settings,
    ValueChanged<double>? onProgress,
  }) async {
    if (settings.isConverterLite) {
      return _convertLite(inputPath, preset, settings);
    }

    final outputPath = await _getOutputPath(inputPath, preset, settings);
    final args = _buildArgs(
      inputPath: inputPath,
      outputPath: outputPath,
      preset: preset,
      settings: settings,
    );
    final command = args.join(' ');

    // Get original file size
    final originalFile = File(inputPath);
    final originalSize = await originalFile.length();

    // Execute FFmpeg
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        final compressedSize = await outputFile.length();
        return ConversionResult(
          outputPath: outputPath,
          originalSizeBytes: originalSize,
          compressedSizeBytes: compressedSize,
        );
      }
    }
    return null;
  }

  /// Lightweight "conversion" using simple Dart libs/io.
  Future<ConversionResult?> _convertLite(
    String inputPath,
    ConversionPreset preset,
    SettingsProvider settings,
  ) async {
    final originalFile = File(inputPath);
    final originalSize = await originalFile.length();
    final outputPath = await _getOutputPath(inputPath, preset, settings);

    try {
      if (preset.mediaType == MediaType.image) {
        final bytes = await originalFile.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          List<int> outputBytes;
          if (preset == ConversionPreset.imageResizeSocial) {
            final resized = img.copyResize(image, width: 1080);
            outputBytes = settings.preferredImageFormat == 'png'
                ? img.encodePng(resized)
                : img.encodeJpg(resized, quality: 85);
          } else {
            outputBytes = settings.preferredImageFormat == 'png'
                ? img.encodePng(image)
                : img.encodeJpg(image, quality: 80);
          }
          await File(outputPath).writeAsBytes(outputBytes);
          return ConversionResult(
            outputPath: outputPath,
            originalSizeBytes: originalSize,
            compressedSizeBytes: outputBytes.length,
          );
        }
      }

      // Fallback: Copy file (as "conversion") if lite mode cannot actually process it.
      // This allows the user to still share/save even if compression is unavailable.
      await originalFile.copy(outputPath);
      return ConversionResult(
        outputPath: outputPath,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
      );
    } catch (e) {
      debugPrint('Lite conversion error: $e');
      return null;
    }
  }

  void cancelAll() {
    FFmpegKit.cancel();
  }
}
