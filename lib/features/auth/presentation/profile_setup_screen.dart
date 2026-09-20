import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';
import 'package:oummi3/shared/models/user_model.dart';
import 'dart:math';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final OumiRole initialRole;
  const ProfileSetupScreen({super.key, required this.initialRole});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late OumiRole _role;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _partnerPhoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  String? _bloodGroup;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complétez votre profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choisissez votre rôle', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<OumiRole>(
                value: _role,
                items: OumiRole.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name.toUpperCase()),
                )).toList(),
                onChanged: (val) => setState(() => _role = val!),
                decoration: const InputDecoration(filled: true),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom Complet'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Groupe Sanguin'),
                items: _bloodGroups.map((bg) => DropdownMenuItem(
                  value: bg,
                  child: Text(bg),
                )).toList(),
                onChanged: (val) => setState(() => _bloodGroup = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(labelText: 'Contact d\'Urgence'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(labelText: 'Région'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              if (_role == OumiRole.pregnant || _role == OumiRole.girl) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partnerPhoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone du partenaire (Optionnel)'),
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submit,
                style: OumiDecorations.primaryButton,
                child: const Text('Terminer l\'inscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      // Generate a unique QR identifier for the health record
      final qrId = 'OUMI-${_generateRandomString(8)}';
      final qrBackup = _generateRandomString(12);

      Map<String, dynamic> metadata = {};
      if (_role == OumiRole.pregnant) {
        // Placeholder metadata for pregnancy
        metadata = {
          'riskScore': 0.0,
          'gestationalWeek': 0,
        };
      }

      final profile = OumiUser(
        uid: user.uid,
        email: user.email,
        role: _role,
        fullName: _nameController.text,
        phone: _phoneController.text,
        region: _regionController.text,
        city: _cityController.text,
        partnerPhone: _partnerPhoneController.text.isNotEmpty ? _partnerPhoneController.text : null,
        bloodGroup: _bloodGroup,
        emergencyContact: _emergencyContactController.text,
        qrCode: qrId,
        qrBackup: qrBackup,
        createdAt: DateTime.now(),
        onboardingComplete: true,
        metadata: metadata,
      );

      try {
        await ref.read(userProfileProvider.notifier).completeOnboarding(profile);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: OumiColors.rougeUrgence),
        );
      }
    }
  }
}
