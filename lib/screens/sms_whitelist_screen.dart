import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../services/sms_service.dart';

class SmsWhitelistScreen extends StatefulWidget {
  const SmsWhitelistScreen({super.key});

  @override
  State<SmsWhitelistScreen> createState() => _SmsWhitelistScreenState();
}

class _SmsWhitelistScreenState extends State<SmsWhitelistScreen> {
  List<String> _senders = [];
  bool _loading = true;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final senders = await DatabaseHelper.instance.getAllWhitelistedSenders();
    if (mounted) {
      setState(() {
        _senders = senders;
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    await DatabaseHelper.instance.addWhitelistedSender(value);
    await SmsService.reloadUserSenders();
    _controller.clear();
    await _load();
  }

  Future<void> _remove(String sender) async {
    await DatabaseHelper.instance.removeWhitelistedSender(sender);
    await SmsService.reloadUserSenders();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Sender Whitelist'),
      ),
      body: Column(
        children: [
          // ── Info banner ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              color: cs.secondaryContainer,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: cs.onSecondaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Banks are always included by default. '
                        'Add sender IDs for non-bank services (e.g. KOKO) '
                        'whose debit/credit SMS you want to import.',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Add sender row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Sender ID (e.g. KOKO)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // ── List ───────────────────────────────────────────────────────
          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator.adaptive()))
          else if (_senders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sms_outlined,
                        size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No custom senders yet',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _senders.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (ctx, i) {
                  final s = _senders[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      radius: 18,
                      child: Icon(Icons.message_outlined,
                          size: 18, color: cs.onPrimaryContainer),
                    ),
                    title: Text(s, style: tt.bodyMedium),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: cs.error),
                      tooltip: 'Remove',
                      onPressed: () => _confirmRemove(ctx, s),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext ctx, String sender) {
    showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Remove sender?'),
        content: Text(
            'SMS from "$sender" will no longer be auto-imported as transactions.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) _remove(sender);
    });
  }
}
