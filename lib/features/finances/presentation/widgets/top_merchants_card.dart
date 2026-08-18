import 'package:flutter/material.dart';
import '../../../../data/transaction_model.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_card.dart';

/// Modular Material 3 Card ranking top spending destinations/merchants.
class TopMerchantsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const TopMerchantsCard({
    super.key,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Filter only expense transactions
    final expenses = transactions.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);

    // Group expenses by cleaned merchant description
    final merchantMap = <String, ({double total, int count})>{};
    for (final t in expenses) {
      var name = t.description.trim();
      // Remove trailing identifiers or noise if any
      name = name.split(RegExp(r'\s*-\s*|\s*#\s*')).first.trim();
      if (name.isEmpty) name = 'Other';

      final existing = merchantMap[name];
      if (existing == null) {
        merchantMap[name] = (total: t.amount, count: 1);
      } else {
        merchantMap[name] = (total: existing.total + t.amount, count: existing.count + 1);
      }
    }

    // Sort descending by total spent
    final sortedMerchants = merchantMap.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    final topMerchants = sortedMerchants.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Spending Merchants',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topMerchants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = topMerchants[index];
              final merchantName = entry.key;
              final total = entry.value.total;
              final count = entry.value.count;
              final percent = totalExpense > 0 ? (total / totalExpense) : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${index + 1}',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchantName,
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$count transaction${count > 1 ? 's' : ''} • ${(percent * 100).toStringAsFixed(1)}% of total',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$currency ${total.toStringAsFixed(0)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
