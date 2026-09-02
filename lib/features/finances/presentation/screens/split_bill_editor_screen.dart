import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_card.dart';
import '../../../../core/ui/app_dialog.dart';
import '../../../../core/ui/app_morphing_fab.dart';
import '../../../../data/category_constants.dart';
import '../../../../data/settings_provider.dart';
import '../../../../data/transaction_category.dart';
import '../../../../widgets/calculator_dialog.dart';
import '../../../../widgets/frosted_glass_sliver_app_bar.dart';
import '../../data/models/split_bill_model.dart';
import '../../providers/split_bill_provider.dart';
import '../widgets/receipt_scanner_sheet.dart';

class SplitBillEditorScreen extends StatefulWidget {
  final SplitBillModel? existingBill;
  final int? prelinkedTransactionId;
  final String? initialTitle;
  final double? initialAmount;
  final DateTime? initialDate;

  const SplitBillEditorScreen({
    super.key,
    this.existingBill,
    this.prelinkedTransactionId,
    this.initialTitle,
    this.initialAmount,
    this.initialDate,
  });

  @override
  State<SplitBillEditorScreen> createState() => _SplitBillEditorScreenState();
}

class _SplitBillEditorScreenState extends State<SplitBillEditorScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _newParticipantController = TextEditingController();
  final _payerFriendController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isPayerUser = true;
  bool _includeUserShare = true;
  SplitMode _splitMode = SplitMode.equal;
  String _selectedCategory = CategoryConstants.food;
  String? _receiptImagePath;
  bool _isFabExpanded = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _participantsData = [];
  final Map<String, TextEditingController> _exactAmountControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingBill != null) {
      final b = widget.existingBill!;
      _titleController.text = b.title;
      _amountController.text = b.totalAmount.toStringAsFixed(2).replaceAll('.00', '');
      _selectedDate = b.date;
      _isPayerUser = b.isPayerUser;
      _splitMode = b.splitMode;
      _selectedCategory = b.groupTag ?? CategoryConstants.food;
      _notesController.text = b.notes ?? '';
      _receiptImagePath = b.receiptImagePath;

      if (!_isPayerUser) {
        _payerFriendController.text = b.payerName;
      }

      bool foundUser = false;
      for (final p in b.participants) {
        if (p.contactName.trim().toLowerCase() == 'you') {
          foundUser = true;
        } else {
          _participantsData.add({
            'id': p.id,
            'name': p.contactName,
            'amount': p.shareAmount,
            'hasPaid': p.hasPaid,
          });
          _exactAmountControllers[p.contactName] = TextEditingController(
            text: p.shareAmount.toStringAsFixed(2).replaceAll('.00', ''),
          );
        }
      }
      _includeUserShare = foundUser;
    } else {
      if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2).replaceAll('.00', '');
      }
      if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _newParticipantController.dispose();
    _payerFriendController.dispose();
    _notesController.dispose();
    for (final c in _exactAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  int get _totalSplitCount {
    final othersCount = _participantsData.length;
    return _includeUserShare ? othersCount + 1 : othersCount;
  }

  double get _equalShareAmount {
    final count = _totalSplitCount;
    if (count <= 0 || _totalAmount <= 0) return 0.0;
    return _totalAmount / count;
  }

  double get _allocatedExactSum {
    double sum = 0.0;
    for (final p in _participantsData) {
      final name = p['name'] as String;
      final ctrl = _exactAmountControllers[name];
      if (ctrl != null) {
        sum += double.tryParse(ctrl.text.trim()) ?? 0.0;
      }
    }
    return sum;
  }

  double get _remainingToAllocate => _totalAmount - _allocatedExactSum;

  void _addParticipant(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (clean.toLowerCase() == 'you') return;

    final exists = _participantsData.any((p) => (p['name'] as String).toLowerCase() == clean.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$clean is already added.')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _participantsData.add({
        'id': const Uuid().v4(),
        'name': clean,
        'amount': 0.0,
        'hasPaid': false,
      });
      _exactAmountControllers[clean] = TextEditingController(
        text: _equalShareAmount.toStringAsFixed(2).replaceAll('.00', ''),
      );
      _newParticipantController.clear();
    });
  }

  void _removeParticipant(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      final removed = _participantsData.removeAt(index);
      final name = removed['name'] as String;
      _exactAmountControllers[name]?.dispose();
      _exactAmountControllers.remove(name);
    });
  }

  void _ensureFriendPayerInParticipants(String friendName) {
    final clean = friendName.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'you') return;
    final pIndex = _participantsData.indexWhere((p) => (p['name'] as String).toLowerCase() == clean.toLowerCase());
    if (pIndex == -1) {
      _participantsData.add({
        'id': const Uuid().v4(),
        'name': clean,
        'amount': 0.0,
        'hasPaid': true,
      });
      _exactAmountControllers[clean] = TextEditingController(
        text: _equalShareAmount.toStringAsFixed(2).replaceAll('.00', ''),
      );
    } else {
      _participantsData[pIndex]['hasPaid'] = true;
    }
  }

  Future<void> _scanReceipt() async {
    final result = await ReceiptScannerSheet.show(context);
    if (result != null) {
      setState(() {
        if (result['title'] != null && _titleController.text.isEmpty) {
          _titleController.text = result['title'] as String;
        }
        if (result['total'] != null) {
          _amountController.text = (result['total'] as double).toStringAsFixed(2).replaceAll('.00', '');
        }
        if (result['imagePath'] != null) {
          _receiptImagePath = result['imagePath'] as String;
        }
      });
    }
  }

  Future<void> _openCalculator() async {
    final currentVal = double.tryParse(_amountController.text) ?? 0.0;
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CalculatorDialog(initialValue: currentVal),
    );
    if (result != null) {
      setState(() {
        _amountController.text = result.toStringAsFixed(2).replaceAll('.00', '');
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      if (_isFabExpanded) setState(() => _isFabExpanded = false);
    } else if (notification.direction == ScrollDirection.forward) {
      if (!_isFabExpanded) setState(() => _isFabExpanded = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final splitProvider = Provider.of<SplitBillProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final currency = settings.currency;

    return Scaffold(
      floatingActionButton: AppMorphingFab(
        isExpanded: _isFabExpanded,
        icon: _isSaving ? Icons.hourglass_empty_rounded : Icons.check_rounded,
        label: _isSaving ? 'Saving...' : (widget.existingBill != null ? 'Update Bill' : 'Save Split Bill'),
        onPressed: _isSaving ? () {} : () => _saveBill(),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          slivers: [
            FrostedGlassSliverAppBar(
              titleText: widget.existingBill != null ? 'Edit Split Bill' : 'New Split Bill',
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Scan Physical Receipt',
                  onPressed: _scanReceipt,
                ),
                if (widget.existingBill != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Delete Bill',
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Bill Details Card
                  AppCard(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Bill / Event Title',
                            hintText: 'e.g. Dinner at Botanik, Uber Ride, Starlink',
                            prefixIcon: Icon(Icons.receipt_long_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppLayout.spaceM),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Total Bill Amount (${settings.currency})',
                                  prefixIcon: const Icon(Icons.attach_money_rounded),
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppLayout.spaceS),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.calculate_rounded),
                              tooltip: 'Calculator',
                              onPressed: _openCalculator,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.spaceM),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectDate,
                                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                                label: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.spaceM),
                        // Financial Category Selector
                        Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppLayout.spaceS),
                        Wrap(
                          spacing: AppLayout.spaceS,
                          runSpacing: AppLayout.spaceXS,
                          children: [
                            ...TransactionCategory.allNames.map((cat) {
                              final catColor = TransactionCategory.colorFor(cat);
                              final isSelected = _selectedCategory == cat;
                              return FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedCategory = cat);
                                },
                                selectedColor: catColor.withValues(alpha: 0.2),
                                checkmarkColor: catColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? catColor : colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected ? catColor : colorScheme.outline.withValues(alpha: 0.5),
                                  width: isSelected ? 1.5 : 0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppLayout.spaceM),

                  // Who Paid & Split Mode Card
                  AppCard(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Who Paid for this Bill?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppLayout.spaceS),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('I Paid for All'),
                              icon: Icon(Icons.person_rounded, size: 18),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Friend Paid'),
                              icon: Icon(Icons.group_rounded, size: 18),
                            ),
                          ],
                          selected: {_isPayerUser},
                          onSelectionChanged: (set) {
                            HapticFeedback.lightImpact();
                            setState(() => _isPayerUser = set.first);
                          },
                        ),
                        if (!_isPayerUser) ...[
                          const SizedBox(height: AppLayout.spaceM),
                          TextField(
                            controller: _payerFriendController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Friend Who Paid',
                              hintText: 'e.g. Alex, Sarah',
                              prefixIcon: Icon(Icons.account_circle_rounded),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setState(() {
                                  _ensureFriendPayerInParticipants(val.trim());
                                });
                              }
                            },
                          ),
                          // Quick-select chips from participants & recent contacts
                          Builder(builder: (context) {
                            final suggestions = <String>{};
                            for (final p in _participantsData) {
                              final name = p['name'] as String;
                              if (name.isNotEmpty) suggestions.add(name);
                            }
                            final splitProv = Provider.of<SplitBillProvider>(context, listen: false);
                            for (final c in splitProv.recentContacts) {
                              if (c.name.isNotEmpty) suggestions.add(c.name);
                            }
                            if (suggestions.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: AppLayout.spaceS),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Select Payer:',
                                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: AppLayout.spaceXS),
                                  Wrap(
                                    spacing: AppLayout.spaceXS,
                                    runSpacing: AppLayout.spaceXS,
                                    children: suggestions.map((name) {
                                      final isPayer = _payerFriendController.text.trim().toLowerCase() == name.toLowerCase();
                                      return ChoiceChip(
                                        label: Text(name),
                                        selected: isPayer,
                                        onSelected: (sel) {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _payerFriendController.text = sel ? name : '';
                                            if (sel) {
                                              _ensureFriendPayerInParticipants(name);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: AppLayout.spaceM),
                        SwitchListTile(
                          value: _includeUserShare,
                          onChanged: (val) => setState(() => _includeUserShare = val),
                          title: const Text('Include My Personal Share'),
                          subtitle: Text(
                            _includeUserShare
                                ? 'Your share is calculated and subtracted from what others owe'
                                : 'You paid 100% purely on behalf of others',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        const Divider(height: 24),
                        Text('Splitting Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppLayout.spaceS),
                        SegmentedButton<SplitMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<SplitMode>(
                              value: SplitMode.equal,
                              label: Text('Equal Split'),
                              icon: Icon(Icons.safety_divider_rounded, size: 18),
                            ),
                            ButtonSegment<SplitMode>(
                              value: SplitMode.exact,
                              label: Text('Custom Exact'),
                              icon: Icon(Icons.tune_rounded, size: 18),
                            ),
                          ],
                          selected: {_splitMode},
                          onSelectionChanged: (set) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _splitMode = set.first;
                              if (_splitMode == SplitMode.exact) {
                                final eq = _equalShareAmount;
                                for (final p in _participantsData) {
                                  final name = p['name'] as String;
                                  if (_exactAmountControllers[name]?.text.isEmpty ?? true) {
                                    _exactAmountControllers[name]?.text = eq.toStringAsFixed(2).replaceAll('.00', '');
                                  }
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppLayout.spaceM),

                  // Participants List Card
                  AppCard(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Participants ($_totalSplitCount)',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_splitMode == SplitMode.equal && _totalSplitCount > 0 && _totalAmount > 0)
                              Text(
                                'Rs. ${_equalShareAmount.toStringAsFixed(2)} / person',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.spaceS),

                        // Recent Friends Quick Add Chips
                        if (splitProvider.recentContacts.isNotEmpty) ...[
                          Text(
                            'Quick Add Recent Friends:',
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppLayout.spaceXS),
                          Wrap(
                            spacing: AppLayout.spaceXS,
                            runSpacing: AppLayout.spaceXS,
                            children: splitProvider.recentContacts.map((c) {
                              final isAdded = _participantsData.any((p) => (p['name'] as String).toLowerCase() == c.name.toLowerCase());
                              if (isAdded) return const SizedBox.shrink();
                              return ActionChip(
                                avatar: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Color(c.colorValue),
                                  child: Text(
                                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                                label: Text(c.name),
                                onPressed: () => _addParticipant(c.name),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppLayout.spaceM),
                        ],

                        // Add Person Field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newParticipantController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Enter friend name...',
                                  prefixIcon: Icon(Icons.person_add_rounded),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: _addParticipant,
                              ),
                            ),
                            const SizedBox(width: AppLayout.spaceS),
                            IconButton.filled(
                              icon: const Icon(Icons.add_rounded),
                              tooltip: 'Add Person',
                              onPressed: () => _addParticipant(_newParticipantController.text),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppLayout.spaceM),

                        // User Share Tile
                        if (_includeUserShare) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text('You', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                            ),
                            title: const Text('You (Your Share)'),
                            subtitle: Text(_isPayerUser ? 'Payer • Already paid' : 'Owed to friend'),
                            trailing: Text(
                              _splitMode == SplitMode.equal
                                  ? 'Rs. ${_equalShareAmount.toStringAsFixed(2)}'
                                  : 'Rs. ${_remainingToAllocate.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(),
                        ],

                        // Participant Rows
                        if (_participantsData.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceL),
                            child: Center(
                              child: Text(
                                'Add at least one friend to split this bill.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _participantsData.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final p = _participantsData[index];
                              final name = p['name'] as String;
                              final ctrl = _exactAmountControllers[name];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.secondaryContainer,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: (!_isPayerUser && _payerFriendController.text.trim().toLowerCase() == name.toLowerCase())
                                    ? const Text('Payer • Settled', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500))
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_splitMode == SplitMode.equal)
                                      Text(
                                        '$currency ${_equalShareAmount.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                      )
                                    else
                                      SizedBox(
                                        width: 130,
                                        child: TextField(
                                          controller: ctrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            prefixText: '$currency ',
                                            prefixStyle: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            filled: true,
                                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                                            ),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    const SizedBox(width: AppLayout.spaceS),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      tooltip: 'Remove',
                                      onPressed: () => _removeParticipant(index),
                                    ),
                                  ],
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppLayout.spaceXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBill() async {
    final title = _titleController.text.trim();
    final total = _totalAmount;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bill title.')),
      );
      return;
    }

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount.')),
      );
      return;
    }

    if (_participantsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one friend to split with.')),
      );
      return;
    }

    if (!_isPayerUser && _payerFriendController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the name of the friend who paid.')),
      );
      return;
    }

    final splitProvider = Provider.of<SplitBillProvider>(context, listen: false);
    setState(() => _isSaving = true);
    await HapticFeedback.mediumImpact();

    try {
      final billId = widget.existingBill?.id ?? const Uuid().v4();
      final participantsList = <SplitParticipantModel>[];

      if (!_isPayerUser && _payerFriendController.text.trim().isNotEmpty) {
        _ensureFriendPayerInParticipants(_payerFriendController.text.trim());
      }

      if (_splitMode == SplitMode.equal) {
        final share = _equalShareAmount;
        if (_includeUserShare) {
          participantsList.add(
            SplitParticipantModel(
              id: const Uuid().v4(),
              billId: billId,
              contactName: 'You',
              shareAmount: share,
              hasPaid: _isPayerUser, // If user paid, user share is already paid
              paidAt: _isPayerUser ? DateTime.now() : null,
            ),
          );
        }

        for (final p in _participantsData) {
          final isPayerFriend = !_isPayerUser &&
              (p['name'] as String).trim().toLowerCase() == _payerFriendController.text.trim().toLowerCase();
          final hasPaid = isPayerFriend ? true : (p['hasPaid'] as bool? ?? false);

          participantsList.add(
            SplitParticipantModel(
              id: p['id'] as String? ?? const Uuid().v4(),
              billId: billId,
              contactName: p['name'] as String,
              shareAmount: share,
              hasPaid: hasPaid,
              paidAt: hasPaid ? (p['paidAt'] as DateTime? ?? DateTime.now()) : null,
            ),
          );
        }
      } else {
        // Custom Exact Mode
        for (final p in _participantsData) {
          final name = p['name'] as String;
          final ctrl = _exactAmountControllers[name];
          final exactShare = double.tryParse(ctrl?.text.trim() ?? '') ?? 0.0;
          final isPayerFriend = !_isPayerUser &&
              name.trim().toLowerCase() == _payerFriendController.text.trim().toLowerCase();
          final hasPaid = isPayerFriend ? true : (p['hasPaid'] as bool? ?? false);

          participantsList.add(
            SplitParticipantModel(
              id: p['id'] as String? ?? const Uuid().v4(),
              billId: billId,
              contactName: name,
              shareAmount: exactShare,
              hasPaid: hasPaid,
              paidAt: hasPaid ? (p['paidAt'] as DateTime? ?? DateTime.now()) : null,
            ),
          );
        }

        if (_includeUserShare) {
          final userShare = _remainingToAllocate;
          participantsList.add(
            SplitParticipantModel(
              id: const Uuid().v4(),
              billId: billId,
              contactName: 'You',
              shareAmount: userShare > 0 ? userShare : 0.0,
              hasPaid: _isPayerUser,
              paidAt: _isPayerUser ? DateTime.now() : null,
            ),
          );
        }
      }

      final payer = _isPayerUser ? 'You' : _payerFriendController.text.trim();
      final newBill = SplitBillModel(
        id: billId,
        transactionId: widget.existingBill?.transactionId ?? widget.prelinkedTransactionId,
        title: title,
        totalAmount: total,
        payerName: payer,
        isPayerUser: _isPayerUser,
        splitMode: _splitMode,
        groupTag: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        receiptImagePath: _receiptImagePath,
        participants: participantsList,
      );

      if (widget.existingBill != null) {
        await splitProvider.updateBill(newBill);
      } else {
        await splitProvider.createBill(newBill);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingBill != null ? 'Split bill updated.' : 'Split bill created.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving split bill: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final bill = widget.existingBill!;
    final hasLinkedTx = bill.transactionId != null;
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Split Bill?',
      message: hasLinkedTx
          ? 'Are you sure you want to delete "${bill.title}"? The associated ledger expense will also be removed.'
          : 'Are you sure you want to delete "${bill.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      final splitProvider = Provider.of<SplitBillProvider>(context, listen: false);
      await splitProvider.deleteBill(bill.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasLinkedTx
                ? 'Split bill and linked expense deleted.'
                : 'Split bill deleted.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                splitProvider.restoreBill(bill.id);
              },
            ),
          ),
        );
      }
    }
  }
}
