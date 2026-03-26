import 'package:flutter/material.dart';
import '../services/sms_service.dart';

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

      final ok = await SmsService.requestPermissions();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS permission is required to import transactions.'), behavior: SnackBarBehavior.floating));
        return;
      }
    }

    setState(() => _loading = true);
    final offsetDays = _periods[_selectedIndex].$2;
    final from = offsetDays != null ? DateTime.now().subtract(Duration(days: offsetDays)) : DateTime(2000);
    final count = await SmsService.syncInboxFrom(from);

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count == 0 ? 'No new transactions found.' : 'Imported $count new transaction${count == 1 ? '' : 's'} from SMS.'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Import SMS Transactions', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Choose how far back to scan your SMS inbox for bank transactions.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          ...List.generate(_periods.length, (i) {
            final (label, _) = _periods[i];
            return RadioListTile<int>(title: Text(label), value: i, groupValue: _selectedIndex, onChanged: _loading ? null : (v) => setState(() => _selectedIndex = v!), contentPadding: EdgeInsets.zero, dense: true);
          }),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _runImport,
                icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_outlined, size: 18),
                label: Text(_loading ? 'Importing…' : 'Import'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
