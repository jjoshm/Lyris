import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/database.dart';
import '../models/cycle_models.dart';
import '../services/prediction_engine.dart';

// ── Database Provider ──

final databaseProvider = Provider<LyrisDatabase>((ref) {
  return LyrisDatabase(_openConnection());
});

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lyris_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// ── Period Data Providers ──

final allPeriodEntriesProvider = FutureProvider<List<PeriodEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllPeriodEntries();
});

final cyclesProvider = Provider<List<CycleData>>((ref) {
  final entries = ref.watch(allPeriodEntriesProvider);
  return entries.when(
    data: (data) => PredictionEngine.extractCycles(data),
    loading: () => [],
    error: (_, __) => [],
  );
});

final predictionProvider = Provider<CyclePrediction>((ref) {
  final cycles = ref.watch(cyclesProvider);
  return PredictionEngine.predict(cycles);
});

final currentPhaseProvider = Provider<CyclePhase>((ref) {
  final prediction = ref.watch(predictionProvider);
  return PredictionEngine.currentPhase(prediction);
});

final currentCycleDayProvider = Provider<int?>((ref) {
  final cycles = ref.watch(cyclesProvider);
  return PredictionEngine.currentCycleDay(cycles);
});

// ── Symptom Providers ──

final symptomsForDateProvider = FutureProvider.family<List<SymptomEntry>, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  return db.getSymptomsForDate(date);
});

// ── Actions ──

class CycleActions {
  final Ref _ref;

  CycleActions(this._ref);

  Future<void> logPeriodDay(DateTime date, {int flow = 2, String? notes}) async {
    final db = _ref.read(databaseProvider);
    await db.insertPeriodEntry(PeriodEntriesCompanion.insert(
      date: DateTime(date.year, date.month, date.day),
      flow: Value(flow),
      notes: Value(notes),
    ));
    _ref.invalidate(allPeriodEntriesProvider);
  }

  Future<void> removePeriodDay(DateTime date) async {
    final db = _ref.read(databaseProvider);
    await db.deletePeriodEntriesForDate(DateTime(date.year, date.month, date.day));
    _ref.invalidate(allPeriodEntriesProvider);
  }

  Future<void> logSymptom(DateTime date, SymptomDef symptom, {int severity = 1}) async {
    final db = _ref.read(databaseProvider);
    await db.insertSymptomEntry(SymptomEntriesCompanion.insert(
      date: DateTime(date.year, date.month, date.day),
      category: symptom.category,
      symptom: symptom.key,
      severity: Value(severity),
    ));
    _ref.invalidate(symptomsForDateProvider);
  }

  Future<void> removeSymptom(int id) async {
    final db = _ref.read(databaseProvider);
    await db.deleteSymptomEntry(id);
    _ref.invalidate(symptomsForDateProvider);
  }

  Future<void> removeSymptomsForDateAndCategory(DateTime date, String category) async {
    final db = _ref.read(databaseProvider);
    await db.deleteSymptomsForDateAndCategory(DateTime(date.year, date.month, date.day), category);
    _ref.invalidate(symptomsForDateProvider);
  }
}

final cycleActionsProvider = Provider<CycleActions>((ref) {
  return CycleActions(ref);
});

// ── Partner Data (for BLE sharing) ──

final partnerExportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(databaseProvider);
  final prediction = ref.watch(predictionProvider);
  final phase = ref.watch(currentPhaseProvider);
  final cycleDay = ref.watch(currentCycleDayProvider);

  final export = await db.exportAllData();
  export['prediction'] = {
    'nextPeriodStart': prediction.nextPeriodStart?.toIso8601String(),
    'ovulationDay': prediction.ovulationDay?.toIso8601String(),
    'fertileWindowStart': prediction.fertileWindowStart.toIso8601String(),
    'fertileWindowEnd': prediction.fertileWindowEnd.toIso8601String(),
    'pmsStart': prediction.pmsStart?.toIso8601String(),
    'predictedCycleLength': prediction.predictedCycleLength,
    'predictedPeriodLength': prediction.predictedPeriodLength,
    'confidence': prediction.confidence,
  };
  export['currentPhase'] = phase.name;
  export['currentCycleDay'] = cycleDay;

  return export;
});
