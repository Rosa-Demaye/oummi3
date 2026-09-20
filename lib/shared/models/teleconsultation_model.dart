import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsultationStatus { requested, paid, scheduled, ongoing, completed, cancelled }

class Teleconsultation {
  final String id;
  final String patientId;
  final String? doctorId;
  final DateTime requestedAt;
  final DateTime? scheduledFor;
  final ConsultationStatus status;
  final String? paymentId;
  final String? diagnosis;

  Teleconsultation({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.requestedAt,
    this.scheduledFor,
    required this.status,
    this.paymentId,
    this.diagnosis,
  });

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'doctorId': doctorId,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
        'status': status.name,
        'paymentId': paymentId,
        'diagnosis': diagnosis,
      };

  factory Teleconsultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Teleconsultation(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'],
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
      status: ConsultationStatus.values.byName(data['status'] ?? 'requested'),
      paymentId: data['paymentId'],
      diagnosis: data['diagnosis'],
    );
  }
}
