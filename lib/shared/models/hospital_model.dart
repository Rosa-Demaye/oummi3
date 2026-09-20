import 'package:cloud_firestore/cloud_firestore.dart';

enum HospitalStatus { open, crowded, emergencyOnly, closed }

class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int availableBeds;
  final int totalBeds;
  final int availableLaborRooms;
  final bool hasEmergencyService;
  final HospitalStatus status;
  final DateTime lastUpdate;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availableBeds,
    required this.totalBeds,
    required this.availableLaborRooms,
    required this.hasEmergencyService,
    required this.status,
    required this.lastUpdate,
  });

  double get occupancyRate => (totalBeds - availableBeds) / totalBeds;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'availableBeds': availableBeds,
        'totalBeds': totalBeds,
        'availableLaborRooms': availableLaborRooms,
        'hasEmergencyService': hasEmergencyService,
        'status': status.name,
        'lastUpdate': Timestamp.fromDate(lastUpdate),
      };

  factory Hospital.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hospital(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      availableBeds: data['availableBeds'] ?? 0,
      totalBeds: data['totalBeds'] ?? 1,
      availableLaborRooms: data['availableLaborRooms'] ?? 0,
      hasEmergencyService: data['hasEmergencyService'] ?? true,
      status: HospitalStatus.values.byName(data['status'] ?? 'open'),
      lastUpdate: (data['lastUpdate'] as Timestamp).toDate(),
    );
  }
}
