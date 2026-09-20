import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/widgets/oumi_widgets.dart';

class DoctorValidationScreen extends StatelessWidget {
  final String? code;
  const DoctorValidationScreen({super.key, this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OumiColors.background,
      appBar: AppBar(
        title: const Text('Validation Consultation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: OumiColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Patient Card
            OumiCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: OumiColors.blueLight,
                    child: Text('RM', style: TextStyle(color: OumiColors.blue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rosa Moussa', style: OumiTypography.h2),
                        Text('ID: ${code ?? 'OUMI-MR-4B8C'}', style: OumiTypography.caption),
                        const SizedBox(height: 4),
                        const OumiBadge(label: '2ème Trimestre', color: OumiColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Payment Status Section
            OumiCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: OumiColors.green, size: 48),
                  const SizedBox(height: 12),
                  Text('Paiement Validé', style: OumiTypography.h3.copyWith(color: OumiColors.green)),
                  const SizedBox(height: 8),
                  Text(
                    'Le montant de 5,000 FCFA a été séquestré et sera libéré après votre validation.',
                    textAlign: TextAlign.center,
                    style: OumiTypography.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Medical Action
            const OumiSectionHeader(title: 'Actions médicales'),
            const SizedBox(height: 12),
            _buildActionTile(Icons.edit_note, 'Remplir le carnet de santé', 'Mise à jour des constantes et notes'),
            const SizedBox(height: 12),
            _buildActionTile(Icons.medication, 'Générer une ordonnance', 'Envoyer directement sur l\'app de la patiente'),

            const SizedBox(height: 48),
            
            OumiButton(
              label: 'Valider la séance',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Consultation validée avec succès !')),
                );
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String sub) {
    return OumiCard(
      padding: const EdgeInsets.all(16),
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: OumiColors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OumiTypography.label),
                Text(sub, style: OumiTypography.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: OumiColors.border),
        ],
      ),
    );
  }
}
