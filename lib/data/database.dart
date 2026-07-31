import 'package:drift/drift.dart';

part 'database.g.dart';

/// Period entries — one row per bleeding day
class PeriodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get flow => integer().withDefault(const Constant(1))(); // 1=light, 2=medium, 3=heavy
  TextColumn get notes => text().nullable()();
}

/// Symptom logs — one row per symptom per day
class SymptomEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()(); // pain, mood, body, energy, skin, other
  TextColumn get symptom => text()(); // specific symptom key
  IntColumn get severity => integer().withDefault(const Constant(1))(); // 1-3
  TextColumn get notes => text().nullable()();
}

/// Cycle metadata — user corrections, notes per cycle
class CycleNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get cycleStart => dateTime()();
  TextColumn get note => text()();
}

/// App settings stored in DB for portability
class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

@DriftDatabase(tables: [PeriodEntries, SymptomEntries, CycleNotes, AppSettings])
class LyrisDatabase extends _$LyrisDatabase {
  LyrisDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // ── Period queries ──

  Future<List<PeriodEntry>> getPeriodEntriesForRange(DateTime start, DateTime end) {
    return (select(periodEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<List<PeriodEntry>> getAllPeriodEntries() {
    return (select(periodEntries)..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
  }

  Future<void> insertPeriodEntry(PeriodEntriesCompanion entry) => into(periodEntries).insert(entry);

  Future<void> deletePeriodEntry(int id) =>
      (delete(periodEntries)..where((t) => t.id.equals(id))).go();

  Future<void> deletePeriodEntriesForDate(DateTime date) =>
      (delete(periodEntries)..where((t) => t.date.equals(date))).go();

  // ── Symptom queries ──

  Future<List<SymptomEntry>> getSymptomsForDate(DateTime date) {
    return (select(symptomEntries)..where((t) => t.date.equals(date))).get();
  }

  Future<List<SymptomEntry>> getSymptomsForRange(DateTime start, DateTime end) {
    return (select(symptomEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<void> insertSymptomEntry(SymptomEntriesCompanion entry) => into(symptomEntries).insert(entry);

  Future<void> deleteSymptomEntry(int id) =>
      (delete(symptomEntries)..where((t) => t.id.equals(id))).go();

  Future<void> deleteSymptomsForDateAndCategory(DateTime date, String category) =>
      (delete(symptomEntries)
            ..where((t) => t.date.equals(date) & t.category.equals(category)))
          .go();

  // ── Cycle notes ──

  Future<List<CycleNote>> getAllCycleNotes() => select(cycleNotes).get();

  Future<void> insertCycleNote(CycleNotesCompanion note) => into(cycleNotes).insert(note);

  // ── Settings ──

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insert(
      AppSettingsCompanion.insert(key: key, value: value),
      onConflict: DoUpdate((_) => AppSettingsCompanion.custom(value: Variable(value))),
    );
  }

  // ── Delete all ──

  Future<void> deleteAllData() async {
    await delete(periodEntries).go();
    await delete(symptomEntries).go();
    await delete(cycleNotes).go();
  }

  // ── Export / Partner sharing ──

  Future<Map<String, dynamic>> exportAllData() async {
    final periods = await getAllPeriodEntries();
    final symptoms = await (select(symptomEntries)..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
    final notes = await getAllCycleNotes();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'periods': periods
          .map((p) => {
                'date': p.date.toIso8601String(),
                'flow': p.flow,
                'notes': p.notes,
              })
          .toList(),
      'symptoms': symptoms
          .map((s) => {
                'date': s.date.toIso8601String(),
                'category': s.category,
                'symptom': s.symptom,
                'severity': s.severity,
              })
          .toList(),
      'cycleNotes': notes
          .map((n) => {
                'cycleStart': n.cycleStart.toIso8601String(),
                'note': n.note,
              })
          .toList(),
    };
  }
}
