import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { highRisk, laborStart, emergency, routineCheck }
enum Recipient { doctor, hospital, emergencyContact }

class MaternalAlert {
  final String id;
  final String userId;
  final AlertType type;
  final Recipient primaryRecipient;
  final List<Recipient> allRecipients;
  final String medicalSummary; // structured text or JSON
  final DateTime triggeredAt;
  final bool consentGiven;
  final String status; // pending, sent, acknowledged, closed
  final List<String> notificationIds; // FCM tokens sent to

  MaternalAlert({
    required this.id,
    required this.userId,
    required this.type,
    this.primaryRecipient = Recipient.doctor,
    required this.allRecipients,
    this.medicalSummary = '',
    required this.triggeredAt,
    required this.consentGiven,
    this.status = 'pending',
    this.notificationIds = const [],
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'primaryRecipient': primaryRecipient.name,
        'allRecipients': allRecipients.map((r) => r.name).toList(),
        'medicalSummary': medicalSummary,
        'triggeredAt': Timestamp.fromDate(triggeredAt),
        'consentGiven': consentGiven,
        'status': status,
        'notificationIds': notificationIds,
      };

  factory MaternalAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaternalAlert(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: AlertType.values.byName(data['type'] ?? 'emergency'),
      primaryRecipient: Recipient.values.byName(data['primaryRecipient'] ?? 'doctor'),
      allRecipients: (data['allRecipients'] as List?)
              ?.map((e) => Recipient.values.byName(e))
              .toList() ??
          [],
      medicalSummary: data['medicalSummary'] ?? '',
      triggeredAt: (data['triggeredAt'] as Timestamp).toDate(),
      consentGiven: data['consentGiven'] ?? false,
      status: data['status'] ?? 'pending',
      notificationIds: (data['notificationIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
