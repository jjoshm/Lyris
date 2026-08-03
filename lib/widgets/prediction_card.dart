import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cycle_models.dart';
import '../theme/lyris_theme.dart';

/// Shows upcoming predictions: next period, ovulation, fertile window.
/// With no logged data (prediction == null) it shows a "not enough data"
/// state instead of fabricated dates.
class PredictionCard extends StatelessWidget {
  final CyclePrediction? prediction;

  PredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final p = prediction;

    if (p == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predictions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LyrisTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hourglass_empty_rounded,
                      size: 20, color: LyrisTheme.primary),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Not enough data yet. Log your periods and predictions '
                    'will appear here automatically.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('MMM d');
    final confidencePercent = (p.confidence * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Predictions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _confidenceColor(p.confidence, context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$confidencePercent% confident',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _confidenceColor(p.confidence, context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _PredictionRow(
            icon: Icons.water_drop_rounded,
            color: LyrisTheme.periodColor,
            label: 'Next Period',
            value: p.nextPeriodStart != null
                ? dateFormat.format(p.nextPeriodStart!)
                : '—',
            sublabel: _daysUntil(p.nextPeriodStart),
          ),
          SizedBox(height: 12),
          _PredictionRow(
            icon: Icons.science_rounded,
            color: LyrisTheme.ovulationColor,
            label: 'Ovulation',
            value: p.ovulationDay != null
                ? dateFormat.format(p.ovulationDay!)
                : '—',
            sublabel: _daysUntil(p.ovulationDay),
          ),
          SizedBox(height: 12),
          _PredictionRow(
            icon: Icons.spa_rounded,
            color: LyrisTheme.fertileColor,
            label: 'Fertile Window',
            value: '${dateFormat.format(p.fertileWindowStart)} – ${dateFormat.format(p.fertileWindowEnd)}',
            sublabel: _daysUntil(p.fertileWindowStart),
          ),
          SizedBox(height: 12),
          _PredictionRow(
            icon: Icons.waves_rounded,
            color: LyrisTheme.pmsColor,
            label: 'PMS likely from',
            value: p.pmsStart != null
                ? dateFormat.format(p.pmsStart!)
                : '—',
            sublabel: _daysUntil(p.pmsStart),
          ),
        ],
      ),
    );
  }

  String _daysUntil(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(today).inDays;
    if (days < 0) return '${-days}d ago';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  Color _confidenceColor(double confidence, BuildContext context) {
    if (confidence >= 0.7) return LyrisTheme.success;
    if (confidence >= 0.4) return LyrisTheme.warning;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _PredictionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sublabel;

  const _PredictionRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (sublabel.isNotEmpty)
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
      ],
    );
  }
}
