import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/features/hospital/data/repositories/hospital_repository.dart';
import 'package:oummi3/shared/models/hospital_model.dart';
import 'package:oummi3/shared/models/booking_model.dart';

final hospitalRepositoryProvider = Provider((ref) => HospitalRepository());

final hospitalsStreamProvider = StreamProvider<List<Hospital>>((ref) {
  return ref.watch(hospitalRepositoryProvider).watchHospitals();
});

final activeBookingStreamProvider = StreamProvider<LaborRoomBooking?>((ref) {
  return ref.watch(hospitalRepositoryProvider).watchActiveBooking();
});
