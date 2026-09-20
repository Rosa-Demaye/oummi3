import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:oummi3/shared/models/user_model.dart';

/// A single step in a role onboarding flow.
class OnboardingStep {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color accentColor;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.accentColor,
  });
}

/// Holds the "Start" button text for the last step of each role.
final Map<OumiRole, String> _roleStartButtonTexts = {
  OumiRole.girl: 'Commencer mon parcours',
  OumiRole.pregnant: 'Commencer mon suivi',
  OumiRole.father: 'Accompagner ma famille',
  OumiRole.doctor: 'Accéder à mon espace médecin',
  OumiRole.hospital: "Accéder à l'espace Hôpital",
};

/// Configurable onboarding steps per role.
final Map<OumiRole, List<OnboardingStep>> _roleOnboardingConfigs = {
  OumiRole.girl: [
    OnboardingStep(
      title: 'Bienvenue dans OUMI 🌸',
      subtitle:
          'Ton corps évolue chaque jour, et tu mérites de mieux le comprendre.\n'
          'OUMI t\'accompagne pour suivre ton cycle, comprendre les changements de ton corps et prendre soin de ta santé en toute confidentialité.',
      backgroundColor: const Color(0xFFF8DCE6), // Rose Clair
      accentColor: const Color(0xFFE986A7),   // OUMI Rose
    ),
    OnboardingStep(
      title: 'Ton cycle, expliqué simplement',
      subtitle:
          '❤️ tes prochaines règles\n'
          '🌸 ta période fertile\n'
          '😊 tes symptômes\n'
          '📅 des rappels personnalisés\n'
          'Tu n\'auras plus besoin de compter les jours.',
      backgroundColor: const Color(0xFFF8DCE6),
      accentColor: const Color(0xFFE986A7),
    ),
    OnboardingStep(
      title: "Tu n'es jamais seule",
      subtitle:
          'Pose tes questions anonymement.\n'
          'Discute avec d\'autres jeunes filles.\n'
          'Reçois des conseils de professionnels vérifiés.\n'
          'En français ou en arabe tchadien.',
      backgroundColor: const Color(0xFFF8DCE6),
      accentColor: const Color(0xFFE986A7),
    ),
    OnboardingStep(
      title: 'Prends soin de toi dès aujourd\'hui',
      subtitle:
          'Chaque étape compte.\n'
          'Chaque cycle raconte une histoire.\n'
          'OUMI est là pour t\'accompagner.',
      backgroundColor: const Color(0xFFF8DCE6),
      accentColor: const Color(0xFFE986A7),
    ),
  ],

  OumiRole.pregnant: [
    OnboardingStep(
      title: 'Bienvenue Maman ❤️',
      subtitle:
          'Chaque grossesse est unique.\n'
          'Chaque maman mérite un accompagnement sûr, humain et personnalisé.\n'
          'Avec OUMI, tu n\'es jamais seule.',
      backgroundColor: const Color(0xFFEAF4FC), // Bleu Très Clair
      accentColor: const Color(0xFF4A90E2),   // Bleu Santé
    ),
    OnboardingStep(
      title: 'Nous suivons ta grossesse avec toi',
      subtitle:
          'Chaque semaine tu découvriras :\n'
          '👶 le développement de ton bébé\n'
          '🩺 des conseils adaptés\n'
          '🍎 ton alimentation\n'
          '💊 tes vitamines\n'
          '📅 tes rendez-vous',
      backgroundColor: const Color(0xFFEAF4FC),
      accentColor: const Color(0xFF4A90E2),
    ),
    OnboardingStep(
      title: 'Nous veillons sur ta santé',
      subtitle:
          'Grâce à des questionnaires intelligents,\n'
          'OUMI peut détecter les premiers signes de risque.\n'
          'En cas d\'urgence,\n'
          'nous t\'aiderons à contacter rapidement un professionnel de santé.',
      backgroundColor: const Color(0xFFEAF4FC),
      accentColor: const Color(0xFF4A90E2),
    ),
    OnboardingStep(
      title: 'Une maternité plus sereine',
      subtitle:
          '✔ Téléconsultation\n'
          '✔ Médecins vérifiés\n'
          '✔ Hôpitaux certifiés\n'
          '✔ Carnet numérique sécurisé\n'
          '✔ Alertes personnalisées\n'
          '✔ Assistance vocale',
      backgroundColor: const Color(0xFFEAF4FC),
      accentColor: const Color(0xFF4A90E2),
    ),
    OnboardingStep(
      title: 'Nous prendrons soin de vous',
      subtitle:
          'Jusqu\'à la naissance de votre bébé.\n'
          'Bienvenue dans la famille OUMI ❤️',
      backgroundColor: const Color(0xFFEAF4FC),
      accentColor: const Color(0xFF4A90E2),
    ),
  ],

  OumiRole.father: [
    OnboardingStep(
      title: 'Être papa commence avant la naissance.',
      subtitle:
          'Votre soutien peut faire toute la différence.\n'
          'Avec OUMI, vous accompagnez votre famille à chaque étape.',
      backgroundColor: const Color(0xFFF0F0FF), // très clair violet
      accentColor: const Color(0xFF8E7CC3),   // Violet OUMI
    ),
    OnboardingStep(
      title: 'Suivez la grossesse avec votre partenaire',
      subtitle:
          'Recevez :\n'
          '📅 les rendez‑vous\n'
          '👶 les étapes du bébé\n'
          '🚨 les alertes importantes\n'
          '💬 les recommandations médicales',
      backgroundColor: const Color(0xFFF0F0FF),
      accentColor: const Color(0xFF8E7CC3),
    ),
    OnboardingStep(
      title: 'Soyez présent au bon moment',
      subtitle:
          'Préparez l\'accouchement.\n'
          'Suivez les urgences.\n'
          'Contactez rapidement les médecins.\n'
          'Recevez des conseils adaptés aux futurs papas.',
      backgroundColor: const Color(0xFFF0F0FF),
      accentColor: const Color(0xFF8E7CC3),
    ),
    OnboardingStep(
      title: 'Une maman soutenue',
      subtitle: 'Bienvenue parmi les papas OUMI.',
      backgroundColor: const Color(0xFFF0F0FF),
      accentColor: const Color(0xFF8E7CC3),
    ),
  ],

  OumiRole.doctor: [
    OnboardingStep(
      title: 'Bienvenue Docteur.',
      subtitle: 'OUMI est conçue pour simplifier votre pratique médicale.',
      backgroundColor: const Color(0xFFF0FFF4), // très clair vert
      accentColor: const Color(0xFF4CAF50),   // Vert Santé
    ),
    OnboardingStep(
      title: 'Gérez vos consultations intelligemment',
      subtitle:
          '📅 Agenda\n'
          '💻 Téléconsultation\n'
          '📄 Ordonnances numériques\n'
          '📋 Dossiers patients\n'
          'Notifications automatiques',
      backgroundColor: const Color(0xFFF0FFF4),
      accentColor: const Color(0xFF4CAF50),
    ),
    OnboardingStep(
      title: 'Moins d\'attente.',
      subtitle:
          'Plus de temps pour soigner.\n'
          'Les rendez‑vous sont organisés.\n'
          'Les urgences sont prioritaires.\n'
          'Les paiements sont sécurisés.',
      backgroundColor: const Color(0xFFF0FFF4),
      accentColor: const Color(0xFF4CAF50),
    ),
    OnboardingStep(
      title: 'Une plateforme qui valorise votre expertise',
      subtitle:
          'Profil vérifié\n'
          'Notation\n'
          'Statistiques\n'
          'Historique\n'
          'Revenus',
      backgroundColor: const Color(0xFFF0FFF4),
      accentColor: const Color(0xFF4CAF50),
    ),
    OnboardingStep(
      title: 'Ensemble, améliorons la santé maternelle',
      subtitle: 'Au Tchad.',
      backgroundColor: const Color(0xFFF0FFF4),
      accentColor: const Color(0xFF4CAF50),
    ),
  ],

  OumiRole.hospital: [
    OnboardingStep(
      title: 'Bienvenue dans OUMI Hospital.',
      subtitle:
          'Une plateforme pensée pour moderniser la gestion des soins maternels.',
      backgroundColor: const Color(0xFFFDF2E9), // très clair pêche
      accentColor: const Color(0xFFD97D64),   // Peach / Corail
    ),
    OnboardingStep(
      title: 'Centralisez vos services',
      subtitle:
          'Gestion des patientes\n'
          'Gestion des médecins\n'
          'Salles d\'accouchement\n'
          'Urgences\n'
          'Consultations\n'
          'Téléconsultations',
      backgroundColor: const Color(0xFFFDF2E9),
      accentColor: const Color(0xFFD97D64),
    ),
    OnboardingStep(
      title: 'Anticipez les urgences',
      subtitle:
          'Recevez les signalements d\'accouchement.\n'
          'Préparez les équipes.\n'
          'Réservez les salles.\n'
          'Organisez les ambulances.',
      backgroundColor: const Color(0xFFFDF2E9),
      accentColor: const Color(0xFFD97D64),
    ),
    OnboardingStep(
      title: 'Décidez grâce aux données',
      subtitle:
          'Tableaux de bord\n'
          'Statistiques\n'
          'Naissances\n'
          'Mortalité\n'
          'Consultations\n'
          'Prévisions\n'
          'Rapports',
      backgroundColor: const Color(0xFFFDF2E9),
      accentColor: const Color(0xFFD97D64),
    ),
    OnboardingStep(
      title: 'Construisons ensemble',
      subtitle: 'Un système de santé plus performant.',
      backgroundColor: const Color(0xFFFDF2E9),
      accentColor: const Color(0xFFD97D64),
    ),
  ],
  OumiRole.admin: [
     OnboardingStep(
      title: 'Bienvenue Administrateur.',
      subtitle: 'Gérez la plateforme OUMI.',
      backgroundColor: const Color(0xFFF0FFF4),
      accentColor: const Color(0xFF4CAF50),
    ),
  ],
};

