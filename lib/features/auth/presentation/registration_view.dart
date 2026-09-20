import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/widgets/oumi_widgets.dart';
import 'package:oummi3/shared/models/user_model.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';
import 'package:oummi3/core/services/user_repository.dart';

/// ── Role‑specific field configurations ────────────────────────────────
final Map<OumiRole, List<Map<String, dynamic>>> roleFields = {
  OumiRole.girl: [
    {"label": "Nom complet", "key": "fullName", "type": "name", "required": true},
    {"label": "Date de naissance", "key": "dob", "type": "date", "required": true},
    {"label": "Nationalité", "key": "nationality", "type": "name", "required": true},
    {"label": "Langue", "key": "language", "type": "name", "required": true},
    {"label": "Région", "key": "region", "type": "name", "required": true},
    {"label": "Ville", "key": "city", "type": "name", "required": true},
    {"label": "Adresse", "key": "address", "type": "name", "required": true},
    {"label": "Statut menstruel", "key": "menstrualStatus", "type": "name", "required": true},
    {"label": "Longueur de cycle moyenne", "key": "cycleLength", "type": "number", "required": true},
    {"label": "Dernière règles", "key": "lastPeriod", "type": "date", "required": true},
    {"label": "Groupe sanguin (optionnel)", "key": "bloodGroup", "type": "name", "required": false},
    {"label": "Contact urgent", "key": "emergencyContact", "type": "phone", "required": true},
    {"label": "Relation contact urgent", "key": "emergencyRelation", "type": "name", "required": true},
  ],
  OumiRole.pregnant: [
    {"label": "Nom complet", "key": "fullName", "type": "name", "required": true},
    {"label": "Date de naissance", "key": "dob", "type": "date", "required": true},
    {"label": "Nationalité", "key": "nationality", "type": "name", "required": true},
    {"label": "Langue", "key": "language", "type": "name", "required": true},
    {"label": "Région", "key": "region", "type": "name", "required": true},
    {"label": "Ville", "key": "city", "type": "name", "required": true},
    {"label": "Adresse", "key": "address", "type": "name", "required": true},
    {"label": "Date d'accouchement prévue", "key": "dueDate", "type": "date", "required": true},
    {"label": "Semaine de grossesse actuelle", "key": "pregnancyWeek", "type": "number", "required": true},
    {"label": "Nombre de grossesses précédentes", "key": "prevPregnancies", "type": "number", "required": true},
    {"label": "Accouchement césarien précédent?", "key": "previousCSection", "type": "boolean", "required": true},
    {"label": "Nom du partenaire (maris)", "key": "partnerName", "type": "name", "required": true},
    {"label": "Téléphone du partenaire", "key": "partnerPhone", "type": "phone", "required": true},
    {"label": "Hôpital préféré", "key": "preferredHospital", "type": "name", "required": true},
    {"label": "Contact urgent", "key": "emergencyContact", "type": "phone", "required": true},
    {"label": "Relation contact urgent", "key": "emergencyRelation", "type": "name", "required": true},
  ],
  OumiRole.father: [
    {"label": "Nom complet", "key": "fullName", "type": "name", "required": true},
    {"label": "Profession", "key": "occupation", "type": "name", "required": true},
    {"label": "Code partenaire (QR/ID)", "key": "partnerCode", "type": "name", "required": true},
    {"label": "Relation partenaire", "key": "partnerRelation", "type": "name", "required": true},
    {"label": "Type de relation (Mari, Gardien, Autre)", "key": "relationType", "type": "name", "required": true},
  ],
  OumiRole.doctor: [
    {"label": "Nom complet", "key": "fullName", "type": "name", "required": true},
    {"label": "Numéro d'inscription médicale", "key": "medRegNumber", "type": "name", "required": true},
    {"label": "Licence médicale", "key": "medLicense", "type": "name", "required": true},
    {"label": "Hôpital", "key": "hospital", "type": "name", "required": true},
    {"label": "Spécialité", "key": "speciality", "type": "name", "required": true},
    {"label": "Années d'expérience", "key": "yearsExperience", "type": "number", "required": true},
    {"label": "Frais de consultation", "key": "consultationFee", "type": "number", "required": true},
  ],
  OumiRole.hospital: [
    {"label": "Nom de l'hôpital", "key": "hospitalName", "type": "name", "required": true},
    {"label": "Type d'hôpital", "key": "hospitalType", "type": "dropdown", "options": "hospital_type", "required": true},
    {"label": "Région", "key": "region", "type": "name", "required": true},
    {"label": "Licence hôpital", "key": "hospitalLicense", "type": "name", "required": true},
    {"label": "Administrateur", "key": "adminName", "type": "name", "required": true},
    {"label": "Nombre de lits", "key": "beds", "type": "number", "required": true},
    {"label": "Nombre de médecins", "key": "doctorsCount", "type": "number", "required": true},
    {"label": "Urgences disponibles ?", "key": "emergencyAvailable", "type": "boolean", "required": true},
  ],
};

