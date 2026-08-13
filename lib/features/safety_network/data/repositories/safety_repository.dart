import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:oummi3/features/safety_network/data/models/alert_model.dart';

class SafetyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  Future<void> saveAlert(MaternalAlert alert) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('maternal_alerts')
        .doc(alert.id)
        .set(alert.toFirestore());
  }

  Future<void> increaseReminderFrequency() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({
        'reminderFrequencyIncrement': FieldValue.increment(1),
        'lastRiskAssessment': FieldValue.serverTimestamp(),
      });
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
