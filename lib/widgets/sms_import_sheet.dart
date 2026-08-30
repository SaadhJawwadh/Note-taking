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
    ('Last 24 hours (Default)', 1),
    ('Last 7 days', 7),
    ('Last 30 days', 30),
    ('Last 90 days', 90),
    ('All time', null),
  ];

  int _selectedIndex = 0;
  bool _bypassTombstones = false;

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

    final offsetDays = _periods[_selectedIndex].$2;
    final from = offsetDays != null
        ? DateTime.now().subtract(Duration(days: offsetDays))
        : DateTime(2000);

    // Non-blocking dispatch: dismiss modal sheet immediately so user can continue using the app
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Started SMS import in background...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    await SmsService.performSmsSync(
      trigger: SmsSyncTrigger.historicalSheet,
      fromTime: from,
      bypassTombstones: _bypassTombstones,
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
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.manage_search_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Advanced SMS Import Options', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quick sync automatically scans messages from the last 24 hours. Select a custom date range below to scan older history or re-import past transactions.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ...List.generate(_periods.length, (i) {
            final (label, _) = _periods[i];
            return Material(
              color: Colors.transparent,
              child: RadioListTile<int>(
                title: Text(label),
                value: i,
                // ignore: deprecated_member_use
                groupValue: _selectedIndex,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedIndex = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            );
          }),
          const Divider(height: 24),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              title: const Text('Force Re-Scan Previously Deleted SMS'),
              subtitle: Text(
                'Bypasses tombstone filters to re-import transactions you previously purged.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              value: _bypassTombstones,
              onChanged: (v) => setState(() => _bypassTombstones = v ?? false),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _runImport,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Start Import'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
