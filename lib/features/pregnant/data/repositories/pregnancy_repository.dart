import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oummi3/shared/models/pregnancy_model.dart';
import 'package:oummi3/shared/models/cycle_model.dart';

class PregnancyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<PregnancyRecord?> watchCurrentPregnancy() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('pregnancy_records')
        .where('status', isEqualTo: 'ongoing')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        return PregnancyRecord.fromFirestore(snap.docs.first);
      }
      return null;
    });
  }

  Future<String> startPregnancyFromCycle(CycleRecord cycleRecord) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Calculate due date (standard 280 days from LMP)
    final lmp = cycleRecord.startDate;
    final edd = lmp.add(const Duration(days: 280));
    
    // Calculate current week
    final diff = DateTime.now().difference(lmp).inDays;
    final week = diff ~/ 7;
    final day = diff % 7;

    final newPregnancy = PregnancyRecord(
      id: '',
      userId: user.uid,
      startDate: lmp,
      expectedDueDate: edd,
      currentWeek: week,
      currentDay: day,
      status: PregnancyStatus.ongoing,
    );

    final docRef = await _db
        .collection('users')
        .doc(user.uid)
        .collection('pregnancy_records')
        .add(newPregnancy.toFirestore());

    // Optionally mark the cycle as "pregnant" or completed
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('cycle_records')
        .doc(cycleRecord.id)
        .update({'stats.isPregnancyTransition': true});

    return docRef.id;
  }

  /// Check if the cycle record indicates a high probability of pregnancy
  /// and needs transition.
  Future<bool> shouldTransition(CycleRecord record) async {
    // Logic: High probability (>70%) or user confirmed test
    return record.pregnancyProbability > 0.7;
  }
}
