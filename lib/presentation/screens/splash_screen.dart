import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';
import 'package:oummi3/main.dart';
import 'package:oummi3/core/emergency/emergency_service.dart';
import 'package:oummi3/shared/models/user_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      
      // Sequence d'initialisation
      await userRepo.initialise();
      await globalSyncService.init();
      
      // Init Emergency Service (Safe for web)
      try {
        await EmergencyService().init();
      } catch (e) {
        debugPrint('Emergency Service Init Error: $e');
      }

      // On attend un peu pour montrer la belle animation (min 2.5s)
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return;

      final firebaseUser = userRepo.firebaseUser;
      if (firebaseUser == null) {
        context.go('/welcome'); // Vers Welcome
        return;
      }

      await userRepo.refreshCurrentUser();
      final profile = userRepo.currentUser;

      if (profile == null) {
        context.go('/welcome');
        return;
      }

      final String userRole = profile.role.name;
      if (userRepo.needOnboarding && profile.role != OumiRole.girl) {
        context.go('/onboarding/$userRole');
      } else {
        context.go('/dashboard/$userRole/home');
      }
    } catch (e) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OumiColors.primaryDark,
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: OumiColors.primary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: OumiColors.primaryGradient,
                            borderRadius: BorderRadius.circular(OumiRadius.extraLarge),
                            boxShadow: [
                              BoxShadow(
                                color: OumiColors.primary.withValues(alpha: 0.5),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'O',
                              style: OumiTypography.display.copyWith(
                                color: Colors.white,
                                fontSize: 46,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'OUMI',
                  style: OumiTypography.display.copyWith(
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre santé. Votre grossesse.\nVotre communauté.',
                  textAlign: TextAlign.center,
                  style: OumiTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Tchad Flag / Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Fait au Tchad 🇹🇩',
                style: OumiTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
