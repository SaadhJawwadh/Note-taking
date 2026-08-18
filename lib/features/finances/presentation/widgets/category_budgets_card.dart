import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/settings_provider.dart';
import '../../../../data/transaction_category.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_card.dart';

/// Modular Material 3 Card displaying category budget progress and over-budget warnings.
class CategoryBudgetsCard extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final SettingsProvider settings;
  final String currency;
  final VoidCallback onBudgetChanged;

  const CategoryBudgetsCard({
    super.key,
    required this.categoryExpenses,
    required this.settings,
    required this.currency,
    required this.onBudgetChanged,
  });

  void _showSetBudgetDialog(BuildContext context, String category, double currentBudget) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Set Monthly Budget for $category'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '$currency ',
              hintText: 'Enter monthly limit (e.g. 5000)',
              helperText: 'Enter 0 or leave empty to remove budget',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final val = double.tryParse(controller.text.trim()) ?? 0.0;
                await settings.setCategoryBudget(category, val);
                onBudgetChanged();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final budgets = settings.categoryBudgets;

    final allDisplayCategories = <String>{
      ...budgets.keys.where((k) => (budgets[k] ?? 0) > 0),
      ...categoryExpenses.keys,
    }.toList()..sort();

    if (allDisplayCategories.isEmpty) {
      allDisplayCategories.addAll(TransactionCategory.all.take(5));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Category Budgets',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Tap to adjust',
                style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allDisplayCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = allDisplayCategories[index];
              final spent = categoryExpenses[category] ?? 0.0;
              final budget = budgets[category] ?? 0.0;
              final hasBudget = budget > 0;
              final ratio = hasBudget ? (spent / budget) : 0.0;
              final progress = ratio.clamp(0.0, 1.0);
              final isOverBudget = spent > budget && hasBudget;

              final progressColor = isOverBudget
                  ? colorScheme.error
                  : ratio >= 0.7
                      ? Colors.amber.shade700
                      : colorScheme.primary;

              return InkWell(
                onTap: () => _showSetBudgetDialog(context, category, budget),
                borderRadius: BorderRadius.circular(AppLayout.radiusM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            TransactionCategory.iconFor(category),
                            size: 16,
                            color: TransactionCategory.colorFor(category),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            hasBudget
                                ? '$currency ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}'
                                : '$currency ${spent.toStringAsFixed(0)}',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isOverBudget ? colorScheme.error : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                        child: LinearProgressIndicator(
                          value: hasBudget ? progress : 0.0,
                          minHeight: 6,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      if (isOverBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Exceeded by $currency ${(spent - budget).toStringAsFixed(0)}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
