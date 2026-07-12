import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/recurring_rule_model.dart';
import '../data/repositories/recurring_rule_repository.dart';
import '../data/settings_provider.dart';

/// Bottom sheet listing recurring transaction rules with delete support.
class RecurringRulesSheet extends StatefulWidget {
  const RecurringRulesSheet({super.key});

  @override
  State<RecurringRulesSheet> createState() => _RecurringRulesSheetState();
}

class _RecurringRulesSheetState extends State<RecurringRulesSheet> {
  List<RecurringRule>? _rules;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final rules = await RecurringRuleRepository.instance.readAllRules();
    if (mounted) setState(() => _rules = rules);
  }

  Future<void> _deleteRule(RecurringRule rule) async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop repeating?'),
        content: Text(
            '"${rule.description}" will no longer be added automatically. Already-created transactions are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await RecurringRuleRepository.instance.deleteRule(rule.id);
    await _loadRules();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;
    final rules = _rules;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recurring Transactions',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Added automatically when they come due',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (rules == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.event_repeat_outlined,
                        size: 48, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No recurring transactions yet.\nTurn on "Repeat" when adding a transaction.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rules.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.event_repeat,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20),
                      ),
                      title: Text(rule.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${rule.frequency.label} • ${rule.isExpense ? '-' : '+'} '
                        '$currency ${NumberFormat('#,##0').format(rule.amount)} • '
                        'next ${DateFormat('d MMM').format(rule.nextDue)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: theme.colorScheme.error,
                        tooltip: 'Stop repeating',
                        onPressed: () => _deleteRule(rule),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
