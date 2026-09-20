import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

/// A Guard widget that sits inside a ShellRoute and decides whether the
/// user may stay on the current persona‑specific route or is sent back to
/// the onboarding / role‑selection flow.
class RoleGuard extends ConsumerWidget {
  /// The child widget that represents the role‑specific part of the app
  /// (e.g. CycleDashboard, PregnancyDashboard, …).
  final Widget child;
  const RoleGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -----------------------------------------------------------------
    // 1️⃣ Pull the current user profile from the provider
    // -----------------------------------------------------------------
    final userProfile = ref.watch(userProfileProvider).value;

    // -----------------------------------------------------------------
    // 2️⃣ Decision logic
    // -----------------------------------------------------------------
    if (userProfile == null) {
      // No profile found – we forward to role selection.
      // Using addPostFrameCallback ensures the navigation happens after the build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/role-selection');
        }
      });
      // Return a branded loading state while redirecting.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // -----------------------------------------------------------------
    // 3️⃣ User exists – check the onboarding flag
    // -----------------------------------------------------------------
    if (!userProfile.onboardingComplete) {
      // The user has an account but never finished onboarding.
      // Send them back to the role‑selection or registration flow.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/role-selection');
        }
      });
      return const Scaffold(
        body: Center(
          child: Text('Veuillez compléter votre profil.'),
        ),
      );
    }

    // -----------------------------------------------------------------
    // 4️⃣ Onboarding completed – allow access to the dashboard
    // -----------------------------------------------------------------
    return child;
  }
}
