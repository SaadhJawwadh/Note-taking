import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/period_log_model.dart';
import '../data/database_helper.dart';
import '../services/period_prediction_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'settings_screen.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  DateTime _focusedDay = DateTime.now();
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
    _logs = await DatabaseHelper.instance.readAllPeriodLogs();
    _predictedNextPeriod = await PeriodPredictionService.estimateNextPeriod();
    _predictedOvulation = await PeriodPredictionService.estimateOvulationDate();
    _daysUntilNext = await PeriodPredictionService.daysUntilNextPeriod();
    if (mounted) setState(() => _isLoading = false);
  }

  // Helper to check if a specific day is part of any logged period
  PeriodLog? _getLogForDay(DateTime day) {
    for (final log in _logs) {
      final startDate =
          DateTime(log.startDate.year, log.startDate.month, log.startDate.day);
      final endDate = log.endDate != null
          ? DateTime(log.endDate!.year, log.endDate!.month, log.endDate!.day)
          : DateTime
              .now(); // If ongoing, consider today as end for highlighting purposes

      final targetDay = DateTime(day.year, day.month, day.day);

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
    final d = DateTime(day.year, day.month, day.day);
    final p = DateTime(_predictedNextPeriod!.year, _predictedNextPeriod!.month,
        _predictedNextPeriod!.day);
    // Highlight a likely 5-day window for the next period
    return d.isAtSameMomentAs(p) ||
        (d.isAfter(p) && d.isBefore(p.add(const Duration(days: 5))));
  }

  bool _isOvulationDay(DateTime day) {
    if (_predictedOvulation == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    final p = DateTime(_predictedOvulation!.year, _predictedOvulation!.month,
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
    final ongoing = _getCurrentOngoingPeriod();
    if (ongoing != null) {
      // Stop the period
      final updated = ongoing.copyWith(endDate: DateTime.now());
      await DatabaseHelper.instance.updatePeriodLog(updated);
    } else {
      // Start new period
      final newLog = PeriodLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startDate: DateTime.now(),
        intensity: 'Medium',
      );
      await DatabaseHelper.instance.createPeriodLog(newLog);
    }
    await _loadData(); // Re-fetch logs and predictions
  }

  Future<void> _updateIntensity(PeriodLog log, String newIntensity) async {
    final updated = log.copyWith(intensity: newIntensity);
    await DatabaseHelper.instance.updatePeriodLog(updated);
    await _loadData();
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

            // ── Today's Log Card (Start/Stop/Intensity) ───────────────────
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
                        color: isPeriodActive
                            ? periodColor
                            : colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                isPeriodActive
                                    ? 'End your period'
                                    : 'Start your period',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: isPeriodActive
                                      ? onPeriodColor
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _togglePeriodStatus,
                                style: FilledButton.styleFrom(
                                  backgroundColor: isPeriodActive
                                      ? onPeriodColor
                                      : colorScheme.primary,
                                  foregroundColor: isPeriodActive
                                      ? periodColor
                                      : colorScheme.onPrimary,
                                  minimumSize: const Size(double.infinity, 56),
                                ),
                                icon: Icon(isPeriodActive
                                    ? Icons.stop
                                    : Icons.play_arrow),
                                label: Text(
                                  isPeriodActive ? 'Stop' : 'Start',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              if (isPeriodActive) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Flow Intensity',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: onPeriodColor),
                                ),
                                const SizedBox(height: 12),
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
                                  selected: {ongoingPeriod.intensity},
                                  onSelectionChanged:
                                      (Set<String> newSelection) {
                                    _updateIntensity(
                                        ongoingPeriod, newSelection.first);
                                  },
                                  style: SegmentedButton.styleFrom(
                                    backgroundColor: periodColor,
                                    foregroundColor: onPeriodColor,
                                    selectedForegroundColor: periodColor,
                                    selectedBackgroundColor: onPeriodColor,
                                  ),
                                ),
                              ]
                            ],
                          ),
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
