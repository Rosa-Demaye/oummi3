import 'package:flutter/material.dart';
import 'package:oummi3/data/onboarding_config.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  // Navigate to onboarding with role
  void _selectRole(BuildContext context, OumiRole role) {
    // In a real app, you might store this in SharedPreferences/Firestore
    context.go('/onboarding/${role.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient using OUMI Rose + Violet
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE986A7), Color(0xFF8E7CC3)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'OUMI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Role Cards
                  _RoleCard(
                    icon: Icons.person_outline,
                    title: '👧 Jeune Fille',
                    subtitle: 'De 15 à 25 ans',
                    color: OnboardingConfig.girl.primary,
                    onTap: () => _selectRole(context, OumiRole.girl),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.monitor_heart,
                    title: '🤰 Femme Enceinte',
                    subtitle: 'De 0 à 9 mois',
                    color: OnboardingConfig.pregnant.primary,
                    onTap: () => _selectRole(context, OumiRole.pregnant),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.family_restroom, // Fixed: Icons.father_of_family does not exist
                    title: '👨 Mari / Père',
                    subtitle: 'Soutien familial',
                    color: OnboardingConfig.father.primary,
                    onTap: () => _selectRole(context, OumiRole.father),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.local_hospital,
                    title: '👨‍⚕️ Médecin',
                    subtitle: 'Santé maternelle',
                    color: OnboardingConfig.doctor.primary,
                    onTap: () => _selectRole(context, OumiRole.doctor),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.apartment, // Changed from Icons.build to better represent a Hospital
                    title: '🏥 Hôpital',
                    subtitle: 'Gestion des soins',
                    color: OnboardingConfig.hospital.primary,
                    onTap: () => _selectRole(context, OumiRole.hospital),
                  ),
                  const Spacer(),
                  // Footer quote
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        '"Chaque mère mérite une grossesse en toute sécurité."',
                        style: TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
