import 'package:flutter/material.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_card.dart';
import '../../../../widgets/moon_phase_painter.dart';

/// Standardized Material 3 Tonal Hero Card rendering moon phase visualizer,
/// active cycle day metrics, and physiological guidance.
class CyclePhaseHeroCard extends StatelessWidget {
  final String phase;
  final String description;
  final int? cycleDay;
  final int avgCycleLength;
  final Color phaseColor;
  final String? predictionStatus;

  const CyclePhaseHeroCard({
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
    final isDark = theme.brightness == Brightness.dark;

    // Calculate lunar phase progression (0.0 to 1.0)
    // 0.0/1.0 = New Moon (Menstrual start)
    // 0.5 = Full Moon (Ovulation)
    double phaseValue = 0.0;
    if (cycleDay != null && avgCycleLength > 0) {
      phaseValue = ((cycleDay! - 1) / avgCycleLength).clamp(0.0, 1.0);
    }

    return AppCard.tonal(
      color: phaseColor.withValues(alpha: isDark ? 0.20 : 0.45),
      borderColor: phaseColor.withValues(alpha: isDark ? 0.35 : 0.45),
      borderRadius: AppLayout.radiusXL,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            MoonPhaseWidget(
              phase: phaseValue,
              size: 80,
              moonColor: phaseColor,
            ),
            const SizedBox(width: 20),
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
