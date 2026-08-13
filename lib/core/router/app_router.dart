import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/features/auth/presentation/login_screen.dart';
import 'package:oummi3/presentation/onboarding/role_selection_screen.dart';
import 'package:oummi3/features/home/presentation/home_screen.dart';
import 'package:oummi3/features/pregnancy/presentation/pregnancy_screen.dart';
import 'package:oummi3/features/doctors/presentation/doctor_dashboard.dart';
import 'package:oummi3/features/fathers/presentation/father_dashboard.dart';
import 'package:oummi3/features/hospitals/presentation/hospital_dashboard.dart';

import 'package:oummi3/presentation/onboarding/onboarding_screen.dart';
import 'package:oummi3/data/onboarding_config.dart';
import 'package:oummi3/features/cycle_tracking/presentation/screens/cycle_dashboard.dart';
import 'package:oummi3/features/safety_network/presentation/screens/safety_alert_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/role-selection',
  redirect: (context, state) {
    // Basic auth guard placeholder
    // final isAuthenticated = _authService.currentUser != null;
    // if (!isAuthenticated && state.matchedLocation != '/auth') return '/auth';
    return null;
  },
  routes: [
    // Auth & Onboarding
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginSignUpScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding/:role',
      builder: (context, state) {
        final roleName = state.pathParameters['role'];
        final role = OumiRole.values.firstWhere(
          (r) => r.name == roleName,
          orElse: () => OumiRole.girl,
        );
        return OnboardingScreen(role: role);
      },
    ),
    
    // Role-specific dashboards
    GoRoute(
      path: '/home/:role',
      builder: (context, state) {
        final role = state.pathParameters['role']!;
        return _roleDashboard(role);
      },
    ),
    
    // Feature screens
    GoRoute(
      path: '/cycle',
      builder: (context, state) => const CycleDashboard(),
    ),
    GoRoute(
      path: '/pregnancy',
      builder: (context, state) => const PregnancyDashboard(),
    ),
    GoRoute(
      path: '/safety',
      builder: (context, state) => const SafetyAlertScreen(),
    ),
  ],
);

Widget _roleDashboard(String role) {
  switch (role) {
    case 'girl':
      return const CycleDashboard();
    case 'pregnant':
      return const PregnancyDashboard();
    case 'father':
      return const FatherDashboard();
    case 'doctor':
      return const DoctorDashboard();
    case 'hospital':
      return const HospitalDashboard();
    default:
      return HomeScreen(role: role);
  }
}
