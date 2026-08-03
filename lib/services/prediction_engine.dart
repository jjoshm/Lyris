import '../data/database.dart';
import '../models/cycle_models.dart';

/// Prediction engine matching Clue's published methodology:
/// - Predictions based on last 12 cycles
/// - Averages based on last 6 cycles
/// - Ovulation = predicted next period - 13 days
/// - Weighted toward recent cycles (Bayesian-inspired recency weighting)
/// - Outlier rejection for cycles outside 15-60 day range
///
/// Reference: Clue Support "How are my predictions and averages calculated?"
/// + Urteaga et al. (2021) "A Generative Modeling Approach to Calibrated
/// Predictions" (PMC8782440) — co-authored by Clue's data science team.
class PredictionEngine {
  static const int _defaultCycleLength = 28;
  static const int _defaultPeriodLength = 5;
  static const int _ovulationOffset = 13; // Clue uses 13, not 14
  static const int _predictionWindow = 12; // last 12 cycles for predictions
  static const int _averageWindow = 6; // last 6 cycles for averages
  static const int _pmsDaysBeforePeriod = 7;

  /// Extract cycle data from raw period entries.
  /// A cycle = first day of period to day before next period starts.
  static List<CycleData> extractCycles(List<PeriodEntry> entries) {
    if (entries.isEmpty) return [];

    // Deduplicate: only one entry per calendar day (protects against double-taps)
    final seen = <DateTime>{};
    final uniqueEntries = <PeriodEntry>[];
    for (final entry in entries) {
      final date = _dateOnly(entry.date);
      if (seen.add(date)) {
        uniqueEntries.add(entry);
      }
    }

    // Group consecutive period days into cycles
    final cycles = <CycleData>[];
    DateTime? cycleStart;
    DateTime? lastPeriodDay;

    for (int i = 0; i < uniqueEntries.length; i++) {
      final entry = uniqueEntries[i];
      final date = _dateOnly(entry.date);

      if (cycleStart == null) {
        cycleStart = date;
        lastPeriodDay = date;
        continue;
      }

      final daysSinceLast = date.difference(lastPeriodDay!).inDays;

      if (daysSinceLast <= 2) {
        // Consecutive period day (allow 1-day gap for missed logs)
        lastPeriodDay = date;
      } else {
        // New cycle — finalize previous
        final periodLength = lastPeriodDay.difference(cycleStart).inDays + 1;
        cycles.add(CycleData(
          startDate: cycleStart,
          endDate: lastPeriodDay,
          periodLength: periodLength,
        ));
        cycleStart = date;
        lastPeriodDay = date;
      }
    }

    // Add the last (possibly ongoing) cycle
    if (cycleStart != null) {
      final periodLength = lastPeriodDay!.difference(cycleStart).inDays + 1;
      cycles.add(CycleData(
        startDate: cycleStart,
        endDate: lastPeriodDay,
        periodLength: periodLength,
      ));
    }

    // Calculate cycle lengths (days between consecutive cycle starts)
    for (int i = 0; i < cycles.length - 1; i++) {
      final cycleLength = cycles[i + 1].startDate.difference(cycles[i].startDate).inDays;
      // Only accept biologically plausible cycle lengths
      if (cycleLength >= 15 && cycleLength <= 60) {
        cycles[i] = CycleData(
          startDate: cycles[i].startDate,
          endDate: cycles[i].endDate,
          cycleLength: cycleLength,
          periodLength: cycles[i].periodLength,
        );
      }
    }

    return cycles;
  }

