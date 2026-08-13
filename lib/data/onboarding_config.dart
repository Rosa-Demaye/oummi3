import 'package:flutter/material.dart';

// --- Role Enum ---
enum OumiRole { girl, pregnant, father, doctor, hospital }

// --- Role Palette (colors per role, from your approved palette) ---
class RolePalette {
  final Color background;
  final Color primary; // CTA button / main accent
  final Color secondary; // supportive elements
  final Color textPrimary;
  final Color textSecondary;

  const RolePalette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
  });
}

// --- Map Role → Palette ---
class OnboardingConfig {
  // Young Girl: Rose doux, Lavande, Blanc, Bleu clair
  static const RolePalette girl = RolePalette(
    background: Color(0xFFF8DCE6), // Rose Clair
    primary: Color(0xFFE986A7),    // OUMI Rose
    secondary: Color(0xFF8E7CC3),  // Violet
    textPrimary: Color(0xFF263238), // noir doux
    textSecondary: Color(0xFF6B7280), // gris texte
  );

  // Pregnant: Rouge passionné, blanc, bleu clair
  static const RolePalette pregnant = RolePalette(
    background: Color(0xFFFFF0F0), // léger rouge/blanc
    primary: Color(0xFFE53935),    // Rouge Urgence (or use a soft red)
    secondary: Color(0xFF4A90E2),  // Bleu Santé
    textPrimary: Color(0xFF263238),
    textSecondary: Color(0xFF6B7280),
  );

  // Father/Husband: Bleu ciel, blanc, vert clair
  static const RolePalette father = RolePalette(
    background: Color(0xFFEAF4FC), // Bleu Très Clair
    primary: Color(0xFF4A90E2),    // Bleu Santé
    secondary: Color(0xFF4CAF50),  // Vert Santé
    textPrimary: Color(0xFF263238),
    textSecondary: Color(0xFF6B7280),
  );

