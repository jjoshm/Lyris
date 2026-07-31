// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PeriodEntriesTable extends PeriodEntries
    with TableInfo<$PeriodEntriesTable, PeriodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flowMeta = const VerificationMeta('flow');
  @override
  late final GeneratedColumn<int> flow = GeneratedColumn<int>(
    'flow',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, flow, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('flow')) {
      context.handle(
        _flowMeta,
        flow.isAcceptableOrUnknown(data['flow']!, _flowMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      flow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flow'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $PeriodEntriesTable createAlias(String alias) {
    return $PeriodEntriesTable(attachedDatabase, alias);
  }
}

class PeriodEntry extends DataClass implements Insertable<PeriodEntry> {
  final int id;
  final DateTime date;
  final int flow;
  final String? notes;
  const PeriodEntry({
    required this.id,
    required this.date,
    required this.flow,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['flow'] = Variable<int>(flow);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PeriodEntriesCompanion toCompanion(bool nullToAbsent) {
    return PeriodEntriesCompanion(
      id: Value(id),
      date: Value(date),
      flow: Value(flow),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory PeriodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      flow: serializer.fromJson<int>(json['flow']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'flow': serializer.toJson<int>(flow),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PeriodEntry copyWith({
    int? id,
    DateTime? date,
    int? flow,
    Value<String?> notes = const Value.absent(),
  }) => PeriodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    flow: flow ?? this.flow,
    notes: notes.present ? notes.value : this.notes,
  );
  PeriodEntry copyWithCompanion(PeriodEntriesCompanion data) {
    return PeriodEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      flow: data.flow.present ? data.flow.value : this.flow,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('flow: $flow, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, flow, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.flow == this.flow &&
          other.notes == this.notes);
}

class PeriodEntriesCompanion extends UpdateCompanion<PeriodEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> flow;
  final Value<String?> notes;
  const PeriodEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.flow = const Value.absent(),
    this.notes = const Value.absent(),
  });
  PeriodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.flow = const Value.absent(),
    this.notes = const Value.absent(),
  }) : date = Value(date);
  static Insertable<PeriodEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? flow,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (flow != null) 'flow': flow,
      if (notes != null) 'notes': notes,
    });
  }

  PeriodEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? flow,
    Value<String?>? notes,
  }) {
    return PeriodEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      flow: flow ?? this.flow,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (flow.present) {
      map['flow'] = Variable<int>(flow.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('flow: $flow, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SymptomEntriesTable extends SymptomEntries
    with TableInfo<$SymptomEntriesTable, SymptomEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymptomEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symptomMeta = const VerificationMeta(
    'symptom',
  );
  @override
  late final GeneratedColumn<String> symptom = GeneratedColumn<String>(
    'symptom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    category,
    symptom,
    severity,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptom_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SymptomEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('symptom')) {
      context.handle(
        _symptomMeta,
        symptom.isAcceptableOrUnknown(data['symptom']!, _symptomMeta),
      );
    } else if (isInserting) {
      context.missing(_symptomMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SymptomEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymptomEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      symptom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptom'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SymptomEntriesTable createAlias(String alias) {
    return $SymptomEntriesTable(attachedDatabase, alias);
  }
}

class SymptomEntry extends DataClass implements Insertable<SymptomEntry> {
  final int id;
  final DateTime date;
  final String category;
  final String symptom;
  final int severity;
  final String? notes;
  const SymptomEntry({
    required this.id,
    required this.date,
    required this.category,
    required this.symptom,
    required this.severity,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['category'] = Variable<String>(category);
    map['symptom'] = Variable<String>(symptom);
    map['severity'] = Variable<int>(severity);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SymptomEntriesCompanion toCompanion(bool nullToAbsent) {
    return SymptomEntriesCompanion(
      id: Value(id),
      date: Value(date),
      category: Value(category),
      symptom: Value(symptom),
      severity: Value(severity),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SymptomEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymptomEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      symptom: serializer.fromJson<String>(json['symptom']),
      severity: serializer.fromJson<int>(json['severity']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String>(category),
      'symptom': serializer.toJson<String>(symptom),
      'severity': serializer.toJson<int>(severity),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SymptomEntry copyWith({
    int? id,
    DateTime? date,
    String? category,
    String? symptom,
    int? severity,
    Value<String?> notes = const Value.absent(),
  }) => SymptomEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    category: category ?? this.category,
    symptom: symptom ?? this.symptom,
    severity: severity ?? this.severity,
    notes: notes.present ? notes.value : this.notes,
  );
  SymptomEntry copyWithCompanion(SymptomEntriesCompanion data) {
    return SymptomEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      symptom: data.symptom.present ? data.symptom.value : this.symptom,
      severity: data.severity.present ? data.severity.value : this.severity,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('symptom: $symptom, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, category, symptom, severity, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymptomEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.category == this.category &&
          other.symptom == this.symptom &&
          other.severity == this.severity &&
          other.notes == this.notes);
}

class SymptomEntriesCompanion extends UpdateCompanion<SymptomEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> category;
  final Value<String> symptom;
  final Value<int> severity;
  final Value<String?> notes;
  const SymptomEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.symptom = const Value.absent(),
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SymptomEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String category,
    required String symptom,
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
  }) : date = Value(date),
       category = Value(category),
       symptom = Value(symptom);
  static Insertable<SymptomEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? symptom,
    Expression<int>? severity,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (symptom != null) 'symptom': symptom,
      if (severity != null) 'severity': severity,
      if (notes != null) 'notes': notes,
    });
  }

  SymptomEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? category,
    Value<String>? symptom,
    Value<int>? severity,
    Value<String?>? notes,
  }) {
    return SymptomEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      symptom: symptom ?? this.symptom,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (symptom.present) {
      map['symptom'] = Variable<String>(symptom.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('symptom: $symptom, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $CycleNotesTable extends CycleNotes
    with TableInfo<$CycleNotesTable, CycleNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CycleNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleStartMeta = const VerificationMeta(
    'cycleStart',
  );
  @override
  late final GeneratedColumn<DateTime> cycleStart = GeneratedColumn<DateTime>(
    'cycle_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, cycleStart, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycle_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CycleNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_start')) {
      context.handle(
        _cycleStartMeta,
        cycleStart.isAcceptableOrUnknown(data['cycle_start']!, _cycleStartMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleStartMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CycleNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CycleNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cycle_start'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $CycleNotesTable createAlias(String alias) {
    return $CycleNotesTable(attachedDatabase, alias);
  }
}

class CycleNote extends DataClass implements Insertable<CycleNote> {
  final int id;
  final DateTime cycleStart;
  final String note;
  const CycleNote({
    required this.id,
    required this.cycleStart,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_start'] = Variable<DateTime>(cycleStart);
    map['note'] = Variable<String>(note);
    return map;
  }

  CycleNotesCompanion toCompanion(bool nullToAbsent) {
    return CycleNotesCompanion(
      id: Value(id),
      cycleStart: Value(cycleStart),
      note: Value(note),
    );
  }

  factory CycleNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CycleNote(
      id: serializer.fromJson<int>(json['id']),
      cycleStart: serializer.fromJson<DateTime>(json['cycleStart']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleStart': serializer.toJson<DateTime>(cycleStart),
      'note': serializer.toJson<String>(note),
    };
  }

  CycleNote copyWith({int? id, DateTime? cycleStart, String? note}) =>
      CycleNote(
        id: id ?? this.id,
        cycleStart: cycleStart ?? this.cycleStart,
        note: note ?? this.note,
      );
  CycleNote copyWithCompanion(CycleNotesCompanion data) {
    return CycleNote(
      id: data.id.present ? data.id.value : this.id,
      cycleStart: data.cycleStart.present
          ? data.cycleStart.value
          : this.cycleStart,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CycleNote(')
          ..write('id: $id, ')
          ..write('cycleStart: $cycleStart, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cycleStart, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CycleNote &&
          other.id == this.id &&
          other.cycleStart == this.cycleStart &&
          other.note == this.note);
}

class CycleNotesCompanion extends UpdateCompanion<CycleNote> {
  final Value<int> id;
  final Value<DateTime> cycleStart;
  final Value<String> note;
  const CycleNotesCompanion({
    this.id = const Value.absent(),
    this.cycleStart = const Value.absent(),
    this.note = const Value.absent(),
  });
  CycleNotesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime cycleStart,
    required String note,
  }) : cycleStart = Value(cycleStart),
       note = Value(note);
  static Insertable<CycleNote> custom({
    Expression<int>? id,
    Expression<DateTime>? cycleStart,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleStart != null) 'cycle_start': cycleStart,
      if (note != null) 'note': note,
    });
  }

  CycleNotesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? cycleStart,
    Value<String>? note,
  }) {
    return CycleNotesCompanion(
      id: id ?? this.id,
      cycleStart: cycleStart ?? this.cycleStart,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleStart.present) {
      map['cycle_start'] = Variable<DateTime>(cycleStart.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CycleNotesCompanion(')
          ..write('id: $id, ')
          ..write('cycleStart: $cycleStart, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String key;
  final String value;
  const AppSetting({required this.id, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({int? id, String? key, String? value}) => AppSetting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$LyrisDatabase extends GeneratedDatabase {
  _$LyrisDatabase(QueryExecutor e) : super(e);
  $LyrisDatabaseManager get managers => $LyrisDatabaseManager(this);
  late final $PeriodEntriesTable periodEntries = $PeriodEntriesTable(this);
  late final $SymptomEntriesTable symptomEntries = $SymptomEntriesTable(this);
  late final $CycleNotesTable cycleNotes = $CycleNotesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    periodEntries,
    symptomEntries,
    cycleNotes,
    appSettings,
  ];
}

typedef $$PeriodEntriesTableCreateCompanionBuilder =
    PeriodEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<int> flow,
      Value<String?> notes,
    });
typedef $$PeriodEntriesTableUpdateCompanionBuilder =
    PeriodEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> flow,
      Value<String?> notes,
    });

class $$PeriodEntriesTableFilterComposer
    extends Composer<_$LyrisDatabase, $PeriodEntriesTable> {
  $$PeriodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flow => $composableBuilder(
    column: $table.flow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeriodEntriesTableOrderingComposer
    extends Composer<_$LyrisDatabase, $PeriodEntriesTable> {
  $$PeriodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flow => $composableBuilder(
    column: $table.flow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeriodEntriesTableAnnotationComposer
    extends Composer<_$LyrisDatabase, $PeriodEntriesTable> {
  $$PeriodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get flow =>
      $composableBuilder(column: $table.flow, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$PeriodEntriesTableTableManager
    extends
        RootTableManager<
          _$LyrisDatabase,
          $PeriodEntriesTable,
          PeriodEntry,
          $$PeriodEntriesTableFilterComposer,
          $$PeriodEntriesTableOrderingComposer,
          $$PeriodEntriesTableAnnotationComposer,
          $$PeriodEntriesTableCreateCompanionBuilder,
          $$PeriodEntriesTableUpdateCompanionBuilder,
          (
            PeriodEntry,
            BaseReferences<_$LyrisDatabase, $PeriodEntriesTable, PeriodEntry>,
          ),
          PeriodEntry,
          PrefetchHooks Function()
        > {
  $$PeriodEntriesTableTableManager(_$LyrisDatabase db, $PeriodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> flow = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PeriodEntriesCompanion(
                id: id,
                date: date,
                flow: flow,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<int> flow = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PeriodEntriesCompanion.insert(
                id: id,
                date: date,
                flow: flow,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeriodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LyrisDatabase,
      $PeriodEntriesTable,
      PeriodEntry,
      $$PeriodEntriesTableFilterComposer,
      $$PeriodEntriesTableOrderingComposer,
      $$PeriodEntriesTableAnnotationComposer,
      $$PeriodEntriesTableCreateCompanionBuilder,
      $$PeriodEntriesTableUpdateCompanionBuilder,
      (
        PeriodEntry,
        BaseReferences<_$LyrisDatabase, $PeriodEntriesTable, PeriodEntry>,
      ),
      PeriodEntry,
      PrefetchHooks Function()
    >;
typedef $$SymptomEntriesTableCreateCompanionBuilder =
    SymptomEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required String category,
      required String symptom,
      Value<int> severity,
      Value<String?> notes,
    });
typedef $$SymptomEntriesTableUpdateCompanionBuilder =
    SymptomEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> category,
      Value<String> symptom,
      Value<int> severity,
      Value<String?> notes,
    });

class $$SymptomEntriesTableFilterComposer
    extends Composer<_$LyrisDatabase, $SymptomEntriesTable> {
  $$SymptomEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptom => $composableBuilder(
    column: $table.symptom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SymptomEntriesTableOrderingComposer
    extends Composer<_$LyrisDatabase, $SymptomEntriesTable> {
  $$SymptomEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptom => $composableBuilder(
    column: $table.symptom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SymptomEntriesTableAnnotationComposer
    extends Composer<_$LyrisDatabase, $SymptomEntriesTable> {
  $$SymptomEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get symptom =>
      $composableBuilder(column: $table.symptom, builder: (column) => column);

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$SymptomEntriesTableTableManager
    extends
        RootTableManager<
          _$LyrisDatabase,
          $SymptomEntriesTable,
          SymptomEntry,
          $$SymptomEntriesTableFilterComposer,
          $$SymptomEntriesTableOrderingComposer,
          $$SymptomEntriesTableAnnotationComposer,
          $$SymptomEntriesTableCreateCompanionBuilder,
          $$SymptomEntriesTableUpdateCompanionBuilder,
          (
            SymptomEntry,
            BaseReferences<_$LyrisDatabase, $SymptomEntriesTable, SymptomEntry>,
          ),
          SymptomEntry,
          PrefetchHooks Function()
        > {
  $$SymptomEntriesTableTableManager(
    _$LyrisDatabase db,
    $SymptomEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SymptomEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SymptomEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SymptomEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> symptom = const Value.absent(),
                Value<int> severity = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SymptomEntriesCompanion(
                id: id,
                date: date,
                category: category,
                symptom: symptom,
                severity: severity,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String category,
                required String symptom,
                Value<int> severity = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SymptomEntriesCompanion.insert(
                id: id,
                date: date,
                category: category,
                symptom: symptom,
                severity: severity,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SymptomEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LyrisDatabase,
      $SymptomEntriesTable,
      SymptomEntry,
      $$SymptomEntriesTableFilterComposer,
      $$SymptomEntriesTableOrderingComposer,
      $$SymptomEntriesTableAnnotationComposer,
      $$SymptomEntriesTableCreateCompanionBuilder,
      $$SymptomEntriesTableUpdateCompanionBuilder,
      (
        SymptomEntry,
        BaseReferences<_$LyrisDatabase, $SymptomEntriesTable, SymptomEntry>,
      ),
      SymptomEntry,
      PrefetchHooks Function()
    >;
typedef $$CycleNotesTableCreateCompanionBuilder =
    CycleNotesCompanion Function({
      Value<int> id,
      required DateTime cycleStart,
      required String note,
    });
typedef $$CycleNotesTableUpdateCompanionBuilder =
    CycleNotesCompanion Function({
      Value<int> id,
      Value<DateTime> cycleStart,
      Value<String> note,
    });

class $$CycleNotesTableFilterComposer
    extends Composer<_$LyrisDatabase, $CycleNotesTable> {
  $$CycleNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cycleStart => $composableBuilder(
    column: $table.cycleStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CycleNotesTableOrderingComposer
    extends Composer<_$LyrisDatabase, $CycleNotesTable> {
  $$CycleNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cycleStart => $composableBuilder(
    column: $table.cycleStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CycleNotesTableAnnotationComposer
    extends Composer<_$LyrisDatabase, $CycleNotesTable> {
  $$CycleNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get cycleStart => $composableBuilder(
    column: $table.cycleStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CycleNotesTableTableManager
    extends
        RootTableManager<
          _$LyrisDatabase,
          $CycleNotesTable,
          CycleNote,
          $$CycleNotesTableFilterComposer,
          $$CycleNotesTableOrderingComposer,
          $$CycleNotesTableAnnotationComposer,
          $$CycleNotesTableCreateCompanionBuilder,
          $$CycleNotesTableUpdateCompanionBuilder,
          (
            CycleNote,
            BaseReferences<_$LyrisDatabase, $CycleNotesTable, CycleNote>,
          ),
          CycleNote,
          PrefetchHooks Function()
        > {
  $$CycleNotesTableTableManager(_$LyrisDatabase db, $CycleNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CycleNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CycleNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CycleNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> cycleStart = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => CycleNotesCompanion(
                id: id,
                cycleStart: cycleStart,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime cycleStart,
                required String note,
              }) => CycleNotesCompanion.insert(
                id: id,
                cycleStart: cycleStart,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CycleNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$LyrisDatabase,
      $CycleNotesTable,
      CycleNote,
      $$CycleNotesTableFilterComposer,
      $$CycleNotesTableOrderingComposer,
      $$CycleNotesTableAnnotationComposer,
      $$CycleNotesTableCreateCompanionBuilder,
      $$CycleNotesTableUpdateCompanionBuilder,
      (CycleNote, BaseReferences<_$LyrisDatabase, $CycleNotesTable, CycleNote>),
      CycleNote,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String key,
      required String value,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$LyrisDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$LyrisDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$LyrisDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$LyrisDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$LyrisDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$LyrisDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => AppSettingsCompanion(id: id, key: key, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
              }) => AppSettingsCompanion.insert(id: id, key: key, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$LyrisDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$LyrisDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $LyrisDatabaseManager {
  final _$LyrisDatabase _db;
  $LyrisDatabaseManager(this._db);
  $$PeriodEntriesTableTableManager get periodEntries =>
      $$PeriodEntriesTableTableManager(_db, _db.periodEntries);
  $$SymptomEntriesTableTableManager get symptomEntries =>
      $$SymptomEntriesTableTableManager(_db, _db.symptomEntries);
  $$CycleNotesTableTableManager get cycleNotes =>
      $$CycleNotesTableTableManager(_db, _db.cycleNotes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
