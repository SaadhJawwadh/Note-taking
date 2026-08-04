import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../screens/app_lock_screen.dart';

class SmsImportSheet extends StatefulWidget {
  const SmsImportSheet({super.key});

  @override
  State<SmsImportSheet> createState() => _SmsImportSheetState();
}

class _SmsImportSheetState extends State<SmsImportSheet> {
  static const _periods = [
    ('Last day', 1),
    ('Last 7 days', 7),
    ('Last 30 days', 30),
    ('Last 3 months', 90),
    ('All time', null),
  ];

  int _selectedIndex = 2;
  bool _loading = false;
  int _scannedCount = 0;
  int _totalCount = 0;
  int _foundCount = 0;

  Future<void> _runImport() async {
    final granted = await SmsService.hasPermission();
    if (!mounted) return;

    if (!granted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS Access'),
          content: const Text(
            'This app needs permission to read your SMS messages so it can detect and import bank transactions.\n\nOnly messages from recognised bank senders are processed. No messages are sent off-device or shared.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Allow')),
          ],
        ),
      );
      if (proceed != true) return;

      AppLockScreen.ignoreNextResumeLock();
      final ok = await SmsService.requestPermissions();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to import transactions.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _loading = true;
      _scannedCount = 0;
      _totalCount = 0;
      _foundCount = 0;
    });

    final offsetDays = _periods[_selectedIndex].$2;
    final from = offsetDays != null
        ? DateTime.now().subtract(Duration(days: offsetDays))
        : DateTime(2000);

    final count = await SmsService.syncInboxFrom(
      from,
      onProgress: (scanned, total, found) {
        if (mounted) {
          setState(() {
            _scannedCount = scanned;
            _totalCount = total;
            _foundCount = found;
          });
        }
      },
    );

    final newSenders = await SmsService.discoverNewBankSenders();

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);

    String message = count == 0
        ? 'No new transactions found.'
        : 'Imported $count new transaction${count == 1 ? '' : 's'} from SMS.';
    if (newSenders.isNotEmpty) {
      message += ' Found ${newSenders.length} new bank sender${newSenders.length == 1 ? '' : 's'}.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import SMS Transactions', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Choose how far back to scan your SMS inbox for bank transactions.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ...List.generate(_periods.length, (i) {
            final (label, _) = _periods[i];
            return RadioListTile<int>(
              title: Text(label),
              value: i,
              // ignore: deprecated_member_use
              groupValue: _selectedIndex,
              // ignore: deprecated_member_use
              onChanged: _loading ? null : (v) => setState(() => _selectedIndex = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
          if (_loading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _totalCount > 0 ? _scannedCount / _totalCount : null,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              _totalCount > 0
                  ? 'Scanning message $_scannedCount of $_totalCount... Found $_foundCount transaction${_foundCount == 1 ? '' : 's'}.'
                  : 'Preparing SMS inbox scan...',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _runImport,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text(_loading ? 'Importing…' : 'Import'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