/// 🎯 High-Fidelity Persona-Based Onboarding Screen.
/// 
/// This widget uses the specific copy and palette approved for Oummi Chad.
/// It features:
/// - Smooth PageView transitions.
/// - Dynamic color mapping per role.
/// - Integrated state management with Riverpod and UserRepository.
class RoleOnboardingScreen extends ConsumerStatefulWidget {
  final OumiRole role;

  const RoleOnboardingScreen({
    required this.role,
    super.key,
  });

  @override
  ConsumerState<RoleOnboardingScreen> createState() => _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends ConsumerState<RoleOnboardingScreen> {
  late final List<OnboardingStep> _steps;
  late final Color _accentColor;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Load the steps and visual configuration based on the user's role.
    _steps = _roleOnboardingConfigs[widget.role] ?? _roleOnboardingConfigs[OumiRole.girl]!;
    _accentColor = _steps.first.accentColor;
  }

  /// Handles the "Suivant" button logic. 
  /// Either moves to the next page or triggers the final completion.
  void _nextStep() {
    if (_currentIndex < _steps.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  /// Redirects to profile setup. The actual profile completion happens 
  /// in the setup screen to ensure all mandatory data (Phone, Region) is captured.
  void _finishOnboarding() {
    if (mounted) {
      context.go('/profile-setup/${widget.role.name}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            itemBuilder: (context, index) => _buildStep(index),
          ),
          Positioned(
            bottom: 32.0,
            left: 24.0,
            right: 24.0,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Text(
                _currentIndex == _steps.length - 1
                    ? _roleStartButtonTexts[widget.role] ?? 'Commencer'
                    : 'Suivant',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int index) {
    final step = _steps[index];
    return Container(
      width: double.infinity,
      color: index.isEven ? step.backgroundColor : const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // 🎭 Animation Slot
          Center(
            child: Lottie.asset(
              'assets/animations/welcome.json',
              height: 200,
              repeat: true,
              errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200), // Fallback if file missing
            ),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            step.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
