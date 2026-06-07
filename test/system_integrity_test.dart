import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/ffmpeg_service.dart';
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FfmpegService and SettingsProvider Tests', () {
    late SettingsProvider settings;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getTemporaryDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        },
      );
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await settings.loadSettings(); // Public method now
    });

    test('Lite Mode defaults to true', () {
      expect(settings.isConverterLite, true);
    });

    test('FfmpegService detects media type correctly', () {
      final service = FfmpegService.instance;
      expect(service.detectMediaType('test.mp4'), MediaType.video);
      expect(service.detectMediaType('test.jpg'), MediaType.image);
      expect(service.detectMediaType('test.gif'), MediaType.gif);
      expect(service.detectMediaType('test.mp3'), MediaType.audio);
    });

    test('FfmpegService presets for file are filtered', () {
      final service = FfmpegService.instance;
      final videoPresets = service.presetsForFile('test.mp4');
      expect(videoPresets.contains(ConversionPreset.socialVideo720p), true);
      expect(videoPresets.contains(ConversionPreset.imageCompress), false);
    });

    test('FfmpegService simulation behavior with matching and mismatched extensions', () async {
      final service = FfmpegService.instance;
      
      // Create a temporary file to act as input
      final tempDir = Directory.systemTemp.createTempSync('ffmpeg_test');
      final inputFile = File('${tempDir.path}/input.jpg');
      await inputFile.writeAsString('test content');

      // 1. Same extension: jpg to jpg via imageCompress preset (preferredImageFormat defaults to jpg/png)
      final sameResult = await service.convertFile(
        inputPath: inputFile.path,
        preset: ConversionPreset.imageCompress,
        settings: settings,
      );
      expect(sameResult, isNotNull);
      final sameOutputFile = File(sameResult!.outputPath);
      expect(await sameOutputFile.exists(), true);
      expect(await sameOutputFile.readAsString(), 'test content');

      // 2. Mismatched extension: mp4 to m4a (audioExtract preset)
      final videoInputFile = File('${tempDir.path}/input.mp4');
      await videoInputFile.writeAsString('video content');
      final diffResult = await service.convertFile(
        inputPath: videoInputFile.path,
        preset: ConversionPreset.audioExtract, // outputs .m4a
        settings: settings,
      );
      expect(diffResult, isNotNull);
      final diffOutputFile = File(diffResult!.outputPath);
      expect(await diffOutputFile.exists(), true);
      expect(await diffOutputFile.readAsString(), contains('Simulated conversion from .mp4 to .m4a'));

      // Clean up
      tempDir.deleteSync(recursive: true);
    });
  });
}
