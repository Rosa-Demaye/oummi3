import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/oumi_widgets.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/models/user_model.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If the user already has a profile and is onboarded, we skip and go to dashboard
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile != null && userProfile.onboardingComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard/${userProfile.role.name}/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: OumiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Je suis…',
                style: OumiTypography.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez votre profil pour une expérience personnalisée',
                style: OumiTypography.body.copyWith(color: OumiColors.textMuted),
              ),
              const SizedBox(height: 32),
              ...OumiRole.values
                  .where((role) => role != OumiRole.admin)
                  .map((role) => _RoleItem(role: role)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleItem extends ConsumerWidget {
  final OumiRole role;
  const _RoleItem({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OumiCard(
        padding: const EdgeInsets.all(16),
        onTap: () async {
          final userRepo = ref.read(userRepositoryProvider);
          final user = userRepo.firebaseUser;

          if (user != null) {
            await userRepo.saveUserData(
              uid: user.uid,
              phoneNumber: user.phoneNumber ?? '',
              onboardingStep: 'role_selected',
              role: role.name,
            );
          }
          
          if (context.mounted) {
            context.go('/registration/${role.name}');
          }
        },
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _getRoleBgColor(role),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  _getRoleEmoji(role),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRoleTitle(role),
                    style: OumiTypography.label.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getRoleDesc(role),
                    style: OumiTypography.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: OumiColors.border),
          ],
        ),
      ),
    );
  }

  String _getRoleEmoji(OumiRole role) {
    switch (role) {
      case OumiRole.girl: return '👧';
      case OumiRole.pregnant: return '🤰';
      case OumiRole.father: return '👨‍👧';
      case OumiRole.doctor: return '👨‍⚕️';
      case OumiRole.hospital: return '🏥';
      default: return '👤';
    }
  }

  String _getRoleTitle(OumiRole role) {
    switch (role) {
      case OumiRole.girl: return 'Jeune fille';
      case OumiRole.pregnant: return 'Femme / Femme enceinte';
      case OumiRole.father: return 'Père / Mari';
      case OumiRole.doctor: return 'Médecin';
      case OumiRole.hospital: return 'Hôpital';
      default: return role.roleDisplayName;
    }
  }

  String _getRoleDesc(OumiRole role) {
    switch (role) {
      case OumiRole.girl: return 'Suivi menstruel & éducation à la santé';
      case OumiRole.pregnant: return 'Suivi de grossesse & soins maternels';
      case OumiRole.father: return 'Accompagner ma partenaire';
      case OumiRole.doctor: return 'Gérer mes patients & consultations';
      case OumiRole.hospital: return 'Gestion hospitalière maternelle';
      default: return '';
    }
  }

  Color _getRoleBgColor(OumiRole role) {
    switch (role) {
      case OumiRole.girl: return OumiColors.peachLight;
      case OumiRole.pregnant: return OumiColors.primaryLight;
      case OumiRole.father: return OumiColors.tealLight;
      case OumiRole.doctor: return OumiColors.blueLight;
      case OumiRole.hospital: return OumiColors.soft;
      default: return OumiColors.soft;
    }
  }
}
