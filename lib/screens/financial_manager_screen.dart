// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../data/settings_provider.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/recurring_rule_repository.dart';
import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import '../data/sms_contact.dart';
import '../services/sms_service.dart';
import '../services/sms_constants.dart';
import 'transaction_editor_screen.dart';
import 'settings_screen.dart';
import 'app_lock_screen.dart';
import '../services/backup_service.dart';
import '../utils/app_route.dart';
import '../theme/app_layout.dart';
import '../widgets/finance/financial_category_donut_card.dart';
import '../widgets/finance/financial_trend_regression_card.dart';

class FinancialManagerScreen extends StatefulWidget {
  static final ValueNotifier<String?> tabRedirectNotifier = ValueNotifier<String?>(null);

  const FinancialManagerScreen({super.key});

  @override
  State<FinancialManagerScreen> createState() => _FinancialManagerScreenState();
}

class _FinancialManagerScreenState extends State<FinancialManagerScreen> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _allDateFiltered = [];
  bool _isLoading = true;
  String? _selectedCategory;
  List<String> _activeCategories = [];
  late String _selectedTab;
  String _analyticsSegment = 'Trends';

  List<Map<String, dynamic>> _monthlyData = [];
  bool _isDashboardLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  StreamSubscription<TransactionModel>? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _selectedTab = FinancialManagerScreen.tabRedirectNotifier.value ?? 'Ledger';
    FinancialManagerScreen.tabRedirectNotifier.addListener(_handleTabRedirect);
    _refreshTransactions();
    _smsSubscription = SmsService.incomingTransactions.listen((t) async {
      if (!mounted) return;
      await _refreshTransactions();
    });
  }

  void _handleTabRedirect() {
    final newTab = FinancialManagerScreen.tabRedirectNotifier.value;
    if (newTab != null && mounted) {
      setState(() {
        _selectedTab = newTab;
      });
      FinancialManagerScreen.tabRedirectNotifier.value = null; // consume
    }
  }

  Map<String, double> get _categoryExpenses {
    final Map<String, double> totals = {};
    for (final t in _allDateFiltered) {
      if (t.isExpense) {
        totals[t.category] = (totals[t.category] ?? 0.0) + t.amount;
      }
    }
    return totals;
  }

  double get _totalDateExpense {
    return _allDateFiltered
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  void dispose() {
    FinancialManagerScreen.tabRedirectNotifier.removeListener(_handleTabRedirect);
    _smsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      _isLoading = true;
      _isDashboardLoading = true;
    });
    // Materialize any recurring transactions that came due since last visit.
    try {
      await RecurringRuleRepository.instance.materializeDueRules();
    } catch (e) {
      debugPrint('Recurring materialization error: $e');
    }
    final allTransactions = await TransactionRepository.instance.readAllTransactions();

    _allDateFiltered = allTransactions.where((t) {
      // Filter out any orphan reversal sentinels
      if (t.category == SmsConstants.reversalSentinel) return false;
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final start = DateTime(_selectedRange.start.year,
          _selectedRange.start.month, _selectedRange.start.day);
      final end = DateTime(_selectedRange.end.year, _selectedRange.end.month,
          _selectedRange.end.day);
      return tDate.isAfter(start.subtract(const Duration(days: 1))) &&
          tDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    _monthlyData =
        await TransactionRepository.instance.getMonthlyTransactionSummary(6);

    _applyFilters();
    setState(() {
      _isDashboardLoading = false;
    });
  }

  /// Applies category and search filters from the cached [_allDateFiltered]
  /// list. No DB call, no loading spinner — instant.
  void _applyFilters() {
    final activeCategories =
        _allDateFiltered.map((t) => t.category).toSet().toList()..sort();

    var filtered = _selectedCategory == null
        ? _allDateFiltered
        : _allDateFiltered
            .where((t) => t.category == _selectedCategory)
            .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.description.toLowerCase().contains(_searchQuery) ||
              t.category.toLowerCase().contains(_searchQuery))
          .toList();
    }

    setState(() {
      _activeCategories = activeCategories;
      _transactions = filtered;
      _isLoading = false;
    });
  }

  double get _totalExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalIncome {
    return _transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Flat list of [String] date-header labels and [TransactionModel] items,
  /// ordered newest-first, for the grouped transaction list.
  List<dynamic> get _groupedTransactions {
    if (_transactions.isEmpty) return [];
    final items = <dynamic>[];
    DateTime? lastDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final t in _transactions) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      if (lastDate == null || tDate != lastDate) {
        String header;
        if (tDate == today) {
          header = 'Today';
        } else if (tDate == yesterday) {
          header = 'Yesterday';
        } else {
          header = DateFormat.MMMd().format(tDate);
        }
        items.add(header);
        lastDate = tDate;
      }
      items.add(t);
    }
    return items;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    final thisMonth = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    final lastMonth = DateTimeRange(
      start: DateTime(now.year, now.month - 1, 1),
      end: DateTime(now.year, now.month, 0),
    );
    final last90Days = DateTimeRange(
      start: now.subtract(const Duration(days: 90)),
      end: now,
    );
    final thisYear = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: now,
    );
    final allTime = DateTimeRange(
      start: DateTime(2000, 1, 1),
      end: DateTime(2100, 1, 1),
    );

    final selectedPreset = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool isCurrent(DateTimeRange range) {
          return _selectedRange.start.year == range.start.year &&
              _selectedRange.start.month == range.start.month &&
              _selectedRange.start.day == range.start.day &&
              _selectedRange.end.year == range.end.year &&
              _selectedRange.end.month == range.end.month &&
              _selectedRange.end.day == range.end.day;
        }

        Widget buildPresetCard(String label, IconData icon, DateTimeRange range) {
          final isSelected = isCurrent(range);
          return InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, range);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Select Period',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: buildPresetCard('This Month', Icons.today_outlined, thisMonth)),
                    const SizedBox(width: 10),
                    Expanded(child: buildPresetCard('Last Month', Icons.history_outlined, lastMonth)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: buildPresetCard('Last 90 Days', Icons.auto_graph_outlined, last90Days)),
                    const SizedBox(width: 10),
                    Expanded(child: buildPresetCard('This Year', Icons.calendar_today_outlined, thisYear)),
                  ],
                ),
                const SizedBox(height: 10),
                buildPresetCard('All Time (Full History)', Icons.all_inclusive_outlined, allTime),
                const SizedBox(height: 16),
                Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(Icons.date_range_outlined, color: colorScheme.onSecondaryContainer),
                  ),
                  title: Text(
                    'Custom Date Range…',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Pick exact start and end dates from calendar',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final customPicked = await showDateRangePicker(
                      context: context,
                      initialDateRange: _selectedRange,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  surface: Theme.of(context).colorScheme.surfaceContainerHigh,
                                ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (customPicked != null && customPicked != _selectedRange) {
                      setState(() => _selectedRange = customPicked);
                      await _refreshTransactions();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPreset != null && selectedPreset != _selectedRange) {
      setState(() => _selectedRange = selectedPreset);
      await _refreshTransactions();
    }
  }

  // ── Dashboard widgets ────────────────────────────────────────────────────

  Future<void> _quickImportRecentSms() async {
    final granted = await SmsService.hasPermission();
    if (!mounted) return;

    if (!granted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS Access'),
          content: const Text(
            'This app needs permission to read your SMS messages '
            'so it can detect and import bank transactions.\n\n'
            'Only messages from recognised bank senders are processed. '
            'No messages are sent off-device or shared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Allow'),
            ),
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

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanning recent messages...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );

    // Fetch the last 24 hours (1 day)
    final from = DateTime.now().subtract(const Duration(days: 1));
    final count = await SmsService.syncInboxFrom(from);

    if (!mounted) return;
    await _refreshTransactions();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'No new bank SMS detected in past 24h.'
              : 'Successfully imported $count new transaction${count == 1 ? '' : 's'}! 🎉',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cleanupLedgerDuplicates() async {
    final messenger = ScaffoldMessenger.of(context);
    await HapticFeedback.mediumImpact();
    final count = await TransactionRepository.instance.cleanupDuplicates();
    if (!mounted) return;
    await _refreshTransactions();
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'Ledger is 100% clean! No duplicate transactions found.'
              : 'Successfully cleaned up $count duplicate transaction${count == 1 ? '' : 's'}! 🎉',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _discoverBankSenders() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    await HapticFeedback.mediumImpact();

    final candidates = await SmsService.discoverNewBankSenders();
    if (!mounted) return;

    if (candidates.isEmpty) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No unrecognized bank senders found in your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.radar_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Discovered Bank Senders',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Found ${candidates.length} candidate bank sender${candidates.length == 1 ? '' : 's'} in your messages. Tap to allow auto-import:',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final sender = candidates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined, size: 20)),
                          title: Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: FilledButton.tonal(
                            onPressed: () async {
                              await TransactionRepository.instance.upsertSmsContact(
                                SmsContact(id: sender, label: sender, senderIds: [sender], isBlocked: false),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Added "$sender" to allowed bank senders!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Allow'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Combined hero card: net balance + income/expense breakdown for the
  /// currently selected date range.
  Widget _buildHeroSummaryCard(ColorScheme cs, TextTheme tt, String currency) {
    if (_isLoading) {
      return const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator()));
    }
    final net = _totalIncome - _totalExpense;
    final isPositive = net >= 0;
    final onColor = isPositive ? cs.onTertiaryContainer : cs.onErrorContainer;
    final rangeLabel = _selectedRange.duration.inDays == 0
        ? DateFormat.MMMMEEEEd().format(_selectedRange.start)
        : '${DateFormat.MMMd().format(_selectedRange.start)} – ${DateFormat.MMMd().format(_selectedRange.end)}';

    return Card(
      elevation: 0,
      color: isPositive ? cs.tertiaryContainer : cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range + trend icon
            Row(
              children: [
                Text(
                  rangeLabel,
                  style: tt.labelMedium?.copyWith(color: onColor),
                ),
                const Spacer(),
                Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 24,
                  color: onColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Net balance headline
            Text(
              '${isPositive ? '+' : '-'} $currency ${net.abs().toStringAsFixed(0)}',
              style: tt.headlineMedium?.copyWith(
                color: onColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: onColor.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 12),
            // Income / Expense breakdown
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _miniStat(tt, Icons.south_west, 'Income',
                        _totalIncome, currency, onColor),
                  ),
                  VerticalDivider(
                      width: 1, color: onColor.withValues(alpha: 0.2)),
                  Expanded(
                    child: _miniStat(tt, Icons.arrow_outward, 'Expense',
                        _totalExpense, currency, onColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(TextTheme tt, IconData icon, String label, double amount,
      String currency, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(label,
                style: tt.labelSmall
                    ?.copyWith(color: color.withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$currency ${amount.toStringAsFixed(0)}',
          style: tt.titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildBarChartCard(ColorScheme cs, TextTheme tt, String currency) {
    if (_isDashboardLoading || _monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final barGroups = _monthlyData.asMap().entries.map((e) {
      final idx = e.key;
      final data = e.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: data['totalIncome'] as double,
            width: 10,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [cs.tertiary.withValues(alpha: 0.5), cs.tertiary],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          BarChartRodData(
            toY: data['totalExpense'] as double,
            width: 10,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [cs.error.withValues(alpha: 0.5), cs.error],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();

    final monthLabels = _monthlyData
        .map((d) => DateFormat.MMM().format(d['month'] as DateTime))
        .toList();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 6 Months',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _legendDot(cs.tertiary),
                const SizedBox(width: 4),
                Text('Income',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                _legendDot(cs.error),
                const SizedBox(width: 4),
                Text('Expense',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= monthLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              monthLabels[idx],
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          final formatted = value >= 1000
                              ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K'
                              : value.toStringAsFixed(0);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatted,
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => cs.surfaceContainerHighest,
                      tooltipBorder: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Income' : 'Expense';
                        final color = rodIndex == 0 ? cs.tertiary : cs.error;
                        return BarTooltipItem(
                          '$type\n',
                          tt.labelSmall?.copyWith(color: cs.onSurfaceVariant) ?? const TextStyle(),
                          children: [
                            TextSpan(
                              text: '$currency ${rod.toY.toStringAsFixed(0)}',
                              style: tt.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonTile(
    ColorScheme cs,
    TextTheme tt,
    String label,
    double amount,
    double pctChange,
    String currency,
    bool negativeIsGood,
  ) {
    final isIncrease = pctChange >= 0;
    final Color changeColor;
    if (negativeIsGood) {
      changeColor = isIncrease ? cs.error : cs.tertiary;
    } else {
      changeColor = isIncrease ? cs.tertiary : cs.error;
    }

    return Column(
      children: [
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          '$currency ${amount.abs().toStringAsFixed(0)}',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: changeColor,
            ),
            Text(
              '${pctChange.abs().toStringAsFixed(1)}%',
              style: tt.labelSmall?.copyWith(color: changeColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthComparisonCard(
      ColorScheme cs, TextTheme tt, String currency) {
    if (_isDashboardLoading || _monthlyData.length < 2) {
      return const SizedBox.shrink();
    }

    final thisMonth = _monthlyData.last;
    final lastMonth = _monthlyData[_monthlyData.length - 2];

    double pctChange(double current, double previous) {
      if (previous == 0) return current > 0 ? 100.0 : 0.0;
      return ((current - previous) / previous) * 100.0;
    }

    final thisIncome = thisMonth['totalIncome'] as double;
    final thisExpense = thisMonth['totalExpense'] as double;
    final lastIncome = lastMonth['totalIncome'] as double;
    final lastExpense = lastMonth['totalExpense'] as double;
    final thisNet = thisIncome - thisExpense;
    final lastNet = lastIncome - lastExpense;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month vs Last Month',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _comparisonTile(cs, tt, 'Income', thisIncome,
                      pctChange(thisIncome, lastIncome), currency, false),
                ),
                Container(width: 1, height: 48, color: cs.outlineVariant),
                Expanded(
                  child: _comparisonTile(cs, tt, 'Expense', thisExpense,
                      pctChange(thisExpense, lastExpense), currency, true),
                ),
                Container(width: 1, height: 48, color: cs.outlineVariant),
                Expanded(
                  child: _comparisonTile(cs, tt, 'Net', thisNet,
                      pctChange(thisNet, lastNet), currency, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = Provider.of<SettingsProvider>(context);
    final currency = settings.currency;

    return Scaffold(
      body: AnimationLimiter(
        child: CustomScrollView(
          slivers: _buildSlivers(colorScheme, textTheme, currency, settings),
        ),
      ),
      floatingActionButton: OpenContainer<bool>(
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 300),
        openBuilder: (context, _) => const TransactionEditorScreen(),
        closedElevation: 6.0,
        openElevation: 0,
        closedShape: const StadiumBorder(),
        closedColor: colorScheme.primary,
        openColor: colorScheme.surface,
        onClosed: (updated) {
          if (updated == true) _refreshTransactions();
        },
        closedBuilder: (context, openContainer) {
          return SizedBox(
            height: 56,
            child: FloatingActionButton.extended(
              heroTag: 'finance_fab',
              label: const Text('New Transaction'),
              icon: const Icon(Icons.add),
              tooltip: 'Add Transaction',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: const StadiumBorder(),
              onPressed: () {
                HapticFeedback.lightImpact();
                openContainer();
              },
            ),
          );
        },
      ),
    );
  }
  List<Widget> _buildSlivers(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String currency,
    SettingsProvider settings,
  ) {
    return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
              toolbarHeight: 84,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              title: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                  boxShadow: AppLayout.softShadow(context),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _selectDateRange(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Finances',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedRange.duration.inDays == 0
                                      ? DateFormat.MMMd().format(_selectedRange.start)
                                      : '${DateFormat.MMMd().format(_selectedRange.start)} – ${DateFormat.MMMd().format(_selectedRange.end)}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.sync_outlined),
                      tooltip: 'Quick Import (24h)',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _quickImportRecentSms();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      tooltip: 'Select Date Range',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _selectDateRange(context);
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More Tools',
                      onSelected: (value) {
                        if (value == 'cleanup') {
                          _cleanupLedgerDuplicates();
                        } else if (value == 'discover') {
                          _discoverBankSenders();
                        } else if (value == 'export') {
                          BackupService.exportTransactionsToCsv(context);
                        } else if (value == 'settings') {
                          AppRoute.push(context, const SettingsScreen());
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'cleanup',
                          child: Row(
                            children: [
                              Icon(Icons.cleaning_services_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Purge Duplicates'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'discover',
                          child: Row(
                            children: [
                              Icon(Icons.radar_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Discover Bank Senders'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.table_view_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Export to CSV'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Settings'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

      // ── Hero summary card (net + income/expense breakdown) ────────
            // ── Hero summary card (net + income/expense breakdown) ────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 2,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildHeroSummaryCard(
                          colorScheme, textTheme, currency),
                    ),
                  ),
                ),
              ),
            ),

      // ── Tab selector ──────────────────────────────────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _buildTabSelector(colorScheme),
        ),
      ),
      if (_selectedTab == 'Ledger') ...[
        // ── Search bar ──────────────────────────────────────────────
            // ── Search bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 3,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(
                              () => _searchQuery = value.trim().toLowerCase());
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search transactions…',
                          prefixIcon: const Icon(Icons.search_outlined),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

        // ── Category filter chips ────────────────────────────────────
        if (_activeCategories.isNotEmpty)
          SliverToBoxAdapter(
            child: AnimationConfiguration.staggeredList(
              position: 4,
              duration: const Duration(milliseconds: 220),
              child: SlideAnimation(
                verticalOffset: 24.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            showCheckmark: false,
                            avatar: const Icon(Icons.all_inclusive, size: 16),
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (_) {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategory = null);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                          ..._activeCategories.map((cat) {
                            final catColor = TransactionCategory.colorFor(cat);
                            final catIcon = TransactionCategory.iconFor(cat);
                            final selected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                showCheckmark: false,
                                avatar: Icon(
                                  catIcon,
                                  size: 16,
                                  color: selected ? catColor : colorScheme.onSurfaceVariant,
                                ),
                                label: Text(cat),
                                selected: selected,
                                onSelected: (_) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedCategory = selected ? null : cat);
                                  _applyFilters();
                                },
                                selectedColor: catColor.withValues(alpha: 0.2),
                                checkmarkColor: catColor,
                                labelStyle: TextStyle(
                                  color: selected ? catColor : colorScheme.onSurfaceVariant,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: selected ? catColor : colorScheme.outline,
                                  width: selected ? 1.5 : 0.5,
                                ),
                              ),
                            );
                          }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

        // ── Transaction list ──────────────────────────────────────────
            // ── Transaction list ──────────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_transactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No results for "$_searchQuery"'
                            : _selectedCategory != null
                                ? 'No $_selectedCategory transactions\nin this period'
                                : 'No transactions in this period',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _applyFilters();
                          },
                          child: const Text('Clear search'),
                        ),
                      ] else if (_selectedCategory != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedCategory = null);
                            _applyFilters();
                          },
                          child: const Text('Clear filter'),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () async {
                            await HapticFeedback.lightImpact();
                            if (!mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionEditorScreen(),
                              ),
                            );
                            await _refreshTransactions();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Transaction'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _groupedTransactions[index];

                      // Date group header
                      if (item is String) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 300),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                                child: Text(
                                  item,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final transaction = item as TransactionModel;
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 300),
                        child: SlideAnimation(
                          verticalOffset: 20.0,
                          child: FadeInAnimation(
                            child: OpenContainer<bool>(
                              transitionType: ContainerTransitionType.fadeThrough,
                              transitionDuration: const Duration(milliseconds: 300),
                              openBuilder: (context, _) =>
                                  TransactionEditorScreen(
                                      transaction: transaction),
                              closedElevation: 0,
                              openElevation: 0,
                              closedColor: colorScheme.surfaceContainer,
                              openColor: colorScheme.surface,
                              closedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                              onClosed: (updated) {
                                if (updated == true) _refreshTransactions();
                              },
                              closedBuilder: (context, openContainer) {
                                return Dismissible(
                                  key: ValueKey('tx_${transaction.id}_${transaction.date.millisecondsSinceEpoch}'),
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: Row(
                                      children: [
                                        Icon(Icons.content_copy, color: colorScheme.onPrimaryContainer),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Duplicate',
                                          style: TextStyle(
                                            color: colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
                                      ],
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    if (direction == DismissDirection.startToEnd) {
                                      // Swipe Right -> Duplicate Transaction
                                      await HapticFeedback.mediumImpact();
                                      final duplicate = TransactionModel(
                                        amount: transaction.amount,
                                        description: '${transaction.description} (Copy)',
                                        date: DateTime.now(),
                                        isExpense: transaction.isExpense,
                                        category: transaction.category,
                                        smsId: null,
                                      );
                                      await TransactionRepository.instance.createTransaction(duplicate);
                                      await _refreshTransactions();
                                      if (mounted) {
                                        messenger.clearSnackBars();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Duplicated "${transaction.description}"'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                      return false; // Retain original item
                                    } else {
                                      // Swipe Left -> Delete Transaction with UNDO
                                      await HapticFeedback.mediumImpact();
                                      await TransactionRepository.instance.deleteTransaction(transaction.id!);
                                      await _refreshTransactions();
                                      if (mounted) {
                                        messenger.clearSnackBars();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Deleted "${transaction.description}"'),
                                            behavior: SnackBarBehavior.floating,
                                            action: SnackBarAction(
                                              label: 'UNDO',
                                              onPressed: () async {
                                                await TransactionRepository.instance.createTransaction(transaction);
                                                await _refreshTransactions();
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                      return true;
                                    }
                                  },
                                  child: Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: colorScheme.surfaceContainer,
                                    child: InkWell(
                                      onTap: () async {
                                        await HapticFeedback.lightImpact();
                                        openContainer();
                                      },
                                      onLongPress: () async {
                                        await HapticFeedback.mediumImpact();
                                        if (!context.mounted) return;
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title:
                                                const Text('Delete Transaction'),
                                            content: Text(
                                                'Delete "${transaction.description}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      colorScheme.error,
                                                  foregroundColor:
                                                      colorScheme.onError,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && mounted) {
                                          await TransactionRepository.instance
                                              .deleteTransaction(transaction.id!);
                                          await _refreshTransactions();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: TransactionCategory.colorFor(transaction.category).withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: TransactionCategory.colorFor(transaction.category).withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: TransactionCategory.colorFor(transaction.category).withValues(alpha: 0.1),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                TransactionCategory.iconFor(transaction.category),
                                                color: TransactionCategory.colorFor(transaction.category),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    transaction.description,
                                                    style: textTheme.bodyLarge
                                                        ?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: TransactionCategory
                                                              .colorFor(
                                                                  transaction
                                                                      .category)
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                        color: TransactionCategory
                                                                .colorFor(
                                                                    transaction
                                                                        .category)
                                                            .withValues(
                                                                alpha: 0.4),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      transaction.category,
                                                      style: textTheme.labelSmall
                                                          ?.copyWith(
                                                        color: TransactionCategory
                                                            .colorFor(transaction
                                                                .category),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${transaction.isExpense ? '-' : '+'} $currency ${transaction.amount.toStringAsFixed(0)}',
                                              style:
                                                  textTheme.titleMedium?.copyWith(
                                                color: transaction.isExpense
                                                    ? colorScheme.error
                                                    : colorScheme.tertiary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _groupedTransactions.length,
                  ),
                ),
              ),
      ] else ...[
        // ── Analytics Sub-Views (Trends / Breakdown / Budgets) ───────────────────
        if (MediaQuery.sizeOf(context).width >= 600)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_analyticsSegment == 'Breakdown')
                          FinancialCategoryDonutCard(
                            categoryExpenses: _categoryExpenses,
                            totalExpense: _totalDateExpense,
                            currency: currency,
                          ),
                        if (_analyticsSegment == 'Trends') ...[
                          FinancialTrendRegressionCard(
                            monthlyData: _monthlyData,
                            currency: currency,
                          ),
                          const SizedBox(height: 16),
                          _buildBarChartCard(colorScheme, textTheme, currency),
                        ],
                        if (_analyticsSegment == 'Budgets')
                          Consumer<SettingsProvider>(
                            builder: (context, settings, child) {
                              return _buildCategoryBudgetsCard(colorScheme, textTheme, settings);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_analyticsSegment == 'Trends')
                          _buildMonthComparisonCard(colorScheme, textTheme, currency),
                        if (_analyticsSegment == 'Budgets')
                          _buildTopMerchantsCard(colorScheme, textTheme, currency),
                        if (_analyticsSegment == 'Breakdown')
                          _buildTopMerchantsCard(colorScheme, textTheme, currency),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // ── Segment 1: Category Breakdown ────────────────────────────
          if (_analyticsSegment == 'Breakdown')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                child: FinancialCategoryDonutCard(
                  categoryExpenses: _categoryExpenses,
                  totalExpense: _totalDateExpense,
                  currency: currency,
                ),
              ),
            ),

          // ── Segment 2: Spending Trends ────────────────────────────────
          if (_analyticsSegment == 'Trends') ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FinancialTrendRegressionCard(
                  monthlyData: _monthlyData,
                  currency: currency,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildBarChartCard(colorScheme, textTheme, currency),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                child: _buildMonthComparisonCard(colorScheme, textTheme, currency),
              ),
            ),
          ],

          // ── Segment 3: Budgets & Merchants ────────────────────────────
          if (_analyticsSegment == 'Budgets') ...[
            SliverToBoxAdapter(
              child: Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildCategoryBudgetsCard(colorScheme, textTheme, settings),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                child: _buildTopMerchantsCard(colorScheme, textTheme, currency),
              ),
            ),
          ],
        ],
      ],
    ];
  }


  // Helper tab selector: Responsive single row for Ledger, Trends, Breakdown, and Budgets
  Widget _buildTabSelector(ColorScheme colorScheme) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 480;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<String>(
            value: 'Ledger',
            label: const Text('Ledger', maxLines: 1, softWrap: false),
            icon: isCompact ? null : const Icon(Icons.list_alt_outlined, size: 16),
          ),
          ButtonSegment<String>(
            value: 'Trends',
            label: const Text('Trends', maxLines: 1, softWrap: false),
            icon: isCompact ? null : const Icon(Icons.auto_graph, size: 16),
          ),
          ButtonSegment<String>(
            value: 'Breakdown',
            label: Text(isCompact ? 'Charts' : 'Breakdown', maxLines: 1, softWrap: false),
            icon: isCompact ? null : const Icon(Icons.pie_chart_outline, size: 16),
          ),
          ButtonSegment<String>(
            value: 'Budgets',
            label: const Text('Budgets', maxLines: 1, softWrap: false),
            icon: isCompact ? null : const Icon(Icons.track_changes, size: 16),
          ),
        ],
        selected: {_selectedTab},
        onSelectionChanged: (Set<String> newSelection) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTab = newSelection.first;
            if (_selectedTab != 'Ledger') {
              _analyticsSegment = _selectedTab;
            }
          });
        },
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 4),
        ),
      ),
    );
  }

  // Budgets & Analytics helper: Levenshtein distance
  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);
    
    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      v0 = List<int>.from(v1);
    }
    return v0[s2.length];
  }

  // Budgets & Analytics helper: merchant clustering
  List<Map<String, dynamic>> _calculateClusteredMerchants() {
    final Map<String, List<TransactionModel>> clusters = {};
    for (var tx in _transactions) {
      if (!tx.isExpense) continue;
      final desc = tx.description.trim();
      if (desc.isEmpty) continue;
      
      String? bestMatch;
      for (var existing in clusters.keys) {
        if (desc.toLowerCase() == existing.toLowerCase()) {
          bestMatch = existing;
          break;
        }
        final distance = _levenshtein(desc.toLowerCase(), existing.toLowerCase());
        final maxLength = desc.length > existing.length ? desc.length : existing.length;
        if (maxLength > 0 && (distance / maxLength) < 0.25) {
          bestMatch = existing;
          break;
        }
      }
      
      if (bestMatch != null) {
        clusters[bestMatch]!.add(tx);
      } else {
        clusters[desc] = [tx];
      }
    }
    
    final List<Map<String, dynamic>> result = [];
    clusters.forEach((merchant, list) {
      final total = list.fold<double>(0.0, (sum, item) => sum + item.amount);
      result.add({
        'merchant': merchant,
        'total': total,
        'count': list.length,
      });
    });
    
    result.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return result;
  }

  // Budgets & Analytics card: Category Budgets
  Widget _buildCategoryBudgetsCard(ColorScheme colorScheme, TextTheme textTheme, SettingsProvider settings) {
    final budgets = settings.categoryBudgets;
    
    // Calculate total spent per category in currently visible transactions
    final Map<String, double> spentMap = {};
    for (var tx in _transactions) {
      if (tx.isExpense) {
        spentMap[tx.category] = (spentMap[tx.category] ?? 0.0) + tx.amount;
      }
    }
    
    // We can display the predefined categories, or ones with active budgets
    final categories = TransactionCategory.allNames;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusXL),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.donut_large_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Budgets',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  settings.currency,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final budget = budgets[category] ?? 0.0;
              final spent = spentMap[category] ?? 0.0;
              final hasBudget = budget > 0;
              final progress = hasBudget ? (spent / budget).clamp(0.0, 1.0) : 0.0;
              final isOverBudget = spent > budget && hasBudget;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showSetBudgetDialog(context, settings, category, budget);
                  },
                  borderRadius: BorderRadius.circular(AppLayout.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  TransactionCategory.iconFor(category),
                                  size: 16,
                                  color: TransactionCategory.colorFor(category),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              hasBudget
                                  ? '${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}'
                                  : '${spent.toStringAsFixed(0)} (No Budget)',
                              style: textTheme.bodySmall?.copyWith(
                                color: isOverBudget
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: hasBudget ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (hasBudget) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: isOverBudget
                                  ? colorScheme.error
                                  : TransactionCategory.colorFor(category),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Budget dialog
  void _showSetBudgetDialog(
    BuildContext context,
    SettingsProvider settings,
    String category,
    double currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Budget for $category'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Monthly Limit (${settings.currency})',
            hintText: 'Enter amount or leave empty to disable',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0.0;
              settings.setCategoryBudget(category, value);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Budgets & Analytics card: Top Merchants
  Widget _buildTopMerchantsCard(ColorScheme colorScheme, TextTheme textTheme, String currency) {
    final merchants = _calculateClusteredMerchants();
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusXL),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Top Spending Outlets',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (merchants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No transaction outlets identified yet.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...merchants.take(5).map((m) {
                final double amount = m['total'];
                final int count = m['count'];
                final String merchant = m['merchant'];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchant,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$count transaction${count > 1 ? "s" : ""}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '- $currency ${amount.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

}
