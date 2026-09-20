import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/shared/models/alert_model.dart';
import 'package:oummi3/features/safety_network/data/repositories/safety_repository.dart';
import 'package:oummi3/features/young_woman/data/repositories/cycle_repository.dart';
import 'package:oummi3/features/young_woman/presentation/providers/cycle_provider.dart' as cp;
import 'package:oummi3/shared/models/cycle_model.dart';

final safetyRepositoryProvider = Provider((ref) => SafetyRepository());

final safetyAlertProvider = StateNotifierProvider<SafetyAlertNotifier, AlertStatus>((ref) {
  final cycleRepo = ref.watch(cp.cycleRepositoryProvider);
  final safetyRepo = ref.watch(safetyRepositoryProvider);
  return SafetyAlertNotifier(cycleRepo: cycleRepo, safetyRepo: safetyRepo);
});

enum AlertStatus { idle, assessing, sent, noRisk, error }

class SafetyAlertNotifier extends StateNotifier<AlertStatus> {
  final CycleRepository _cycleRepo;
  final SafetyRepository _safetyRepo;

  SafetyAlertNotifier({
    required CycleRepository cycleRepo,
    required SafetyRepository safetyRepo,
  })  : _cycleRepo = cycleRepo,
        _safetyRepo = safetyRepo,
        super(AlertStatus.idle);

  Future<void> assessRisk() async {
    state = AlertStatus.assessing;
    try {
      // Get the current cycle record
      final record = await _cycleRepo.watchCurrentCycle().first;
      
      bool isHighRisk = false;
      List<Recipient> recipients = [];
      AlertType type = AlertType.routineCheck;
      String medicalSummary = '';

      if (record.dailyCheckIns.isNotEmpty) {
        // Get the most recent check-in
        final sortedDates = record.dailyCheckIns.keys.toList()..sort();
        final lastDate = sortedDates.last;
        final lastCheck = record.dailyCheckIns[lastDate]!;

        // Risk assessment logic
        if (lastCheck.symptoms.any((s) => [Symptom.fever, Symptom.vaginalBleeding].contains(s)) ||
            lastCheck.mood == Mood.stressed) {
          isHighRisk = true;
          type = AlertType.highRisk;
          recipients = [Recipient.doctor, Recipient.hospital];
          medicalSummary = _buildMedicalSummary(record, lastCheck);
        }
      }

      if (isHighRisk) {
        await _sendAlert(type, recipients, medicalSummary);
      } else {
        state = AlertStatus.noRisk;
      }
    } catch (e) {
      state = AlertStatus.error;
    }
  }

  String _buildMedicalSummary(CycleRecord record, DailyCheckIn checkIn) {
    final buffer = StringBuffer();
    buffer.writeln('=== Résumé médical OUMI ===');
    buffer.writeln('ID Utilisatrice: ${record.userId}');
    buffer.writeln('Phase cycle: ${record.phase.name}');
    buffer.writeln('Symptômes: ${checkIn.symptoms.map((s) => s.name).join(', ')}');
    buffer.writeln('Humeur: ${checkIn.mood?.name ?? 'Non spécifiée'}');
    buffer.writeln('Température: ${checkIn.bodyTemperature ?? 'N/A'} °C');
    buffer.writeln('Poids: ${checkIn.weight ?? 'N/A'} kg');
    buffer.writeln('Activité sexuelle: ${checkIn.sexualActivity.name}');
    buffer.writeln('Date du cycle: ${record.startDate.day}/${record.startDate.month}/${record.startDate.year}');
    return buffer.toString();
  }

  Future<void> _sendAlert(AlertType type, List<Recipient> recipients, String medicalSummary) async {
    try {
      final consent = await _safetyRepo.checkUserConsent();
      final record = await _cycleRepo.watchCurrentCycle().first;
      
      final alert = MaternalAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: record.userId,
        type: type,
        primaryRecipient: recipients.first,
        allRecipients: recipients,
        medicalSummary: medicalSummary,
        triggeredAt: DateTime.now(),
        consentGiven: consent,
      );

      // 1. Save to Firestore
      await _safetyRepo.saveAlert(alert);

      // 2. Mock FCM Notification sending
      // In a real app, this would trigger a Cloud Function or call FirebaseMessaging.instance.send()
      // tokens = await _safetyRepo.fetchRecipientTokens(recipients);

      // 3. Update reminder frequency
      await _safetyRepo.increaseReminderFrequency();

      state = AlertStatus.sent;
    } catch (e) {
      state = AlertStatus.error;
    }
  }
}
