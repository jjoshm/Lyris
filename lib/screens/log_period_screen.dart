import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/cycle_models.dart';
import '../providers/cycle_providers.dart';
import '../theme/lyris_theme.dart';

/// Log period days — tap dates on a mini calendar, set flow
class LogPeriodScreen extends ConsumerStatefulWidget {
  LogPeriodScreen({super.key});

  @override
  ConsumerState<LogPeriodScreen> createState() => _LogPeriodScreenState();
}

class _LogPeriodScreenState extends ConsumerState<LogPeriodScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  FlowLevel _flow = FlowLevel.medium;
  final _noteController = TextEditingController();
  final Set<DateTime> _loggedDays = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadLoggedDays();
  }

  Future<void> _loadLoggedDays() async {
    final entries = await ref.read(databaseProvider).getAllPeriodEntries();
    setState(() {
      _loggedDays.clear();
      for (final e in entries) {
        _loggedDays.add(DateTime(e.date.year, e.date.month, e.date.day));
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Period')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini calendar
            Container(
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
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: LyrisTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: LyrisTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: LyrisTheme.periodColor,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerSize: 6,
                  markerMargin: const EdgeInsets.only(top: 2),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final dateOnly = DateTime(day.year, day.month, day.day);
                    if (_loggedDays.contains(dateOnly)) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: LyrisTheme.periodColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),

            SizedBox(height: 24),

            // Flow selector
            Text(
              'Flow Intensity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: FlowLevel.values.map((level) {
                final isSelected = _flow == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: isSelected
                          ? LyrisTheme.periodColor.withOpacity(0.15)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _flow = level),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Text(
                                level.emoji,
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(height: 4),
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? LyrisTheme.periodColor
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 24),

            // Notes
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note_rounded),
              ),
              maxLines: 2,
            ),

            SizedBox(height: 32),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedDay != null ? _savePeriodDay : null,
                icon: Icon(Icons.check_rounded),
                label: Text(
                  _selectedDay != null
                      ? 'Log ${DateFormat('MMM d').format(_selectedDay!)}'
                      : 'Select a date',
                ),
              ),
            ),

            if (_selectedDay != null &&
                _loggedDays.contains(
                    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _removePeriodDay,
                    icon: Icon(Icons.delete_outline_rounded),
                    label: Text('Remove this day'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LyrisTheme.error,
                      side: BorderSide(color: LyrisTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Future<void> _savePeriodDay() async {
    if (_selectedDay == null) return;

    await ref.read(cycleActionsProvider).logPeriodDay(
          _selectedDay!,
          flow: _flow.value,
          notes: _noteController.text.isNotEmpty ? _noteController.text : null,
        );

    setState(() {
      _loggedDays.add(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged period for ${DateFormat('MMM d').format(_selectedDay!)}'),
          backgroundColor: LyrisTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _removePeriodDay() async {
    if (_selectedDay == null) return;

    await ref.read(cycleActionsProvider).removePeriodDay(_selectedDay!);

    setState(() {
      _loggedDays.remove(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${DateFormat('MMM d').format(_selectedDay!)}'),
          backgroundColor: LyrisTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
