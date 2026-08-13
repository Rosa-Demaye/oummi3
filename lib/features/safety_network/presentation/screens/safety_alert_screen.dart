import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/core/themes/app_theme.dart';
import 'package:oummi3/features/safety_network/data/models/alert_model.dart';
import 'package:oummi3/features/safety_network/presentation/providers/safety_provider.dart';

class SafetyAlertScreen extends ConsumerWidget {
  const SafetyAlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(safetyAlertProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: OumiColors.blanc,
        title: const Text('Sécurité maternelle',
            style: TextStyle(color: OumiColors.noirDoux, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consent toggle
            _buildConsentSection(ref),
            const SizedBox(height: 32),
            // Status card
            _buildStatusCard(context, ref, alertState),
            const SizedBox(height: 32),
            // Manual trigger buttons
            _buildManualTriggers(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection(WidgetRef ref) {
    return Card(
      color: OumiColors.roseClair,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partagez votre sécurité',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: OumiColors.noirDoux),
            ),
            const SizedBox(height: 8),
            const Text(
              'OUMI peut alerter votre médecin, hôpital et contact d\'urgence en cas de risque identifié. Vous pouvez retirer votre consentement à tout moment.',
              style: TextStyle(color: OumiColors.grisTexte, fontSize: 14),
            ),
            CheckboxListTile(
              title: const Text('Je consens aux alertes de sécurité',
                  style: TextStyle(color: OumiColors.noirDoux)),
              value: true, // In real app, fetch from user profile provider
              activeColor: OumiColors.oumiRose,
              onChanged: (val) {
                // Implement consent update in profile provider
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, WidgetRef ref, AlertStatus state) {
    Color statusColor = OumiColors.vertSante;
    String statusText = 'Aucun risque identifié aujourd\'hui';
    
    if (state == AlertStatus.assessing) {
      statusText = 'Évaluation en cours...';
      statusColor = OumiColors.bleuSante;
    } else if (state == AlertStatus.sent) {
      statusText = 'Alerte envoyée au réseau';
      statusColor = OumiColors.orangeAlerte;
    } else if (state == AlertStatus.error) {
      statusText = 'Erreur lors de l\'évaluation';
      statusColor = OumiColors.rougeUrgence;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dernière évaluation des risques',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: OumiColors.noirDoux)),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(statusText)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(safetyAlertProvider.notifier).assessRisk(),
              child: const Text('Évaluer maintenant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTriggers(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _manualTriggerCard(
          icon: Icons.warning_amber_rounded,
          title: 'Symptômes sévères',
          color: OumiColors.orangeAlerte,
          subtitle: 'Alerter médecin + hôpital',
          onTap: () => _showConfirmationDialog(context, ref, AlertType.highRisk),
        ),
        const SizedBox(height: 16),
        _manualTriggerCard(
          icon: Icons.local_hospital_rounded,
          title: 'Début du travail',
          color: OumiColors.rougeUrgence,
          subtitle: 'Pré-alerte hôpital avec résumé',
          onTap: () => _showConfirmationDialog(context, ref, AlertType.laborStart),
        ),
      ],
    );
  }

  Widget _manualTriggerCard({
    required IconData icon,
    required String title,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OumiDecorations.defaultRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(OumiDecorations.defaultRadius),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: OumiColors.grisTexte, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: OumiColors.grisTexte),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref, AlertType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer l\'alerte'),
        content: Text('Êtes-vous sûr de vouloir envoyer une alerte de type ${type.name} à votre réseau de sécurité ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // In a real app, you'd call a specific manual trigger method in the notifier
              ref.read(safetyAlertProvider.notifier).assessRisk(); 
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Alerte ${type.name} envoyée !'), backgroundColor: OumiColors.vertSante),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: OumiColors.oumiRose),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
