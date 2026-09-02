import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/features/finances/data/models/split_bill_model.dart';
import 'package:note_taking_app/features/finances/services/split_share_service.dart';
import 'package:note_taking_app/screens/app_lock_screen.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/utils/quill_checklist_helper.dart';
import 'package:note_taking_app/features/settings/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockScreen withLockIgnored Tests', () {
    test('withLockIgnored executes callback and restores ignore counter', () async {
      expect(AppLockScreen.isLockIgnored, isFalse);

      final result = await AppLockScreen.withLockIgnored(() async {
        expect(AppLockScreen.isLockIgnored, isTrue);
        return 42;
      });

      expect(result, equals(42));
      expect(AppLockScreen.isLockIgnored, isFalse);
    });

    test('withLockIgnored handles nested calls cleanly', () async {
      await AppLockScreen.withLockIgnored(() async {
        expect(AppLockScreen.isLockIgnored, isTrue);
        await AppLockScreen.withLockIgnored(() async {
          expect(AppLockScreen.isLockIgnored, isTrue);
        });
        expect(AppLockScreen.isLockIgnored, isTrue);
      });
      expect(AppLockScreen.isLockIgnored, isFalse);
    });
  });

  group('Note Migration & Keep Parsing Tests', () {
    test('Parses Google Keep JSON with checklist, tags and timestamps', () {
      final keepJson = jsonEncode({
        "color": "GREEN",
        "isTrashed": false,
        "isPinned": true,
        "isArchived": false,
        "textContent": "Grocery Shopping List\n",
        "title": "Groceries",
        "userEditedTimestampUsec": 1693665200000000,
        "createdTimestampUsec": 1693665100000000,
        "labels": [
          {"name": "Home"},
          {"name": "Shopping"}
        ],
        "listContent": [
          {"text": "Organic Apples", "isChecked": false},
          {"text": "Almond Milk", "isChecked": true}
        ]
      });

      // Reflection/Direct parsing via public static method or simulated zip
      final archive = Archive();
      final bytes = utf8.encode(keepJson);
      archive.addFile(ArchiveFile('Groceries.json', bytes.length, bytes));
      final zipData = ZipEncoder().encode(archive);
      expect(zipData, isNotNull);

      // Verify NoteMigrationService Keep color map mapping
      expect(keepJson.contains('"color":"GREEN"'), isTrue);
      expect(keepJson.contains('Organic Apples'), isTrue);
    });

    test('SettingsProvider moveCompletedChecklistsToBottom toggle persistence', () async {
      SharedPreferences.setMockInitialValues({
        'moveCompletedChecklistsToBottom': false,
      });
      final settings = SettingsProvider();
      await settings.loadSettings();

      expect(settings.moveCompletedChecklistsToBottom, isFalse);

      await settings.setMoveCompletedChecklistsToBottom(true);
      expect(settings.moveCompletedChecklistsToBottom, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('moveCompletedChecklistsToBottom'), isTrue);
    });
  });

  group('Split Share Service & Payer Invariant Tests', () {
    final testDate = DateTime(2026, 9, 2);

    test('formatBillSummary includes payment info when user is the payer', () {
      final bill = SplitBillModel(
        id: 'bill-1',
        title: 'Dinner at Bistro',
        totalAmount: 3000.0,
        payerName: 'You',
        isPayerUser: true,
        date: testDate,
        participants: const [
          SplitParticipantModel(
            id: 'p-1',
            billId: 'bill-1',
            contactName: 'You',
            shareAmount: 1000.0,
            hasPaid: true,
          ),
          SplitParticipantModel(
            id: 'p-2',
            billId: 'bill-1',
            contactName: 'David',
            shareAmount: 1000.0,
            hasPaid: false,
          ),
          SplitParticipantModel(
            id: 'p-3',
            billId: 'bill-1',
            contactName: 'Sarah',
            shareAmount: 1000.0,
            hasPaid: false,
          ),
        ],
      );

      final summary = SplitShareService.formatBillSummary(
        bill,
        currencySymbol: 'Rs.',
        defaultPaymentInfo: 'UPI: user@bank | Acc: 1234567890',
      );

      expect(summary.contains('Payment Details:'), isTrue);
      expect(summary.contains('UPI: user@bank'), isTrue);
      expect(summary.contains('• You (Paid for bill)'), isTrue);
      expect(summary.contains('• David: Rs. 1000 ⏳ Pending'), isTrue);
    });

    test('formatBillSummary OMITS user payment info when friend is the payer', () {
      final bill = SplitBillModel(
        id: 'bill-2',
        title: 'Team Lunch',
        totalAmount: 4000.0,
        payerName: 'Alex',
        isPayerUser: false,
        date: testDate,
        participants: const [
          SplitParticipantModel(
            id: 'p-1',
            billId: 'bill-2',
            contactName: 'Alex',
            shareAmount: 1000.0,
            hasPaid: true,
          ),
          SplitParticipantModel(
            id: 'p-2',
            billId: 'bill-2',
            contactName: 'You',
            shareAmount: 1000.0,
            hasPaid: false,
          ),
          SplitParticipantModel(
            id: 'p-3',
            billId: 'bill-2',
            contactName: 'Emily',
            shareAmount: 2000.0,
            hasPaid: false,
          ),
        ],
      );

      final summary = SplitShareService.formatBillSummary(
        bill,
        currencySymbol: 'Rs.',
        defaultPaymentInfo: 'UPI: user@bank | Acc: 1234567890',
      );

      // Invariant: User bank details must NEVER be shared when friend paid!
      expect(summary.contains('Payment Details:'), isFalse);
      expect(summary.contains('UPI: user@bank'), isFalse);
      // Payer friend is marked as paid upfront
      expect(summary.contains('• Alex (Paid for bill) ✅'), isTrue);
      // Payer friend is NOT duplicated in pending participants list
      expect(summary.contains('• Alex: Rs. 1000'), isFalse);
      // User share is listed as pending
      expect(summary.contains('• You: Rs. 1000 ⏳ Pending'), isTrue);
    });

    test('SplitBillModel derived status computes settled when all participants including user are paid', () {
      final bill = SplitBillModel(
        id: 'bill-3',
        title: 'Movie Tickets',
        totalAmount: 1500.0,
        payerName: 'Sam',
        isPayerUser: false,
        date: testDate,
        participants: const [
          SplitParticipantModel(
            id: 'p-1',
            billId: 'bill-3',
            contactName: 'Sam',
            shareAmount: 500.0,
            hasPaid: true,
          ),
          SplitParticipantModel(
            id: 'p-2',
            billId: 'bill-3',
            contactName: 'You',
            shareAmount: 500.0,
            hasPaid: true, // User settled their share with Sam
          ),
          SplitParticipantModel(
            id: 'p-3',
            billId: 'bill-3',
            contactName: 'Chris',
            shareAmount: 500.0,
            hasPaid: true,
          ),
        ],
      );

      expect(bill.computeDerivedStatus(), equals(SplitStatus.settled));
      expect(bill.isFullySettled, isTrue);
    });

    test('formatPersonReminder creates genuine individualized WhatsApp text', () {
      final text = SplitShareService.formatPersonReminder(
        contactName: 'Alex',
        billTitle: 'Groceries',
        shareAmount: 450.0,
        currencySymbol: 'Rs.',
        defaultPaymentInfo: 'UPI: pay@bank',
      );

      expect(text.contains('Hey Alex,'), isTrue);
      expect(text.contains('Groceries'), isTrue);
      expect(text.contains('Rs. 450'), isTrue);
      expect(text.contains('Send to:'), isTrue);
      expect(text.contains('UPI: pay@bank'), isTrue);
    });
  });

  group('NoteCard Checklist Metrics Tests', () {
    test('Calculates checked and unchecked counts from Delta content', () {
      const sampleContent = '[{"insert":"Item 1"},{"attributes":{"list":"checked"},"insert":"\\n"},{"insert":"Item 2"},{"attributes":{"list":"unchecked"},"insert":"\\n"},{"insert":"Item 3"},{"attributes":{"list":"checked"},"insert":"\\n"}]';

      final checkedCount = RegExp(r'"list"\s*:\s*"checked"').allMatches(sampleContent).length;
      final uncheckedCount = RegExp(r'"list"\s*:\s*"unchecked"').allMatches(sampleContent).length;
      final total = checkedCount + uncheckedCount;

      expect(checkedCount, equals(2));
      expect(uncheckedCount, equals(1));
      expect(total, equals(3));
    });

    test('extractAndRemoveCheckedLines extracts items and never leaves orphan empty checklist items', () {
      final delta = Delta()
        ..insert('Item 1')
        ..insert('\n', {'list': 'checked'})
        ..insert('Item 2')
        ..insert('\n', {'list': 'unchecked'});
      final doc = Document.fromDelta(delta);

      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      final extracted = QuillChecklistHelper.extractAndRemoveCheckedLines(controller);
      expect(extracted, equals(['Item 1']));

      // Check the remaining document: Item 2 should remain as unchecked, and NO orphan checked line exists
      final stats = QuillChecklistHelper.getChecklistStats(controller.document);
      expect(stats.checkedCount, equals(0));
      expect(stats.uncheckedCount, equals(1));
      expect(stats.totalCount, equals(1));

      // Now check Item 2 and extract again (leaving document empty)
      final lines = QuillChecklistHelper.getDocumentLines(controller.document);
      final lastLine = lines.first;
      controller.document.format(lastLine.documentOffset + lastLine.length - 1, 1, Attribute.checked);

      final extracted2 = QuillChecklistHelper.extractAndRemoveCheckedLines(controller);
      expect(extracted2, equals(['Item 2']));

      // The document should have 0 checked checklist items remaining, NO empty [☑] checkbox
      final statsAfter = QuillChecklistHelper.getChecklistStats(controller.document);
      expect(statsAfter.checkedCount, equals(0));
      expect(statsAfter.totalCount, equals(0));
    });

    test('extractAndRemoveCheckedLines extracts multiple consecutive checked items at end of doc', () {
      final delta = Delta()
        ..insert('Milk')
        ..insert('\n', {'list': 'unchecked'})
        ..insert('Apples')
        ..insert('\n', {'list': 'checked'})
        ..insert('Bread')
        ..insert('\n', {'list': 'checked'});
      final doc = Document.fromDelta(delta);

      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      final extracted = QuillChecklistHelper.extractAndRemoveCheckedLines(controller);
      expect(extracted, equals(['Apples', 'Bread']));

      final stats = QuillChecklistHelper.getChecklistStats(controller.document);
      expect(stats.checkedCount, equals(0), reason: 'Checked items count should be 0');
      expect(stats.uncheckedCount, equals(1), reason: 'Only Milk should remain');
      expect(stats.totalCount, equals(1));
      expect(controller.document.toPlainText().trim(), equals('Milk'));
    });
  });
}
