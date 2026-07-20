import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/period_log_model.dart';
import '../data/repositories/period_repository.dart';
import '../services/period_prediction_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'settings_screen.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import 'package:flutter/services.dart';
import '../utils/app_route.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/moon_phase_painter.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen>
    with WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  List<PeriodLog> _logs = [];
  bool _isLoading = true;

  DateTime? _predictedNextPeriod;
  DateTime? _predictedOvulation;
  int? _daysUntilNext;

  // Privacy and cycle state variables
  int _avgCycleLength = 28;
  int? _currentCycleDay;
  String _currentPhase = 'No Data';
  String _phaseDescription = 'Log a period to start prediction.';

  // UI state
  bool _symptomsExpanded = false;

  static const List<String> _predefinedSymptoms = [
    'Cramps',
    'Bloating',
    'Headache',
    'Fatigue',
    'Acne',
    'Mood Swings',
    'Nausea',
    'Backache',
  ];

  static const List<IconData> _intensityIcons = [
    Icons.water_drop_outlined,   // Spotting
    Icons.water_drop,            // Light
    Icons.water,                 // Medium
    Icons.flood,                 // Heavy
  ];
  static const List<String> _intensityLabels = [
    'Spotting', 'Light', 'Medium', 'Heavy',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    _logs = await PeriodRepository.instance.readAllPeriodLogs();
    _predictedNextPeriod = await PeriodPredictionService.estimateNextPeriod();
    _predictedOvulation = await PeriodPredictionService.estimateOvulationDate();
    _daysUntilNext = await PeriodPredictionService.daysUntilNextPeriod();
    await _calculateCyclePhase();
    if (!kIsWeb) {
      await NotificationService.schedulePeriodNotifications();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _calculateCyclePhase() async {
    _avgCycleLength = await PeriodPredictionService.calculateAverageCycleLength();
    if (_logs.isEmpty) {
      _currentCycleDay = null;
      _currentPhase = "No Logs";
      _phaseDescription = "Log a period start date to see cycle phases.";
      return;
    }
    final latestLog = _logs.first;
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final startUtc = DateTime.utc(latestLog.startDate.year, latestLog.startDate.month, latestLog.startDate.day);
    
    final diff = todayUtc.difference(startUtc).inDays;
    
    // Cycle day is 1-indexed
    final cycleDay = (diff % _avgCycleLength) + 1;
    _currentCycleDay = cycleDay;
    
    if (cycleDay >= 1 && cycleDay <= 5) {
      _currentPhase = "Menstrual Phase";
      _phaseDescription = "Flow begins. Progesterone and estrogen levels drop. Rest and nurture yourself.";
    } else if (cycleDay >= 6 && cycleDay <= 11) {
      _currentPhase = "Follicular Phase";
      _phaseDescription = "Estrogen rises, boosting energy, mood, and focus. Great time for planning.";
    } else if (cycleDay >= 12 && cycleDay <= 16) {
      _currentPhase = "Ovulatory Phase";
      _phaseDescription = "Estrogen peaks, triggering ovulation. High energy and social openness.";
    } else {
      _currentPhase = "Luteal Phase";
      _phaseDescription = "Progesterone peaks, winding down energy. Prioritize self-care.";
    }
  }

  /// Phase colors come from the theme's semantic tokens so they stay
  /// consistent with the rest of the design system.
  Color _resolvePhaseColor(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    switch (_currentPhase) {
      case 'Menstrual Phase':
        return semantic?.phaseMenstrual ?? Colors.red.shade300;
      case 'Follicular Phase':
        return semantic?.phaseFollicular ?? Colors.blue.shade300;
      case 'Ovulatory Phase':
        return semantic?.phaseOvulatory ?? Colors.orange.shade300;
      case 'Luteal Phase':
        return semantic?.phaseLuteal ?? Colors.purple.shade300;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  // Helper to check if a specific day is part of any logged period
  PeriodLog? _getLogForDay(DateTime day) {
    final targetDay = DateTime.utc(day.year, day.month, day.day);
    for (final log in _logs) {
      final startDate =
          DateTime.utc(log.startDate.year, log.startDate.month, log.startDate.day);
      final endDate = log.endDate != null
          ? DateTime.utc(log.endDate!.year, log.endDate!.month, log.endDate!.day)
          : DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      if (targetDay.isAtSameMomentAs(startDate) ||
          targetDay.isAtSameMomentAs(endDate) ||
          (targetDay.isAfter(startDate) &&
              targetDay.isBefore(endDate.add(const Duration(days: 1))))) {
        return log;
      }
    }
    return null;
  }

  bool _isPredictedDay(DateTime day) {
    if (_predictedNextPeriod == null) return false;
    final d = DateTime.utc(day.year, day.month, day.day);
    final p = DateTime.utc(_predictedNextPeriod!.year, _predictedNextPeriod!.month,
        _predictedNextPeriod!.day);
    // Highlight a likely 5-day window for the next period
    return d.isAtSameMomentAs(p) ||
        (d.isAfter(p) && d.isBefore(p.add(const Duration(days: 5))));
  }

  bool _isOvulationDay(DateTime day) {
    if (_predictedOvulation == null) return false;
    final d = DateTime.utc(day.year, day.month, day.day);
    final p = DateTime.utc(_predictedOvulation!.year, _predictedOvulation!.month,
        _predictedOvulation!.day);
    // highlight 3 day block around ovulation
    final start = p.subtract(const Duration(days: 1));
    final end = p.add(const Duration(days: 1));
    return d.isAtSameMomentAs(start) ||
        d.isAtSameMomentAs(end) ||
        d.isAtSameMomentAs(p);
  }

  PeriodLog? _getCurrentOngoingPeriod() {
    return _logs.where((l) => l.endDate == null).firstOrNull;
  }

  Future<void> _togglePeriodStatus() async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    
    final ongoing = _getCurrentOngoingPeriod();
    if (ongoing != null) {
      // Stop the period
      final updated = ongoing.copyWith(endDate: todayUtc);
      if (_checkOverlap(ongoing.startDate, todayUtc, ongoing.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Overlap detected when stopping period.')),
        );
        return;
      }
      await PeriodRepository.instance.updatePeriodLog(updated);
    } else {
      // Start new period
      if (_checkOverlap(todayUtc, null)) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overlap Detected'),
            content: const Text('Starting a period today would overlap with an existing logged period. Please edit the logs instead.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
      final newLog = PeriodLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startDate: todayUtc,
        intensity: 'Medium',
      );
      await PeriodRepository.instance.createPeriodLog(newLog);
    }
    await HapticFeedback.mediumImpact();
    await _loadData(); // Re-fetch logs and predictions
  }

  Future<void> _deleteLog(PeriodLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this period log?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );

    if (confirm == true) {
      await PeriodRepository.instance.deletePeriodLog(log.id);
      await HapticFeedback.mediumImpact();
      await _loadData();
    }
  }

  Future<void> _updateIntensity(PeriodLog log, String newIntensity) async {
    await HapticFeedback.lightImpact();
    final updated = log.copyWith(intensity: newIntensity);
    await PeriodRepository.instance.updatePeriodLog(updated);
    await _loadData();
  }

  bool _checkOverlap(DateTime start, DateTime? end, [String? excludeId]) {
    final s1 = DateTime.utc(start.year, start.month, start.day);
    final e1 = end != null ? DateTime.utc(end.year, end.month, end.day) : DateTime.utc(2999, 12, 31);
    
    for (final log in _logs) {
      if (excludeId != null && log.id == excludeId) continue;
      final s2 = DateTime.utc(log.startDate.year, log.startDate.month, log.startDate.day);
      final e2 = log.endDate != null ? DateTime.utc(log.endDate!.year, log.endDate!.month, log.endDate!.day) : DateTime.utc(2999, 12, 31);
      
      if (s1.isBefore(e2.add(const Duration(days: 1))) && e1.isAfter(s2.subtract(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _showLogEditor(PeriodLog? log, [DateTime? defaultStartDate]) async {
    final theme = Theme.of(context);
    
    DateTime tempStart = log?.startDate ?? defaultStartDate ?? _selectedDay ?? DateTime.now();
    tempStart = DateTime.utc(tempStart.year, tempStart.month, tempStart.day);
    
    DateTime? tempEnd = log?.endDate;
    if (tempEnd != null) {
      tempEnd = DateTime.utc(tempEnd.year, tempEnd.month, tempEnd.day);
    }
    
    String tempIntensity = log?.intensity ?? 'Medium';
    List<String> tempSymptoms = List.from(log?.symptoms ?? []);
    bool isOngoing = tempEnd == null;
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 8, 24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          log != null ? 'Edit Period Log' : 'Add Period Log',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat.yMMMMd().format(tempStart)),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () async {
                        await HapticFeedback.lightImpact();
                        if (!context.mounted) return;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempStart = DateTime.utc(picked.year, picked.month, picked.day);
                            if (tempEnd != null && tempStart.isAfter(tempEnd!)) {
                              tempEnd = null;
                              isOngoing = true;
                            }
                          });
                        }
                      },
                    ),
                    const Divider(),
                    
                    SwitchListTile(
                      title: const Text('Ongoing Period'),
                      subtitle: const Text('Still active/no end date yet'),
                      value: isOngoing,
                      onChanged: (val) async {
                        await HapticFeedback.selectionClick();
                        setModalState(() {
                          isOngoing = val;
                          if (val) {
                            tempEnd = null;
                          } else {
                            tempEnd = tempStart.add(const Duration(days: 4));
                          }
                        });
                      },
                    ),
                    if (!isOngoing) ...[
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('End Date'),
                        subtitle: Text(tempEnd != null ? DateFormat.yMMMMd().format(tempEnd!) : 'Select end date'),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () async {
                          await HapticFeedback.lightImpact();
                          if (!context.mounted) return;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEnd ?? tempStart.add(const Duration(days: 4)),
                            firstDate: tempStart,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              tempEnd = DateTime.utc(picked.year, picked.month, picked.day);
                            });
                          }
                        },
                      ),
                    ],
                    const Divider(),
                    
                    const SizedBox(height: 16),
                    Text('Flow Intensity', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Spotting', label: Text('Spotting')),
                        ButtonSegment(value: 'Light', label: Text('Light')),
                        ButtonSegment(value: 'Medium', label: Text('Medium')),
                        ButtonSegment(value: 'Heavy', label: Text('Heavy')),
                      ],
                      selected: {tempIntensity},
                      onSelectionChanged: (Set<String> selection) {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          tempIntensity = selection.first;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    Text('Symptoms', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedSymptoms.map((symptom) {
                        final isSelected = tempSymptoms.contains(symptom);
                        return FilterChip(
                          label: Text(symptom),
                          selected: isSelected,
                          onSelected: (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              if (selected) {
                                tempSymptoms.add(symptom);
                              } else {
                                tempSymptoms.remove(symptom);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (!isOngoing && tempEnd != null && tempStart.isAfter(tempEnd!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Start date cannot be after end date')),
                          );
                          return;
                        }
                        
                        if (_checkOverlap(tempStart, tempEnd, log?.id)) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Overlap Detected'),
                              content: const Text('The selected dates overlap with an existing logged period. Please adjust the dates.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        
                        Navigator.pop(context, true);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: const Text('Save Log'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    
    if (result == true) {
      if (log != null) {
        final updated = log.copyWith(
          startDate: tempStart,
          endDate: isOngoing ? null : tempEnd,
          intensity: tempIntensity,
          symptoms: tempSymptoms,
        );
        await PeriodRepository.instance.updatePeriodLog(updated);
      } else {
        final newLog = PeriodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startDate: tempStart,
          endDate: isOngoing ? null : tempEnd,
          intensity: tempIntensity,
          symptoms: tempSymptoms,
        );
        await PeriodRepository.instance.createPeriodLog(newLog);
      }
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SkeletonCard(height: 64),
              SizedBox(height: 12),
              SkeletonCard(height: 180),
              SizedBox(height: 12),
              SkeletonCard(height: 120),
              SizedBox(height: 12),
              SkeletonCard(height: 320),
            ],
          ),
        ),
      );
    }

    final ongoingPeriod = _getCurrentOngoingPeriod();
    final isPeriodActive = ongoingPeriod != null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color periodColor = colorScheme.errorContainer;
    Color onPeriodColor = colorScheme.onErrorContainer;
    if (theme.brightness == Brightness.dark) {
      // Make the red explicitly lighter per user request
      periodColor = Colors.red.shade200;
      // Fix accessibility: dark text contrasts much better on a lightened background
      onPeriodColor = Colors.black87;
    }

    return Scaffold(
      body: AnimationLimiter(
        child: CustomScrollView(
          slivers: [
            // ── Custom Sliver AppBar ──────────────────────────────────────
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
              toolbarHeight: 84,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              title: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                  boxShadow: AppLayout.softShadow(context),
                ),
                child: Row(
                  children: [
                    Text(
                      'Tracker',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        AppRoute.push(context, const SettingsScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Cycle Phase Moon Card (Redesigned Dashboard Header) ────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: CyclePhaseMoonWidget(
                        phase: _currentPhase,
                        description: _phaseDescription,
                        cycleDay: _currentCycleDay,
                        avgCycleLength: _avgCycleLength,
                        phaseColor: _resolvePhaseColor(context),
                        predictionStatus: isPeriodActive
                            ? 'Period Ongoing'
                            : (_daysUntilNext == null
                                ? 'Not enough data'
                                : (_daysUntilNext! > 0
                                    ? 'Period in $_daysUntilNext days'
                                    : 'Period overdue by ${_daysUntilNext!.abs()} days')),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Logging Dashboard Card (Start/Stop/Intensity/Symptoms Log) ──
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 1,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Builder(builder: (context) {
                        final selectedLog =
                            _selectedDay != null ? _getLogForDay(_selectedDay!) : null;
                        final now = DateTime.now();
                        final today = DateTime.utc(now.year, now.month, now.day);
                        final isSelectedToday = _selectedDay != null &&
                            isSameDay(_selectedDay, today);

                        return Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          color: isPeriodActive && isSelectedToday
                              ? periodColor
                              : (selectedLog != null
                                  ? periodColor.withValues(alpha: 0.35)
                                  : colorScheme.surfaceContainerHighest),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppLayout.radiusXL)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Header row: title + action buttons ────────────
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedLog != null
                                                ? 'Period Log'
                                                : (isSelectedToday
                                                    ? 'Start your period'
                                                    : 'No log for this day'),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: selectedLog != null
                                                  ? onPeriodColor
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                          if (selectedLog != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              selectedLog.endDate != null
                                                  ? '${DateFormat.MMMd().format(selectedLog.startDate)} – ${DateFormat.MMMd().format(selectedLog.endDate!)}'
                                                  : '${DateFormat.MMMd().format(selectedLog.startDate)} · Ongoing',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: onPeriodColor.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (selectedLog != null) ...[
                                      IconButton(
                                        onPressed: () => _showLogEditor(selectedLog),
                                        icon: Icon(Icons.edit_outlined, size: 18, color: onPeriodColor.withValues(alpha: 0.7)),
                                        tooltip: 'Edit Dates',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteLog(selectedLog),
                                        icon: Icon(Icons.delete_outline, size: 18,
                                            color: Colors.red.shade700),
                                        tooltip: 'Delete Log',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ],
                                ),

                                if (selectedLog == null && isSelectedToday) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _togglePeriodStatus,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      minimumSize: const Size(double.infinity, 52),
                                    ),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start Period'),
                                  ),
                                ],
                                if (selectedLog == null && !isSelectedToday) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () => _showLogEditor(null, _selectedDay),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      minimumSize: const Size(double.infinity, 52),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Period Log'),
                                  ),
                                ],

                                if (selectedLog != null) ...[
                                  // ── Stop Button ────────────────────────────────
                                  if (selectedLog.endDate == null && isSelectedToday) ...[
                                    const SizedBox(height: 10),
                                    FilledButton.icon(
                                      onPressed: _togglePeriodStatus,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: onPeriodColor,
                                        foregroundColor: periodColor,
                                        minimumSize: const Size(double.infinity, 52),
                                      ),
                                      icon: const Icon(Icons.stop_rounded),
                                      label: const Text('Stop Period'),
                                    ),
                                  ],

                                  const SizedBox(height: 14),
                                  Divider(height: 1, color: onPeriodColor.withValues(alpha: 0.15)),
                                  const SizedBox(height: 12),

                                  // ── Flow Intensity (icon-only row, no wrapping) ──
                                  Text(
                                    'Flow Intensity',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: onPeriodColor.withValues(alpha: 0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(_intensityLabels.length, (i) {
                                      final label = _intensityLabels[i];
                                      final icon = _intensityIcons[i];
                                      final isChosen = selectedLog.intensity == label;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => _updateIntensity(selectedLog, label),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isChosen
                                                  ? onPeriodColor
                                                  : onPeriodColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  icon,
                                                  size: 20,
                                                  color: isChosen ? periodColor : onPeriodColor.withValues(alpha: 0.7),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  label,
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: isChosen ? periodColor : onPeriodColor.withValues(alpha: 0.7),
                                                    fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 14),
                                  Divider(height: 1, color: onPeriodColor.withValues(alpha: 0.15)),

                                  // ── Collapsible Symptoms Section ───────────────
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _symptomsExpanded = !_symptomsExpanded);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.mood_outlined,
                                            size: 18,
                                            color: onPeriodColor.withValues(alpha: 0.8),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Symptoms',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: onPeriodColor.withValues(alpha: 0.8),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          if (selectedLog.symptoms.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: onPeriodColor,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${selectedLog.symptoms.length}',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: periodColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Icon(
                                            _symptomsExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: onPeriodColor.withValues(alpha: 0.6),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.topCenter,
                                    child: _symptomsExpanded
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: _predefinedSymptoms.map((symptom) {
                                                  final isSelected = selectedLog.symptoms.contains(symptom);
                                                  // Same palette as intensity tiles: onPeriodColor-based.
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      await HapticFeedback.selectionClick();
                                                      final updatedSymptoms = List<String>.from(selectedLog.symptoms);
                                                      if (isSelected) {
                                                        updatedSymptoms.remove(symptom);
                                                      } else {
                                                        updatedSymptoms.add(symptom);
                                                      }
                                                      final updated = selectedLog.copyWith(symptoms: updatedSymptoms);
                                                      await PeriodRepository.instance.updatePeriodLog(updated);
                                                      await _loadData();
                                                    },
                                                    child: AnimatedContainer(
                                                      duration: const Duration(milliseconds: 180),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? onPeriodColor
                                                            : onPeriodColor.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                                      ),
                                                      child: Text(
                                                        symptom,
                                                        style: theme.textTheme.labelMedium?.copyWith(
                                                          color: isSelected
                                                              ? periodColor
                                                              : onPeriodColor.withValues(alpha: 0.85),
                                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            // ── Calendar Card (History & Predictions) ───────────────────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 2,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppLayout.radiusXL),
                            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month'
                          },
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: theme.textTheme.titleMedium!,
                          ),
                          calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                            final log = _getLogForDay(day);
                            if (log != null) {
                              return _buildMarker(
                                  day, periodColor, onPeriodColor,
                                  isFilled: true);
                            } else if (_isPredictedDay(day)) {
                              return _buildMarker(
                                  day, periodColor, onPeriodColor,
                                  isFilled: false);
                            } else if (_isOvulationDay(day)) {
                              return _buildMarker(
                                  day,
                                  colorScheme.tertiaryContainer,
                                  colorScheme.onTertiaryContainer,
                                  isFilled: false);
                            }
                            return null;
                          }, selectedBuilder: (context, day, focusedDay) {
                            final log = _getLogForDay(day);
                            if (log != null) {
                              return _buildMarker(
                                  day, periodColor, onPeriodColor,
                                  isFilled: true, isSelected: true);
                            }
                            return _buildMarker(
                                day, colorScheme.primary, colorScheme.onPrimary,
                                isFilled: true, isSelected: true);
                          }, todayBuilder: (context, day, focusedDay) {
                            final log = _getLogForDay(day);
                            if (log != null) {
                              return _buildMarker(
                                  day, periodColor, onPeriodColor,
                                  isFilled: true, isToday: true);
                            }
                            return _buildMarker(
                                day,
                                colorScheme.surfaceContainerHighest,
                                colorScheme.onSurface,
                                isFilled: true,
                                isToday: true);
                          }),
                        ),
                      ),
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

  Widget _buildMarker(DateTime day, Color color, Color textColor,
      {required bool isFilled, bool isSelected = false, bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFilled ? color : color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: textColor, width: 2)
            : (isToday ? Border.all(color: color, width: 2) : null),
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isFilled ? textColor : color.withValues(alpha: 0.8),
          fontWeight:
              isSelected || isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class CyclePhaseMoonWidget extends StatelessWidget {
  final String phase;
  final String description;
  final int? cycleDay;
  final int avgCycleLength;
  final Color phaseColor;
  final String? predictionStatus;

  const CyclePhaseMoonWidget({
    super.key,
    required this.phase,
    required this.description,
    required this.cycleDay,
    required this.avgCycleLength,
    required this.phaseColor,
    this.predictionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate phase value (0.0 to 1.0)
    // 0.0/1.0 is new moon (menstrual start)
    // 0.5 is full moon (ovulation, usually around day 14 of 28, i.e., avgCycleLength/2)
    double phaseValue = 0.0;
    if (cycleDay != null && avgCycleLength > 0) {
      // Map cycleDay (1 to avgCycleLength) to phaseValue (0.0 to 1.0)
      phaseValue = (cycleDay! - 1) / avgCycleLength;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusXL),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Moon Visualizer Left
            MoonPhaseWidget(
              phase: phaseValue,
              size: 80,
              moonColor: phaseColor,
            ),
            const SizedBox(width: 20),
            // Phase Text Right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phase,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: phaseColor,
                    ),
                  ),
                  if (cycleDay != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Day $cycleDay of $avgCycleLength',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (predictionStatus != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      predictionStatus!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: phaseColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
