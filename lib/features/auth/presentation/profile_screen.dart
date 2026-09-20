import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/shared/models/user_model.dart';
import 'package:oummi3/features/auth/presentation/qr_scanner_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;

    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(userProfileProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: OumiColors.oumiRose,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            _infoTile('Nom Complet', userProfile.fullName),
            _infoTile('Rôle', userProfile.role.name.toUpperCase()),
            _infoTile('Téléphone', userProfile.phone),
            _infoTile('Région', userProfile.region),
            _infoTile('Ville', userProfile.city),
            if (userProfile.bloodGroup != null)
              _infoTile('Groupe Sanguin', userProfile.bloodGroup!),
            
            const Divider(height: 40),
            
            // QR Code Display for Mothers
            if (userProfile.role == OumiRole.girl || userProfile.role == OumiRole.pregnant) ...[
              const Text('Votre Code OUMMI', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [OumiDecorations.cardShadow],
                ),
                child: Column(
                  children: [
                    // In a real app, use a QR widget here
                    const Icon(Icons.qr_code_2, size: 150, color: OumiColors.noirDoux),
                    const SizedBox(height: 8),
                    Text(
                      userProfile.qrCode ?? 'ID Manquant',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Montrez ce code à votre mari ou à votre médecin pour lier vos comptes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: OumiColors.grisTexte),
              ),
            ],

            // Scanner for Fathers/Doctors
            if (userProfile.role == OumiRole.father || userProfile.role == OumiRole.doctor) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _handleQrScan(context, ref, userProfile),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner le code d\'une patiente'),
                style: OumiDecorations.primaryButton,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleQrScan(BuildContext context, WidgetRef ref, OumiUser currentUser) async {
    final scannedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedId != null && scannedId.startsWith('OUMI-')) {
      _showLinkConfirmation(context, ref, scannedId, currentUser);
    }
  }

  void _showLinkConfirmation(BuildContext context, WidgetRef ref, String qrId, OumiUser currentUser) async {
    // 1. Find the user with this QR ID
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('qrCode', isEqualTo: qrId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code OUMMI invalide')),
        );
      }
      return;
    }

    final targetUser = OumiUser.fromFirestore(query.docs.first);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer le lien'),
          content: Text('Voulez-vous lier votre compte à celui de ${targetUser.fullName} ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final relation = currentUser.role == OumiRole.father ? 'partner' : 'doctor';
                await ref.read(authRepositoryProvider).addLinkedUser(currentUser.uid, targetUser.uid, relation);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lien établi avec ${targetUser.fullName}')),
                  );
                }
              },
              child: const Text('Lier les comptes'),
            ),
          ],
        ),
      );
    }
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OumiColors.grisTexte)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: OumiColors.noirDoux)),
        ],
      ),
    );
  }
}