class RegistrationView extends ConsumerStatefulWidget {
  final OumiRole role;
  const RegistrationView({required this.role, super.key});

  @override
  ConsumerState<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends ConsumerState<RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late List<Map<String, dynamic>> _fields;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fields = roleFields[widget.role] ?? [];
    _controllers = {};
    for (var f in _fields) {
      _controllers[f['key'] as String] = TextEditingController();
    }
    
    // Auth controllers
    _controllers['email'] = TextEditingController();
    _controllers['password'] = TextEditingController();
    _controllers['confirmPassword'] = TextEditingController();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSocialSignIn(String provider) async {
    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      if (provider == 'google') {
        await userRepo.signInWithGoogle();
      } else if (provider == 'apple') {
        await userRepo.signInWithApple();
      }
      
      final firebaseUser = userRepo.firebaseUser;
      if (firebaseUser != null && firebaseUser.email != null) {
        _controllers['email']!.text = firebaseUser.email!;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion réussie. Veuillez compléter votre profil.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: OumiColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userRepo = ref.read(userRepositoryProvider);
    final isSocialLogin = userRepo.firebaseUser != null;

    if (!isSocialLogin) {
      if (_controllers['password']!.text != _controllers['confirmPassword']!.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: OumiColors.red),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final formData = <String, dynamic>{};
    _controllers.forEach((key, ctrl) {
      formData[key] = ctrl.text;
    });

    try {
      String? uid;
      if (!isSocialLogin) {
        final cred = await userRepo.signUpWithEmail(formData['email'], formData['password']);
        uid = cred.user!.uid;
      } else {
        uid = userRepo.firebaseUser!.uid;
      }

      final profile = OumiUser(
        uid: uid,
        email: formData['email'],
        role: widget.role,
        fullName: formData['fullName'] ?? formData['hospitalName'] ?? '',
        phone: formData['phone'] ?? '',
        region: formData['region'] ?? '',
        city: formData['city'] ?? '',
        onboardingComplete: false,
        metadata: formData,
      );

      await userRepo.setUserRole(widget.role.name);
      await userRepo.updateUserProfile(profile);

      if (mounted) {
        context.go('/onboarding/${widget.role.name}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: OumiColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.watch(userRepositoryProvider);
    final isSocialLogin = userRepo.firebaseUser != null;

    return Scaffold(
      backgroundColor: OumiColors.background,
      appBar: AppBar(
        title: Text("Inscription - ${widget.role.roleDisplayName}", style: OumiTypography.h3.copyWith(color: Colors.white)),
        backgroundColor: OumiColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: OumiColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isSocialLogin) ...[
                      Text("S'inscrire avec", style: OumiTypography.label),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_"G"_Logo.svg', height: 18, errorBuilder: (c,e,s) => const Icon(Icons.login)),
                              label: "Google",
                              onPressed: () => _handleSocialSignIn('google'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSocialButton(
                              icon: const Icon(Icons.apple, size: 18),
                              label: "Apple",
                              onPressed: () => _handleSocialSignIn('apple'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const _DividerWithText(text: "OU"),
                      const SizedBox(height: 32),
                      Text("Créez votre compte", style: OumiTypography.h2),
                      const SizedBox(height: 16),
                      _buildInputField('email', 'Email', TextInputType.emailAddress),
                      _buildInputField('password', 'Mot de passe', TextInputType.visiblePassword, isPassword: true),
                      _buildInputField('confirmPassword', 'Répéter le mot de passe', TextInputType.visiblePassword, isPassword: true),
                    ] else ...[
                      _buildSocialSuccessCard(userRepo),
                    ],
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: OumiColors.border),
                    ),
                    
                    Text("Complétez votre profil", style: OumiTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      "Ces informations nous aident à personnaliser votre accompagnement.",
                      style: OumiTypography.bodySmall,
                    ),
                    const SizedBox(height: 24),

                    // Role-Specific Fields
                    ..._fields.map((f) => _buildDynamicField(f)),
                    
                    const SizedBox(height: 32),
                    OumiButton(
                      label: "Finaliser l'inscription",
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSocialButton({required Widget icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: OumiColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: OumiColors.text,
      ),
    );
  }

  Widget _buildSocialSuccessCard(UserRepository userRepo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OumiColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OumiColors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: OumiColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Connecté : ${userRepo.firebaseUser?.email ?? 'Compte Social'}",
              style: OumiTypography.label.copyWith(color: OumiColors.green),
            ),
          ),
          TextButton(
            onPressed: () => userRepo.signOut(),
            child: Text("Changer", style: TextStyle(color: OumiColors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String key, String label, TextInputType type, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OumiTypography.label.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _controllers[key],
            obscureText: isObscure(key, isPassword),
            keyboardType: type,
            decoration: InputDecoration(
              hintText: "Entrez votre $label",
              suffixIcon: isPassword ? IconButton(
                icon: Icon(passwordVisible(key) ? Icons.visibility_off : Icons.visibility, color: OumiColors.textMuted),
                onPressed: () => togglePassword(key),
              ) : null,
            ),
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
        ],
      ),
    );
  }

  // Password visibility management
  final Map<String, bool> _passwordVisibility = {};
  bool isObscure(String key, bool def) => _passwordVisibility[key] ?? def;
  bool passwordVisible(String key) => !(_passwordVisibility[key] ?? true);
  void togglePassword(String key) => setState(() => _passwordVisibility[key] = !(_passwordVisibility[key] ?? true));

  Widget _buildDynamicField(Map<String, dynamic> f) {
    final key = f['key'] as String;
    final label = f['label'] as String;
    final type = f['type'] as String;
    final required = f['required'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OumiTypography.label.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          _buildInputWidget(type, key, label, required, f),
        ],
      ),
    );
  }

  Widget _buildInputWidget(String type, String key, String label, bool required, Map<String, dynamic> f) {
    switch (type) {
      case 'name':
      case 'phone':
      case 'number':
      case 'date':
        return TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(hintText: "Entrez $label"),
          keyboardType: type == 'number' ? TextInputType.number : (type == 'phone' ? TextInputType.phone : TextInputType.text),
          validator: required ? (val) => val!.isEmpty ? "Requis" : null : null,
        );
      case 'boolean':
        return SwitchListTile(
          title: Text(label, style: OumiTypography.body),
          value: _controllers[key]?.text == "true",
          onChanged: (val) => setState(() => _controllers[key]!.text = val ? "true" : "false"),
          activeColor: OumiColors.primary,
          contentPadding: EdgeInsets.zero,
        );
      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: _controllers[key]?.text.isNotEmpty == true ? _controllers[key]!.text : null,
          decoration: const InputDecoration(),
          items: ["Option 1", "Option 2"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _controllers[key]!.text = val ?? ""),
        );
      default: return const SizedBox.shrink();
    }
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: OumiColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: OumiTypography.bodySmall),
        ),
        const Expanded(child: Divider(color: OumiColors.border)),
      ],
    );
  }
}
