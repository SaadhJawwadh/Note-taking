import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:note_taking_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Editor & SMS & Auto-Backup QoL Tests', () {
    test('Quill header attribute extraction maps to correct heading levels', () {
      final doc = Document();
      final controller = QuillController.basic()..document = doc;

      // Default should have no header (Body)
      var style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], isNull);

      // Format as H1
      controller.formatSelection(Attribute.h1);
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], equals(Attribute.h1));

      // Format as H2
      controller.formatSelection(Attribute.h2);
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], equals(Attribute.h2));

      // Format as H3
      controller.formatSelection(Attribute.h3);
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], equals(Attribute.h3));

      // Format back to Body
      controller.formatSelection(const Attribute('header', AttributeScope.block, null));
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], isNull);
    });

    test('showBackupNotification runs without unhandled exception', () async {
      await NotificationService.showBackupNotification(
        title: '📦 Auto-Backup Complete',
        body: 'Data safely backed up at 10:30 PM.',
      );
      // Completes cleanly
      expect(true, isTrue);
    });
  });
}
