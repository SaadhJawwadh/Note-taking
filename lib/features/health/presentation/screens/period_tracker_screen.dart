import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../utils/app_route.dart';
import '../../../../widgets/skeleton_card.dart';
import 'package:note_taking_app/features/settings/presentation/screens/settings_screen.dart';
import '../../providers/period_tracker_provider.dart';
import '../widgets/cycle_phase_hero_card.dart';
import '../widgets/cycle_insights_card.dart';
import '../widgets/period_log_dashboard_card.dart';
import '../widgets/period_calendar_card.dart';
import '../widgets/period_log_editor_sheet.dart';

class PeriodTrackerScreen extends StatefulWidget {
  static final ValueNotifier<DateTime?> openLogEditorNotifier = ValueNotifier<DateTime?>(null);

  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> with WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    PeriodTrackerScreen.openLogEditorNotifier.addListener(_handleLogEditorNotifier);
  }

  void _handleLogEditorNotifier() {
    final date = PeriodTrackerScreen.openLogEditorNotifier.value;
    if (date != null && mounted) {
      PeriodTrackerScreen.openLogEditorNotifier.value = null; // consume
      final provider = context.read<PeriodTrackerProvider>();
      PeriodLogEditorSheet.show(
        context: context,
        defaultStartDate: date,
        provider: provider,
      );
    }
  }

  @override
  void dispose() {
    PeriodTrackerScreen.openLogEditorNotifier.removeListener(_handleLogEditorNotifier);
    _scrollController.dispose();
    super.dispose();
  }

  Color _resolvePhaseColor(BuildContext context, String phase) {
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    switch (phase) {
      case 'Menstrual Phase':
        return semantic?.phaseMenstrual ?? const Color(0xFFD32F2F);
      case 'Follicular Phase':
        return semantic?.phaseFollicular ?? const Color(0xFF1976D2);
      case 'Ovulatory Phase':
        return semantic?.phaseOvulatory ?? const Color(0xFFF57C00);
      case 'Luteal Phase':
        return semantic?.phaseLuteal ?? const Color(0xFF7B1FA2);
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PeriodTrackerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
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

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final phaseColor = _resolvePhaseColor(context, provider.currentPhase);

        final daysUntilNext = provider.daysUntilNext;
        final predictionStatus = provider.isPeriodActive
            ? 'Period Ongoing'
            : (daysUntilNext == null
                ? 'Not enough data'
                : (daysUntilNext > 0
                    ? 'Period in $daysUntilNext days'
                    : 'Period overdue by ${daysUntilNext.abs()} days'));

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimationLimiter(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Seamless Borderless Top Bar ────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  snap: false,
                  primary: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: MediaQuery.of(context).padding.top + 68.0,
                  titleSpacing: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 6,
                          left: 16,
                          right: 16,
                          bottom: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow.withValues(alpha: isDark ? 0.82 : 0.88),
                        ),
                        child: SizedBox(
                          height: 56,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Period Tracker',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      provider.currentCycleDay != null
                                          ? 'Day ${provider.currentCycleDay} • ${provider.currentPhase}'
                                          : provider.currentPhase,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.tertiary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.today_outlined),
                                tooltip: 'Today',
                                onPressed: () async {
                                  await HapticFeedback.selectionClick();
                                  setState(() {
                                    _focusedDay = DateTime.now();
                                    _selectedDay = DateTime.now();
                                  });
                                  if (_scrollController.hasClients) {
                                    await _scrollController.animateTo(
                                      0,
                                      duration: AppLayout.animDefault,
                                      curve: AppLayout.curveExpressive,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_outlined),
                                tooltip: 'Settings',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  AppRoute.push(context, const SettingsScreen());
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Hero Moon Phase Card ──────────────────────────────────
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 220),
                    child: SlideAnimation(
                      verticalOffset: 24.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: CyclePhaseHeroCard(
                            phase: provider.currentPhase,
                            description: provider.phaseDescription,
                            cycleDay: provider.currentCycleDay,
                            avgCycleLength: provider.avgCycleLength,
                            phaseColor: phaseColor,
                            predictionStatus: predictionStatus,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Cycle Statistical Insights Card ───────────────────────
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 1,
                    duration: const Duration(milliseconds: 220),
                    child: SlideAnimation(
                      verticalOffset: 24.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: CycleInsightsCard(
                            stats: provider.cycleStats,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Selected-Day Logging Dashboard Card ───────────────────
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 2,
                    duration: const Duration(milliseconds: 220),
                    child: SlideAnimation(
                      verticalOffset: 24.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: PeriodLogDashboardCard(
                            selectedDay: _selectedDay ?? _focusedDay,
                            provider: provider,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Period & Ovulation Calendar Card ──────────────────────
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 3,
                    duration: const Duration(milliseconds: 220),
                    child: SlideAnimation(
                      verticalOffset: 24.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          child: PeriodCalendarCard(
                            focusedDay: _focusedDay,
                            selectedDay: _selectedDay,
                            provider: provider,
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                            },
                            onPageChanged: (focused) {
                              setState(() {
                                _focusedDay = focused;
                              });
                            },
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
      },
    );
  }
}
