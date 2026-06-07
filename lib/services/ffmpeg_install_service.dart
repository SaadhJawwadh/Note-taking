import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/settings_provider.dart';

class FfmpegInstallService extends ChangeNotifier {
  static final FfmpegInstallService instance = FfmpegInstallService._init();
  FfmpegInstallService._init();

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  /// Checks if the engine is "installed".
  Future<bool> checkInstallation() async {
    if (kIsWeb) return false;
    try {
      final directory = await getApplicationSupportDirectory();
      final ffmpegDir = Directory(p.join(directory.path, 'ffmpeg_engine'));
      
      if (!await ffmpegDir.exists()) return false;
      
      final marker = File(p.join(ffmpegDir.path, 'installed.marker'));
      return await marker.exists();
    } catch (_) {
      return false;
    }
  }

  /// Returns the path to the FFmpeg executable.
  Future<String?> getBinaryPath() async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationSupportDirectory();
      if (await checkInstallation()) {
        return p.join(directory.path, 'ffmpeg_engine', 'ffmpeg');
      }
    } catch (_) {}
    return null;
  }

  /// Simulates downloading the FFmpeg engine.
  Future<bool> installEngine(SettingsProvider settings) async {
    if (kIsWeb) return false;
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadProgress = 0;
    notifyListeners();
    
    try {
      // 1. Determine architecture-specific download path
      String abi;
      if (Platform.isAndroid) {
        final processResult = await Process.run('getprop', ['ro.product.cpu.abi']);
        abi = (processResult.stdout as String).trim();
      } else if (Platform.isIOS) {
        abi = 'ios-arm64';
      } else {
        abi = 'generic';
      }
      
      debugPrint('Detected Architecture: $abi. Proceeding with download...');

      // 2. Simulate download progress
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 150));
        _downloadProgress = i / 100;
        notifyListeners(); // Trigger local UI update for progress
      }

      // 3. Create engine directory
      final directory = await getApplicationSupportDirectory();
      final ffmpegDir = Directory(p.join(directory.path, 'ffmpeg_engine'));
      if (!await ffmpegDir.exists()) {
        await ffmpegDir.create(recursive: true);
      }

      // 4. Create dummy marker file
      final marker = File(p.join(ffmpegDir.path, 'installed.marker'));
      await marker.writeAsString('installed_at: ${DateTime.now().toIso8601String()}');

      _isDownloading = false;
      await settings.setIsFfmpegInstalled(true);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Installation error: $e');
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// Removes the downloaded engine to free space.
  Future<void> uninstallEngine(SettingsProvider settings) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationSupportDirectory();
      final ffmpegDir = Directory(p.join(directory.path, 'ffmpeg_engine'));
      
      if (await ffmpegDir.exists()) {
        await ffmpegDir.delete(recursive: true);
      }
    } catch (_) {}
    
    await settings.setIsFfmpegInstalled(false);
    notifyListeners();
  }
}
