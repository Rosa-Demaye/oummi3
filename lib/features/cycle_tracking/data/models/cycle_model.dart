import 'package:cloud_firestore/cloud_firestore.dart';

enum CyclePhase { menstruation, follicular, ovulation, luteal }
enum Symptom { cramps, headache, nausea, breastPain, acne, backPain, fatigue, bloating, fever, vaginalBleeding }
enum Mood { happy, calm, neutral, sad, irritated, stressed }
enum SexualActivity { protected, unprotected, tryingToConceive }

class CycleRecord {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final CyclePhase phase;
  final bool isFertile;
  final bool ovulationToday;
  final double pregnancyProbability;
  final double fertilityProbability;
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
  final Map<DateTime, DailyCheckIn> dailyCheckIns;
  final Map<String, dynamic> stats; // avg cycle, longest, shortest, regularity, etc.
  final List<NotificationToken> upcomingNotifications;

  CycleRecord({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.phase,
    required this.isFertile,
    required this.ovulationToday,
    required this.pregnancyProbability,
    required this.fertilityProbability,
    this.nextPeriodDate,
    this.ovulationDate,
    this.dailyCheckIns = const {},
    this.stats = const {},
    this.upcomingNotifications = const [],
  });

  CycleRecord copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    CyclePhase? phase,
    bool? isFertile,
    bool? ovulationToday,
    double? pregnancyProbability,
    double? fertilityProbability,
    DateTime? nextPeriodDate,
    DateTime? ovulationDate,
    Map<DateTime, DailyCheckIn>? dailyCheckIns,
    Map<String, dynamic>? stats,
    List<NotificationToken>? upcomingNotifications,
  }) {
    return CycleRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      phase: phase ?? this.phase,
      isFertile: isFertile ?? this.isFertile,
      ovulationToday: ovulationToday ?? this.ovulationToday,
      pregnancyProbability: pregnancyProbability ?? this.pregnancyProbability,
      fertilityProbability: fertilityProbability ?? this.fertilityProbability,
      nextPeriodDate: nextPeriodDate ?? this.nextPeriodDate,
      ovulationDate: ovulationDate ?? this.ovulationDate,
      dailyCheckIns: dailyCheckIns ?? this.dailyCheckIns,
      stats: stats ?? this.stats,
      upcomingNotifications: upcomingNotifications ?? this.upcomingNotifications,
    );
  }

  factory CycleRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      phase: CyclePhase.values.byName(data['phase'] ?? 'follicular'),
      isFertile: data['isFertile'] ?? false,
      ovulationToday: data['ovulationToday'] ?? false,
      pregnancyProbability: (data['pregnancyProbability'] ?? 0.0).toDouble(),
      fertilityProbability: (data['fertilityProbability'] ?? 0.0).toDouble(),
      nextPeriodDate: data['nextPeriodDate'] != null ? (data['nextPeriodDate'] as Timestamp).toDate() : null,
      ovulationDate: data['ovulationDate'] != null ? (data['ovulationDate'] as Timestamp).toDate() : null,
      dailyCheckIns: Map.from(data['dailyCheckIns'] ?? {}).map((k, v) => MapEntry(DateTime.parse(k), DailyCheckIn.fromFirestore(v))),
      stats: data['stats'] ?? {},
      upcomingNotifications: (data['upcomingNotifications'] as List?)?.map((e) => NotificationToken.fromFirestore(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'phase': phase.name,
        'isFertile': isFertile,
        'ovulationToday': ovulationToday,
        'pregnancyProbability': pregnancyProbability,
        'fertilityProbability': fertilityProbability,
        'nextPeriodDate': nextPeriodDate != null ? Timestamp.fromDate(nextPeriodDate!) : null,
        'ovulationDate': ovulationDate != null ? Timestamp.fromDate(ovulationDate!) : null,
        'dailyCheckIns': dailyCheckIns.map((k, v) => MapEntry(k.toIso8601String(), v.toFirestore())),
        'stats': stats,
        'upcomingNotifications': upcomingNotifications.map((e) => e.toFirestore()).toList(),
      };
}

class DailyCheckIn {
  final DateTime date;
  final List<Symptom> symptoms;
  final Mood? mood;
  final double? energy; // 1.0 high, 0.5 medium, 0.0 low
  final double? waterIntake; // glasses
  final double? sleepHours;
  final double? bodyTemperature;
  final double? weight;
  final SexualActivity sexualActivity;
  final bool? intercourseToday;

  DailyCheckIn({
    required this.date,
    required this.symptoms,
    this.mood,
    this.energy,
    this.waterIntake,
    this.sleepHours,
    this.bodyTemperature,
    this.weight,
    required this.sexualActivity,
    this.intercourseToday,
  });

  Map<String, dynamic> toFirestore() => {
        'date': Timestamp.fromDate(date),
        'symptoms': symptoms.map((s) => s.name).toList(),
        'mood': mood?.name,
        'energy': energy,
        'waterIntake': waterIntake,
        'sleepHours': sleepHours,
        'bodyTemperature': bodyTemperature,
        'weight': weight,
        'sexualActivity': sexualActivity.name,
        'intercourseToday': intercourseToday,
      };

  factory DailyCheckIn.fromFirestore(Map<String, dynamic> data) => DailyCheckIn(
        date: (data['date'] as Timestamp).toDate(),
        symptoms: (data['symptoms'] as List?)?.map((e) => Symptom.values.byName(e)).toList() ?? [],
        mood: data['mood'] != null ? Mood.values.byName(data['mood']) : null,
        energy: data['energy'],
        waterIntake: data['waterIntake'],
        sleepHours: data['sleepHours'],
        bodyTemperature: data['bodyTemperature'],
        weight: data['weight'],
        sexualActivity: SexualActivity.values.byName(data['sexualActivity'] ?? 'protected'),
        intercourseToday: data['intercourseToday'],
      );
}

class NotificationToken {
  final String id;
  final String title;
  final String body;
  final DateTime triggerAt;
  final String type; // 'period', 'ovulation', 'symptom_reminder', 'prenatal'

  NotificationToken({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerAt,
    required this.type,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'body': body,
        'triggerAt': Timestamp.fromDate(triggerAt),
        'type': type,
      };

  factory NotificationToken.fromFirestore(Map<String, dynamic> data) => NotificationToken(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        body: data['body'] ?? '',
        triggerAt: (data['triggerAt'] as Timestamp).toDate(),
        type: data['type'] ?? '',
      );
}
