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

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  DateTime _focusedDay = DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  List<PeriodLog> _logs = [];
  bool _isLoading = true;

  DateTime? _predictedNextPeriod;
  DateTime? _predictedOvulation;
  int? _daysUntilNext;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _logs = await PeriodRepository.instance.readAllPeriodLogs();
    _predictedNextPeriod = await PeriodPredictionService.estimateNextPeriod();
    _predictedOvulation = await PeriodPredictionService.estimateOvulationDate();
    _daysUntilNext = await PeriodPredictionService.daysUntilNextPeriod();
    if (!kIsWeb) {
      await NotificationService.schedulePeriodNotifications();
    }
    if (mounted) setState(() => _isLoading = false);
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
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await PeriodRepository.instance.deletePeriodLog(log.id);
      await _loadData();
    }
  }

  Future<void> _updateIntensity(PeriodLog log, String newIntensity) async {
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
    bool isOngoing = tempEnd == null;
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                    onChanged: (val) {
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
                      setModalState(() {
                        tempIntensity = selection.first;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  FilledButton(
                    onPressed: () {
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
        );
        await PeriodRepository.instance.updatePeriodLog(updated);
      } else {
        final newLog = PeriodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startDate: tempStart,
          endDate: isOngoing ? null : tempEnd,
          intensity: tempIntensity,
        );
        await PeriodRepository.instance.createPeriodLog(newLog);
      }
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Prediction Status Card ────────────────────────────────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.water_drop,
                                    color: colorScheme.onSecondaryContainer),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      isPeriodActive
                                          ? 'Period Ongoing'
                                          : (_daysUntilNext == null
                                              ? 'Not enough data'
                                              : (_daysUntilNext! > 0
                                                  ? 'Period in $_daysUntilNext days'
                                                  : 'Period overdue by ${_daysUntilNext!.abs()} days')),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_predictedNextPeriod != null &&
                                        !isPeriodActive)
                                      Text(
                                        'Predicted: ${DateFormat.MMMd().format(_predictedNextPeriod!)}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      44), // balance for icon on left for true center
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Calendar Card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 1,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHigh,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
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

            // ── Selected Day Log Card (Start/Stop/Intensity/Delete) ────────
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 2,
                duration: const Duration(milliseconds: 220),
                child: SlideAnimation(
                  verticalOffset: 24.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Builder(builder: (context) {
                        final selectedLog =
                            _selectedDay != null ? _getLogForDay(_selectedDay!) : null;
                        final now = DateTime.now();
                        final today = DateTime.utc(now.year, now.month, now.day);
                        final isSelectedToday = _selectedDay != null &&
                            isSameDay(_selectedDay, today);

                        return Card(
                          elevation: 0,
                          color: isPeriodActive && isSelectedToday
                              ? periodColor
                              : (selectedLog != null
                                  ? periodColor.withValues(alpha: 0.5)
                                  : colorScheme.surfaceContainerHighest),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  selectedLog != null
                                      ? 'Logged Period'
                                      : (isSelectedToday
                                          ? 'Start your period'
                                          : 'No log for this day'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: selectedLog != null
                                        ? onPeriodColor
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (selectedLog == null && isSelectedToday) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _togglePeriodStatus,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      minimumSize: const Size(double.infinity, 56),
                                    ),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text(
                                      'Start Period',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                                if (selectedLog == null && !isSelectedToday) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => _showLogEditor(null, _selectedDay),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      minimumSize: const Size(double.infinity, 56),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text(
                                      'Add Period Log',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                                if (selectedLog != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Start: ${DateFormat.yMMMMd().format(selectedLog.startDate)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(color: onPeriodColor),
                                  ),
                                  Text(
                                    selectedLog.endDate != null
                                        ? 'End: ${DateFormat.yMMMMd().format(selectedLog.endDate!)}'
                                        : 'Status: Ongoing',
                                    style: theme.textTheme.bodyLarge?.copyWith(color: onPeriodColor),
                                  ),
                                  if (selectedLog.endDate == null && isSelectedToday) ...[
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: _togglePeriodStatus,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: onPeriodColor,
                                        foregroundColor: periodColor,
                                        minimumSize: const Size(double.infinity, 56),
                                      ),
                                      icon: const Icon(Icons.stop),
                                      label: const Text(
                                        'Stop Period',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Text(
                                    'Flow Intensity',
                                    style: theme.textTheme.titleMedium?.copyWith(color: onPeriodColor),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                          value: 'Spotting',
                                          label: Text('Spotting',
                                              style: TextStyle(fontSize: 12))),
                                      ButtonSegment(
                                          value: 'Light',
                                          label: Text('Light',
                                              style: TextStyle(fontSize: 12))),
                                      ButtonSegment(
                                          value: 'Medium',
                                          label: Text('Medium',
                                              style: TextStyle(fontSize: 12))),
                                      ButtonSegment(
                                          value: 'Heavy',
                                          label: Text('Heavy',
                                              style: TextStyle(fontSize: 12))),
                                    ],
                                    selected: {selectedLog.intensity},
                                    onSelectionChanged:
                                        (Set<String> newSelection) {
                                      _updateIntensity(
                                          selectedLog, newSelection.first);
                                    },
                                    style: SegmentedButton.styleFrom(
                                      backgroundColor: periodColor,
                                      foregroundColor: onPeriodColor,
                                      selectedForegroundColor: periodColor,
                                      selectedBackgroundColor: onPeriodColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _showLogEditor(selectedLog),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: onPeriodColor,
                                          side: BorderSide(color: onPeriodColor),
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Edit Dates'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _deleteLog(selectedLog),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade900,
                                          side: BorderSide(color: Colors.red.shade900),
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Delete Log'),
                                      ),
                                    ],
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
