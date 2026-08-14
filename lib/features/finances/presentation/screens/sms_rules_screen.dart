import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'package:note_taking_app/data/transaction_category.dart';
import 'package:note_taking_app/services/sms_service.dart';
import 'package:note_taking_app/services/sms_parser.dart';
import 'package:note_taking_app/core/theme/app_layout.dart';
import 'package:note_taking_app/utils/app_route.dart';
import 'package:note_taking_app/widgets/frosted_glass_sliver_app_bar.dart';
import 'package:note_taking_app/features/finances/presentation/screens/category_management_screen.dart';

class SmsRulesScreen extends StatefulWidget {
  const SmsRulesScreen({super.key});

  @override
  State<SmsRulesScreen> createState() => _SmsRulesScreenState();
}

class _SmsRulesScreenState extends State<SmsRulesScreen> {
  // Controllers for adding rules
  final _expenseRuleController = TextEditingController();
  final _incomeRuleController = TextEditingController();
  final _testSmsController = TextEditingController();

  @override
  void dispose() {
    _expenseRuleController.dispose();
    _incomeRuleController.dispose();
    _testSmsController.dispose();
    super.dispose();
  }

  Future<void> _pasteToTest() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _testSmsController.text = data.text!.trim();
      });
    }
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
      body: CustomScrollView(
        slivers: [
          FrostedGlassSliverAppBar(
            titleText: 'SMS Import Rules',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_backup_restore),
                tooltip: 'Restore defaults',
                onPressed: _confirmRestoreDefaults,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer<SettingsProvider>(
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

            // Test SMS Parser Sandbox Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppLayout.radiusL),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.science_outlined, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Test SMS Parser',
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _pasteToTest,
                            icon: const Icon(Icons.content_paste, size: 16),
                            label: const Text('Paste'),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _testSmsController,
                        maxLines: 3,
                        minLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Paste an SMS here to test live detection...',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppLayout.radiusM),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          suffixIcon: _testSmsController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _testSmsController.clear()),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final testText = _testSmsController.text.trim();
                          if (testText.isEmpty) {
                            return Text(
                              'Paste any bank SMS above to preview parsed amount, type, merchant, and category.',
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            );
                          }

                          final parsed = SmsParser.parseMessage(
                            body: testText,
                            address: 'BANK_SMS',
                            messageId: null,
                            messageDate: null,
                            allowedSenderIds: const {},
                            blockedSenderIds: const {},
                            customExpenseRules: expenseRules,
                            customIncomeRules: incomeRules,
                            preferredCurrency: settings.currency,
                          );

                          if (parsed == null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(AppLayout.radiusM),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 20, color: cs.error),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Not recognized as a financial transaction. Try adding custom keywords below or verify currency/amount format.',
                                      style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(AppLayout.radiusM),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      parsed.isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                                      size: 18,
                                      color: parsed.isExpense ? cs.error : cs.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${parsed.isExpense ? '-' : '+'} ${settings.currency} ${parsed.amount.toStringAsFixed(2)}',
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: parsed.isExpense ? cs.error : cs.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                      ),
                                      child: Text(
                                        parsed.isExpense ? 'Expense' : 'Income',
                                        style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '🏷️ Title: ${parsed.description}',
                                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📂 Category: ${parsed.category}',
                                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

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
            child: Column(
              children: List.generate(
                items.length,
                (index) => AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(
                      child: items[index],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
        ],
      ),
    );
  }
}
