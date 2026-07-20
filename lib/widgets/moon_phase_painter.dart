import 'package:flutter/material.dart';
import 'dart:math' as math;

class MoonPhaseWidget extends StatelessWidget {
  final double phase; // 0.0 (New Moon) -> 0.5 (Full Moon) -> 1.0 (New Moon)
  final double size;
  final Color? moonColor;
  final Color? shadowColor;

  const MoonPhaseWidget({
    super.key,
    required this.phase,
    this.size = 100,
    this.moonColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedMoonColor = moonColor ?? theme.colorScheme.primaryContainer.withValues(alpha: 0.9);
    final resolvedShadowColor = shadowColor ?? theme.colorScheme.surfaceContainerHighest;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: resolvedMoonColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: MoonPhasePainter(
            phase: phase.clamp(0.0, 1.0),
            moonColor: resolvedMoonColor,
            shadowColor: resolvedShadowColor,
          ),
        ),
      ),
    );
  }
}

class MoonPhasePainter extends CustomPainter {
  final double phase; // 0.0 to 1.0
  final Color moonColor;
  final Color shadowColor;

  MoonPhasePainter({
    required this.phase,
    required this.moonColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintShadow = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;

    final paintMoon = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill;

    // Draw unlit background (full circle)
    canvas.drawCircle(center, radius, paintShadow);

    if (phase == 0.0 || phase == 1.0) {
      // New Moon: completely unlit
      return;
    } else if (phase == 0.5) {
      // Full Moon: completely lit
      canvas.drawCircle(center, radius, paintMoon);
      return;
    }

    final isWaxing = phase < 0.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (isWaxing) {
      // Light is on the right side
      // Draw right half circle
      canvas.drawArc(rect, -math.pi / 2, math.pi, true, paintMoon);
      
      // Control ellipse for terminator
      final double control = (phase - 0.25) / 0.25; // -1.0 to 1.0
      if (control < 0) {
        // Draw dark semi-ellipse over right side to subtract light (Crescent)
        final ellipseWidth = radius * (-control);
        final ellipseRect = Rect.fromLTRB(center.dx - ellipseWidth, center.dy - radius, center.dx + ellipseWidth, center.dy + radius);
        canvas.drawArc(ellipseRect, -math.pi / 2, math.pi, true, paintShadow);
      } else {
        // Draw light semi-ellipse on left side to add light (Gibbous)
        final ellipseWidth = radius * control;
        final ellipseRect = Rect.fromLTRB(center.dx - ellipseWidth, center.dy - radius, center.dx + ellipseWidth, center.dy + radius);
        canvas.drawArc(ellipseRect, math.pi / 2, math.pi, true, paintMoon);
      }
    } else {
      // Waning: Light is on the left side
      // Draw left half circle
      canvas.drawArc(rect, math.pi / 2, math.pi, true, paintMoon);

      final double control = (phase - 0.75) / 0.25; // -1.0 to 1.0
      if (control < 0) {
        // Draw light semi-ellipse on right side to add light (Gibbous)
        final ellipseWidth = radius * (-control);
        final ellipseRect = Rect.fromLTRB(center.dx - ellipseWidth, center.dy - radius, center.dx + ellipseWidth, center.dy + radius);
        canvas.drawArc(ellipseRect, -math.pi / 2, math.pi, true, paintMoon);
      } else {
        // Draw dark semi-ellipse on left side to subtract light (Crescent)
        final ellipseWidth = radius * control;
        final ellipseRect = Rect.fromLTRB(center.dx - ellipseWidth, center.dy - radius, center.dx + ellipseWidth, center.dy + radius);
        canvas.drawArc(ellipseRect, math.pi / 2, math.pi, true, paintShadow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MoonPhasePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
