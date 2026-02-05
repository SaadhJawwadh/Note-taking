import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import '../data/database_helper.dart';
import '../data/transaction_model.dart';
import 'transaction_editor_screen.dart';
import 'settings_screen.dart';

class FinancialManagerScreen extends StatefulWidget {
  const FinancialManagerScreen({super.key});

  @override
  State<FinancialManagerScreen> createState() => _FinancialManagerScreenState();
}

class _FinancialManagerScreenState extends State<FinancialManagerScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  Future<void> _refreshTransactions() async {
    setState(() => _isLoading = true);
    // In a real app, we should filter by date in SQL.
    // For now, fetching all and filtering in memory as per current DB helper capabilities,
    // or we can add a date filter method to DB helper.
    // Given the task size, I'll fetch all and filter here for simplicity unless performance is an issue.
    final allTransactions = await DatabaseHelper.instance.readAllTransactions();

    _transactions = allTransactions.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month &&
          t.date.day == _selectedDate.day;
    }).toList();

    setState(() => _isLoading = false);
  }

  double get _dailyExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _dailyIncome {
    return _transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _refreshTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                    icon: const Icon(Icons.calendar_today_outlined),
                    tooltip: 'Select Date',
                    onPressed: () => _selectDate(context),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.MMMMEEEEd().format(_selectedDate),
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
                              amount: _dailyExpense,
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
                              amount: _dailyIncome,
                              color: colorScheme.primary, // Or green/tertiary
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
                      'No transactions today',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${transaction.isExpense ? '-' : '+'} \$${transaction.amount.toStringAsFixed(2)}',
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
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
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
          '\$${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
