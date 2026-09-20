import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/services/user_repository.dart';
import 'package:oummi3/shared/models/user_model.dart';

/// A specialized guard for GoRouter that manages redirection based on:
/// 1. Authentication Status (Is the user logged in?)
/// 2. Role Persistence (Does the user have a profile and the correct role?)
/// 3. Onboarding Lifecycle (Has the user completed the persona-specific tutorial?)
class OumiGoRouterGuard {
  final UserRepository _repo;

  OumiGoRouterGuard(this._repo);

  /// The main redirect logic used by GoRouter. 
  /// Evaluated on every navigation attempt.
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final user = _repo.firebaseUser;
    final matchedLocation = state.matchedLocation;

    // ── 1. Authentication Gate ──────────────────────────────────────────
    // Autoriser le Splash, le Welcome, la Sélection de Rôle et l'Inscription sans Auth Firebase.
    if (user == null) {
      if (matchedLocation == '/' || matchedLocation == '/welcome' || matchedLocation == '/role-selection' || matchedLocation.startsWith('/registration')) {
        return null; 
      }
      return '/'; // Retour au Splash par défaut
    }

    // Try to fetch the full profile from Firestore or local cache.
    final profile = await _repo.getUserProfile(user.uid);

    // If a user exists but has no profile document, send them to pick a role.
    if (profile == null) {
      if (matchedLocation == '/role-selection' || matchedLocation.startsWith('/registration') || matchedLocation.startsWith('/profile-setup')) {
        return null;
      }
      return '/role-selection';
    }

    final String currentRole = profile.role.name;
    final bool onboardingDone = profile.onboardingComplete;

    // ── 2. Onboarding Lifecycle ─────────────────────────────────────────
    if (!onboardingDone && profile.role != OumiRole.girl) {
      // If onboarding is not complete, redirect to onboarding if they aren't already there.
      if (matchedLocation.startsWith('/onboarding') || matchedLocation.startsWith('/registration') || matchedLocation.startsWith('/profile-setup')) {
        return null;
      }
      return '/onboarding/$currentRole';
    }

    // ── 3. Dashboard Isolation ──────────────────────────────────────────
    // Ensures a user can only access the dashboard matching their stored role.
    if (matchedLocation.startsWith('/dashboard/')) {
      final targetRole = _extractRole(matchedLocation);
      if (targetRole != null && targetRole != currentRole) {
        // Mismatch detected: Redirect back to their assigned home.
        return '/dashboard/$currentRole/home';
      }
    }

    // ── 4. Prevent going back to setup screens if profile is complete ──
    if (onboardingDone && (matchedLocation == '/role-selection' || matchedLocation.startsWith('/registration') || matchedLocation.startsWith('/profile-setup'))) {
      return '/dashboard/$currentRole/home';
    }

    return null; // All checks passed, allow navigation.
  }

  /// Helper to extract the role identifier from a URL path.
  String? _extractRole(String location) {
    final RegExp exp = RegExp(r'^/(onboarding/|dashboard/)([^/]+)');
    final match = exp.firstMatch(location);
    if (match != null) {
      final potentialRole = match.group(2);
      if (OumiRole.values.any((r) => r.name == potentialRole)) {
        return potentialRole;
      }
    }
    return null;
  }
}
