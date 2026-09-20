import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oummi3/shared/models/hospital_model.dart';
import 'package:oummi3/shared/models/booking_model.dart';
import 'package:oummi3/main.dart';

class HospitalRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Hospital>> watchHospitals() {
    return _db.collection('hospitals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Hospital.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateAvailability(String hospitalId, int beds, int laborRooms) async {
    await globalSyncService.performWrite(
      collection: 'hospitals',
      docId: hospitalId,
      data: {
        'availableBeds': beds,
        'availableLaborRooms': laborRooms,
        'lastUpdate': FieldValue.serverTimestamp(),
      },
      type: 'update',
    );
  }

  Future<String> bookLaborRoom(Hospital hospital) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
    final booking = LaborRoomBooking(
      id: bookingId,
      userId: user.uid,
      hospitalId: hospital.id,
      hospitalName: hospital.name,
      requestTime: DateTime.now(),
      status: BookingStatus.pending,
    );

    // 1. Create the booking record via SyncService
    await globalSyncService.performWrite(
      collection: 'bookings',
      docId: bookingId,
      data: booking.toFirestore(),
    );

    // 2. Decrement available rooms via SyncService
    if (hospital.availableLaborRooms > 0) {
      await globalSyncService.performWrite(
        collection: 'hospitals',
        docId: hospital.id,
        data: {
          'availableLaborRooms': FieldValue.increment(-1),
        },
        type: 'update',
      );
    }

    return bookingId;
  }

  Stream<LaborRoomBooking?> watchActiveBooking() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['pending', 'confirmed', 'active'])
        .orderBy('requestTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        return LaborRoomBooking.fromFirestore(snap.docs.first);
      }
      return null;
    });
  }

  /// Seed mock data for testing in N'Djamena
  Future<void> seedMockHospitals() async {
    final hospitals = [
      Hospital(
        id: 'h1',
        name: 'Hôpital de la Renaissance',
        address: 'N\'Djamena, Quartier Ndjari',
        latitude: 12.1360,
        longitude: 15.0500,
        availableBeds: 15,
        totalBeds: 100,
        availableLaborRooms: 3,
        hasEmergencyService: true,
        status: HospitalStatus.open,
        lastUpdate: DateTime.now(),
      ),
      Hospital(
        id: 'h2',
        name: 'Clinique de la Mère et de l\'Enfant',
        address: 'Avenue Charles de Gaulle',
        latitude: 12.1150,
        longitude: 15.0450,
        availableBeds: 2,
        totalBeds: 40,
        availableLaborRooms: 1,
        hasEmergencyService: true,
        status: HospitalStatus.crowded,
        lastUpdate: DateTime.now(),
      ),
      Hospital(
        id: 'h3',
        name: 'Centre de Santé de Goudji',
        address: 'Goudji, N\'Djamena',
        latitude: 12.1500,
        longitude: 15.0700,
        availableBeds: 25,
        totalBeds: 50,
        availableLaborRooms: 5,
        hasEmergencyService: false,
        status: HospitalStatus.open,
        lastUpdate: DateTime.now(),
      ),
    ];

    for (var h in hospitals) {
      await _db.collection('hospitals').doc(h.id).set(h.toFirestore());
    }
  }
}
