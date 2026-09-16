import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_bottom_sheet.dart';
import '../../../../core/ui/app_card.dart';
import '../../../../core/ui/expressive_wavy_slider.dart';
import 'package:note_taking_app/features/settings/providers/settings_provider.dart';
import '../../../../data/transaction_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../providers/savings_goal_provider.dart';

/// Modal bottom sheet for creating or editing a goal-oriented savings pocket.
class SavingsGoalEditorSheet extends StatefulWidget {
  final SavingsGoal? goal;

  const SavingsGoalEditorSheet({super.key, this.goal});

  static Future<void> show(BuildContext context, {SavingsGoal? goal}) {
    HapticFeedback.lightImpact();
    return AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      title: goal == null ? 'New Savings Goal' : 'Edit Savings Goal',
      child: SavingsGoalEditorSheet(goal: goal),
    );
  }

  @override
  State<SavingsGoalEditorSheet> createState() => _SavingsGoalEditorSheetState();
}

class _SavingsGoalEditorSheetState extends State<SavingsGoalEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _initialAmountController;
  late final TextEditingController _monthlyPaceController;

  int _targetMonths = 6;
  bool _planByMonthlyPace = false;
  String _account = AccountType.savings;
  String _category = 'Savings';
  int _colorValue = 0xFF4CAF50; // default green
  int _iconCodePoint = Icons.savings_rounded.codePoint;
  bool _recordInitialInLedger = true;

  static const List<int> _presetMonths = [3, 6, 9, 12, 18, 24];

  static const List<int> _colorPalette = [
    0xFF4CAF50, // Green
    0xFF009688, // Teal
    0xFF2196F3, // Blue
    0xFF673AB7, // Deep Purple
    0xFFE91E63, // Pink
    0xFFFF9800, // Orange
    0xFF3F51B5, // Indigo
    0xFF00BCD4, // Cyan
  ];

  static final List<IconData> _goalIcons = [
    Icons.savings_rounded,
    Icons.school_rounded,
    Icons.smartphone_rounded,
    Icons.laptop_mac_rounded,
    Icons.flight_takeoff_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.fitness_center_rounded,
    Icons.redeem_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(0) : '',
    );
    _initialAmountController = TextEditingController(
      text: g != null ? g.currentAmount.toStringAsFixed(0) : '',
    );
    _monthlyPaceController = TextEditingController(
      text: g != null && g.monthlyContribution > 0
          ? g.monthlyContribution.toStringAsFixed(0)
          : '',
    );

    if (g != null) {
      _targetMonths = g.targetMonths;
      _account = g.account;
      _category = g.category;
      _colorValue = g.colorValue;
      _iconCodePoint = g.iconCodePoint;
    }

    _targetAmountController.addListener(_recalculatePacing);
    _monthlyPaceController.addListener(_recalculateFromPace);
  }

  @override
  void dispose() {
    _targetAmountController.removeListener(_recalculatePacing);
    _monthlyPaceController.removeListener(_recalculateFromPace);
    _titleController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    _monthlyPaceController.dispose();
    super.dispose();
  }

  void _recalculatePacing() {
    if (_planByMonthlyPace) {
      _recalculateFromPace();
      return;
    }
    final target = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    if (target > 0 && _targetMonths > 0) {
      final monthly = target / _targetMonths;
      _monthlyPaceController.text = monthly.toStringAsFixed(0);
    }
    if (mounted) setState(() {});
  }

  void _recalculateFromPace() {
    if (!_planByMonthlyPace) return;
    final target = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    final pace = double.tryParse(_monthlyPaceController.text.trim()) ?? 0.0;
    if (target > 0 && pace > 0) {
      final calculatedMonths = (target / pace).ceil().clamp(1, 120);
      if (calculatedMonths != _targetMonths) {
        setState(() => _targetMonths = calculatedMonths);
      }
    }
  }

  DateTime _computeTargetDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _targetMonths, now.day);
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final targetAmount = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    final initialAmount = double.tryParse(_initialAmountController.text.trim()) ?? 0.0;
    final monthlyPace = double.tryParse(_monthlyPaceController.text.trim()) ?? (targetAmount / _targetMonths);

    final provider = context.read<SavingsGoalProvider>();

    if (widget.goal == null) {
      final newGoal = SavingsGoal(
        id: const Uuid().v4(),
        title: title,
        targetAmount: targetAmount,
        currentAmount: initialAmount,
        targetMonths: _targetMonths,
        monthlyContribution: monthlyPace,
        targetDate: _computeTargetDate(),
        category: _category,
        account: _account,
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
        createdAt: DateTime.now(),
      );
      await provider.createGoal(newGoal);

      if (initialAmount > 0 && _recordInitialInLedger) {
        await provider.deposit(
          goalId: newGoal.id,
          amount: initialAmount,
          fromAccount: _account == AccountType.savings ? AccountType.daily : AccountType.savings,
          toAccount: _account,
          recordLedgerTransaction: true,
          note: 'Initial funding for $title',
        );
      }
    } else {
      final updated = widget.goal!.copyWith(
        title: title,
        targetAmount: targetAmount,
        targetMonths: _targetMonths,
        monthlyContribution: monthlyPace,
        targetDate: _computeTargetDate(),
        category: _category,
        account: _account,
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
      );
      await provider.updateGoal(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = context.watch<SettingsProvider>().currencySymbol;

    final target = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    final initial = double.tryParse(_initialAmountController.text.trim()) ?? 0.0;
    final netNeeded = (target - initial).clamp(0.0, double.infinity);
    final calculatedMonthly = _targetMonths > 0 ? (netNeeded / _targetMonths) : 0.0;
    final completionDate = _computeTargetDate();
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: viewInsets.bottom + AppLayout.spaceXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal Title
            TextFormField(
              controller: _titleController,
              autofocus: widget.goal == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g. College Semester, Phone, Vacation',
                prefixIcon: Icon(SavingsGoalModel.getIcon(_iconCodePoint), color: Color(_colorValue)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a goal title' : null,
            ),
            const SizedBox(height: AppLayout.spaceM),

            // Target Amount & Initial Amount
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Target Amount',
                      prefixText: '$currency ',
                      hintText: '50000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    validator: (v) {
                      final val = double.tryParse(v?.trim() ?? '');
                      if (val == null || val <= 0) return 'Enter target';
                      return null;
                    },
                  ),
                ),
                if (widget.goal == null) ...[
                  const SizedBox(width: AppLayout.spaceM),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _initialAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Already Saved',
                        prefixText: '$currency ',
                        hintText: '0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ],
            ),
            if (widget.goal == null && initial > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _recordInitialInLedger,
                onChanged: (v) => setState(() => _recordInitialInLedger = v ?? true),
                title: const Text('Record initial deposit in ledger', style: TextStyle(fontSize: 13)),
                subtitle: Text('Transfers $currency ${initial.toStringAsFixed(2)} to savings', style: const TextStyle(fontSize: 11)),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),

            const SizedBox(height: AppLayout.spaceL),

            // Target Duration & Auto-Pacing Planner
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Duration & Pacing', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: Icon(_planByMonthlyPace ? Icons.timeline_rounded : Icons.calculate_outlined, size: 16),
                        label: Text(_planByMonthlyPace ? 'By Months' : 'By Monthly Pace', style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _planByMonthlyPace = !_planByMonthlyPace;
                            if (!_planByMonthlyPace) _recalculatePacing();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.spaceS),

                  if (!_planByMonthlyPace) ...[
                    // Preset Month Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetMonths.map((m) {
                        final selected = _targetMonths == m;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text('$m mos'),
                          selected: selected,
                          onSelected: (_) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _targetMonths = m;
                              _recalculatePacing();
                            });
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppLayout.spaceM),
                    // Stepper / Expressive Wavy Slider
                    Row(
                       children: [
                        Text('$_targetMonths months', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: AppLayout.spaceS),
                        Expanded(
                          child: ExpressiveWavySlider(
                            value: _targetMonths.toDouble().clamp(1.0, 36.0),
                            min: 1,
                            max: 36,
                            divisions: 35,
                            onChanged: (v) {
                              setState(() {
                                _targetMonths = v.round();
                                _recalculatePacing();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Monthly Pace Input
                    TextFormField(
                      controller: _monthlyPaceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Monthly Contribution',
                        prefixText: '$currency ',
                        hintText: 'e.g. 5000',
                        helperText: 'Auto-calculates required months to reach target',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: AppLayout.spaceS),
                    Text('Will take approximately $_targetMonths months', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],

                  const Divider(height: 24),

                  // Smart Breakdown Summary
                  Container(
                    padding: const EdgeInsets.all(AppLayout.spaceM),
                    decoration: BoxDecoration(
                      color: Color(_colorValue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                      border: Border.all(color: Color(_colorValue).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(_colorValue).withValues(alpha: 0.20),
                          ),
                          child: Icon(
                            Icons.event_repeat_rounded,
                            color: Color(_colorValue),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppLayout.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$currency ${calculatedMonthly.toStringAsFixed(0)} / month',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(_colorValue),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estimated completion by ${completionDate.month}/${completionDate.year} ($_targetMonths months)',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceL),

            // Account Choice (Savings Vault vs Daily Operating)
            Text('Target Account', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppLayout.spaceS),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AccountType.savings,
                  icon: Icon(Icons.account_balance_wallet_rounded, size: 16),
                  label: Text('Savings Vault'),
                ),
                ButtonSegment(
                  value: AccountType.daily,
                  icon: Icon(Icons.credit_card_rounded, size: 16),
                  label: Text('Daily Operating'),
                ),
              ],
              selected: {_account},
              onSelectionChanged: (set) {
                HapticFeedback.lightImpact();
                setState(() => _account = set.first);
              },
            ),
            const SizedBox(height: AppLayout.spaceL),

            // Category Selection
            Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppLayout.spaceS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Savings',
                'Education',
                'Electronics',
                'Travel',
                'Vehicle',
                'Emergency',
                'Shopping',
                'Home',
              ].map((cat) {
                final selected = _category == cat;
                return FilterChip(
                  showCheckmark: false,
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => _category = cat);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppLayout.spaceL),

            // Color & Icon Customization
            Text('Color & Icon', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppLayout.spaceS),
            Row(
              children: [
                // Color Palette
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _colorPalette.map((c) {
                        final selected = _colorValue == c;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _colorValue = c);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: selected ? Border.all(color: colorScheme.onSurface, width: 2.5) : null,
                            ),
                            child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spaceM),
            // Icon Picker Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _goalIcons.map((ic) {
                  final selected = _iconCodePoint == ic.codePoint;
                  return IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: selected ? Color(_colorValue).withValues(alpha: 0.25) : null,
                      foregroundColor: selected ? Color(_colorValue) : colorScheme.onSurfaceVariant,
                    ),
                    icon: Icon(ic),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _iconCodePoint = ic.codePoint);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppLayout.spaceXL),

            // Save Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.goal == null ? 'Create Savings Goal' : 'Save Changes'),
              onPressed: _saveGoal,
            ),
            const SizedBox(height: AppLayout.spaceM),
          ],
        ),
      ),
    );
  }
}
