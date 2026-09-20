import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/emergency/emergency_service.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

class SignalLaborButton extends ConsumerWidget {
  const SignalLaborButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSignal(context, ref, userProfile),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: OumiColors.red, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: OumiColors.red.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Heartbeat Animation
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_v7v9scuz.json', // Pulse/Heartbeat
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.emergency, color: OumiColors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🚨 SIGNAL LABOR',
                      style: TextStyle(
                        color: OumiColors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Services d\'urgence notifiés.',
                      style: TextStyle(
                        color: OumiColors.textMuted.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignal(BuildContext context, WidgetRef ref, dynamic user) async {
    if (user == null) return;
    
    // Quick confirmation dialog
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
