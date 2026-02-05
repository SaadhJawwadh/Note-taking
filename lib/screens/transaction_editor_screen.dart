import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../data/database_helper.dart';
import '../data/transaction_model.dart';
import '../widgets/calculator_dialog.dart';

class TransactionEditorScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionEditorScreen({super.key, this.transaction});

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text =
          widget.transaction!.amount.toStringAsFixed(2).replaceAll('.00', '');
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = widget.transaction!.date;
      _isExpense = widget.transaction!.isExpense;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text;
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final transaction = TransactionModel(
      id: widget.transaction?.id,
      amount: amount,
      description: description,
      date: _selectedDate,
      isExpense: _isExpense,
    );

    if (widget.transaction == null) {
      await DatabaseHelper.instance.createTransaction(transaction);
    } else {
      await DatabaseHelper.instance.updateTransaction(transaction);
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
            'Are you sure you want to delete this transaction? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await DatabaseHelper.instance.deleteTransaction(widget.transaction!.id!);
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openCalculator() async {
    final double? currentVal = double.tryParse(_amountController.text);
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalculatorDialog(initialValue: currentVal),
    );

    if (result != null) {
      setState(() {
        _amountController.text =
            result.toStringAsFixed(2).replaceAll('.00', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = Provider.of<SettingsProvider>(context);
    final currency = settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'New Transaction'
            : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: colorScheme.error,
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transaction Type Segmented Button
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_outward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Income'),
                  icon: Icon(Icons.south_west),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isExpense = newSelection.first;
                });
              },
              style: ButtonStyle(
                side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                  return BorderSide(color: colorScheme.outline);
                }),
              ),
            ),
            const SizedBox(height: 32),

            // Amount Field with Calculator
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _isExpense ? colorScheme.error : colorScheme.primary,
              ),
              decoration: InputDecoration(
                prefixText: '$currency ',
                labelText: 'Amount',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: IconButton(
                  onPressed: _openCalculator,
                  icon: const Icon(Icons.calculate_outlined),
                  tooltip: 'Open Calculator',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Groceries, Rent',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  enabled: false, // Handle tap via InkWell
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveTransaction,
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: const Text('Save Transaction'),
      ),
    );
  }
}
