import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/ffmpeg_service.dart';
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FfmpegService and SettingsProvider Tests', () {
    late SettingsProvider settings;

    setUp(() async {
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
  });
}