  /// Predict next cycle events — Clue methodology:
  /// Uses last 12 completed cycles with recency weighting.
  ///
  /// Returns null when there is no logged data at all — a fresh install
  /// must not see fabricated predictions. Once at least one period day is
  /// logged, a (default-based, low-confidence) prediction anchored to that
  /// real start date is returned.
  static CyclePrediction? predict(List<CycleData> cycles) {
    if (cycles.isEmpty) {
      return null;
    }

    final lastCycle = cycles.last;

    // Get completed cycles with known lengths (exclude ongoing last cycle)
    final completedCycles = cycles
        .where((c) => c.cycleLength != null)
        .toList();

    if (completedCycles.isEmpty) {
      // Only have the current/first cycle — use defaults
      return _defaultPrediction(lastCycle.startDate);
    }

    // ── Clue: predictions use last 12 cycles ──
    final predictionCycles = completedCycles.length > _predictionWindow
        ? completedCycles.sublist(completedCycles.length - _predictionWindow)
        : completedCycles;

    // Predicted cycle length: weighted average of last 12 cycles
    // More recent cycles get exponentially higher weight (Bayesian recency)
    final predictedCycleLength = _recencyWeightedAverage(
      predictionCycles.map((c) => c.cycleLength!.toDouble()).toList(),
    ).round().clamp(21, 45);

    // Predicted period length: weighted average of last 12 cycles
    final periodLengths = predictionCycles
        .where((c) => c.periodLength != null)
        .map((c) => c.periodLength!.toDouble())
        .toList();

    final predictedPeriodLength = periodLengths.isNotEmpty
        ? _recencyWeightedAverage(periodLengths).round().clamp(2, 10)
        : _defaultPeriodLength;

    // ── Confidence estimation ──
    // Based on: amount of data + cycle consistency (coefficient of variation)
    final dataFactor = (predictionCycles.length / _predictionWindow).clamp(0.0, 1.0);
    final cycleLengthValues = predictionCycles.map((c) => c.cycleLength!.toDouble()).toList();
    final cv = cycleLengthValues.length > 1
        ? _coefficientOfVariation(cycleLengthValues)
        : 0.5;
    final consistencyFactor = (1.0 - cv.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    final confidence = (0.4 * dataFactor + 0.6 * consistencyFactor).clamp(0.1, 0.95);

    // ── Calculate dates ──
    final lastStart = lastCycle.startDate;

    // Always predict from the last logged period start + cycle length.
    // If overdue, we still show the FIRST expected date (like Clue's
    // "X days late") instead of jumping to the next theoretical cycle.
    // extractCycles already handles the case where a new period was logged
    // (it would create a new cycle with a later startDate).
    final nextPeriodStart =
        lastStart.add(Duration(days: predictedCycleLength));

    // ── Clue: Ovulation = next period - 13 days ──
    final ovulationDay = nextPeriodStart.subtract(const Duration(days: _ovulationOffset));

    // Fertile window: 5 days before ovulation + ovulation day + 1 day after
    final fertileWindowStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDay.add(const Duration(days: 1));

    // PMS: predicted period start - 7 days (Clue uses tracked PMS length,
    // defaulting to ~7 days before period)
    final pmsStart = nextPeriodStart.subtract(const Duration(days: _pmsDaysBeforePeriod));

    return CyclePrediction(
      nextPeriodStart: nextPeriodStart,
      ovulationDay: ovulationDay,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      pmsStart: pmsStart,
      predictedCycleLength: predictedCycleLength,
      predictedPeriodLength: predictedPeriodLength,
      confidence: confidence,
    );
  }

  /// Clue-style averages: based on last 6 cycles
  static CycleAverages computeAverages(List<CycleData> cycles) {
    final completedCycles = cycles.where((c) => c.cycleLength != null).toList();

    final averageCycles = completedCycles.length > _averageWindow
        ? completedCycles.sublist(completedCycles.length - _averageWindow)
        : completedCycles;

    if (averageCycles.isEmpty) {
      return const CycleAverages(
        cycleLength: _defaultCycleLength,
        periodLength: _defaultPeriodLength,
        cycleCount: 0,
      );
    }

    final avgCycleLength = (averageCycles
                .map((c) => c.cycleLength!)
                .reduce((a, b) => a + b) /
            averageCycles.length)
        .round();

    final periodLengths = averageCycles
        .where((c) => c.periodLength != null)
        .map((c) => c.periodLength!)
        .toList();

    final avgPeriodLength = periodLengths.isNotEmpty
        ? (periodLengths.reduce((a, b) => a + b) / periodLengths.length).round()
        : _defaultPeriodLength;

    return CycleAverages(
      cycleLength: avgCycleLength,
      periodLength: avgPeriodLength,
      cycleCount: completedCycles.length,
    );
  }

  /// Recency-weighted average — exponential weighting favoring recent cycles.
  /// Approximates the Bayesian posterior mean from Urteaga et al. (2021)
  /// where recent observations have higher influence on the predictive distribution.
  static double _recencyWeightedAverage(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;

    double weightedSum = 0;
    double weightSum = 0;

    for (int i = 0; i < values.length; i++) {
      // Exponential recency weight: w_i = 2^(i / (n-1))
      // Oldest cycle gets weight ~1, newest gets weight ~2
      final weight = _pow2(i / (values.length - 1));
      weightedSum += values[i] * weight;
      weightSum += weight;
    }

    return weightedSum / weightSum;
  }

  static double _pow2(double x) {
    // 2^x approximation
    return 1.0 + x; // linear approximation for x in [0,1] → range [1,2]
  }

  /// Coefficient of variation (std / mean)
  static double _coefficientOfVariation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            (values.length - 1);
    final stdDev = variance > 0 ? _sqrt(variance) : 0.0;
    return stdDev / mean;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static CyclePrediction _defaultPrediction(DateTime from) {
    final nextPeriod = from.add(const Duration(days: _defaultCycleLength));
    final ovulation = nextPeriod.subtract(const Duration(days: _ovulationOffset));
    return CyclePrediction(
      nextPeriodStart: nextPeriod,
      ovulationDay: ovulation,
      fertileWindowStart: ovulation.subtract(const Duration(days: 5)),
      fertileWindowEnd: ovulation.add(const Duration(days: 1)),
      pmsStart: nextPeriod.subtract(const Duration(days: _pmsDaysBeforePeriod)),
      predictedCycleLength: _defaultCycleLength,
      predictedPeriodLength: _defaultPeriodLength,
      confidence: 0.2,
    );
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Get the current cycle day (1-based) or null if no data
  static int? currentCycleDay(List<CycleData> cycles) {
    if (cycles.isEmpty) return null;
    final lastStart = cycles.last.startDate;
    final now = _dateOnly(DateTime.now());
    final day = now.difference(lastStart).inDays + 1;
    return day > 0 ? day : null;
  }

  /// Determine the current phase
  static CyclePhase currentPhase(CyclePrediction prediction) {
    final now = _dateOnly(DateTime.now());

    if (prediction.nextPeriodStart != null &&
        !now.isBefore(prediction.nextPeriodStart!) &&
        now.isBefore(prediction.nextPeriodStart!
            .add(Duration(days: prediction.predictedPeriodLength)))) {
      return CyclePhase.period;
    }

    if (prediction.ovulationDay != null &&
        now == _dateOnly(prediction.ovulationDay!)) {
      return CyclePhase.ovulation;
    }

    if (!now.isBefore(prediction.fertileWindowStart) &&
        !now.isAfter(prediction.fertileWindowEnd)) {
      return CyclePhase.fertile;
    }

    if (prediction.pmsStart != null &&
        !now.isBefore(prediction.pmsStart!) &&
        prediction.nextPeriodStart != null &&
        now.isBefore(prediction.nextPeriodStart!)) {
      return CyclePhase.pms;
    }

    return CyclePhase.follicular;
  }
}

/// Averages computed from last 6 cycles (Clue methodology)
class CycleAverages {
  final int cycleLength;
  final int periodLength;
  final int cycleCount;

  const CycleAverages({
    required this.cycleLength,
    required this.periodLength,
    required this.cycleCount,
  });
}

enum CyclePhase {
  period('Period', '🩸'),
  follicular('Follicular', '🌱'),
  fertile('Fertile Window', '🌸'),
  ovulation('Ovulation', '🥚'),
  pms('PMS', '🌊');

  final String label;
  final String emoji;
  const CyclePhase(this.label, this.emoji);
}
