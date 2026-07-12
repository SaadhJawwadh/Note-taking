import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/category_definition.dart';
import '../data/transaction_category.dart';
import '../services/sms_service.dart';
import '../theme/app_layout.dart';

class SmsRulesScreen extends StatefulWidget {
  const SmsRulesScreen({super.key});

  @override
  State<SmsRulesScreen> createState() => _SmsRulesScreenState();
}

class _SmsRulesScreenState extends State<SmsRulesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CategoryDefinition> _categories = [];
  bool _loadingCategories = true;

  // Controllers for adding rules
  final _expenseRuleController = TextEditingController();
  final _incomeRuleController = TextEditingController();
  final Map<String, TextEditingController> _categoryRuleControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expenseRuleController.dispose();
    _incomeRuleController.dispose();
    for (final c in _categoryRuleControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await TransactionRepository.instance.getAllCategoryDefinitions();
    if (mounted) {
      setState(() {
        _categories = cats;
        _loadingCategories = false;
        // Ensure every category has a controller
        for (final cat in cats) {
          _categoryRuleControllers.putIfAbsent(cat.name, () => TextEditingController());
        }
      });
    }
  }

  Future<void> _confirmRestoreDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore default rules?'),
        content: const Text(
            'All custom transaction-type rules will be removed and built-in category keywords reset to their defaults. Custom categories themselves are kept.'),
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
    await _loadCategories();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS rules restored to defaults')),
      );
    }
  }

  Future<void> _addCategoryKeyword(CategoryDefinition def, String keyword) async {
    final kw = keyword.trim().toLowerCase();
    if (kw.isEmpty || def.keywords.contains(kw)) return;

    final updatedKeywords = List<String>.from(def.keywords)..add(kw);
    final updatedDef = def.copyWith(keywords: updatedKeywords);

    await TransactionRepository.instance.upsertCategoryDefinition(updatedDef);
    await TransactionCategory.reload();
    _categoryRuleControllers[def.name]?.clear();
    await _loadCategories();
  }

  Future<void> _removeCategoryKeyword(CategoryDefinition def, String keyword) async {
    final updatedKeywords = List<String>.from(def.keywords)..remove(keyword);
    final updatedDef = def.copyWith(keywords: updatedKeywords);

    await TransactionRepository.instance.upsertCategoryDefinition(updatedDef);
    await TransactionCategory.reload();
    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Import Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: 'Restore defaults',
            onPressed: _confirmRestoreDefaults,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.swap_vert_outlined),
              text: 'Transaction Types',
            ),
            Tab(
              icon: Icon(Icons.category_outlined),
              text: 'Categories',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Transaction Types
          _buildTypeRulesTab(colorScheme, textTheme),
          // Tab 2: Category Rules
          _buildCategoryRulesTab(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildTypeRulesTab(ColorScheme cs, TextTheme tt) {
    return Consumer<SettingsProvider>(
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
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.error),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expenseRuleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Paid, Sent, Debited',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          const Divider(height: 48),

          // Income Rules Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income Keywords',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _incomeRuleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Received, Deposited, Salary',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildCategoryRulesTab(ColorScheme cs, TextTheme tt) {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

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
                    'Define matching keywords for transaction categories. '
                    'If a new SMS transaction is imported, the parser scans the description and body '
                    'for these keywords to assign the correct category automatically.',
                    style: tt.bodySmall?.copyWith(color: cs.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // List of Categories and their rules
      ..._categories.map((cat) {
        final catColor = Color(cat.colorValue);
        final controller = _categoryRuleControllers[cat.name] ?? TextEditingController();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusL),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3), width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          TransactionCategory.iconFor(cat.name),
                          color: catColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Add keyword…',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _addCategoryKeyword(cat, val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: cs.primary,
                        onPressed: () {
                          final val = controller.text.trim();
                          if (val.isNotEmpty) {
                            _addCategoryKeyword(cat, val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (cat.keywords.isEmpty)
                    Text(
                      'No keywords defined.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cat.keywords.map((kw) {
                        return Chip(
                          label: Text(kw),
                          labelStyle: tt.labelSmall?.copyWith(color: catColor),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _removeCategoryKeyword(cat, kw),
                          backgroundColor: catColor.withValues(alpha: 0.1),
                          side: BorderSide(color: catColor.withValues(alpha: 0.3), width: 0.5),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
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
  }
}
