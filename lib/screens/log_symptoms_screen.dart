import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/cycle_models.dart';
import '../providers/cycle_providers.dart';
import '../theme/lyris_theme.dart';

/// Log symptoms for a given day — grouped by category
class LogSymptomsScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  LogSymptomsScreen({super.key, this.initialDate});

  @override
  ConsumerState<LogSymptomsScreen> createState() => _LogSymptomsScreenState();
}

class _LogSymptomsScreenState extends ConsumerState<LogSymptomsScreen> {
  late DateTime _selectedDate;
  final Set<String> _selectedSymptoms = {};
  final Map<String, int> _severities = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final db = ref.read(databaseProvider);
    final existing = await db.getSymptomsForDate(_selectedDate);
    setState(() {
      for (final s in existing) {
        _selectedSymptoms.add(s.symptom);
        _severities[s.symptom] = s.severity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = SymptomCatalog.categoryLabels.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Symptoms · ${DateFormat('MMM d').format(_selectedDate)}'),
        actions: [
          TextButton(
            onPressed: _saveSymptoms,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: LyrisTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final symptoms = SymptomCatalog.byCategory(category.key);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  category.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom.key);
                  final severity = _severities[symptom.key] ?? 1;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSymptoms.remove(symptom.key);
                          _severities.remove(symptom.key);
                        } else {
                          _selectedSymptoms.add(symptom.key);
                          _severities[symptom.key] = 1;
                        }
                      });
                    },
                    onLongPress: isSelected
                        ? () => _showSeverityPicker(symptom)
                        : null,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? LyrisTheme.primary.withOpacity(0.12)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? LyrisTheme.primary.withOpacity(0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(symptom.emoji, style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text(
                            symptom.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? LyrisTheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isSelected && severity > 1) ...[
                            SizedBox(width: 4),
                            Text(
                              '×$severity',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: LyrisTheme.primaryDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (index < categories.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Theme.of(context).dividerColor),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSeverityPicker(SymptomDef symptom) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${symptom.emoji} ${symptom.label} — Severity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3].map((level) {
                  final isSelected = (_severities[symptom.key] ?? 1) == level;
                  final labels = ['Mild', 'Moderate', 'Severe'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Material(
                      color: isSelected
                          ? LyrisTheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() => _severities[symptom.key] = level);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          child: Text(
                            labels[level - 1],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSymptoms() async {
    final actions = ref.read(cycleActionsProvider);
    final db = ref.read(databaseProvider);

    // Remove existing symptoms for this date, then re-insert selected
    final existing = await db.getSymptomsForDate(_selectedDate);
    for (final e in existing) {
      await actions.removeSymptom(e.id);
    }

    for (final key in _selectedSymptoms) {
      final def = SymptomCatalog.findByKey(key);
      if (def != null) {
        await actions.logSymptom(
          _selectedDate,
          def,
          severity: _severities[key] ?? 1,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedSymptoms.length} symptoms logged'),
          backgroundColor: LyrisTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
