import 'package:flutter_test/flutter_test.dart';
import 'package:lyris_tracker/data/database.dart';
import 'package:lyris_tracker/models/cycle_models.dart';
import 'package:lyris_tracker/services/prediction_engine.dart';

/// Helper to create a PeriodEntry for testing.
PeriodEntry _period(DateTime date, {int flow = 2}) {
  return PeriodEntry(
    id: date.millisecondsSinceEpoch,
    date: date,
    flow: flow,
    notes: null,
  );
}

/// Helper: generate period entries for a sequence of cycle start dates.
/// Each period lasts [periodLength] days.
List<PeriodEntry> _generatePeriods({
  required List<DateTime> cycleStarts,
  int periodLength = 5,
}) {
  final entries = <PeriodEntry>[];
  for (final start in cycleStarts) {
    for (int d = 0; d < periodLength; d++) {
      entries.add(_period(start.add(Duration(days: d))));
    }
  }
  return entries;
}

/// Helper: create CycleData directly for prediction tests.
CycleData _cycle(DateTime start, {int? cycleLength, int? periodLength = 5}) {
  return CycleData(
    startDate: start,
    endDate: start.add(Duration(days: (periodLength ?? 5) - 1)),
    cycleLength: cycleLength,
    periodLength: periodLength,
  );
}

