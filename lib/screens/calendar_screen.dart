import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../models/cycle_models.dart';
import '../providers/cycle_providers.dart';
import '../services/prediction_engine.dart';
import '../theme/lyris_theme.dart';

/// Vertical scrolling calendar — months stacked top to bottom.
/// Tap a day → bottom sheet with period toggle + symptoms (inline editing).
class CalendarScreen extends ConsumerStatefulWidget {
  CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _selectedDay;
  Map<DateTime, List<PeriodEntry>> _periodMap = {};
  Map<DateTime, List<SymptomEntry>> _symptomMap = {};
  List<DateTime> _months = [];
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToCurrent = false;
  DateTime? _pulseDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _months = _buildMonthList(null);
    _loadData();
    _scrollToCurrentMonth();
  }

  /// Build the list of months to render.
  /// From (earliest data or 12 months ago) through 12 months ahead.
  List<DateTime> _buildMonthList(DateTime? earliestData) {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month - 12, 1);
    if (earliestData != null) {
      final dataStart = DateTime(earliestData.year, earliestData.month - 1, 1);
      if (dataStart.isBefore(start)) start = dataStart;
    }
    final end = DateTime(now.year, now.month + 12, 1);

    final months = <DateTime>[];
    var m = start;
    while (!m.isAfter(end)) {
      months.add(m);
      m = DateTime(m.year, m.month + 1, 1);
    }
    return months;
  }

  void _scrollToCurrentMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrolledToCurrent && _scrollController.hasClients && _months.isNotEmpty) {
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month, 1);
        final index = _months.indexOf(currentMonth);
        if (index >= 0) {
          // Estimate offset: each month block is roughly equal height
          final maxScroll = _scrollController.position.maxScrollExtent;
          final estimatedOffset = (index / (_months.length - 1)) * maxScroll;
          _scrollController.animateTo(
            estimatedOffset.clamp(0.0, maxScroll),
            duration: Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
        _scrolledToCurrent = true;
      }
    });
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final periods = await db.getAllPeriodEntries();
    final symptoms = await db.getSymptomsForRange(
      DateTime(2020),
      DateTime(2030),
    );

    DateTime? earliest;
    final periodMap = <DateTime, List<PeriodEntry>>{};
    for (final p in periods) {
      final key = DateTime(p.date.year, p.date.month, p.date.day);
      periodMap.putIfAbsent(key, () => []).add(p);
      if (earliest == null || key.isBefore(earliest)) earliest = key;
    }
    final symptomMap = <DateTime, List<SymptomEntry>>{};
    for (final s in symptoms) {
      final key = DateTime(s.date.year, s.date.month, s.date.day);
      symptomMap.putIfAbsent(key, () => []).add(s);
    }

    setState(() {
      _periodMap = periodMap;
      _symptomMap = symptomMap;
      // Extend month list backwards if there's older data
      _months = _buildMonthList(earliest);
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _pulseDay = day;
    });
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _pulseDay = null);
    });
    _showDayDetailSheet(day);
  }

  /// Inline day detail — bottom sheet keeps you in calendar context.
  Future<void> _showDayDetailSheet(DateTime date) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final dayKey = DateTime(date.year, date.month, date.day);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final periods = _periodMap[dayKey] ?? [];
            final symptoms = _symptomMap[dayKey] ?? [];
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        Text(
                          DateFormat('EEEE, d. MMMM yyyy').format(date),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Period status
                        if (periods.isNotEmpty)
                          _InfoChip(
                            icon: Icons.water_drop_rounded,
                            color: LyrisTheme.periodColor,
                            label: 'Period · ${FlowLevel.fromValue(periods.first.flow).label} flow',
                          ),

                        // Symptoms
                        if (symptoms.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: symptoms.map((s) {
                              final def = SymptomCatalog.findByKey(s.symptom);
                              return GestureDetector(
                                onLongPress: () async {
                                  final db = ref.read(databaseProvider);
                                  await db.deleteSymptomEntry(s.id);
                                  await _loadData();
                                  setSheetState(() {});
                                },
                                child: _InfoChip(
                                  icon: Icons.emoji_emotions_rounded,
                                  color: LyrisTheme.fertileColor,
                                  label: def != null ? '${def.emoji} ${def.label}' : s.symptom,
                                  trailing: Icons.close_rounded,
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Long-press a symptom to remove it',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ],

                        if (periods.isEmpty && symptoms.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Nothing logged for this day',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final db = ref.read(databaseProvider);
                                  if (_periodMap.containsKey(dayKey)) {
                                    await db.deletePeriodEntriesForDate(dayKey);
                                  } else {
                                    await db.insertPeriodEntry(PeriodEntriesCompanion.insert(
                                      date: dayKey,
                                      flow: Value(2),
                                    ));
                                  }
                                  await _loadData();
                                  ref.invalidate(allPeriodEntriesProvider);
                                  setSheetState(() {});
                                },
                                icon: Icon(
                                  periods.isNotEmpty ? Icons.remove_rounded : Icons.water_drop_rounded,
                                  size: 18,
                                ),
                                label: Text(periods.isNotEmpty ? 'Remove Period' : 'Add Period'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      periods.isNotEmpty ? LyrisTheme.error : LyrisTheme.periodColor,
                                  side: BorderSide(
                                    color: (periods.isNotEmpty
                                            ? LyrisTheme.error
                                            : LyrisTheme.periodColor)
                                        .withOpacity(0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await _showInlineSymptomPicker(date);
                                  await _loadData();
                                },
                                icon: Icon(Icons.emoji_emotions_rounded, size: 18),
                                label: Text('Edit Symptoms'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LyrisTheme.fertileColor,
                                  side: BorderSide(color: LyrisTheme.fertileColor.withOpacity(0.4)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Inline symptom picker — bottom sheet, stays in calendar context
  Future<void> _showInlineSymptomPicker(DateTime date) async {
    final db = ref.read(databaseProvider);
    final existing = await db.getSymptomsForDate(date);
    final selected = <String>{for (final s in existing) s.symptom};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final categories = SymptomCatalog.categoryLabels.entries.toList();
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'Symptoms · ${DateFormat('d. MMM').format(date)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text('Done',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: LyrisTheme.primary)),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: categories.map((cat) {
                        final symptoms = SymptomCatalog.byCategory(cat.key);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 12),
                              child: Text(
                                cat.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: symptoms.map((symptom) {
                                final isSelected = selected.contains(symptom.key);
                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selected.remove(symptom.key);
                                      } else {
                                        selected.add(symptom.key);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? LyrisTheme.fertileColor.withOpacity(0.15)
                                          : Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? LyrisTheme.fertileColor
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${symptom.emoji} ${symptom.label}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? LyrisTheme.fertileColor
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Save changes: delete removed, insert added
    final dayKey = DateTime(date.year, date.month, date.day);
    for (final s in existing) {
      if (!selected.contains(s.symptom)) {
        await db.deleteSymptomEntry(s.id);
      }
    }
    final existingKeys = {for (final s in existing) s.symptom};
    for (final key in selected) {
      if (!existingKeys.contains(key)) {
        final def = SymptomCatalog.findByKey(key);
        if (def != null) {
          await db.insertSymptomEntry(SymptomEntriesCompanion.insert(
            date: dayKey,
            category: def.category,
            symptom: def.key,
            severity: Value(1),
          ));
        }
      }
    }
    ref.invalidate(symptomsForDateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final prediction = ref.watch(predictionProvider);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    // Compute historical phases from past cycles
    final historicalPhases = _computeHistoricalPhases();

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          // Jump to today
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDay = now;
                _scrolledToCurrent = false;
              });
              _scrollToCurrentMonth();
            },
            child: Text(
              'Today',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: LyrisTheme.primary,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _CalendarLegend(),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final month = _months[index];
                final isCurrentMonth = month == currentMonth;
                return _MonthBlock(
                  month: month,
                  isCurrentMonth: isCurrentMonth,
                  selectedDay: _selectedDay,
                  pulseDay: _pulseDay,
                  periodMap: _periodMap,
                  symptomMap: _symptomMap,
                  prediction: prediction,
                  historicalPhases: historicalPhases,
                  onDaySelected: _onDaySelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Compute historical ovulation, fertile window, and PMS dates from past cycles.
  Map<DateTime, String> _computeHistoricalPhases() {
    final entries = ref.read(allPeriodEntriesProvider).value ?? [];
    final cycles = PredictionEngine.extractCycles(entries);
    final phases = <DateTime, String>{};

    for (final cycle in cycles) {
      if (cycle.cycleLength == null) continue;
      final nextStart = cycle.startDate.add(Duration(days: cycle.cycleLength!));

      // Ovulation = next period - 13 days
      final ovulation = nextStart.subtract(Duration(days: 13));
      phases[DateTime(ovulation.year, ovulation.month, ovulation.day)] = 'ovulation';

      // Fertile window = ovulation-5 to ovulation+1
      for (var i = -5; i <= 1; i++) {
        final d = ovulation.add(Duration(days: i));
        final key = DateTime(d.year, d.month, d.day);
        if (!phases.containsKey(key)) phases[key] = 'fertile';
      }

      // PMS = next period - 7 to next period - 1
      for (var i = 7; i >= 1; i--) {
        final d = nextStart.subtract(Duration(days: i));
        final key = DateTime(d.year, d.month, d.day);
        if (!phases.containsKey(key)) phases[key] = 'pms';
      }
    }
    return phases;
  }
}

/// A single month: header + weekday row + day grid.
class _MonthBlock extends StatelessWidget {
  final DateTime month;
  final bool isCurrentMonth;
  final DateTime? selectedDay;
  final DateTime? pulseDay;
  final Map<DateTime, List<PeriodEntry>> periodMap;
  final Map<DateTime, List<SymptomEntry>> symptomMap;
  final CyclePrediction prediction;
  final Map<DateTime, String> historicalPhases;
  final void Function(DateTime) onDaySelected;

  const _MonthBlock({
    required this.month,
    required this.isCurrentMonth,
    required this.selectedDay,
    required this.pulseDay,
    required this.periodMap,
    required this.symptomMap,
    required this.prediction,
    required this.historicalPhases,
    required this.onDaySelected,
  });

  static const _weekdayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final prevMonthLastDay = DateTime(month.year, month.month, 0);
    final nextMonthFirstDay = DateTime(month.year, month.month + 1, 1);

    // Leading blanks so day 1 lands on the correct weekday column
    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final prevDay = d == 1 ? prevMonthLastDay : DateTime(month.year, month.month, d - 1);
      final nextDay = d == daysInMonth ? nextMonthFirstDay : DateTime(month.year, month.month, d + 1);

      // Phase per day — priority: period > predicted > ovulation > fertile > pms
      final dateOnly = DateTime(day.year, day.month, day.day);
      final predictionWindowStart =
          prediction.fertileWindowStart.subtract(Duration(days: 7));
      final predictionWindowEnd = prediction.nextPeriodStart != null
          ? prediction.nextPeriodStart!
              .add(Duration(days: prediction.predictedPeriodLength))
          : prediction.fertileWindowEnd.add(Duration(days: 14));
      final inPredictionWindow = !dateOnly.isBefore(predictionWindowStart) &&
          !dateOnly.isAfter(predictionWindowEnd);

      final isPredictedPeriod = inPredictionWindow &&
          prediction.nextPeriodStart != null &&
          !dateOnly.isBefore(prediction.nextPeriodStart!) &&
          dateOnly.isBefore(prediction.nextPeriodStart!
              .add(Duration(days: prediction.predictedPeriodLength)));
      final isFertile = inPredictionWindow &&
          !dateOnly.isBefore(prediction.fertileWindowStart) &&
          !dateOnly.isAfter(prediction.fertileWindowEnd);
      final isOvulation = inPredictionWindow &&
          prediction.ovulationDay != null &&
          dateOnly == DateTime(prediction.ovulationDay!.year,
              prediction.ovulationDay!.month, prediction.ovulationDay!.day);
      final isPms = inPredictionWindow &&
          prediction.pmsStart != null &&
          prediction.nextPeriodStart != null &&
          !dateOnly.isBefore(prediction.pmsStart!) &&
          dateOnly.isBefore(prediction.nextPeriodStart!);

      String? phase;
      if (periodMap.containsKey(day)) {
        phase = 'period';
      } else if (isPredictedPeriod) {
        phase = 'predicted';
      } else if (historicalPhases[day] == 'ovulation' || isOvulation) {
        phase = 'ovulation';
      } else if (historicalPhases[day] == 'fertile' || isFertile) {
        phase = 'fertile';
      } else if (historicalPhases[day] == 'pms' || isPms) {
        phase = 'pms';
      }

      String? phaseOf(DateTime d) {
        if (periodMap.containsKey(d)) return 'period';
        final k = DateTime(d.year, d.month, d.day);
        final predictionWindowStartN =
            prediction.fertileWindowStart.subtract(Duration(days: 7));
        final predictionWindowEndN = prediction.nextPeriodStart != null
            ? prediction.nextPeriodStart!
                .add(Duration(days: prediction.predictedPeriodLength))
            : prediction.fertileWindowEnd.add(Duration(days: 14));
        final inWindow = !k.isBefore(predictionWindowStartN) &&
            !k.isAfter(predictionWindowEndN);
        if (inWindow &&
            prediction.nextPeriodStart != null &&
            !k.isBefore(prediction.nextPeriodStart!) &&
            k.isBefore(prediction.nextPeriodStart!
                .add(Duration(days: prediction.predictedPeriodLength)))) {
          return 'predicted';
        }
        if (historicalPhases[k] == 'ovulation') return 'ovulation';
        if (inWindow &&
            prediction.ovulationDay != null &&
            k == DateTime(prediction.ovulationDay!.year,
                prediction.ovulationDay!.month, prediction.ovulationDay!.day)) {
          return 'ovulation';
        }
        if (historicalPhases[k] == 'fertile') return 'fertile';
        if (inWindow &&
            !k.isBefore(prediction.fertileWindowStart) &&
            !k.isAfter(prediction.fertileWindowEnd)) {
          return 'fertile';
        }
        if (historicalPhases[k] == 'pms') return 'pms';
        if (inWindow &&
            prediction.pmsStart != null &&
            prediction.nextPeriodStart != null &&
            !k.isBefore(prediction.pmsStart!) &&
            k.isBefore(prediction.nextPeriodStart!)) {
          return 'pms';
        }
        return null;
      }

      cells.add(_DayCell(
        day: day,
        isToday: isCurrentMonth && day.day == DateTime.now().day,
        isSelected: selectedDay != null &&
            selectedDay!.year == day.year &&
            selectedDay!.month == day.month &&
            selectedDay!.day == day.day,
        pulse: pulseDay != null &&
            pulseDay!.year == day.year &&
            pulseDay!.month == day.month &&
            pulseDay!.day == day.day,
        phase: phase,
        prevPhase: phaseOf(prevDay),
        nextPhase: phaseOf(nextDay),
        hasSymptoms: symptomMap.containsKey(day),
        onTap: () => onDaySelected(day),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM').format(month),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isCurrentMonth ? LyrisTheme.primary : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  '${month.year}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isCurrentMonth) ...[
                  SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: LyrisTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'now',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: LyrisTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Weekday labels
          Row(
            children: _weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 4),

          // Day grid — square cells
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
}

/// A single day cell — square design with period / prediction / phase overlays.
/// Consecutive days of the same phase merge into a connected bar
/// (rounded corners only on the outer edges).
class _DayCell extends StatefulWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool pulse;
  final String? phase; // 'period', 'predicted', 'ovulation', 'fertile', 'pms'
  final String? prevPhase;
  final String? nextPhase;
  final bool hasSymptoms;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    this.pulse = false,
    required this.phase,
    this.prevPhase,
    this.nextPhase,
    required this.hasSymptoms,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.84), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.84, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _DayCell old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !old.pulse) _pulseCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final phase = widget.phase;
    final hasPeriod = phase == 'period';

    // ── Resolve visual state (Clue-inspired) ──
    Color? bgColor;
    Color textColor = Theme.of(context).colorScheme.onSurface;
    Border? border;
    bool showOvulationRing = false;
    bool showTodayDot = false;

    // Connection logic: consecutive days of the same phase merge into a
    // continuous bar with rounded corners only on the outer edges.
    // Ovulation is treated as part of the fertile window for connection.
    String? connGroup(String? p) => (p == 'ovulation') ? 'fertile' : p;
    final group = connGroup(phase);
    final connectsLeft = group != null && connGroup(widget.prevPhase) == group;
    final connectsRight = group != null && connGroup(widget.nextPhase) == group;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(connectsLeft ? 0 : 10),
      bottomLeft: Radius.circular(connectsLeft ? 0 : 10),
      topRight: Radius.circular(connectsRight ? 0 : 10),
      bottomRight: Radius.circular(connectsRight ? 0 : 10),
    );

    if (hasPeriod) {
      // Logged period — SOLID fill (Clue signature), white number
      bgColor = LyrisTheme.periodColor;
      textColor = Colors.white;
    } else if (phase == 'predicted') {
      // Predicted period — HOLLOW outline, colored number
      border = Border.all(color: LyrisTheme.periodColor.withOpacity(isDark ? 0.75 : 0.55), width: 1.5);
      textColor = LyrisTheme.periodColor;
    } else if (phase == 'fertile') {
      // Fertile window — soft tint
      bgColor = LyrisTheme.fertileColor.withOpacity(isDark ? 0.26 : 0.10);
    } else if (phase == 'pms') {
      // PMS — soft tint
      bgColor = LyrisTheme.pmsColor.withOpacity(isDark ? 0.24 : 0.09);
    }

    // Ovulation — ring marker around the number (overlays fertile tint)
    if (phase == 'ovulation') {
      showOvulationRing = true;
      bgColor ??= LyrisTheme.ovulationColor.withOpacity(isDark ? 0.22 : 0.10);
    }

    // Today — subtle dot under the number
    if (widget.isToday && !hasPeriod) {
      showTodayDot = true;
    }

    // The day number, optionally wrapped in an ovulation ring
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
                '${widget.day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: LyrisTheme.ovulationColor,
                ),
              ),
            ),
          )
        : Text(
            '${widget.day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.isToday ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
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
                if (showTodayDot)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: LyrisTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (widget.hasSymptoms && !hasPeriod)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: LyrisTheme.fertileColor,
                      shape: BoxShape.circle,
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

/// Legend row showing all calendar color codes (Clue-inspired, theme-adaptive).
class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        // Period — solid fill
        _LegendSwatch(
          color: LyrisTheme.periodColor,
          label: 'Period',
        ),
        // Predicted — hollow outline
        _LegendSwatch(
          color: Colors.transparent,
          border: LyrisTheme.periodColor.withOpacity(isDark ? 0.75 : 0.55),
          label: 'Predicted',
        ),
        // Ovulation — ring
        _LegendSwatch(
          color: Colors.transparent,
          border: LyrisTheme.ovulationColor,
          round: true,
          label: 'Ovulation',
        ),
        // Fertile — soft tint
        _LegendSwatch(
          color: LyrisTheme.fertileColor.withOpacity(isDark ? 0.26 : 0.10),
          label: 'Fertile',
        ),
        // PMS — soft tint
        _LegendSwatch(
          color: LyrisTheme.pmsColor.withOpacity(isDark ? 0.24 : 0.09),
          label: 'PMS',
        ),
      ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final IconData? trailing;

  const _InfoChip({required this.icon, required this.color, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 4),
            Icon(trailing, size: 14, color: color.withOpacity(0.5)),
          ],
        ],
      ),
    );
  }
}
