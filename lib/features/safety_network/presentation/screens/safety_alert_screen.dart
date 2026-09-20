import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/widgets/oumi_widgets.dart';
import 'package:oummi3/core/emergency/emergency_service.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

class SafetyAlertScreen extends ConsumerWidget {
  const SafetyAlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5), // Figma BG for emergency
      body: CustomScrollView(
        slivers: [
          // Header
          SliverPadding(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: OumiColors.red),
                    style: IconButton.styleFrom(
                      backgroundColor: OumiColors.red.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🚨 Besoin d\'aide ?', style: OumiTypography.h1.copyWith(color: OumiColors.red)),
                        Text('Choisissez l\'action selon votre situation', style: OumiTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Action: SIGNAL LABOR
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _buildSignalLaborCard(context, ref, userProfile),
            ),
          ),

          // Secondary Actions
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildEmergencyTile(
                    icon: '📞',
                    label: 'Appeler les urgences',
                    sub: '1515 — Urgences médicales nationales',
                    color: OumiColors.amber,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyTile(
                    icon: '🏥',
                    label: 'Contacter l\'hôpital',
                    sub: 'Clinique SALAM — Votre hôpital partenaire',
                    color: OumiColors.blue,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyTile(
                    icon: '📍',
                    label: 'Hôpital le plus proche',
                    sub: 'Trouver et obtenir l\'itinéraire',
                    color: OumiColors.teal,
                    onTap: () => context.push('/dashboard/${userProfile?.role.name}/hospitals-map'),
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyTile(
                    icon: '🚑',
                    label: 'Demander une ambulance',
                    sub: 'Si disponible dans votre zone',
                    color: OumiColors.primary,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // Emergency Contact
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _buildEmergencyContactCard(),
            ),
          ),

          // Offline Note
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Text(
                '⚡ Ces actions fonctionnent aussi hors ligne via SMS quand internet n\'est pas disponible',
                textAlign: TextAlign.center,
                style: OumiTypography.caption.copyWith(height: 1.6),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSignalLaborCard(BuildContext context, WidgetRef ref, dynamic user) {
    return InkWell(
      onTap: () => _triggerSignalLabor(context, user),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [OumiColors.red, Color(0xFFC62828)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: OumiColors.red.withValues(alpha: 0.42),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: Text('👶', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signaler le début du travail', style: OumiTypography.h3.copyWith(color: Colors.white, fontSize: 17)),
                  Text('Alerter votre équipe médicale immédiatement', style: OumiTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile({
    required String icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bgColor = color.withValues(alpha: 0.1);
    return OumiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: OumiTypography.label),
                Text(sub, style: OumiTypography.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: OumiColors.border),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OumiColors.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OumiColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact d\'urgence', style: OumiTypography.label.copyWith(fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: OumiColors.primary,
                child: Text('MA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Moussa Ali (Mari)', style: OumiTypography.label),
                    Text('+235 66 XX XX XX', style: OumiTypography.caption),
                  ],
                ),
              ),
              _contactButton(Icons.phone, OumiColors.green),
              const SizedBox(width: 8),
              _contactButton(Icons.chat_bubble_outline, OumiColors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, Color color) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  void _triggerSignalLabor(BuildContext context, dynamic user) async {
    if (user == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le signal ?'),
        content: const Text('Ceci enverra une alerte immédiate à votre hôpital et vos proches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: OumiColors.red),
            child: const Text('SIGNALER MAINTENANT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await EmergencyService().signalLabor(user);
    }
  }
}
