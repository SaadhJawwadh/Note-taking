import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/settings_provider.dart';

class FfmpegInstallService {
  static final FfmpegInstallService instance = FfmpegInstallService._init();
  FfmpegInstallService._init();

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  /// Checks if the engine is "installed".
  /// In a real app, this would verify the existence and checksum of the binary.
  Future<bool> checkInstallation() async {
    final directory = await getApplicationSupportDirectory();
    final ffmpegDir = Directory(p.join(directory.path, 'ffmpeg_engine'));
    
    if (!await ffmpegDir.exists()) return false;
    
    // Check for a dummy marker file for this prototype
    final marker = File(p.join(ffmpegDir.path, 'installed.marker'));
    return await marker.exists();
  }

  /// Returns the path to the FFmpeg executable.
  Future<String?> getBinaryPath() async {
    final directory = await getApplicationSupportDirectory();
    // On Android/iOS, this would be the actual path to the downloaded executable
    // For this prototype, we'll return a simulated path if installed
    if (await checkInstallation()) {
      return p.join(directory.path, 'ffmpeg_engine', 'ffmpeg');
    }
    return null;
  }

  /// Simulates downloading the FFmpeg engine.
  /// In a real implementation, this would fetch from a CDN based on ABI.
  Future<bool> installEngine(SettingsProvider settings) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadProgress = 0;
    
    try {
      // 1. Determine architecture-specific download path
      String abi;
      if (Platform.isAndroid) {
        // Simple mapping of supported Android ABIs
        final processResult = await Process.run('getprop', ['ro.product.cpu.abi']);
        abi = (processResult.stdout as String).trim();
      } else if (Platform.isIOS) {
        abi = 'ios-arm64';
      } else {
        abi = 'generic';
      }

      // Real-world path mapping example:
      // Map<String, String> abiUrls = {
      //   'arm64-v8a': 'https://example.com/ffmpeg-arm64-v8a.zip',
      //   'armeabi-v7a': 'https://example.com/ffmpeg-armeabi-v7a.zip',
      //   'x86_64': 'https://example.com/ffmpeg-x86_64.zip',
      // };
      // String downloadUrl = abiUrls[abi] ?? 'https://example.com/ffmpeg-generic.zip';
      
      debugPrint('Detected Architecture: $abi. Proceeding with download...');

      // 2. Simulate download progress
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 150));
        _downloadProgress = i / 100;
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        settings.notifyListeners(); // Trigger UI update for progress
      }

      // 3. Create engine directory
      final directory = await getApplicationSupportDirectory();
      final ffmpegDir = Directory(p.join(directory.path, 'ffmpeg_engine'));
      if (!await ffmpegDir.exists()) {
        await ffmpegDir.create(recursive: true);
      }

      // 4. Create dummy marker file (but not the binary, so FfmpegService uses its simulation)
      final marker = File(p.join(ffmpegDir.path, 'installed.marker'));
      await marker.writeAsString('installed_at: ${DateTime.now().toIso8601String()}');

      _isDownloading = false;
      await settings.setIsFfmpegInstalled(true);
      return true;
    } catch (e) {
      debugPrint('Installation error: $e');
      _isDownloading = false;
      return false;
    }
  }

  /// Removes the downloaded engine to free space.
  Future<void> uninstallEngine(SettingsProvider settings) async {
    final directory = await getApplicationSupportDirectory();
    final ffmpegDir = Directory(p.join(directory.path, 'ffmpeg_engine'));
    
    if (await ffmpegDir.exists()) {
      await ffmpegDir.delete(recursive: true);
    }
    
    await settings.setIsFfmpegInstalled(false);
  }
}
