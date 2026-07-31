import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/lyris_theme.dart';

/// Read-only calendar for partner view — Clue-inspired design:
/// solid period fills, hollow predicted outlines, ovulation rings,
/// connected consecutive period days, historical phases.
class PartnerCalendar extends StatelessWidget {
  final Set<DateTime> periodDates;
  final DateTime? nextPeriod;
  final int predictedPeriodLength;
  final DateTime? ovulation;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;

  const PartnerCalendar({
    super.key,
    required this.periodDates,
    this.nextPeriod,
    this.predictedPeriodLength = 5,
    this.ovulation,
    this.fertileStart,
    this.fertileEnd,
  });

  static const _weekdayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = <DateTime>[
      DateTime(now.year, now.month - 1, 1),
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    ];

    final historicalPhases = _computeHistoricalPhases();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend (Clue-inspired, theme-adaptive)
        Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _LegendSwatch(color: LyrisTheme.periodColor, label: 'Period'),
                _LegendSwatch(color: Colors.transparent, border: LyrisTheme.periodColor.withOpacity(isDark ? 0.75 : 0.55), label: 'Predicted'),
                _LegendSwatch(color: Colors.transparent, border: LyrisTheme.ovulationColor, round: true, label: 'Ovulation'),
                _LegendSwatch(color: LyrisTheme.fertileColor.withOpacity(isDark ? 0.26 : 0.10), label: 'Fertile'),
                _LegendSwatch(color: LyrisTheme.pmsColor.withOpacity(isDark ? 0.24 : 0.09), label: 'PMS'),
              ],
            ),
          );
        }),
        SizedBox(height: 8),
        ...months.map((month) => _buildMonth(context, month, now, historicalPhases)),
      ],
    );
  }

  /// Compute historical ovulation, fertile, PMS from period start dates.
  Map<DateTime, String> _computeHistoricalPhases() {
    final phases = <DateTime, String>{};
    final sorted = periodDates.toList()..sort();

    final cycleStarts = <DateTime>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i == 0 || sorted[i].difference(sorted[i - 1]).inDays > 2) {
        cycleStarts.add(sorted[i]);
      }
    }

    for (var i = 0; i < cycleStarts.length - 1; i++) {
      final start = cycleStarts[i];
      final nextStart = cycleStarts[i + 1];
      final cycleLength = nextStart.difference(start).inDays;
      if (cycleLength < 15 || cycleLength > 60) continue;

      final ovu = nextStart.subtract(Duration(days: 13));
      phases[DateTime(ovu.year, ovu.month, ovu.day)] = 'ovulation';

      for (var d = -5; d <= 1; d++) {
        final day = ovu.add(Duration(days: d));
        final key = DateTime(day.year, day.month, day.day);
        if (!phases.containsKey(key)) phases[key] = 'fertile';
      }

      for (var d = 7; d >= 1; d--) {
        final day = nextStart.subtract(Duration(days: d));
        final key = DateTime(day.year, day.month, day.day);
        if (!phases.containsKey(key)) phases[key] = 'pms';
      }
    }
    return phases;
  }

  Widget _buildMonth(BuildContext context, DateTime month, DateTime now, Map<DateTime, String> historicalPhases) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final prevMonthLastDay = DateTime(month.year, month.month, 0);
    final nextMonthFirstDay = DateTime(month.year, month.month + 1, 1);

    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final prevDay = d == 1 ? prevMonthLastDay : DateTime(month.year, month.month, d - 1);
      final nextDay = d == daysInMonth ? nextMonthFirstDay : DateTime(month.year, month.month, d + 1);

      final dateOnly = DateTime(day.year, month.month, d);
      final isPredictedPeriod = nextPeriod != null &&
          !dateOnly.isBefore(nextPeriod!) &&
          dateOnly.isBefore(nextPeriod!.add(Duration(days: predictedPeriodLength)));
      final isFertilePrediction = fertileStart != null &&
          fertileEnd != null &&
          !dateOnly.isBefore(fertileStart!) &&
          !dateOnly.isAfter(fertileEnd!);
      final isOvulationPrediction = ovulation != null &&
          dateOnly == DateTime(ovulation!.year, ovulation!.month, ovulation!.day);

      String? phase;
      if (periodDates.contains(day)) {
        phase = 'period';
      } else if (isPredictedPeriod) {
        phase = 'predicted';
      } else if (historicalPhases[dateOnly] == 'ovulation' || isOvulationPrediction) {
        phase = 'ovulation';
      } else if (historicalPhases[dateOnly] == 'fertile' || isFertilePrediction) {
        phase = 'fertile';
      } else if (historicalPhases[dateOnly] == 'pms') {
        phase = 'pms';
      }

      String? phaseOf(DateTime d) {
        if (periodDates.contains(d)) return 'period';
        final k = DateTime(d.year, d.month, d.day);
        if (nextPeriod != null &&
            !k.isBefore(nextPeriod!) &&
            k.isBefore(nextPeriod!.add(Duration(days: predictedPeriodLength)))) {
          return 'predicted';
        }
        if (historicalPhases[k] == 'ovulation') return 'ovulation';
        if (ovulation != null &&
            k == DateTime(ovulation!.year, ovulation!.month, ovulation!.day)) {
          return 'ovulation';
        }
        if (historicalPhases[k] == 'fertile') return 'fertile';
        if (fertileStart != null &&
            fertileEnd != null &&
            !k.isBefore(fertileStart!) &&
            !k.isAfter(fertileEnd!)) {
          return 'fertile';
        }
        if (historicalPhases[k] == 'pms') return 'pms';
        return null;
      }

      cells.add(_buildDayCell(
        context, day, now, historicalPhases,
        phase: phase,
        prevPhase: phaseOf(prevDay),
        nextPhase: phaseOf(nextDay),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM').format(month),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isCurrentMonth ? LyrisTheme.primary : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '${month.year}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: _weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime now,
    Map<DateTime, String> historicalPhases, {
    required String? phase,
    required String? prevPhase,
    required String? nextPhase,
  }) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final isToday = dateOnly == DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPeriod = phase == 'period';

    // Connected days of the same phase — rounded corners only on outer edges.
    // Ovulation is treated as part of the fertile window for connection.
    String? connGroup(String? p) => (p == 'ovulation') ? 'fertile' : p;
    final group = connGroup(phase);
    final connectsLeft = group != null && connGroup(prevPhase) == group;
    final connectsRight = group != null && connGroup(nextPhase) == group;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(connectsLeft ? 0 : 10),
      bottomLeft: Radius.circular(connectsLeft ? 0 : 10),
      topRight: Radius.circular(connectsRight ? 0 : 10),
      bottomRight: Radius.circular(connectsRight ? 0 : 10),
    );
    // Resolve visual state (Clue-inspired)
    Color? bgColor;
    Color textColor = Theme.of(context).colorScheme.onSurface;
    Border? border;
    bool showOvulationRing = false;

    if (hasPeriod) {
      // Solid fill, white number
      bgColor = LyrisTheme.periodColor;
      textColor = Colors.white;
    } else if (phase == 'predicted') {
      // Hollow outline, colored number
      border = Border.all(color: LyrisTheme.periodColor.withOpacity(isDark ? 0.75 : 0.55), width: 1.5);
      textColor = LyrisTheme.periodColor;
    } else if (phase == 'fertile') {
      bgColor = LyrisTheme.fertileColor.withOpacity(isDark ? 0.26 : 0.10);
    } else if (phase == 'pms') {
      bgColor = LyrisTheme.pmsColor.withOpacity(isDark ? 0.24 : 0.09);
    }

    if (phase == 'ovulation') {
      showOvulationRing = true;
      bgColor ??= LyrisTheme.ovulationColor.withOpacity(isDark ? 0.22 : 0.10);
    }

    final numberWidget = showOvulationRing
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: LyrisTheme.ovulationColor, width: 1.8),
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: LyrisTheme.ovulationColor,
                ),
              ),
            ),
          )
        : Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              color: textColor,
            ),
          );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: border,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            numberWidget,
            if (isToday && !hasPeriod)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: LyrisTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final Color? border;
  final bool round;
  final String label;

  const _LegendSwatch({required this.color, this.border, this.round = false, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: round ? null : BorderRadius.circular(4),
            border: border != null ? Border.all(color: border!, width: 1.5) : null,
          ),
        ),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
