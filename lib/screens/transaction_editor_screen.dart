import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../data/settings_provider.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import '../data/category_definition.dart';
import '../data/recurring_rule_model.dart';
import '../data/repositories/recurring_rule_repository.dart';
import '../widgets/calculator_dialog.dart';
import 'category_management_screen.dart';
import '../services/sms_service.dart';
import '../utils/app_route.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_layout.dart';

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
  String _category = TransactionCategory.other;
  RecurringFrequency? _repeatFrequency;

  late String _initialCategory;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text =
          widget.transaction!.amount.toStringAsFixed(2).replaceAll('.00', '');
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = widget.transaction!.date;
      _isExpense = widget.transaction!.isExpense;
      _category = widget.transaction!.category;
    }
    _initialCategory = _category;
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
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero')),
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
      category: _category,
      smsId: widget.transaction?.smsId,
    );

    if (widget.transaction == null) {
      await TransactionRepository.instance.createTransaction(transaction);

      if (_repeatFrequency != null) {
        // The transaction just saved covers this period; the rule owns the
        // next one onward.
        var rule = RecurringRule(
          id: const Uuid().v4(),
          description: description,
          amount: amount,
          category: _category,
          isExpense: _isExpense,
          frequency: _repeatFrequency!,
          nextDue: _selectedDate,
        );
        rule = rule.copyWith(nextDue: rule.advance(_selectedDate));
        await RecurringRuleRepository.instance.createRule(rule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Repeats ${_repeatFrequency!.label.toLowerCase()} — manage in Settings → Financial Manager'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      await TransactionRepository.instance.updateTransaction(transaction);

      // Training Prompt logic
      if (widget.transaction!.smsId != null &&
          widget.transaction!.isExpense != _isExpense) {
        final rule = await _showTrainingDialog(description);
        if (rule != null && rule.isNotEmpty) {
           if (!mounted) return;
           final settings = Provider.of<SettingsProvider>(context, listen: false);
           await settings.addCustomRule(rule, isExpense: _isExpense);
           // We also need to reload the static SMS service cache
           // For that, we need to import SmsService at the top.
           try {
             // Use dynamic invocation or ensure reloadSmsContacts is available.
             // We will import sms_service.dart at the top.
             await SmsService.reloadSmsContacts();
           } catch (_) {}
        }
      }

      // Category Training Prompt logic
      if (widget.transaction!.smsId != null &&
          _initialCategory != _category) {
        final rule = await _showCategoryTrainingDialog(description, _category);
        if (rule != null && rule.isNotEmpty) {
          final db = TransactionRepository.instance;
          final defs = await db.getAllCategoryDefinitions();
          CategoryDefinition? targetDef;
          for (final d in defs) {
            if (d.name == _category) {
              targetDef = d;
              break;
            }
          }
          if (targetDef != null) {
            if (!targetDef.keywords.contains(rule)) {
              final updatedKeywords = List<String>.from(targetDef.keywords)..add(rule.toLowerCase());
              await db.upsertCategoryDefinition(targetDef.copyWith(keywords: updatedKeywords));
              await TransactionCategory.reload();
            }
          }
        }
      }
    }

    setState(() => _isLoading = false);
    if (mounted) {
      final navigator = Navigator.of(context);
      await HapticFeedback.mediumImpact();
      navigator.pop(true);
    }
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
      await TransactionRepository.instance.deleteTransaction(widget.transaction!.id!);
      setState(() => _isLoading = false);
      if (mounted) {
        final navigator = Navigator.of(context);
        await HapticFeedback.mediumImpact();
        navigator.pop(true);
      }
    }
  }

  Future<String?> _showTrainingDialog(String initialKeyword) async {
    String keyword = initialKeyword.replaceAll(RegExp(r'(?:Debit|Credit|Payment at|Purchase at|Transfer to)\s*', caseSensitive: false), '').trim();

    return showDialog<String>(
      context: context,
      builder: (context) {
        String input = keyword;
        return AlertDialog(
          title: const Text('Train SMS Parser?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Would you like the app to remember this? Future SMS messages containing the keyword below will automatically be marked as exactly what you selected.'),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: keyword),
                decoration: const InputDecoration(
                  labelText: 'Matching Keyword/Phrase',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Uber, Keells, Salary',
                ),
                onChanged: (v) => input = v.trim(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('No, just this once'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, input),
              child: const Text('Train Parser'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showCategoryTrainingDialog(String initialKeyword, String category) async {
    String keyword = initialKeyword.replaceAll(RegExp(r'(?:Debit|Credit|Payment at|Purchase at|Transfer to)\s*', caseSensitive: false), '').trim();

    return showDialog<String>(
      context: context,
      builder: (context) {
        String input = keyword;
        return AlertDialog(
          title: const Text('Train Category Parser?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Would you like the app to remember this? Future SMS messages containing the keyword below will automatically be categorized as "$category".'),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: keyword),
                decoration: const InputDecoration(
                  labelText: 'Matching Keyword/Phrase',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Uber, Keells, Mc',
                ),
                onChanged: (v) => input = v.trim(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('No, just this once'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, input),
              child: const Text('Train Category'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      await HapticFeedback.lightImpact();
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openCalculator() async {
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    final double? currentVal = double.tryParse(_amountController.text);
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CalculatorDialog(initialValue: currentVal),
    );

    if (result != null) {
      setState(() {
        _amountController.text =
            result.toStringAsFixed(2).replaceAll('.00', '');
      });
    }
  }

  static const _colorSwatches = [
    Color(0xFFE53935), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
  ];

  Future<void> _showNewCategoryDialog() async {
    String name = '';
    Color selectedColor = _colorSwatches[5];

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      hintText: 'e.g., Groceries',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => name = v.trim(),
                  ),
                  const SizedBox(height: 16),
                  Text('Color', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colorSwatches.map((c) {
                      final isSelected =
                          c.toARGB32() == selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: c,
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && name.isNotEmpty) {
      final def = CategoryDefinition(
        name: name,
        colorValue: selectedColor.toARGB32(),
        keywords: [],
      );
      await TransactionRepository.instance.upsertCategoryDefinition(def);
      await TransactionCategory.reload();
      setState(() => _category = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
                HapticFeedback.selectionClick();
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
                color: _isExpense ? colorScheme.error : colorScheme.tertiary,
              ),
              decoration: InputDecoration(
                prefixText: '$currency ',
                labelText: 'Amount',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppLayout.radiusL),
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
                  borderRadius: BorderRadius.circular(AppLayout.radiusL),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Category Picker
            Row(
              children: [
                Text(
                  'Category',
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await AppRoute.push(context, const CategoryManagementScreen());
                    await TransactionCategory.reload();
                    if (!TransactionCategory.allNames.contains(_category)) {
                      _category = TransactionCategory.other;
                    }
                    setState(() {});
                  },
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...TransactionCategory.allNames.map((cat) {
                  final catColor = TransactionCategory.colorFor(cat);
                  final selected = _category == cat;
                  return FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      HapticFeedback.lightImpact();
                      setState(() => _category = cat);
                    },
                    selectedColor: catColor.withValues(alpha: 0.2),
                    checkmarkColor: catColor,
                    labelStyle: TextStyle(
                      color: selected ? catColor : colorScheme.onSurfaceVariant,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? catColor : colorScheme.outline,
                      width: selected ? 1.5 : 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                  );
                }),
                ActionChip(
                  avatar: Icon(Icons.add, size: 18, color: colorScheme.primary),
                  label:
                      Text('New', style: TextStyle(color: colorScheme.primary)),
                  onPressed: _showNewCategoryDialog,
                  side: BorderSide(color: colorScheme.primary, width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppLayout.radiusL),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radiusL),
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

            // Repeat picker (creating only — editing a materialized
            // transaction shouldn't silently spawn a rule)
            if (widget.transaction == null) ...[
              const SizedBox(height: 24),
              Text(
                'Repeat',
                style: textTheme.labelLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              SegmentedButton<RecurringFrequency?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Once')),
                  ButtonSegment(
                      value: RecurringFrequency.daily, label: Text('Daily')),
                  ButtonSegment(
                      value: RecurringFrequency.weekly, label: Text('Weekly')),
                  ButtonSegment(
                      value: RecurringFrequency.monthly,
                      label: Text('Monthly')),
                ],
                selected: {_repeatFrequency},
                onSelectionChanged: (selection) {
                  HapticFeedback.selectionClick();
                  setState(() => _repeatFrequency = selection.first);
                },
              ),
              if (_repeatFrequency != null) ...[
                const SizedBox(height: 8),
                Text(
                  'This will be added automatically every '
                  '${_repeatFrequency!.label.toLowerCase().replaceFirst('ly', '')} '
                  'starting from the date above.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transaction_editor_fab',
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
