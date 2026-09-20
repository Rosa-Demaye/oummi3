import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oummi3/shared/models/cycle_model.dart';
import 'package:oummi3/main.dart'; // To access globalSyncService

class CycleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<CycleRecord> watchCurrentCycle() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('cycle_records')
        .orderBy('startDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        return CycleRecord.fromFirestore(snap.docs.first);
      } else {
        // Return a placeholder that indicates NO DATA
        return CycleRecord(
          id: 'no_data',
          userId: user.uid,
          startDate: DateTime.now(),
          phase: CyclePhase.follicular,
          isFertile: false,
          ovulationToday: false,
          pregnancyProbability: 0.0,
          fertilityProbability: 0.0,
        );
      }
    });
  }

  Future<List<CycleRecord>> getCycleHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('cycle_records')
        .orderBy('startDate', descending: true)
        .get();

    return snap.docs.map((doc) => CycleRecord.fromFirestore(doc)).toList();
  }

  /// Checks if the current cycle has a high pregnancy probability (>70%).
  /// This can be used by the UI to trigger a transition to the pregnancy dashboard.
  Future<bool> checkPregnancyProbability() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('cycle_records')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return false;
    final record = CycleRecord.fromFirestore(snap.docs.first);
    return record.pregnancyProbability > 0.7;
  }

  Future<String> saveCycleRecord(CycleRecord record) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final docId = record.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : record.id;
    final path = 'users/${user.uid}/cycle_records';

    await globalSyncService.performWrite(
      collection: path,
      docId: docId,
      data: record.toFirestore(),
    );
    
    return docId;
  }

  Future<DailyCheckIn> saveDailyCheckIn(DailyCheckIn checkIn) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final recordSnap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('cycle_records')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();
        
    if (recordSnap.docs.isEmpty) throw Exception('No cycle record found');
    
    final recordId = recordSnap.docs.first.id;
    final checkInId = checkIn.date.toIso8601String().split('T')[0];
    final path = 'users/${user.uid}/cycle_records/$recordId/daily_check_ins';

    await globalSyncService.performWrite(
      collection: path,
      docId: checkInId,
      data: checkIn.toFirestore(),
    );
        
    return checkIn;
  }

  Future<void> updateFertilityPrediction(String recordId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('cycle_records')
        .doc(recordId);
        
    final snap = await docRef.get();
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>;
    final startDate = (data['startDate'] as Timestamp).toDate();
    
    // Simple logic: if period started recently, calculate fertile window
    // In production, use a proper fertility algorithm
    final now = DateTime.now();
    const cycleLength = 28; // This should ideally be fetched from user settings/stats
    final ovulation = startDate.add(const Duration(days: cycleLength - 14));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    final bool isFertile = now.isAfter(fertileStart) && now.isBefore(fertileEnd);
    final bool isOvulationToday = ovulation.year == now.year && 
                                  ovulation.month == now.month && 
                                  ovulation.day == now.day;

    await docRef.update({
      'isFertile': isFertile,
      'ovulationToday': isOvulationToday,
      'fertilityProbability': isFertile ? 0.9 : 0.1,
      'nextPeriodDate': Timestamp.fromDate(startDate.add(const Duration(days: cycleLength))),
      'ovulationDate': Timestamp.fromDate(ovulation),
    });
  }
}