  // Doctor: Bleu nuit, blanc, gris médical
  static const RolePalette doctor = RolePalette(
    background: Color(0xFFE9EFF5), // fond médecin
    primary: Color(0xFF4A90E2),    // Bleu Santé
    secondary: Color(0xFFB0BEC5),  // gris médical léger
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF6B7280),
  );

  // Hospital: Vert santé, blanc, gris
  static const RolePalette hospital = RolePalette(
    background: Color(0xFFE8F5E9), // vert très clair
    primary: Color(0xFF4CAF50),    // Vert Santé
    secondary: Color(0xFF7CB34A),  // vert plus foncé
    textPrimary: Color(0xFF263238),
    textSecondary: Color(0xFF6B7280),
  );

  // --- Get palette by role ---
  static RolePalette getPaletteForRole(OumiRole role) {
    switch (role) {
      case OumiRole.girl: return girl;
      case OumiRole.pregnant: return pregnant;
      case OumiRole.father: return father;
      case OumiRole.doctor: return doctor;
      case OumiRole.hospital: return hospital;
    }
    return girl; // fallback
  }

  // --- Screen data per role (copy, illustration path, button text) ---
  static List<OnboardingPageData> getPagesForRole(OumiRole role) {
    switch (role) {
      case OumiRole.girl: return _girlPages;
      case OumiRole.pregnant: return _pregnantPages;
      case OumiRole.father: return _fatherPages;
      case OumiRole.doctor: return _doctorPages;
      case OumiRole.hospital: return _hospitalPages;
    }
    return _girlPages;
  }

  // ==================== GIRL PAGES ====================
  static final List<OnboardingPageData> _girlPages = [
    OnboardingPageData(
      title: 'Bienvenue dans OUMI 🌸',
      body: 'Ton corps évolue chaque jour, et tu mérites de mieux le comprendre.\nOUMI t\'accompagne pour suivre ton cycle, comprendre les changements de ton corps et prendre soin de ta santé en toute confidentialité.',
      illustration: 'assets/illustrations/girl_cycle.png',
      buttonText: 'Commencer mon parcours',
    ),
    OnboardingPageData(
      title: 'Ton cycle, expliqué simplement',
      body: '❤️ tes prochaines règles\n🌸 ta période fertile\n😊 tes symptômes\n📅 des rappels personnalisés\nTu n\'aura plus besoin de compter les jours.',
      illustration: 'assets/illustrations/girl_calendar.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Tu n\'es jamais seule',
      body: 'Pose tes questions anonymement.\nDiscute avec d\'autres jeunes filles.\nReçois des conseils de professionnels vérifiés.\nEn français ou en arabe tchadien.',
      illustration: 'assets/illustrations/girl_chat.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Prends soin de toi dès aujourd\'hui',
      body: 'Chaque étape compte.\nChaque cycle raconte une histoire.\nOUMI est là pour t\'accompagner.',
      illustration: '', // Added empty illustration to fix constructor error
      buttonText: 'Commencer mon parcours',
    ),
  ];

  // ==================== PREGNANT PAGES ====================
  static final List<OnboardingPageData> _pregnantPages = [
    OnboardingPageData(
      title: 'Bienvenue Maman ❤️',
      body: 'Chaque grossesse est unique.\nChaque maman mérite un accompagnement sûr, humain et personnalisé.\nAvec OUMI, tu n\'es jamais seule.',
      illustration: 'assets/illustrations/pregnant_heart.png',
      buttonText: 'Commencer mon suivi',
    ),
    OnboardingPageData(
      title: 'Nous suivons ta grossesse avec toi',
      body: 'Chaque semaine tu découvriras :\n👶 le développement de ton bébé\n🩺 des conseils adaptés\n🍎 ton alimentation\n💊 tes vitamines\n📅 tes rendez-vous',
      illustration: 'assets/illustrations/pregnant_week.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Nous veillons sur ta santé',
      body: 'Grâce à des questionnaires intelligents,\nOUMI peut détecter les premiers signes de risque.\nEn cas d\'urgence,\nnous t\'aiderons à contacter rapidement un professionnel de santé.',
      illustration: 'assets/illustrations/pregnant_alert.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Une maternité plus sereine',
      body: '✔ Téléconsultation\n✔ Médecins vérifiés\n✔ Hôpitaux certifiés\n✔ Carnet numérique sécurisé\n✔ Alertes personnalisées\n✔ Assistance vocale',
      illustration: 'assets/illustrations/pregnant_check.png',
      buttonText: 'Commencer mon suivi',
    ),
  ];

  // ==================== FATHER PAGES ====================
  static final List<OnboardingPageData> _fatherPages = [
    OnboardingPageData(
      title: 'Être papa commence avant la naissance',
      body: 'Votre soutien peut faire toute la différence.\nAvec OUMI, vous accompagnez votre famille à chaque étape.',
      illustration: 'assets/illustrations/father_family.png',
      buttonText: 'Accompagner ma famille',
    ),
    OnboardingPageData(
      title: 'Suivez la grossesse avec votre partenaire',
      body: 'Recevez :\n📅 les rendez-vous\n👶 les étapes du bébé\n🚨 les alertes importantes\n💬 les recommandations médicales',
      illustration: 'assets/illustrations/father_appointments.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Soyez présent au bon moment',
      body: 'Préparez l\'accouchement.\nSuivez les urgences.\nContactez rapidement les médecins.\nRecevez des conseils adaptés aux futurs papas.',
      illustration: 'assets/illustrations/father_ready.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Une maman soutenue est une maman plus sereine',
      body: 'Bienvenue parmi les papas OUMI.',
      illustration: '', // Added empty illustration to fix constructor error
      buttonText: 'Accompagner ma famille',
    ),
  ];

  // ==================== DOCTOR PAGES ====================
  static final List<OnboardingPageData> _doctorPages = [
    OnboardingPageData(
      title: 'Bienvenue Docteur',
      body: 'OUMI est conçue pour simplifier votre pratique médicale.',
      illustration: 'assets/illustrations/doctor_stethoscope.png',
      buttonText: 'Accéder à mon espace médecin',
    ),
    OnboardingPageData(
      title: 'Gérez vos consultations intelligemment',
      body: '📅 Agenda\n💻 Téléconsultation\n📄 Ordonnances numériques\n📋 Dossiers patients\nNotifications automatiques',
      illustration: 'assets/illustrations/doctor_dashboard.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Moins d\'attente.\nPlus de temps pour soigner.',
      body: 'Les rendez-vous sont organisés.\nLes urgences sont prioritaires.\nLes paiements sont sécurisés.',
      illustration: 'assets/illustrations/doctor_time.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Une plateforme qui valorise votre expertise',
      body: 'Profil vérifié\nNotation\nStatistiques\nHistorique\nRevenus',
      illustration: 'assets/illustrations/doctor_expertise.png',
      buttonText: 'Accéder à mon espace médecin',
    ),
  ];

  // ==================== HOSPITAL PAGES ====================
  static final List<OnboardingPageData> _hospitalPages = [
    OnboardingPageData(
      title: 'Bienvenue dans OUMI Hospital',
      body: 'Une plateforme pensée pour moderniser la gestion des soins maternels.',
      illustration: 'assets/illustrations/hospital_building.png',
      buttonText: 'Accéder à l\'espace Hôpital',
    ),
    OnboardingPageData(
      title: 'Centralisez vos services',
      body: 'Gestion des patientes\nGestion des médecins\nSalles d\'accouchement\nUrgences\nConsultations\nTéléconsultations',
      illustration: 'assets/illustrations/hospital_services.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Anticipez les urgences',
      body: 'Recevez les signalements d\'accouchement.\nPréparez les équipes.\nRéservez les salles.\nOrganisez les ambulances.',
      illustration: 'assets/illustrations/hospital_urgency.png',
      buttonText: 'Suivant',
    ),
    OnboardingPageData(
      title: 'Décidez grâce aux données',
      body: 'Tableaux de bord\nStatistiques\nNaissances\nMortalité\nConsultations\nPrévisions\nRapports',
      illustration: 'assets/illustrations/hospital_data.png',
      buttonText: 'Accéder à l\'espace Hôpital',
    ),
  ];
}

// --- Data class ---
class OnboardingPageData {
  final String title;
  final String body;
  final String illustration;
  final String? buttonText;

  OnboardingPageData({
    required this.title,
    required this.body,
    required this.illustration,
    this.buttonText,
  });
}
