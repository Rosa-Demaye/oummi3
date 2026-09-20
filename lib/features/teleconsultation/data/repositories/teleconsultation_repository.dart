import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:oummi3/shared/models/teleconsultation_model.dart';
import 'package:oummi3/shared/models/payment_model.dart';

class TeleconsultationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> initiateConsultationPayment(PaymentProvider provider) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final HttpsCallable callable = _functions.httpsCallable('initiatePayment');
    final response = await callable.call({
      'amount': 2500, // Fixed price for demo
      'provider': provider.name,
    });

    return Map<String, dynamic>.from(response.data);
  }

  Future<void> confirmConsultation(String paymentId, String verificationCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Check if payment is verified
    final paymentDoc = await _db.collection('pendingPayments').doc(paymentId).get();
    if (!paymentDoc.exists) throw Exception('Payment record not found');
    
    final paymentData = paymentDoc.data()!;
    if (paymentData['verificationCode'] != verificationCode) {
      throw Exception('Code de vérification incorrect');
    }
    
    if (paymentData['status'] != 'verified') {
      throw Exception('Le paiement n\'a pas encore été vérifié par l\'opérateur.');
    }

    // 2. Create the consultation
    final consultation = Teleconsultation(
      id: '',
      patientId: user.uid,
      requestedAt: DateTime.now(),
      status: ConsultationStatus.paid,
      paymentId: paymentId,
    );

    await _db.collection('teleconsultations').add(consultation.toFirestore());

    // 3. Mark payment as confirmed
    await _db.collection('pendingPayments').doc(paymentId).update({
      'status': 'confirmed',
    });
  }
}
