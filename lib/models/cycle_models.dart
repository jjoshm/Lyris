import 'package:equatable/equatable.dart';

/// Represents a single menstrual cycle
class CycleData extends Equatable {
  final DateTime startDate;
  final DateTime? endDate; // last period day
  final int? cycleLength; // days until next cycle start
  final int? periodLength; // days of bleeding
  final int? lutealPhaseLength;

  const CycleData({
    required this.startDate,
    this.endDate,
    this.cycleLength,
    this.periodLength,
    this.lutealPhaseLength,
  });

  @override
  List<Object?> get props => [startDate, endDate, cycleLength, periodLength];
}

/// Prediction result for upcoming cycle events
class CyclePrediction extends Equatable {
  final DateTime? nextPeriodStart;
  final DateTime? ovulationDay;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime? pmsStart;
  final int predictedCycleLength;
  final int predictedPeriodLength;
  final double confidence; // 0.0 - 1.0

  const CyclePrediction({
    this.nextPeriodStart,
    this.ovulationDay,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    this.pmsStart,
    required this.predictedCycleLength,
    required this.predictedPeriodLength,
    required this.confidence,
  });

  @override
  List<Object?> get props => [
        nextPeriodStart,
        ovulationDay,
        fertileWindowStart,
        fertileWindowEnd,
        pmsStart,
        predictedCycleLength,
        predictedPeriodLength,
        confidence,
      ];
}

/// Symptom definition for the catalog
class SymptomDef extends Equatable {
  final String key;
  final String category;
  final String label;
  final String emoji;

  const SymptomDef({
    required this.key,
    required this.category,
    required this.label,
    required this.emoji,
  });

  @override
  List<Object?> get props => [key];
}

/// Flow level
enum FlowLevel {
  light(1, 'Light', '💧'),
  medium(2, 'Medium', '💧💧'),
  heavy(3, 'Heavy', '💧💧💧');

  final int value;
  final String label;
  final String emoji;
  const FlowLevel(this.value, this.label, this.emoji);

  static FlowLevel fromValue(int v) =>
      FlowLevel.values.firstWhere((f) => f.value == v, orElse: () => FlowLevel.medium);
}

/// Symptom catalog — Clue-inspired categories
class SymptomCatalog {
  static const List<SymptomDef> all = [
    // Pain
    SymptomDef(key: 'cramps', category: 'pain', label: 'Cramps', emoji: '😣'),
    SymptomDef(key: 'headache', category: 'pain', label: 'Headache', emoji: '🤕'),
    SymptomDef(key: 'backache', category: 'pain', label: 'Back pain', emoji: '🔙'),
    SymptomDef(key: 'breast_tenderness', category: 'pain', label: 'Tender breasts', emoji: '🫁'),
    SymptomDef(key: 'ovulation_pain', category: 'pain', label: 'Ovulation pain', emoji: '⚡'),
    SymptomDef(key: 'joint_pain', category: 'pain', label: 'Joint pain', emoji: '🦴'),

    // Mood
    SymptomDef(key: 'happy', category: 'mood', label: 'Happy', emoji: '😊'),
    SymptomDef(key: 'sad', category: 'mood', label: 'Sad', emoji: '😢'),
    SymptomDef(key: 'irritable', category: 'mood', label: 'Irritable', emoji: '😤'),
    SymptomDef(key: 'anxious', category: 'mood', label: 'Anxious', emoji: '😰'),
    SymptomDef(key: 'calm', category: 'mood', label: 'Calm', emoji: '😌'),
    SymptomDef(key: 'emotional', category: 'mood', label: 'Emotional', emoji: '🥺'),
    SymptomDef(key: 'motivated', category: 'mood', label: 'Motivated', emoji: '🔥'),

    // Body
    SymptomDef(key: 'bloating', category: 'body', label: 'Bloating', emoji: '🎈'),
    SymptomDef(key: 'nausea', category: 'body', label: 'Nausea', emoji: '🤢'),
    SymptomDef(key: 'cravings', category: 'body', label: 'Cravings', emoji: '🍫'),
    SymptomDef(key: 'appetite_loss', category: 'body', label: 'Low appetite', emoji: '🍽️'),
    SymptomDef(key: 'digestive', category: 'body', label: 'Digestive issues', emoji: '🚽'),
    SymptomDef(key: 'hot_flashes', category: 'body', label: 'Hot flashes', emoji: '🥵'),
    SymptomDef(key: 'dizziness', category: 'body', label: 'Dizziness', emoji: '💫'),

    // Energy
    SymptomDef(key: 'fatigue', category: 'energy', label: 'Fatigue', emoji: '😴'),
    SymptomDef(key: 'energetic', category: 'energy', label: 'Energetic', emoji: '⚡'),
    SymptomDef(key: 'insomnia', category: 'energy', label: 'Insomnia', emoji: '🌙'),
    SymptomDef(key: 'sleepy', category: 'energy', label: 'Sleepy', emoji: '🥱'),

    // Skin
    SymptomDef(key: 'acne', category: 'skin', label: 'Acne', emoji: '😟'),
    SymptomDef(key: 'oily_skin', category: 'skin', label: 'Oily skin', emoji: '✨'),
    SymptomDef(key: 'dry_skin', category: 'skin', label: 'Dry skin', emoji: '🏜️'),
    SymptomDef(key: 'glowing', category: 'skin', label: 'Glowing skin', emoji: '🌟'),

    // Other
    SymptomDef(key: 'libido_high', category: 'other', label: 'High libido', emoji: '❤️‍🔥'),
    SymptomDef(key: 'libido_low', category: 'other', label: 'Low libido', emoji: '🧊'),
    SymptomDef(key: 'spotting', category: 'other', label: 'Spotting', emoji: '🩸'),
    SymptomDef(key: 'discharge', category: 'other', label: 'Discharge', emoji: '💦'),
  ];

  static List<SymptomDef> byCategory(String category) =>
      all.where((s) => s.category == category).toList();

  static SymptomDef? findByKey(String key) {
    try {
      return all.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  static const Map<String, String> categoryLabels = {
    'pain': 'Pain',
    'mood': 'Mood',
    'body': 'Body',
    'energy': 'Energy',
    'skin': 'Skin',
    'other': 'Other',
  };
}
