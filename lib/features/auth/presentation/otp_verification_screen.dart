import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyAndProceed() async {
    final otpCode = _otpControllers.map((c) => c.text).join();

    if (otpCode.length != 6) {
      setState(() => _errorMessage = "Veuillez entrer le code complet");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final cred = await userRepo.signInWithOtpCredential(_currentVerificationId, otpCode);
      
      final user = cred.user;
      if (user != null) {
        // Initialiser l'utilisateur avec son numéro vérifié
        await userRepo.initializeUser(
          phoneNumber: widget.phoneNumber,
          onboardingStep: 'otp_verified',
        );

        if (mounted) {
          context.go('/role-selection');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Code invalide ou expiré";
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userRepositoryProvider).startPhoneVerification(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verId, forceToken) {
          setState(() {
            _currentVerificationId = verId;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nouveau code envoyé")),
          );
        },
        onError: (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: OumiColors.primary),
              const SizedBox(height: 24),
              Text(
                "Vérification du numéro",
                style: OumiTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Code envoyé au ${widget.phoneNumber}",
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpField(index)),
              ),

              const SizedBox(height: 32),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: OumiColors.red)),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _verifyAndProceed,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Vérifier"),
              ),
              
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: const Text("Renvoyer le code"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && value.isNotEmpty) {
            _verifyAndProceed();
          }
        },
      ),
    );
  }
}
