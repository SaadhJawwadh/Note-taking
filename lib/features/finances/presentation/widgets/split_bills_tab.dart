import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_card.dart';
import '../../../../core/ui/app_chip.dart';
import '../../../../data/settings_provider.dart';
import '../../../../data/transaction_category.dart';
import '../../data/models/split_bill_model.dart';
import '../../providers/split_bill_provider.dart';
import '../../services/split_share_service.dart';
import '../screens/split_bill_editor_screen.dart';
import 'settle_up_sheet.dart';

class SplitBillsTab extends StatefulWidget {
  const SplitBillsTab({super.key});

  @override
  State<SplitBillsTab> createState() => _SplitBillsTabState();
}

class _SplitBillsTabState extends State<SplitBillsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SplitBillProvider>(context, listen: false).loadSplitBills(showLoading: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final splitProvider = Provider.of<SplitBillProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final bills = splitProvider.filteredBills.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.title.toLowerCase().contains(q) ||
          b.payerName.toLowerCase().contains(q) ||
          b.participants.any((p) => p.contactName.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      onRefresh: () => splitProvider.loadSplitBills(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS),
        children: [
          // 1. Dynamic Split Summary Hero Card
          _buildHeroSummaryCard(context, splitProvider, isDark),

          const SizedBox(height: AppLayout.spaceM),

          // 2. View Mode Selector (People vs Bills)
          Center(
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('People (${splitProvider.contactBalances.length})'),
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Bills (${splitProvider.bills.length})'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                ),
              ],
              selected: {splitProvider.activeViewMode},
              onSelectionChanged: (set) {
                HapticFeedback.lightImpact();
                splitProvider.setViewMode(set.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: colorScheme.secondaryContainer,
                selectedForegroundColor: colorScheme.onSecondaryContainer,
                backgroundColor: colorScheme.surfaceContainerLow,
              ),
            ),
          ),

          const SizedBox(height: AppLayout.spaceM),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search friends or bills...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),

          const SizedBox(height: AppLayout.spaceM),

          // 3. Filter Chips Bar
          _buildFilterBar(context, splitProvider),

          const SizedBox(height: AppLayout.spaceM),

          // 4. Content Section (People View vs Bills View)
          if (splitProvider.isLoading && splitProvider.bills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (splitProvider.activeViewMode == 0)
            _buildPeopleView(context, splitProvider)
          else
            _buildBillsView(context, bills, splitProvider, settings),

          const SizedBox(height: 96), // Clearance for morphing FAB
        ],
      ),
    );
  }

  Widget _buildHeroSummaryCard(BuildContext context, SplitBillProvider splitProvider, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final owedToUser = splitProvider.totalOwedToUser;
    final userOwes = splitProvider.totalUserOwes;
    final net = splitProvider.netBalance;

    final heroAlpha = isDark ? 0.20 : 0.50;
    final heroBg = colorScheme.primaryContainer.withValues(alpha: heroAlpha);

    return AppCard(
      padding: const EdgeInsets.all(AppLayout.spaceL),
      backgroundColor: heroBg,
      border: BorderSide(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: AppLayout.spaceS),
                  Text(
                    'Split Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              // Net Position Pill
              AppChip(
                label: net >= 0
                    ? '+Rs. ${net.toStringAsFixed(2).replaceAll('.00', '')} (Net Owed)'
                    : '-Rs. ${net.abs().toStringAsFixed(2).replaceAll('.00', '')} (Net You Owe)',
                backgroundColor: net >= 0
                    ? Colors.green.withValues(alpha: 0.18)
                    : Colors.red.withValues(alpha: 0.18),
                textColor: net >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceL),
          Row(
            children: [
              // You are owed metric
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    splitProvider.setFilter('i_am_owed');
                  },
                  borderRadius: BorderRadius.circular(AppLayout.radiusM),
                  child: Container(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: isDark ? 0.12 : 0.10),
                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 16),
                            const SizedBox(width: AppLayout.spaceXS),
                            Text(
                              'You are owed',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.spaceXS),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Rs. ${owedToUser.toStringAsFixed(2).replaceAll('.00', '')}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.spaceM),
              // You owe metric
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    splitProvider.setFilter('i_owe');
                  },
                  borderRadius: BorderRadius.circular(AppLayout.radiusM),
                  child: Container(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.10),
                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: AppLayout.spaceXS),
                            Text(
                              'You owe',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.spaceXS),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Rs. ${userOwes.toStringAsFixed(2).replaceAll('.00', '')}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, SplitBillProvider splitProvider) {
    final filters = [
      {'id': 'all', 'label': 'All', 'icon': null},
      {'id': 'unsettled', 'label': 'Unsettled', 'icon': Icons.hourglass_top_rounded},
      {'id': 'settled', 'label': 'Settled', 'icon': Icons.check_circle_outline_rounded},
      {'id': 'i_am_owed', 'label': 'I am owed', 'icon': Icons.arrow_downward_rounded},
      {'id': 'i_owe', 'label': 'I owe', 'icon': Icons.arrow_upward_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...filters.map((f) {
            final id = f['id']! as String;
            final label = f['label']! as String;
            final icon = f['icon'] as IconData?;
            final isSelected = splitProvider.activeFilter == id && splitProvider.activeGroupTag == null;

            return Padding(
              padding: const EdgeInsets.only(right: AppLayout.spaceS),
              child: FilterChip(
                showCheckmark: false,
                avatar: icon != null ? Icon(icon, size: 16) : null,
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  splitProvider.setFilter(id);
                  splitProvider.setGroupTag(null);
                },
              ),
            );
          }),
          // Group tags
          ...splitProvider.availableGroupTags.map((tag) {
            final isSelected = splitProvider.activeGroupTag == tag;
            return Padding(
              padding: const EdgeInsets.only(right: AppLayout.spaceS),
              child: FilterChip(
                showCheckmark: false,
                label: Text('# $tag'),
                selected: isSelected,
                onSelected: (sel) {
                  HapticFeedback.selectionClick();
                  splitProvider.setGroupTag(sel ? tag : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeopleView(BuildContext context, SplitBillProvider splitProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balances = splitProvider.contactBalances;
    final contacts = splitProvider.recentContacts;

    if (balances.isEmpty && contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppLayout.spaceM),
              Text(
                'No friend balances yet',
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppLayout.spaceXS),
              Text(
                'Create a split bill to track who owes you and who you owe.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLayout.spaceM),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SplitBillEditorScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Split a New Bill'),
              ),
            ],
          ),
        ),
      );
    }

    final personNames = balances.keys.toList();
    for (final c in contacts) {
      if (!personNames.contains(c.name)) {
        personNames.add(c.name);
      }
    }

    return AnimationLimiter(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: personNames.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppLayout.spaceS),
        itemBuilder: (context, index) {
          final name = personNames[index];
          final netBalance = balances[name] ?? 0.0;
          final isOwed = netBalance > 0;
          final owes = netBalance < 0;
          final isSettled = netBalance == 0;

          // Find open bills for this person
          final openBills = splitProvider.bills.where((b) {
            if (b.isFullySettled) return false;
            if (b.isPayerUser) {
              return b.participants.any((p) => p.contactName.trim().toLowerCase() == name.trim().toLowerCase() && !p.hasPaid);
            } else {
              return b.payerName.trim().toLowerCase() == name.trim().toLowerCase();
            }
          }).toList();

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 250),
            child: SlideAnimation(
              verticalOffset: 20.0,
              child: FadeInAnimation(
                child: AppCard(
                  padding: const EdgeInsets.all(AppLayout.spaceM),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isOwed
                            ? Colors.green.withValues(alpha: 0.2)
                            : (owes ? Colors.red.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOwed ? Colors.green : (owes ? Colors.red : colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppLayout.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              isSettled
                                  ? 'All settled up'
                                  : (isOwed
                                      ? 'Owes you for ${openBills.length} bill${openBills.length == 1 ? '' : 's'}'
                                      : 'You owe for ${openBills.length} bill${openBills.length == 1 ? '' : 's'}'),
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isSettled
                                ? 'Rs. 0'
                                : (isOwed
                                    ? '+Rs. ${netBalance.toStringAsFixed(2).replaceAll('.00', '')}'
                                    : '-Rs. ${netBalance.abs().toStringAsFixed(2).replaceAll('.00', '')}'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOwed ? Colors.green : (owes ? Colors.red : colorScheme.onSurfaceVariant),
                            ),
                          ),
                          if (!isSettled) ...[
                            const SizedBox(height: AppLayout.spaceXS),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOwed) ...[
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, size: 18),
                                    tooltip: 'Remind on WhatsApp',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      final firstBill = openBills.isNotEmpty ? openBills.first : null;
                                      if (firstBill != null) {
                                        SplitShareService.shareToWhatsAppOrSystem(
                                          firstBill,
                                          defaultPaymentInfo: Provider.of<SettingsProvider>(context, listen: false).defaultPaymentInfo,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: AppLayout.spaceXS),
                                ],
                                FilledButton.tonal(
                                  onPressed: () => SettleUpSheet.show(
                                    context,
                                    contactName: name,
                                    netAmount: netBalance,
                                  ),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                                  ),
                                  child: const Text('Settle Up', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillsView(
    BuildContext context,
    List<SplitBillModel> bills,
    SplitBillProvider splitProvider,
    SettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (bills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppLayout.spaceM),
              Text(
                'No split bills found',
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppLayout.spaceM),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SplitBillEditorScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Split a New Bill'),
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: bills.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppLayout.spaceS),
        itemBuilder: (context, index) {
          final bill = bills[index];
          final isSettled = bill.isFullySettled;
          final totalReceived = bill.totalReceived;
          final totalExpected = bill.totalOthersShare;
          final progress = totalExpected > 0 ? (totalReceived / totalExpected).clamp(0.0, 1.0) : 1.0;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 250),
            child: SlideAnimation(
              verticalOffset: 20.0,
              child: FadeInAnimation(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SplitBillEditorScreen(existingBill: bill)),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppLayout.radiusM),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bill.title,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (bill.groupTag != null && bill.groupTag!.isNotEmpty) ...[
                                        const SizedBox(width: AppLayout.spaceXS),
                                        AppChip(
                                          label: bill.groupTag!,
                                          backgroundColor: TransactionCategory.colorFor(bill.groupTag!).withValues(alpha: 0.15),
                                          textColor: TransactionCategory.colorFor(bill.groupTag!),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat('MMM d, yyyy').format(bill.date)} • Paid by ${bill.payerName}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppLayout.spaceM),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. ${bill.totalAmount.toStringAsFixed(2).replaceAll('.00', '')}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Builder(
                                  builder: (context) {
                                    final String statusLabel;
                                    final IconData statusIcon;
                                    final Color statusColor;
                                    if (!bill.isPayerUser) {
                                      if (bill.isUserSharePaid) {
                                        statusLabel = 'Settled for You';
                                        statusIcon = Icons.check_circle_rounded;
                                        statusColor = Colors.green;
                                      } else {
                                        statusLabel = 'You Owe Rs. ${bill.userShare.toStringAsFixed(2).replaceAll('.00', '')}';
                                        statusIcon = Icons.hourglass_top_rounded;
                                        statusColor = Colors.red;
                                      }
                                    } else {
                                      if (isSettled) {
                                        statusLabel = 'Settled';
                                        statusIcon = Icons.check_circle_rounded;
                                        statusColor = Colors.green;
                                      } else if (bill.totalReceived > 0) {
                                        statusLabel = 'Partial';
                                        statusIcon = Icons.timelapse_rounded;
                                        statusColor = Colors.blue;
                                      } else {
                                        statusLabel = 'Unsettled';
                                        statusIcon = Icons.hourglass_top_rounded;
                                        statusColor = Colors.amber.shade800;
                                      }
                                    }

                                    return AppChip(
                                      label: statusLabel,
                                      icon: statusIcon,
                                      backgroundColor: statusColor.withValues(alpha: 0.15),
                                      textColor: statusColor,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Interactive Status Banner when Someone Else Paid
                        if (!bill.isPayerUser) ...[
                          const SizedBox(height: AppLayout.spaceM),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: bill.isUserSharePaid
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : colorScheme.errorContainer.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(AppLayout.radiusS),
                              border: Border.all(
                                color: bill.isUserSharePaid
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : colorScheme.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  bill.isUserSharePaid ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                                  size: 18,
                                  color: bill.isUserSharePaid ? Colors.green : colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bill.isUserSharePaid
                                        ? 'Your share of Rs. ${bill.userShare.toStringAsFixed(2).replaceAll('.00', '')} is settled with ${bill.payerName}'
                                        : 'You owe ${bill.payerName}: Rs. ${bill.userShare.toStringAsFixed(2).replaceAll('.00', '')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: bill.isUserSharePaid ? Colors.green : colorScheme.error,
                                    ),
                                  ),
                                ),
                                if (!bill.isUserSharePaid) ...[
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    onPressed: () {
                                      final userPart = bill.participants.where((p) => p.contactName.trim().toLowerCase() == 'you').firstOrNull;
                                      SettleUpSheet.show(
                                        context,
                                        contactName: bill.payerName,
                                        netAmount: -bill.userShare,
                                        specificBill: bill,
                                        specificParticipant: userPart,
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                                    ),
                                    child: const Text('Settle My Share', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Progress Bar for Payers
                        if (bill.isPayerUser && totalExpected > 0) ...[
                          const SizedBox(height: AppLayout.spaceM),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: AppLayout.spaceXS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Received Rs. ${totalReceived.toStringAsFixed(2).replaceAll('.00', '')} of ${totalExpected.toStringAsFixed(2).replaceAll('.00', '')}',
                                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                '${bill.participants.where((p) => p.hasPaid && p.contactName.toLowerCase() != 'you').length}/${bill.participants.where((p) => p.contactName.toLowerCase() != 'you').length} Paid',
                                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],

                        // Participants Avatars & 1-Tap Toggle
                        const SizedBox(height: AppLayout.spaceM),
                        Wrap(
                          spacing: AppLayout.spaceS,
                          runSpacing: AppLayout.spaceS,
                          children: bill.participants.map((p) {
                            final isYou = p.contactName.trim().toLowerCase() == 'you';
                            final isPayer = !bill.isPayerUser &&
                                p.contactName.trim().toLowerCase() == bill.payerName.trim().toLowerCase();

                            return Semantics(
                              button: !isPayer,
                              label: isYou
                                  ? 'Your share: Rs. ${p.shareAmount.toStringAsFixed(0)}, ${p.hasPaid ? 'paid' : 'tap to settle'}'
                                  : (bill.isPayerUser
                                      ? 'Mark ${p.contactName} as ${p.hasPaid ? 'unpaid' : 'paid'}'
                                      : '${p.contactName} owes ${bill.payerName}: Rs. ${p.shareAmount.toStringAsFixed(0)}, ${p.hasPaid ? 'paid' : 'unpaid'}'),
                              child: InkWell(
                                onTap: isPayer
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        if (isYou) {
                                          if (!p.hasPaid) {
                                            SettleUpSheet.show(
                                              context,
                                              contactName: bill.payerName,
                                              netAmount: -p.shareAmount,
                                              specificBill: bill,
                                              specificParticipant: p,
                                            );
                                          } else {
                                            splitProvider.toggleParticipantPaid(p.id, false);
                                          }
                                        } else if (bill.isPayerUser) {
                                          // You paid the bill -> other participants pay YOU back
                                          if (!p.hasPaid) {
                                            SettleUpSheet.show(
                                              context,
                                              contactName: p.contactName,
                                              netAmount: p.shareAmount,
                                              specificBill: bill,
                                              specificParticipant: p,
                                            );
                                          } else {
                                            splitProvider.toggleParticipantPaid(p.id, false);
                                          }
                                        } else {
                                          // Friend paid the bill -> other friends owe the payer, NOT you!
                                          // Toggling marks it in the split record only; NO ledger transaction.
                                          splitProvider.toggleParticipantPaid(p.id, !p.hasPaid);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(p.hasPaid
                                                  ? 'Marked ${p.contactName} as unpaid to ${bill.payerName}'
                                                  : 'Marked ${p.contactName} as paid to ${bill.payerName} (split record only)'),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                onLongPress: (!p.hasPaid && !isYou && !isPayer)
                                    ? () async {
                                        final settings = Provider.of<SettingsProvider>(context, listen: false);
                                        await HapticFeedback.mediumImpact();
                                        final reminder = SplitShareService.formatPersonReminder(
                                          contactName: p.contactName,
                                          billTitle: bill.title,
                                          shareAmount: p.shareAmount,
                                          currencySymbol: settings.currency,
                                          defaultPaymentInfo: settings.defaultPaymentInfo,
                                        );
                                        await SplitShareService.shareText(reminder, subject: 'Split Bill Reminder');
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: p.hasPaid
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                    border: Border.all(
                                      color: p.hasPaid ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        p.hasPaid ? Icons.check_circle_rounded : Icons.circle_outlined,
                                        size: 16,
                                        color: p.hasPaid ? Colors.green : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isYou
                                            ? 'You: Rs. ${p.shareAmount.toStringAsFixed(0)}'
                                            : (bill.isPayerUser
                                                ? '${p.contactName}: Rs. ${p.shareAmount.toStringAsFixed(0)}'
                                                : '${p.contactName}: Rs. ${p.shareAmount.toStringAsFixed(0)} (owes ${bill.payerName})'),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: p.hasPaid ? Colors.green : colorScheme.onSurface,
                                          fontWeight: p.hasPaid ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Action row
                        const SizedBox(height: AppLayout.spaceS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Semantics(
                              button: true,
                              label: 'Share bill details on WhatsApp',
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                child: IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 20),
                                  tooltip: 'Share on WhatsApp',
                                  onPressed: () => SplitShareService.shareToWhatsAppOrSystem(
                                    bill,
                                    defaultPaymentInfo: settings.defaultPaymentInfo,
                                  ),
                                ),
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Copy bill breakdown to clipboard',
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                child: IconButton(
                                  icon: const Icon(Icons.copy_all_rounded, size: 20),
                                  tooltip: 'Copy Breakdown',
                                  onPressed: () {
                                    final summary = SplitShareService.formatBillSummary(
                                      bill,
                                      defaultPaymentInfo: settings.defaultPaymentInfo,
                                    );
                                    SplitShareService.copyToClipboard(summary);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bill breakdown copied to clipboard.')),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
