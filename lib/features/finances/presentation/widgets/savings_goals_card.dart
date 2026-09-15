import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_card.dart';
import '../../../../core/ui/app_chip.dart';
import '../../../../core/ui/app_dialog.dart';
import '../../../../data/settings_provider.dart';
import '../../../../data/transaction_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../providers/savings_goal_provider.dart';
import 'savings_goal_deposit_sheet.dart';
import 'savings_goal_editor_sheet.dart';

/// Card widget showcasing active goal-oriented savings pockets, progress, auto-pacing, and quick deposit.
class SavingsGoalsCard extends StatelessWidget {
  final String? currency;

  const SavingsGoalsCard({super.key, this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currencySymbol = currency ??
        Provider.of<SettingsProvider?>(context)?.currencySymbol ??
        'Rs.';

    final provider = Provider.of<SavingsGoalProvider?>(context);
    final goals = provider?.activeGoals ?? const <SavingsGoal>[];

    return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: AppLayout.spaceS),
                  Text(
                    'Savings Pockets',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Goal'),
                    onPressed: () => SavingsGoalEditorSheet.show(context),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.spaceS),

              if (goals.isEmpty) ...[
                // Empty State
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceM),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 44,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppLayout.spaceS),
                        Text(
                          'No active savings goals',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save monthly for college, phone, travel, or emergencies.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: AppLayout.spaceM),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create First Goal'),
                          onPressed: () => SavingsGoalEditorSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Aggregate Overview
                _buildAggregateOverview(context, goals, currencySymbol),
                const SizedBox(height: AppLayout.spaceM),
                const Divider(height: 1),
                const SizedBox(height: AppLayout.spaceS),

                // Goals List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppLayout.spaceM),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalRow(context, goal, currencySymbol, provider);
                  },
                ),
              ],
            ],
          ),
        );
  }

  Widget _buildAggregateOverview(
    BuildContext context,
    List<SavingsGoal> goals,
    String currency,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalSaved = goals.fold<double>(0.0, (acc, g) => acc + g.currentAmount);
    final totalTarget = goals.fold<double>(0.0, (acc, g) => acc + g.targetAmount);
    final ratio = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppLayout.radiusM),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Target: $currency ${totalTarget.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$currency ${totalSaved.toStringAsFixed(0)} (${(ratio * 100).toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppLayout.radiusS),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(
    BuildContext context,
    SavingsGoal goal,
    String currency,
    SavingsGoalProvider? provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goalColor = Color(goal.colorValue);

    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.radiusM),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon, Title, Category Pill, Menu
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: goalColor.withValues(alpha: 0.18),
                child: Icon(
                  SavingsGoalModel.getIcon(goal.iconCodePoint),
                  color: goalColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppLayout.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AppChip(
                          label: goal.category,
                          backgroundColor: goalColor.withValues(alpha: 0.15),
                          textColor: goalColor,
                          isCompact: true,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          goal.account == AccountType.savings ? 'Savings Vault' : 'Daily Operating',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                onSelected: (val) {
                  if (val == 'edit') {
                    SavingsGoalEditorSheet.show(context, goal: goal);
                  } else if (val == 'deposit') {
                    SavingsGoalDepositSheet.show(context, goal: goal);
                  } else if (val == 'delete') {
                    _confirmDelete(context, goal, provider);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'deposit',
                    child: ListTile(
                      leading: Icon(Icons.add_circle_outline_rounded, size: 18),
                      title: Text('Deposit / Withdraw'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined, size: 18),
                      title: Text('Edit Goal'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded, size: 18, color: colorScheme.error),
                      title: Text('Delete Goal', style: TextStyle(color: colorScheme.error)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceM),

          // Row 2: Progress & Amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currency ${goal.currentAmount.toStringAsFixed(0)} / $currency ${goal.targetAmount.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (goal.milestoneLabel.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppLayout.radiusS),
                      ),
                      child: Text(
                        goal.milestoneLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: goalColor),
                      ),
                    ),
                  Text(
                    '${goal.progressPercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: goalColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppLayout.radiusS),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              minHeight: 7,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: goalColor,
            ),
          ),
          const SizedBox(height: AppLayout.spaceM),

          // Row 3: Pacing & Quick Deposit Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '$currency ${goal.effectiveMonthlyPace.toStringAsFixed(0)} / mo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~${goal.estimatedMonthsRemaining} months left to reach target',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: goalColor.withValues(alpha: 0.15),
                  foregroundColor: goalColor,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Deposit'),
                onPressed: () => SavingsGoalDepositSheet.show(context, goal: goal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SavingsGoal goal, SavingsGoalProvider? provider) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Savings Goal?',
      message: 'Are you sure you want to delete "${goal.title}"? Your recorded ledger transactions will not be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && provider != null) {
      await provider.deleteGoal(goal.id);
    }
  }
}
