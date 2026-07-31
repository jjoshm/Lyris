import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/prediction_engine.dart';
import '../theme/lyris_theme.dart';

/// Clue-style circular cycle ring showing current day and phase
class CycleRing extends StatelessWidget {
  final int? cycleDay;
  final int cycleLength;
  final CyclePhase phase;

  CycleRing({
    super.key,
    required this.cycleDay,
    required this.cycleLength,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final phaseColor = LyrisTheme.phaseColor(phase.name);

    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(
          painter: _CycleRingPainter(
            cycleDay: cycleDay,
            cycleLength: cycleLength,
            phaseColor: phaseColor,
            dividerColor: Theme.of(context).dividerColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cycleDay != null ? '$cycleDay' : '—',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  cycleDay != null ? 'Cycle Day' : 'No data yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${phase.emoji} ${phase.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: phaseColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  final int? cycleDay;
  final int cycleLength;
  final Color phaseColor;
  final Color dividerColor;

  _CycleRingPainter({
    required this.cycleDay,
    required this.cycleLength,
    required this.phaseColor,
    required this.dividerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Background ring
    final bgPaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Phase segments (approximate: period 5d, follicular, fertile 6d, luteal)
    if (cycleDay != null) {
      final progress = (cycleDay! / cycleLength).clamp(0.0, 1.0);

      // Progress arc
      final progressPaint = Paint()
        ..color = phaseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // Current day dot
      final dotAngle = -math.pi / 2 + sweepAngle;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);

      final dotPaint = Paint()
        ..color = phaseColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 8, dotPaint);

      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 4, innerDot);
    }

    // Phase markers (small dots at key positions)
    _drawPhaseMarker(canvas, center, radius, 0, LyrisTheme.periodColor); // Day 1
    _drawPhaseMarker(canvas, center, radius, 5 / cycleLength, LyrisTheme.follicularColor);
    _drawPhaseMarker(canvas, center, radius, (cycleLength - 19) / cycleLength, LyrisTheme.fertileColor);
    _drawPhaseMarker(canvas, center, radius, (cycleLength - 14) / cycleLength, LyrisTheme.ovulationColor);
  }

  void _drawPhaseMarker(Canvas canvas, Offset center, double radius, double progress, Color color) {
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final x = center.dx + (radius + 14) * math.cos(angle);
    final y = center.dy + (radius + 14) * math.sin(angle);

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 3, paint);
  }

  @override
  bool shouldRepaint(covariant _CycleRingPainter oldDelegate) =>
      oldDelegate.cycleDay != cycleDay || oldDelegate.phaseColor != phaseColor;
}