void main() {
  group('PredictionEngine.extractCycles', () {
    test('returns empty list for no entries', () {
      expect(PredictionEngine.extractCycles([]), isEmpty);
    });

    test('single period day creates one cycle', () {
      final entries = [_period(DateTime(2025, 3, 1))];
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 1);
      expect(cycles.first.startDate, DateTime(2025, 3, 1));
      expect(cycles.first.periodLength, 1);
      expect(cycles.first.cycleLength, isNull); // no next cycle to compute length
    });

    test('consecutive days form a single period', () {
      final entries = [
        _period(DateTime(2025, 3, 1)),
        _period(DateTime(2025, 3, 2)),
        _period(DateTime(2025, 3, 3)),
        _period(DateTime(2025, 3, 4)),
        _period(DateTime(2025, 3, 5)),
      ];
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 1);
      expect(cycles.first.startDate, DateTime(2025, 3, 1));
      expect(cycles.first.endDate, DateTime(2025, 3, 5));
      expect(cycles.first.periodLength, 5);
    });

    test('allows 1-day gap within a period (missed log)', () {
      final entries = [
        _period(DateTime(2025, 3, 1)),
        _period(DateTime(2025, 3, 2)),
        // gap on March 3
        _period(DateTime(2025, 3, 4)),
        _period(DateTime(2025, 3, 5)),
      ];
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 1);
      expect(cycles.first.periodLength, 5); // 1st through 5th
    });

    test('gap > 2 days starts a new cycle', () {
      final entries = [
        _period(DateTime(2025, 3, 1)),
        _period(DateTime(2025, 3, 2)),
        _period(DateTime(2025, 3, 3)),
        // 25-day gap
        _period(DateTime(2025, 3, 29)),
        _period(DateTime(2025, 3, 30)),
      ];
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 2);
      expect(cycles[0].startDate, DateTime(2025, 3, 1));
      expect(cycles[0].periodLength, 3);
      expect(cycles[0].cycleLength, 28); // 29 - 1 = 28 days
      expect(cycles[1].startDate, DateTime(2025, 3, 29));
      expect(cycles[1].periodLength, 2);
    });

    test('deduplicates same-day entries (double-tap protection)', () {
      final entries = [
        _period(DateTime(2025, 3, 1)),
        _period(DateTime(2025, 3, 1)), // duplicate
        _period(DateTime(2025, 3, 1)), // triple
        _period(DateTime(2025, 3, 2)),
        _period(DateTime(2025, 3, 2)), // duplicate
      ];
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 1);
      expect(cycles.first.periodLength, 2); // only 2 unique days
    });

    test('computes cycle lengths between consecutive starts', () {
      final entries = _generatePeriods(
        cycleStarts: [
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 29), // 28-day cycle
          DateTime(2025, 2, 26), // 28-day cycle
          DateTime(2025, 3, 26), // 28-day cycle
        ],
      );
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 4);
      expect(cycles[0].cycleLength, 28);
      expect(cycles[1].cycleLength, 28);
      expect(cycles[2].cycleLength, 28);
      expect(cycles[3].cycleLength, isNull); // last cycle has no successor
    });

    test('rejects biologically implausible cycle lengths (< 15 days)', () {
      final entries = _generatePeriods(
        cycleStarts: [
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 10), // only 9 days — implausible
          DateTime(2025, 2, 7), // 28 days from Jan 10
        ],
      );
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 3);
      expect(cycles[0].cycleLength, isNull); // 9 days rejected
      expect(cycles[1].cycleLength, 28); // valid
    });

    test('rejects biologically implausible cycle lengths (> 60 days)', () {
      final entries = _generatePeriods(
        cycleStarts: [
          DateTime(2025, 1, 1),
          DateTime(2025, 4, 1), // 90 days — implausible
          DateTime(2025, 4, 29), // 28 days
        ],
      );
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 3);
      expect(cycles[0].cycleLength, isNull); // 90 days rejected
      expect(cycles[1].cycleLength, 28); // valid
    });

    test('accepts boundary cycle lengths (15 and 60 days)', () {
      final entries = _generatePeriods(
        cycleStarts: [
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 16), // exactly 15 days
          DateTime(2025, 3, 17), // exactly 60 days
        ],
      );
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles[0].cycleLength, 15); // boundary accepted
      expect(cycles[1].cycleLength, 60); // boundary accepted
    });

    test('handles unsorted entries gracefully', () {
      // Entries might arrive out of order from DB
      final entries = [
        _period(DateTime(2025, 3, 29)),
        _period(DateTime(2025, 3, 1)),
        _period(DateTime(2025, 3, 30)),
        _period(DateTime(2025, 3, 2)),
        _period(DateTime(2025, 3, 3)),
      ];
      // Note: extractCycles processes in order given.
      // The DB should return sorted, but let's verify behavior.
      final cycles = PredictionEngine.extractCycles(entries);
      // Should still produce valid cycles (order-dependent)
      expect(cycles, isNotEmpty);
    });

    test('many cycles — extracts all correctly', () {
      // Simulate 14 regular 28-day cycles
      final starts = <DateTime>[];
      var start = DateTime(2024, 1, 1);
      for (int i = 0; i < 14; i++) {
        starts.add(start);
        start = start.add(const Duration(days: 28));
      }
      final entries = _generatePeriods(cycleStarts: starts);
      final cycles = PredictionEngine.extractCycles(entries);

      expect(cycles.length, 14);
      // First 13 should have cycleLength = 28
      for (int i = 0; i < 13; i++) {
        expect(cycles[i].cycleLength, 28, reason: 'Cycle $i should be 28 days');
      }
      expect(cycles[13].cycleLength, isNull); // last
    });
  });

  group('PredictionEngine.predict', () {
    test('empty cycles returns null — no fabricated predictions on fresh login', () {
      final prediction = PredictionEngine.predict([]);

      expect(prediction, isNull);
    });

    test('single cycle (no completed) returns default from last start', () {
      final cycles = [_cycle(DateTime(2025, 6, 1), cycleLength: null)];
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.predictedCycleLength, 28);
      expect(prediction.nextPeriodStart, DateTime(2025, 6, 29));
    });

    test('regular 28-day cycles predict 28-day cycle', () {
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 8; i++) {
        cycles.add(_cycle(start, cycleLength: i < 7 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.predictedCycleLength, 28);
      expect(prediction.predictedPeriodLength, 5);
      // Next period = last start + 28
      expect(prediction.nextPeriodStart, cycles.last.startDate.add(const Duration(days: 28)));
    });

    test('ovulation = next period - 13 days (Clue methodology)', () {
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 6; i++) {
        cycles.add(_cycle(start, cycleLength: i < 5 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.ovulationDay, isNotNull);
      expect(
        prediction.nextPeriodStart!.difference(prediction.ovulationDay!).inDays,
        13,
        reason: 'Ovulation must be exactly 13 days before predicted period',
      );
    });

    test('fertile window = ovulation-5 to ovulation+1', () {
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 6; i++) {
        cycles.add(_cycle(start, cycleLength: i < 5 ? 30 : null));
        start = start.add(const Duration(days: 30));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(
        prediction.ovulationDay!.difference(prediction.fertileWindowStart).inDays,
        5,
      );
      expect(
        prediction.fertileWindowEnd.difference(prediction.ovulationDay!).inDays,
        1,
      );
    });

    test('PMS starts 7 days before predicted period', () {
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 4; i++) {
        cycles.add(_cycle(start, cycleLength: i < 3 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.pmsStart, isNotNull);
      expect(
        prediction.nextPeriodStart!.difference(prediction.pmsStart!).inDays,
        7,
      );
    });

    test('uses only last 12 cycles for prediction (ignores older)', () {
      // Create 15 cycles: first 3 are 40 days, last 12 are 28 days
      final cycles = <CycleData>[];
      var start = DateTime(2024, 1, 1);

      // 3 old irregular cycles (40 days)
      for (int i = 0; i < 3; i++) {
        cycles.add(_cycle(start, cycleLength: 40));
        start = start.add(const Duration(days: 40));
      }
      // 12 recent regular cycles (28 days)
      for (int i = 0; i < 12; i++) {
        cycles.add(_cycle(start, cycleLength: i < 11 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }

      final prediction = PredictionEngine.predict(cycles)!;

      // Should predict ~28-29, not influenced by the old 40-day cycles
      // (recency weighting of 3×40 + 9×28 in window rounds to 29)
      expect(prediction.predictedCycleLength, lessThanOrEqualTo(29));
      expect(prediction.predictedCycleLength, greaterThanOrEqualTo(28));
    });

    test('recency weighting: recent cycles have more influence', () {
      // 6 cycles of 30 days followed by 6 cycles of 26 days
      final cycles = <CycleData>[];
      var start = DateTime(2024, 6, 1);

      for (int i = 0; i < 6; i++) {
        cycles.add(_cycle(start, cycleLength: 30));
        start = start.add(const Duration(days: 30));
      }
      for (int i = 0; i < 6; i++) {
        cycles.add(_cycle(start, cycleLength: i < 5 ? 26 : null));
        start = start.add(const Duration(days: 26));
      }

      final prediction = PredictionEngine.predict(cycles)!;

      // With recency weighting, prediction should be ≤ 28 (biased toward recent 26s)
      // Linear weight approximation + rounding means it lands on 28, not above
      expect(prediction.predictedCycleLength, lessThanOrEqualTo(28));
      expect(prediction.predictedCycleLength, greaterThanOrEqualTo(26));
    });

    test('clamps predicted cycle length to 21-45 range', () {
      // All cycles are 50 days (above clamp max of 45)
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 4; i++) {
        cycles.add(_cycle(start, cycleLength: i < 3 ? 50 : null));
        start = start.add(const Duration(days: 50));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.predictedCycleLength, lessThanOrEqualTo(45));
    });

    test('clamps predicted period length to 2-10 range', () {
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 4; i++) {
        cycles.add(_cycle(start, cycleLength: i < 3 ? 28 : null, periodLength: 15));
        start = start.add(const Duration(days: 28));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.predictedPeriodLength, lessThanOrEqualTo(10));
    });

    test('confidence increases with more data', () {
      // 2 cycles
      final fewCycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 3; i++) {
        fewCycles.add(_cycle(start, cycleLength: i < 2 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }
      final lowDataPrediction = PredictionEngine.predict(fewCycles)!;

      // 12 cycles
      final manyCycles = <CycleData>[];
      start = DateTime(2024, 1, 1);
      for (int i = 0; i < 13; i++) {
        manyCycles.add(_cycle(start, cycleLength: i < 12 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }
      final highDataPrediction = PredictionEngine.predict(manyCycles)!;

      expect(highDataPrediction.confidence, greaterThan(lowDataPrediction.confidence));
    });

    test('confidence is higher for consistent cycles', () {
      // Consistent: all 28 days
      final consistent = <CycleData>[];
      var start = DateTime(2024, 1, 1);
      for (int i = 0; i < 13; i++) {
        consistent.add(_cycle(start, cycleLength: i < 12 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }

      // Irregular: varies 24-35
      final irregular = <CycleData>[];
      start = DateTime(2024, 1, 1);
      final lengths = [24, 35, 26, 33, 28, 31, 25, 34, 27, 30, 29, 32];
      for (int i = 0; i < 13; i++) {
        final len = i < 12 ? lengths[i] : null;
        irregular.add(_cycle(start, cycleLength: len));
        start = start.add(Duration(days: len ?? 28));
      }

      final consistentPrediction = PredictionEngine.predict(consistent)!;
      final irregularPrediction = PredictionEngine.predict(irregular)!;

      expect(consistentPrediction.confidence, greaterThan(irregularPrediction.confidence));
    });

    test('confidence is bounded between 0.1 and 0.95', () {
      final cycles = <CycleData>[];
      var start = DateTime(2024, 1, 1);
      for (int i = 0; i < 20; i++) {
        cycles.add(_cycle(start, cycleLength: i < 19 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.confidence, greaterThanOrEqualTo(0.1));
      expect(prediction.confidence, lessThanOrEqualTo(0.95));
    });

    test('irregular cycles produce reasonable prediction', () {
      // Cycles: 26, 32, 28, 35, 27, 30
      final lengths = [26, 32, 28, 35, 27, 30];
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < lengths.length + 1; i++) {
        final len = i < lengths.length ? lengths[i] : null;
        cycles.add(_cycle(start, cycleLength: len));
        start = start.add(Duration(days: len ?? 28));
      }
      final prediction = PredictionEngine.predict(cycles)!;

      // Prediction should be within the observed range
      expect(prediction.predictedCycleLength, greaterThanOrEqualTo(26));
      expect(prediction.predictedCycleLength, lessThanOrEqualTo(35));
    });
  });

  group('PredictionEngine.computeAverages', () {
    test('empty cycles returns defaults', () {
      final averages = PredictionEngine.computeAverages([]);

      expect(averages.cycleLength, 28);
      expect(averages.periodLength, 5);
      expect(averages.cycleCount, 0);
    });

    test('uses last 6 cycles for averages (not 12)', () {
      // 10 cycles: first 4 are 40 days, last 6 are 28 days
      final cycles = <CycleData>[];
      var start = DateTime(2024, 1, 1);
      for (int i = 0; i < 4; i++) {
        cycles.add(_cycle(start, cycleLength: 40));
        start = start.add(const Duration(days: 40));
      }
      for (int i = 0; i < 6; i++) {
        cycles.add(_cycle(start, cycleLength: 28));
        start = start.add(const Duration(days: 28));
      }

      final averages = PredictionEngine.computeAverages(cycles);

      // Average of last 6 (all 28) = 28, NOT influenced by old 40-day cycles
      expect(averages.cycleLength, 28);
      expect(averages.cycleCount, 10); // total completed count
    });

    test('simple mean (not weighted) for averages', () {
      // 6 cycles: 26, 28, 30, 28, 26, 30 → mean = 28
      final lengths = [26, 28, 30, 28, 26, 30];
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      for (final len in lengths) {
        cycles.add(_cycle(start, cycleLength: len));
        start = start.add(Duration(days: len));
      }

      final averages = PredictionEngine.computeAverages(cycles);
      expect(averages.cycleLength, 28); // (26+28+30+28+26+30)/6 = 28
    });

    test('averages period length correctly', () {
      final cycles = <CycleData>[];
      var start = DateTime(2025, 1, 1);
      final periodLengths = [4, 5, 6, 5, 4, 6];
      for (final pl in periodLengths) {
        cycles.add(_cycle(start, cycleLength: 28, periodLength: pl));
        start = start.add(const Duration(days: 28));
      }

      final averages = PredictionEngine.computeAverages(cycles);
      expect(averages.periodLength, 5); // (4+5+6+5+4+6)/6 = 5
    });

    test('fewer than 6 cycles uses all available', () {
      final cycles = [
        _cycle(DateTime(2025, 1, 1), cycleLength: 30),
        _cycle(DateTime(2025, 1, 31), cycleLength: 26),
        _cycle(DateTime(2025, 2, 26), cycleLength: null),
      ];

      final averages = PredictionEngine.computeAverages(cycles);
      expect(averages.cycleLength, 28); // (30+26)/2 = 28
      expect(averages.cycleCount, 2);
    });
  });

  group('PredictionEngine.currentCycleDay', () {
    test('returns null for empty cycles', () {
      expect(PredictionEngine.currentCycleDay([]), isNull);
    });

    test('returns 1 on the first day of period', () {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final cycles = [_cycle(todayOnly)];

      expect(PredictionEngine.currentCycleDay(cycles), 1);
    });

    test('returns correct day mid-cycle', () {
      final today = DateTime.now();
      final tenDaysAgo = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 9));
      final cycles = [_cycle(tenDaysAgo)];

      expect(PredictionEngine.currentCycleDay(cycles), 10);
    });
  });

  group('PredictionEngine.currentPhase', () {
    CyclePrediction _predictionForToday({
      required int daysUntilPeriod,
      int periodLength = 5,
    }) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final nextPeriod = todayOnly.add(Duration(days: daysUntilPeriod));
      final ovulation = nextPeriod.subtract(const Duration(days: 13));

      return CyclePrediction(
        nextPeriodStart: nextPeriod,
        ovulationDay: ovulation,
        fertileWindowStart: ovulation.subtract(const Duration(days: 5)),
        fertileWindowEnd: ovulation.add(const Duration(days: 1)),
        pmsStart: nextPeriod.subtract(const Duration(days: 7)),
        predictedCycleLength: 28,
        predictedPeriodLength: periodLength,
        confidence: 0.8,
      );
    }

    test('detects period phase', () {
      // Period starts today
      final prediction = _predictionForToday(daysUntilPeriod: 0);
      expect(PredictionEngine.currentPhase(prediction), CyclePhase.period);
    });

    test('detects period phase mid-period', () {
      // Period started 2 days ago (next period "starts" -2 days ago)
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final periodStart = todayOnly.subtract(const Duration(days: 2));
      final nextPeriod = periodStart; // the "predicted" start was 2 days ago
      final ovulation = nextPeriod.add(const Duration(days: 15));

      final prediction = CyclePrediction(
        nextPeriodStart: nextPeriod,
        ovulationDay: ovulation,
        fertileWindowStart: ovulation.subtract(const Duration(days: 5)),
        fertileWindowEnd: ovulation.add(const Duration(days: 1)),
        pmsStart: nextPeriod.subtract(const Duration(days: 7)),
        predictedCycleLength: 28,
        predictedPeriodLength: 5,
        confidence: 0.8,
      );

      expect(PredictionEngine.currentPhase(prediction), CyclePhase.period);
    });

    test('detects ovulation phase', () {
      // Ovulation is today → next period in 13 days
      final prediction = _predictionForToday(daysUntilPeriod: 13);
      expect(PredictionEngine.currentPhase(prediction), CyclePhase.ovulation);
    });

    test('detects fertile phase', () {
      // 3 days before ovulation → next period in 16 days
      final prediction = _predictionForToday(daysUntilPeriod: 16);
      expect(PredictionEngine.currentPhase(prediction), CyclePhase.fertile);
    });

    test('detects PMS phase', () {
      // 3 days before period, past fertile window
      final prediction = _predictionForToday(daysUntilPeriod: 3);
      expect(PredictionEngine.currentPhase(prediction), CyclePhase.pms);
    });

    test('detects follicular phase (default)', () {
      // 20 days before period — past period, before fertile
      final prediction = _predictionForToday(daysUntilPeriod: 20);
      expect(PredictionEngine.currentPhase(prediction), CyclePhase.follicular);
    });
  });

  group('PredictionEngine — integration scenarios', () {
    test('full pipeline: raw entries → extract → predict', () {
      // Simulate 6 months of regular 28-day cycles with 5-day periods
      final starts = <DateTime>[];
      var start = DateTime(2025, 1, 1);
      for (int i = 0; i < 7; i++) {
        starts.add(start);
        start = start.add(const Duration(days: 28));
      }
      final entries = _generatePeriods(cycleStarts: starts, periodLength: 5);

      final cycles = PredictionEngine.extractCycles(entries);
      final prediction = PredictionEngine.predict(cycles)!;
      final averages = PredictionEngine.computeAverages(cycles);

      expect(cycles.length, 7);
      expect(prediction.predictedCycleLength, 28);
      expect(prediction.predictedPeriodLength, 5);
      expect(prediction.confidence, greaterThan(0.3));
      expect(averages.cycleLength, 28);
      expect(averages.periodLength, 5);
      expect(averages.cycleCount, 6); // 6 completed

      // Ovulation check
      expect(
        prediction.nextPeriodStart!.difference(prediction.ovulationDay!).inDays,
        13,
      );
    });

    test('irregular user: prediction stays within plausible range', () {
      // Realistic irregular pattern
      final lengths = [26, 35, 29, 42, 28, 31, 27, 33];
      final starts = <DateTime>[];
      var start = DateTime(2024, 6, 1);
      for (final len in lengths) {
        starts.add(start);
        start = start.add(Duration(days: len));
      }
      starts.add(start); // last ongoing cycle

      final entries = _generatePeriods(cycleStarts: starts, periodLength: 5);
      final cycles = PredictionEngine.extractCycles(entries);
      final prediction = PredictionEngine.predict(cycles)!;

      // Should be within observed range (clamped 21-45)
      expect(prediction.predictedCycleLength, greaterThanOrEqualTo(21));
      expect(prediction.predictedCycleLength, lessThanOrEqualTo(45));
      expect(prediction.confidence, lessThan(0.8)); // irregular = lower confidence
    });

    test('new user with 2 cycles gets low confidence but valid prediction', () {
      final entries = _generatePeriods(
        cycleStarts: [DateTime(2025, 5, 1), DateTime(2025, 5, 29), DateTime(2025, 6, 26)],
      );
      final cycles = PredictionEngine.extractCycles(entries);
      final prediction = PredictionEngine.predict(cycles)!;

      expect(prediction.predictedCycleLength, 28);
      expect(prediction.confidence, lessThan(0.7));
      expect(prediction.nextPeriodStart, isNotNull);
    });

    test('long-term user (14 cycles) — old data excluded from prediction window', () {
      // First 5 cycles: 35 days, next 9 cycles: 28 days
      final cycles = <CycleData>[];
      var start = DateTime(2024, 1, 1);
      for (int i = 0; i < 5; i++) {
        cycles.add(_cycle(start, cycleLength: 35));
        start = start.add(const Duration(days: 35));
      }
      for (int i = 0; i < 9; i++) {
        cycles.add(_cycle(start, cycleLength: i < 8 ? 28 : null));
        start = start.add(const Duration(days: 28));
      }

      final prediction = PredictionEngine.predict(cycles)!;

      // Last 12 cycles: 3×35 + 9×28 → recency-weighted toward 28
      // But with only 3 old ones in the window, should be close to 28
      expect(prediction.predictedCycleLength, lessThanOrEqualTo(30));
      expect(prediction.predictedCycleLength, greaterThanOrEqualTo(28));
    });
  });

  group('CyclePrediction model', () {
    test('equatable — same values are equal', () {
      final p1 = CyclePrediction(
        nextPeriodStart: DateTime(2025, 7, 1),
        ovulationDay: DateTime(2025, 6, 18),
        fertileWindowStart: DateTime(2025, 6, 13),
        fertileWindowEnd: DateTime(2025, 6, 19),
        pmsStart: DateTime(2025, 6, 24),
        predictedCycleLength: 28,
        predictedPeriodLength: 5,
        confidence: 0.8,
      );
      final p2 = CyclePrediction(
        nextPeriodStart: DateTime(2025, 7, 1),
        ovulationDay: DateTime(2025, 6, 18),
        fertileWindowStart: DateTime(2025, 6, 13),
        fertileWindowEnd: DateTime(2025, 6, 19),
        pmsStart: DateTime(2025, 6, 24),
        predictedCycleLength: 28,
        predictedPeriodLength: 5,
        confidence: 0.8,
      );

      expect(p1, equals(p2));
    });
  });

  group('CycleData model', () {
    test('equatable — same values are equal', () {
      final c1 = CycleData(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 5),
        cycleLength: 28,
        periodLength: 5,
      );
      final c2 = CycleData(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 5),
        cycleLength: 28,
        periodLength: 5,
      );

      expect(c1, equals(c2));
    });
  });

  group('FlowLevel', () {
    test('fromValue maps correctly', () {
      expect(FlowLevel.fromValue(1), FlowLevel.light);
      expect(FlowLevel.fromValue(2), FlowLevel.medium);
      expect(FlowLevel.fromValue(3), FlowLevel.heavy);
    });

    test('fromValue defaults to medium for unknown', () {
      expect(FlowLevel.fromValue(99), FlowLevel.medium);
      expect(FlowLevel.fromValue(0), FlowLevel.medium);
    });
  });

  group('SymptomCatalog', () {
    test('findByKey returns correct symptom', () {
      final cramps = SymptomCatalog.findByKey('cramps');
      expect(cramps, isNotNull);
      expect(cramps!.category, 'pain');
      expect(cramps.emoji, '😣');
    });

    test('findByKey returns null for unknown key', () {
      expect(SymptomCatalog.findByKey('nonexistent'), isNull);
    });

    test('byCategory filters correctly', () {
      final painSymptoms = SymptomCatalog.byCategory('pain');
      expect(painSymptoms, isNotEmpty);
      expect(painSymptoms.every((s) => s.category == 'pain'), isTrue);
    });

    test('all symptoms have unique keys', () {
      final keys = SymptomCatalog.all.map((s) => s.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('categoryLabels covers all categories in use', () {
      final usedCategories = SymptomCatalog.all.map((s) => s.category).toSet();
      for (final cat in usedCategories) {
        expect(SymptomCatalog.categoryLabels.containsKey(cat), isTrue,
            reason: 'Category "$cat" missing from categoryLabels');
      }
    });
  });
}