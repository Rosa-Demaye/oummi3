import 'package:cloud_firestore/cloud_firestore.dart';

enum PregnancyStatus { ongoing, completed, loss }

class PregnancyRecord {
  final String id;
  final String userId;
  final DateTime startDate; // Last Menstrual Period (LMP)
  final DateTime expectedDueDate;
  final int currentWeek;
  final int currentDay;
  final PregnancyStatus status;
  final List<String> symptoms;
  final List<PrenatalVisit> visits;
  final Map<String, dynamic> stats;

  PregnancyRecord({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.expectedDueDate,
    required this.currentWeek,
    required this.currentDay,
    this.status = PregnancyStatus.ongoing,
    this.symptoms = const [],
    this.visits = const [],
    this.stats = const {},
  });

  factory PregnancyRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List<PrenatalVisit> visits = [];
    final rawVisits = data['visits'];
    if (rawVisits is List) {
      for (var e in rawVisits) {
        visits.add(PrenatalVisit.fromMap(e as Map<String, dynamic>));
      }
    }

    return PregnancyRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      expectedDueDate: (data['expectedDueDate'] as Timestamp).toDate(),
      currentWeek: data['currentWeek'] ?? 0,
      currentDay: data['currentDay'] ?? 0,
      status: PregnancyStatus.values.byName(data['status'] ?? 'ongoing'),
      symptoms: List<String>.from(data['symptoms'] ?? []),
      visits: visits,
      stats: data['stats'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'startDate': Timestamp.fromDate(startDate),
        'expectedDueDate': Timestamp.fromDate(expectedDueDate),
        'currentWeek': currentWeek,
        'currentDay': currentDay,
        'status': status.name,
        'symptoms': symptoms,
        'visits': visits.map((e) => e.toMap()).toList(),
        'stats': stats,
      };

  PregnancyRecord copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? expectedDueDate,
    int? currentWeek,
    int? currentDay,
    PregnancyStatus? status,
    List<String>? symptoms,
    List<PrenatalVisit>? visits,
    Map<String, dynamic>? stats,
  }) {
    return PregnancyRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      expectedDueDate: expectedDueDate ?? this.expectedDueDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      visits: visits ?? this.visits,
      stats: stats ?? this.stats,
    );
  }
}

class PrenatalVisit {
  final DateTime date;
  final String hospitalId;
  final String doctorId;
  final String notes;
  final Map<String, dynamic> measurements;

  PrenatalVisit({
    required this.date,
    required this.hospitalId,
    required this.doctorId,
    required this.notes,
    this.measurements = const {},
  });

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'hospitalId': hospitalId,
        'doctorId': doctorId,
        'notes': notes,
        'measurements': measurements,
      };

  factory PrenatalVisit.fromMap(Map<String, dynamic> data) => PrenatalVisit(
        date: (data['date'] as Timestamp).toDate(),
        hospitalId: data['hospitalId'] ?? '',
        doctorId: data['doctorId'] ?? '',
        notes: data['notes'] ?? '',
        measurements: data['measurements'] ?? {},
      );
}
