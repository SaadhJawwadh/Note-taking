import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/transaction_category.dart';
import '../services/sms_service.dart';
import '../theme/app_layout.dart';
import '../utils/app_route.dart';
import 'category_management_screen.dart';

class SmsRulesScreen extends StatefulWidget {
  const SmsRulesScreen({super.key});

  @override
  State<SmsRulesScreen> createState() => _SmsRulesScreenState();
}

class _SmsRulesScreenState extends State<SmsRulesScreen> {
  // Controllers for adding rules
  final _expenseRuleController = TextEditingController();
  final _incomeRuleController = TextEditingController();

  @override
  void dispose() {
    _expenseRuleController.dispose();
    _incomeRuleController.dispose();
    super.dispose();
  }

  Future<void> _confirmRestoreDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore default rules?'),
        content: const Text(
            'All custom transaction-type rules will be removed and built-in category keywords reset to their defaults.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.clearCustomRules();
    await TransactionRepository.instance.resetBuiltInCategoryKeywords();
    await TransactionCategory.reload();
    await SmsService.reloadSmsContacts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS rules restored to defaults')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            height: 64,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
              boxShadow: AppLayout.softShadow(context),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    await HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'SMS Import Rules',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: const Icon(Icons.settings_backup_restore),
                    tooltip: 'Restore defaults',
                    onPressed: _confirmRestoreDefaults,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final expenseRules = settings.customExpenseRules;
          final incomeRules = settings.customIncomeRules;

          final items = <Widget>[
            // Info Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: cs.secondaryContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: cs.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Define keywords that identify whether an incoming SMS is an Expense or Income. '
                          'If a message body contains one of these keywords, the app will set the type accordingly.',
                          style: tt.bodySmall?.copyWith(color: cs.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expense Rules Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Keywords',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expenseRuleController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Paid, Sent, Debited',
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              settings.addCustomRule(val.trim(), isExpense: true);
                              SmsService.reloadSmsContacts();
                              _expenseRuleController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final val = _expenseRuleController.text.trim();
                          if (val.isNotEmpty) {
                            settings.addCustomRule(val, isExpense: true);
                            SmsService.reloadSmsContacts();
                            _expenseRuleController.clear();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (expenseRules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No custom expense rules set.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expenseRules.map((rule) {
                        return Chip(
                          label: Text(rule),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            settings.removeCustomRule(rule, isExpense: true);
                            SmsService.reloadSmsContacts();
                          },
                          backgroundColor: cs.errorContainer.withValues(alpha: 0.3),
                          side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),

            // Income Rules Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Keywords',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.tertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _incomeRuleController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Received, Deposited, Salary',
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              settings.addCustomRule(val.trim(), isExpense: false);
                              SmsService.reloadSmsContacts();
                              _incomeRuleController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final val = _incomeRuleController.text.trim();
                          if (val.isNotEmpty) {
                            settings.addCustomRule(val, isExpense: false);
                            SmsService.reloadSmsContacts();
                            _incomeRuleController.clear();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (incomeRules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No custom income rules set.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: incomeRules.map((rule) {
                        return Chip(
                          label: Text(rule),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            settings.removeCustomRule(rule, isExpense: false);
                            SmsService.reloadSmsContacts();
                          },
                          backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.3),
                          side: BorderSide(color: cs.tertiary.withValues(alpha: 0.3)),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),

            // Link to Category Rules & Keywords
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppLayout.radiusL),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: Icon(Icons.category_outlined, color: cs.primary),
                  title: const Text('Category Rules & Keywords'),
                  subtitle: const Text('Edit category names, icons, colors, and auto-matching rules'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppRoute.push(context, const CategoryManagementScreen());
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),
          ];

          return AnimationLimiter(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(
                      child: items[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
