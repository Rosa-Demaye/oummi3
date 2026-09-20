import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, active, completed, cancelled }

class LaborRoomBooking {
  final String id;
  final String userId;
  final String hospitalId;
  final String hospitalName;
  final DateTime requestTime;
  final DateTime? arrivalTime;
  final BookingStatus status;
  final String? notes;

  LaborRoomBooking({
    required this.id,
    required this.userId,
    required this.hospitalId,
    required this.hospitalName,
    required this.requestTime,
    this.arrivalTime,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'requestTime': Timestamp.fromDate(requestTime),
        'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
        'status': status.name,
        'notes': notes,
      };

  factory LaborRoomBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LaborRoomBooking(
      id: doc.id,
      userId: data['userId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      requestTime: (data['requestTime'] as Timestamp).toDate(),
      arrivalTime: data['arrivalTime'] != null ? (data['arrivalTime'] as Timestamp).toDate() : null,
      status: BookingStatus.values.byName(data['status'] ?? 'pending'),
      notes: data['notes'],
    );
  }
}
