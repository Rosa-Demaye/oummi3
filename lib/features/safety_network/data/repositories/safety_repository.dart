import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:oummi3/shared/models/alert_model.dart';
import 'package:oummi3/main.dart';

class SafetyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  Future<void> saveAlert(MaternalAlert alert) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final path = 'users/${user.uid}/maternal_alerts';

    await globalSyncService.performWrite(
      collection: path,
      docId: alert.id,
      data: alert.toFirestore(),
    );
  }

  Future<void> increaseReminderFrequency() async {
    final user = _auth.currentUser;
    if (user != null) {
      await globalSyncService.performWrite(
        collection: 'users',
        docId: user.uid,
        data: {
          'reminderFrequencyIncrement': FieldValue.increment(1),
          'lastRiskAssessment': FieldValue.serverTimestamp(),
        },
        type: 'update',
      );
    }
  }

  Future<List<String>> fetchRecipientTokens(List<Recipient> recipients) async {
    // In a real app, you would fetch these from Firestore 
    // based on the user's linked doctor, hospital, or emergency contacts.
    // For now, returning placeholders.
    return ['dummy_token_1', 'dummy_token_2'];
  }

  Future<bool> checkUserConsent() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['consentGiven'] ?? false;
  }
}
