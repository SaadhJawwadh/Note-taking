import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class AppUpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;

  AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const String _githubRepo = "SaadhJawwadh/Note-taking";

  /// Queries the GitHub Releases API to check for new updates
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final remoteVersion = (data['tag_name'] as String).replaceAll('v', '').trim();
      
      // Get current local version
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version.trim();

      if (_isVersionNewer(localVersion, remoteVersion)) {
        // Find the APK asset in the release assets
        final assets = data['assets'] as List;
        final apkAsset = assets.firstWhere(
          (asset) => (asset['name'] as String).endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset != null) {
          return AppUpdateInfo(
            version: remoteVersion,
            downloadUrl: apkAsset['browser_download_url'],
            releaseNotes: data['body'] ?? 'No release notes provided.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }

  /// Simple semver comparison helper
  static bool _isVersionNewer(String local, String remote) {
    List<int> localParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      int localVal = i < localParts.length ? localParts[i] : 0;
      int remoteVal = i < remoteParts.length ? remoteParts[i] : 0;
      if (remoteVal > localVal) return true;
      if (localVal > remoteVal) return false;
    }
    return false;
  }

  /// Downloads the APK and triggers the native installation screen
  static Stream<OtaEvent> downloadAndInstall(String downloadUrl) {
    return OtaUpdate().execute(
      downloadUrl,
      destinationFilename: 'app-update.apk',
    );
  }
}
