import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/features/payment/presentation/widgets/payment_selector.dart';
import 'package:oummi3/shared/models/payment_model.dart';
import 'package:oummi3/features/teleconsultation/data/repositories/teleconsultation_repository.dart';

final teleconsultationRepoProvider = Provider((ref) => TeleconsultationRepository());

class TeleconsultationBookingScreen extends ConsumerStatefulWidget {
  const TeleconsultationBookingScreen({super.key});

  @override
  ConsumerState<TeleconsultationBookingScreen> createState() => _TeleconsultationBookingScreenState();
}

class _TeleconsultationBookingScreenState extends ConsumerState<TeleconsultationBookingScreen> {
  PaymentProvider _selectedProvider = PaymentProvider.airtel;
  bool _isProcessing = false;
  String? _verificationCode;
  String? _paymentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver une Téléconsultation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parlez à un médecin certifié OUMMI depuis chez vous.',
              style: TextStyle(fontSize: 16, color: OumiColors.grisTexte),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OumiColors.bleuSante.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.medical_services, color: OumiColors.bleuSante),
                  SizedBox(width: 12),
                  Text(
                    'Frais de consultation: 2 500 XAF',
                    style: TextStyle(fontWeight: FontWeight.bold, color: OumiColors.noirDoux),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_verificationCode == null) ...[
              PaymentSelector(
                selectedProvider: _selectedProvider,
                onProviderSelected: (p) => setState(() => _selectedProvider = p),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleInitiatePayment,
                style: OumiDecorations.primaryButton,
                child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Payer et Réserver'),
              ),
            ] else ...[
              _buildVerificationStep(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.lock_clock, size: 60, color: OumiColors.orangeAlerte),
        const SizedBox(height: 24),
        const Text(
          'Paiement initié',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Veuillez finaliser le paiement sur votre téléphone via ${_selectedProvider.name.toUpperCase()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: OumiColors.grisTexte),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'CODE: $_verificationCode',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Une fois le SMS de confirmation reçu, appuyez sur le bouton ci-dessous.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleConfirmPayment,
          style: OumiDecorations.primaryButton,
          child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Vérifier mon paiement'),
        ),
        TextButton(
          onPressed: () => setState(() { _verificationCode = null; }),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Future<void> _handleInitiatePayment() async {
    setState(() => _isProcessing = true);
    try {
      final result = await ref.read(teleconsultationRepoProvider).initiateConsultationPayment(_selectedProvider);
      setState(() {
        _isProcessing = false;
        _paymentId = result['paymentId'];
        _verificationCode = result['verificationCode'];
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  Future<void> _handleConfirmPayment() async {
    if (_paymentId == null || _verificationCode == null) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(teleconsultationRepoProvider).confirmConsultation(_paymentId!, _verificationCode!);
      if (mounted) {
        _showSuccess('Consultation réservée avec succès !');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: OumiColors.rougeUrgence),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: OumiColors.vertSante),
    );
  }
}
