import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/features/auth/presentation/login_screen.dart';
import 'package:oummi3/features/auth/presentation/profile_setup_screen.dart';
import 'package:oummi3/features/auth/presentation/profile_screen.dart';
import 'package:oummi3/features/auth/presentation/qr_scanner_screen.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';
import 'package:oummi3/presentation/onboarding/role_selection_screen.dart';
import 'package:oummi3/features/home/presentation/home_screen.dart';
import 'package:oummi3/features/doctor/presentation/doctor_dashboard.dart';
import 'package:oummi3/features/father/presentation/father_dashboard.dart';
import 'package:oummi3/features/hospital/presentation/hospital_dashboard.dart';
import 'package:oummi3/features/admin/presentation/admin_dashboard.dart';
import 'package:oummi3/shared/models/user_model.dart';
import 'package:oummi3/core/router/go_router_guard.dart';
import 'package:oummi3/core/router/role_guard.dart';

import 'package:oummi3/presentation/screens/splash_screen.dart';
import 'package:oummi3/presentation/onboarding/role_onboarding_screen.dart';
import 'package:oummi3/features/auth/presentation/registration_view.dart';
import 'package:oummi3/features/safety_network/presentation/screens/safety_alert_screen.dart';
import 'package:oummi3/features/hospital/presentation/screens/hospital_map_screen.dart';
import 'package:oummi3/features/teleconsultation/presentation/screens/teleconsultation_booking_screen.dart';
import 'package:oummi3/features/teleconsultation/presentation/screens/payment_screen.dart';
import 'package:oummi3/features/doctor/presentation/doctor_validation_screen.dart';
import 'package:oummi3/presentation/dashboard/woman_dashboard.dart';
import 'package:oummi3/presentation/dashboard/widgets/medical_record_view.dart';

import 'package:oummi3/presentation/onboarding/welcome_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final notifier = ref.watch(routerNotifierProvider);
  final guard = OumiGoRouterGuard(userRepo);

  CustomTransitionPage _fadeTransition(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => guard.redirect(context, state),
    routes: [
      // 🔹 1. Root / Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => _fadeTransition(const WelcomeScreen(), state),
      ),

      // 🔹 2. Authentication
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => _fadeTransition(const LoginSignUpScreen(), state),
      ),

      // 🔹 3. Role Selection & Registration
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        pageBuilder: (context, state) => _fadeTransition(const RoleSelectionScreen(), state),
      ),
      // Alias for backwards compatibility or specific onboarding flow
      GoRoute(
        path: '/onboarding/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/registration/:role',
        name: 'registration',
        builder: (context, state) {
          final roleName = state.pathParameters['role'];
          final role = OumiRole.values.firstWhere(
            (r) => r.name == roleName,
            orElse: () => OumiRole.girl,
          );
          return RegistrationView(role: role);
        },
      ),

      // 🔹 4. Profile & Onboarding
      GoRoute(
        path: '/profile-setup/:role',
        name: 'profile-setup',
        builder: (context, state) {
          final roleName = state.pathParameters['role'];
          final role = OumiRole.values.firstWhere(
            (r) => r.name == roleName,
            orElse: () => OumiRole.girl,
          );
          return ProfileSetupScreen(initialRole: role);
        },
      ),
      GoRoute(
        path: '/onboarding/:role',
        name: 'onboarding',
        builder: (context, state) {
          final roleName = state.pathParameters['role'];
          final role = OumiRole.values.firstWhere(
            (r) => r.name == roleName,
            orElse: () => OumiRole.girl,
          );
          return RoleOnboardingScreen(role: role);
        },
      ),

      // 🔹 5. Main App Shell (Role Isolated)
      ShellRoute(
        builder: (context, state, child) => RoleGuard(child: child),
        routes: [
          GoRoute(
            path: '/dashboard/:role',
            name: 'dashboard',
            pageBuilder: (context, state) {
              final role = state.pathParameters['role']!;
              return _fadeTransition(_roleDashboard(role), state);
            },
            routes: [
              GoRoute(
                path: 'home',
                name: 'home',
                builder: (context, state) {
                  final role = state.pathParameters['role']!;
                  return _roleDashboard(role);
                },
              ),
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'safety',
                name: 'safety',
                builder: (context, state) => const SafetyAlertScreen(),
              ),
              GoRoute(
                path: 'hospitals-map',
                name: 'hospitals-map',
                builder: (context, state) => const HospitalMapScreen(),
              ),
              GoRoute(
                path: 'teleconsultation',
                name: 'teleconsultation',
                builder: (context, state) => const TeleconsultationBookingScreen(),
              ),
              GoRoute(
                path: 'payment',
                name: 'payment',
                builder: (context, state) => const PaymentScreen(),
              ),
              GoRoute(
                path: 'medical-record',
                name: 'medical-record',
                builder: (context, state) => MedicalRecordView(onBack: () => context.pop()),
              ),
              GoRoute(
                path: 'validate-code',
                name: 'validate-code',
                builder: (context, state) => const DoctorValidationScreen(),
              ),
            ],
          ),
        ],
      ),

      // 🔹 6. Global Features
      GoRoute(
        path: '/qr-scanner',
        name: 'qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
    ],
  );
});

Widget _roleDashboard(String role) {
  switch (role) {
    case 'girl':
      return const WomanDashboard(role: OumiRole.girl);
    case 'pregnant':
      return const WomanDashboard(role: OumiRole.pregnant);
    case 'father':
      return const FatherDashboard();
    case 'doctor':
      return const DoctorDashboard();
    case 'hospital':
      return const HospitalDashboard();
    case 'admin':
      return const AdminDashboard();
    default:
      return HomeScreen(role: role);
  }
}
