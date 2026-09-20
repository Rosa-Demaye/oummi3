import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/widgets/oumi_widgets.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

class LoginSignUpScreen extends ConsumerStatefulWidget {
  const LoginSignUpScreen({super.key});

  @override
  ConsumerState<LoginSignUpScreen> createState() => _LoginSignUpScreenState();
}

class _LoginSignUpScreenState extends ConsumerState<LoginSignUpScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPhoneMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OumiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                onPressed: () => context.go('/welcome'),
                icon: const Icon(Icons.arrow_back, color: OumiColors.text),
                style: IconButton.styleFrom(
                  backgroundColor: OumiColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                _isPhoneMode ? 'Connexion' : 'Connexion par Email',
                style: OumiTypography.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                _isPhoneMode 
                    ? 'Entrez votre numéro pour recevoir un code de vérification'
                    : 'Entrez vos identifiants pour vous connecter',
                style: OumiTypography.body.copyWith(color: OumiColors.textMuted),
              ),
              
              const SizedBox(height: 32),
              
              if (_isPhoneMode) ...[
                _buildLabel('Numéro de téléphone'),
                _buildPhoneInput(),
                const SizedBox(height: 24),
                OumiButton(
                  label: 'Recevoir le code',
                  isLoading: _isLoading,
                  onPressed: _phoneController.text.length < 8 ? null : _sendOtp,
                ),
              ] else ...[
                _buildLabel('Email'),
                _buildTextField(_emailController, 'votre@email.com', false),
                const SizedBox(height: 16),
                _buildLabel('Mot de passe'),
                _buildTextField(_passwordController, '••••••••', true),
                const SizedBox(height: 24),
                OumiButton(
                  label: 'Se connecter',
                  isLoading: _isLoading,
                  onPressed: _handleEmailAuth,
                ),
              ],

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isPhoneMode = !_isPhoneMode;
                  }),
                  child: Text(
                    _isPhoneMode 
                        ? 'Utiliser l\'email plutôt' 
                        : 'Utiliser le téléphone plutôt',
                    style: OumiTypography.label.copyWith(color: OumiColors.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const _SocialDivider(),
              const SizedBox(height: 24),
              
              // Social Login Buttons
              _buildSocialButton(
                icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_"G"_Logo.svg', height: 22, errorBuilder: (c,e,s) => const Icon(Icons.login)),
                label: 'Continuer avec Google',
                onPressed: _handleGoogleSignIn,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                icon: const Icon(Icons.apple, size: 22, color: OumiColors.text),
                label: 'Continuer avec Apple',
                onPressed: () {},
              ),

              const SizedBox(height: 48),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: OumiTypography.bodySmall.copyWith(fontSize: 12),
                    children: [
                      const TextSpan(text: 'En continuant, vous acceptez nos '),
                      TextSpan(
                        text: 'Conditions',
                        style: TextStyle(color: OumiColors.primary, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' et '),
                      TextSpan(
                        text: 'Politique de confidentialité',
                        style: TextStyle(color: OumiColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: OumiTypography.label),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _phoneController.text.isNotEmpty ? OumiColors.primary : OumiColors.border,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: OumiColors.border)),
            ),
            child: Row(
              children: [
                const Text('🇹🇩', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('+235', style: OumiTypography.label.copyWith(fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              style: OumiTypography.bodyLarge.copyWith(letterSpacing: 1),
              decoration: const InputDecoration(
                hintText: 'XX XX XX XX',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isObscure) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }

  Widget _buildSocialButton({required Widget icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        foregroundColor: OumiColors.text,
        side: const BorderSide(color: OumiColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: OumiTypography.label.copyWith(fontSize: 14),
      ),
    );
  }

  Future<void> _sendOtp() async {
    // Business logic from original Login screen preserved
    setState(() => _isLoading = true);
    try {
      await ref.read(userRepositoryProvider).startPhoneVerification(
        phoneNumber: '+235${_phoneController.text.trim()}',
        onCodeSent: (verId, token) {
          setState(() => _isLoading = false);
          context.go('/otp-verification', extra: {
            'verificationId': verId,
            'phoneNumber': '+235${_phoneController.text.trim()}',
          });
        },
        onError: (e) {
          setState(() => _isLoading = false);
          _showError(e.message ?? 'Erreur');
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _handleEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userRepositoryProvider).signInWithEmail(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await ref.read(userRepositoryProvider).signInWithGoogle();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: OumiColors.red),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: OumiColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('ou continuer avec', style: OumiTypography.bodySmall.copyWith(fontSize: 12)),
        ),
        const Expanded(child: Divider(color: OumiColors.border)),
      ],
    );
  }
}
