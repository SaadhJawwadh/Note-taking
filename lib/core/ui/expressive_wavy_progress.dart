import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Material 3 Expressive Animated Sinusoidal Wavy Linear Progress Indicator.
class ExpressiveWavyLinearProgress extends StatefulWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const ExpressiveWavyLinearProgress({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.height = 6.0,
  });

  @override
  State<ExpressiveWavyLinearProgress> createState() =>
      _ExpressiveWavyLinearProgressState();
}

class _ExpressiveWavyLinearProgressState
    extends State<ExpressiveWavyLinearProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = widget.color ?? colorScheme.primary;
    final bg = widget.backgroundColor ?? colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height + 6.0),
          painter: _WavyProgressPainter(
            progress: widget.value,
            animationValue: _controller.value,
            color: primary,
            backgroundColor: bg,
            strokeWidth: widget.height,
          ),
        );
      },
    );
  }
}

class _WavyProgressPainter extends CustomPainter {
  final double? progress;
  final double animationValue;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _WavyProgressPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;

    // Background track
    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(strokeWidth / 2, midY),
      Offset(size.width - strokeWidth / 2, midY),
      bgPaint,
    );

    // Active Wavy track
    final Paint activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double activeWidth = progress != null
        ? (size.width * progress!.clamp(0.0, 1.0))
        : size.width;

    if (activeWidth <= strokeWidth) return;

    final Path wavePath = Path();
    wavePath.moveTo(strokeWidth / 2, midY);

    const double wavelength = 20.0;
    const double amplitude = 3.0;
    final double phase = animationValue * 2 * math.pi;

    for (double x = strokeWidth / 2; x <= activeWidth; x += 2.0) {
      final double y = midY + amplitude * math.sin((x / wavelength) * 2 * math.pi - phase);
      wavePath.lineTo(x, y);
    }

    canvas.drawPath(wavePath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _WavyProgressPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
