import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:image/image.dart' as img;
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:note_taking_app/services/ffmpeg_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async {
    return './tmp';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return './tmp';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('File Converter Tests', () {
    late SettingsProvider settings;
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      // Ensure it is in Lite Mode for local testing
      await settings.setIsConverterLite(true);
      
      // Ensure the test temp dir exists
      tempDir = Directory('./tmp');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
    });

    test('WhatsApp HD Video Preset Verification', () {
      const preset = ConversionPreset.whatsappVideoHD;
      
      expect(preset.label, equals('WhatsApp HD Video'));
      expect(preset.icon, equals('💬'));
      expect(preset.subtitle, contains('CRF 22'));
      expect(preset.mediaType, equals(MediaType.video));
    });

    test('Image Compression decodes, resizes and recompresses in Lite Mode', () async {
      // 1. Create a valid test PNG image (100x100)
      final testFile = File(p.join(tempDir.path, 'input_test_image.png'));
      final image = img.Image(width: 100, height: 100);
      
      // Draw a rectangle to make it non-empty
      img.fillRect(image, x1: 10, y1: 10, x2: 90, y2: 90, color: img.ColorRgb8(255, 0, 0));
      
      final pngBytes = img.encodePng(image);
      await testFile.writeAsBytes(pngBytes);

      // 2. Set settings to target JPEG format and 720p limit
      await settings.setPreferredImageFormat('jpg');
      await settings.setVideoResolutionLimit('720p');

      // 3. Perform compression
      final result = await FfmpegService.instance.convertFile(
        inputPath: testFile.path,
        preset: ConversionPreset.imageCompress,
        settings: settings,
      );

      // 4. Verify results
      expect(result, isNotNull);
      expect(result!.originalPath, equals(testFile.path));
      expect(result.outputPath, endsWith('.jpg'));
      expect(result.originalSizeBytes, equals(pngBytes.length));
      
      final outputFile = File(result.outputPath);
      expect(await outputFile.exists(), isTrue);
      expect(result.compressedSizeBytes, equals(outputFile.lengthSync()));
      
      // Verify it is a valid JPEG
      final outputBytes = await outputFile.readAsBytes();
      final decodedOutput = img.decodeJpg(outputBytes);
      expect(decodedOutput, isNotNull);
      expect(decodedOutput!.width, equals(100));
      expect(decodedOutput.height, equals(100));

      // Clean up
      if (await testFile.exists()) await testFile.delete();
      if (await outputFile.exists()) await outputFile.delete();
    });

    test('Image Compression applies resolution limits in Lite Mode', () async {
      // 1. Create a large test PNG image (1000x1000)
      final testFile = File(p.join(tempDir.path, 'large_input_image.png'));
      final image = img.Image(width: 1000, height: 1000);
      final pngBytes = img.encodePng(image);
      await testFile.writeAsBytes(pngBytes);

      // 2. Set settings to limit to 480p (width should shrink to 480)
      await settings.setPreferredImageFormat('png');
      await settings.setVideoResolutionLimit('480p');

      // 3. Perform compression
      final result = await FfmpegService.instance.convertFile(
        inputPath: testFile.path,
        preset: ConversionPreset.imageCompress,
        settings: settings,
      );

      // 4. Verify resolution was downscaled to 480px width
      expect(result, isNotNull);
      final outputFile = File(result!.outputPath);
      final outputBytes = await outputFile.readAsBytes();
      final decodedOutput = img.decodePng(outputBytes);
      
      expect(decodedOutput, isNotNull);
      expect(decodedOutput!.width, equals(480));
      expect(decodedOutput.height, equals(480));

      // Clean up
      if (await testFile.exists()) await testFile.delete();
      if (await outputFile.exists()) await outputFile.delete();
    });

    tearDownAll(() async {
      final dir = Directory('./tmp');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
  });
}
