import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/settings_provider.dart';
import '../data/database_helper.dart';
import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import '../services/sms_service.dart';
import 'transaction_editor_screen.dart';
import 'settings_screen.dart';

class FinancialManagerScreen extends StatefulWidget {
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
  bool _isLoading = true;
  String? _selectedCategory;
  bool _smsSyncRunning = false;
  List<String> _activeCategories = [];

  List<Map<String, dynamic>> _monthlyData = [];
  Map<String, double> _allTimeSummary = {
    'totalIncome': 0.0,
    'totalExpense': 0.0,
  };
  bool _isDashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
    SmsService.startForegroundListener((t) async {
      if (!mounted) return;
      final exists = await DatabaseHelper.instance.smsExists(t.smsId!);
      if (!exists) {
        await DatabaseHelper.instance.createTransaction(t);
        if (mounted) await _refreshTransactions();
      }
    });
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      _isLoading = true;
      _isDashboardLoading = true;
    });
    final allTransactions = await DatabaseHelper.instance.readAllTransactions();

    final dateFiltered = allTransactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final start = DateTime(_selectedRange.start.year,
          _selectedRange.start.month, _selectedRange.start.day);
      final end = DateTime(_selectedRange.end.year, _selectedRange.end.month,
          _selectedRange.end.day);

      return tDate.isAfter(start.subtract(const Duration(days: 1))) &&
          tDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    // Compute active categories before applying category filter
    final activeCategories =
        dateFiltered.map((t) => t.category).toSet().toList()..sort();

    // Apply category filter
    _transactions = _selectedCategory == null
        ? dateFiltered
        : dateFiltered
            .where((t) => t.category == _selectedCategory)
            .toList();

    _monthlyData =
        await DatabaseHelper.instance.getMonthlyTransactionSummary(6);
    _allTimeSummary = await DatabaseHelper.instance.getAllTimeSummary();

    setState(() {
      _activeCategories = activeCategories;
      _isLoading = false;
      _isDashboardLoading = false;
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

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
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
    if (picked != null && picked != _selectedRange) {
      setState(() => _selectedRange = picked);
      await _refreshTransactions();
    }
  }

  // ── Dashboard widgets ────────────────────────────────────────────────────

  Future<void> _syncSms() async {
    final granted = await SmsService.hasPermission();
    if (!granted) {
      // Explain WHY before the system permission dialog appears
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS Access'),
          content: const Text(
            'This app needs permission to read your incoming SMS messages '
            'so it can automatically detect and import bank transactions.\n\n'
            'Only messages from recognised bank senders are processed. '
            'No messages are sent, stored off-device, or shared.',
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
      final ok = await SmsService.requestPermissions();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'SMS permission is required to sync transactions')),
          );
        }
        return;
      }
    }
    setState(() => _smsSyncRunning = true);
    final count = await SmsService.syncInbox();
    await _refreshTransactions();
    if (!mounted) return;
    setState(() => _smsSyncRunning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Imported $count new transaction${count == 1 ? '' : 's'} from SMS'),
      ),
    );
  }

  Widget _buildNetBalanceCard(
      ColorScheme cs, TextTheme tt, String currency) {
    if (_isDashboardLoading) {
      return const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator()));
    }
    final totalIncome = _allTimeSummary['totalIncome'] ?? 0.0;
    final totalExpense = _allTimeSummary['totalExpense'] ?? 0.0;
    final net = totalIncome - totalExpense;
    final isPositive = net >= 0;

    return Card(
      elevation: 0,
      color: isPositive ? cs.primaryContainer : cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All-Time Net Balance',
                  style: tt.labelMedium?.copyWith(
                    color: isPositive
                        ? cs.onPrimaryContainer
                        : cs.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : '-'} $currency ${net.abs().toStringAsFixed(2)}',
                  style: tt.headlineMedium?.copyWith(
                    color: isPositive
                        ? cs.onPrimaryContainer
                        : cs.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 40,
              color: isPositive ? cs.onPrimaryContainer : cs.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildBarChartCard(
      ColorScheme cs, TextTheme tt, String currency) {
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
            color: cs.primary,
            width: 8,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: data['totalExpense'] as double,
            color: cs.error,
            width: 8,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
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
                _legendDot(cs.primary),
                const SizedBox(width: 4),
                Text('Income',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                _legendDot(cs.error),
                const SizedBox(width: 4),
                Text('Expense',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
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
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '$type\n$currency ${rod.toY.toStringAsFixed(2)}',
                          (tt.labelSmall ?? const TextStyle()).copyWith(
                            color: rodIndex == 0 ? cs.primary : cs.error,
                            fontWeight: FontWeight.bold,
                          ),
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
    // For expenses: increase is bad (error); for income/net: increase is good (primary)
    final isIncrease = pctChange >= 0;
    final Color changeColor;
    if (negativeIsGood) {
      changeColor = isIncrease ? cs.error : cs.primary;
    } else {
      changeColor = isIncrease ? cs.primary : cs.error;
    }

    return Column(
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
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
                Container(
                    width: 1, height: 48, color: cs.outlineVariant),
                Expanded(
                  child: _comparisonTile(cs, tt, 'Expense', thisExpense,
                      pctChange(thisExpense, lastExpense), currency, true),
                ),
                Container(
                    width: 1, height: 48, color: cs.outlineVariant),
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
      body: CustomScrollView(
        slivers: [
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
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    'Finances',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: _smsSyncRunning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_outlined),
                    tooltip: 'Sync SMS',
                    onPressed: _smsSyncRunning ? null : _syncSms,
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    tooltip: 'Select Date Range',
                    onPressed: () => _selectDateRange(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Net balance hero card ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child:
                  _buildNetBalanceCard(colorScheme, textTheme, currency),
            ),
          ),

          // ── 6-month bar chart ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child:
                  _buildBarChartCard(colorScheme, textTheme, currency),
            ),
          ),

          // ── Month-over-month comparison ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildMonthComparisonCard(
                  colorScheme, textTheme, currency),
            ),
          ),

          // ── Date-range filtered summary card ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _selectedRange.duration.inDays == 0
                            ? DateFormat.MMMMEEEEd()
                                .format(_selectedRange.start)
                            : '${DateFormat.MMMd().format(_selectedRange.start)} - ${DateFormat.MMMd().format(_selectedRange.end)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: 'Expenses',
                              amount: _totalExpense,
                              currency: currency,
                              color: colorScheme.error,
                              icon: Icons.arrow_outward,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: colorScheme.outlineVariant,
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'Income',
                              amount: _totalIncome,
                              currency: currency,
                              color: colorScheme.primary,
                              icon: Icons.south_west,
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

          // ── Category filter chips ────────────────────────────────────
          if (_activeCategories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) {
                          setState(() => _selectedCategory = null);
                          _refreshTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._activeCategories.map((cat) {
                        final catColor =
                            TransactionCategory.colorFor(cat);
                        final selected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedCategory =
                                  selected ? null : cat);
                              _refreshTransactions();
                            },
                            selectedColor:
                                catColor.withValues(alpha: 0.2),
                            checkmarkColor: catColor,
                            labelStyle: TextStyle(
                              color: selected
                                  ? catColor
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? catColor
                                  : colorScheme.outline,
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
                      _selectedCategory != null
                          ? 'No $_selectedCategory transactions\nin this period'
                          : 'No transactions in this period',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedCategory = null);
                          _refreshTransactions();
                        },
                        child: const Text('Clear filter'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = _transactions[index];
                    return OpenContainer<bool>(
                      transitionType: ContainerTransitionType.fade,
                      openBuilder: (context, _) =>
                          TransactionEditorScreen(transaction: transaction),
                      closedElevation: 0,
                      closedColor: Colors.transparent,
                      closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onClosed: (updated) {
                        if (updated == true) _refreshTransactions();
                      },
                      closedBuilder: (context, openContainer) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: colorScheme.surfaceContainer,
                          child: InkWell(
                            onTap: openContainer,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: transaction.isExpense
                                          ? colorScheme.errorContainer
                                          : colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      transaction.isExpense
                                          ? Icons.remove
                                          : Icons.add,
                                      color: transaction.isExpense
                                          ? colorScheme.onErrorContainer
                                          : colorScheme.onPrimaryContainer,
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
                                          style:
                                              textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: TransactionCategory
                                                .colorFor(transaction.category)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: TransactionCategory
                                                  .colorFor(
                                                      transaction.category)
                                                  .withValues(alpha: 0.4),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            transaction.category,
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                              color: TransactionCategory
                                                  .colorFor(
                                                      transaction.category),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${transaction.isExpense ? '-' : '+'} $currency ${transaction.amount.toStringAsFixed(2)}',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: transaction.isExpense
                                          ? colorScheme.error
                                          : colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _transactions.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: OpenContainer<bool>(
        transitionType: ContainerTransitionType.fade,
        openBuilder: (context, _) => const TransactionEditorScreen(),
        closedElevation: 6.0,
        closedShape: const StadiumBorder(),
        closedColor: colorScheme.primary,
        onClosed: (updated) {
          if (updated == true) _refreshTransactions();
        },
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            onPressed: openContainer,
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$currency ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
