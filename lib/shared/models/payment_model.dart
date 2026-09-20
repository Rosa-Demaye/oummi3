import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, verified, confirmed, completed, failed, refunded }
enum PaymentProvider { airtel, moov, visa }

class PaymentRecord {
  final String id;
  final String userId;
  final double amount;
  final String verificationCode; // 6-digit code
  final PaymentStatus status;
  final PaymentProvider provider;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  PaymentRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.verificationCode,
    required this.status,
    required this.provider,
    required this.createdAt,
    this.verifiedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amount': amount,
        'verificationCode': verificationCode,
        'status': status.name,
        'provider': provider.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      };

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      verificationCode: data['verificationCode'] ?? '',
      status: PaymentStatus.values.byName(data['status'] ?? 'pending'),
      provider: PaymentProvider.values.byName(data['provider'] ?? 'airtel'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }
}
