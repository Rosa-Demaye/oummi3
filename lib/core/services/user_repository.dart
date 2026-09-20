import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:oummi3/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The primary service responsible for managing user state, authentication, 
/// and profile persistence in Firestore.
class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // ✅ REMPLACEZ CET ID par celui de votre console Firebase (Étape 1)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? "METTRE_VOTRE_ID_ICI.apps.googleusercontent.com" : null,
  );

  // ---------------------------------------------------
  // 🔐 Auth State & Current User Caching
  // ---------------------------------------------------
  OumiUser? _cachedUser;
  String? _cachedLastRole; // Tracks the role used during the last onboarding
  static const _lastOnboardingRoleKey = 'last_onboarding_role';

  /// Returns the currently cached profile (may be null if not loaded yet).
  OumiUser? get currentUser => _cachedUser;
  
  /// Returns the underlying Firebase User.
  User? get firebaseUser => _auth.currentUser;

  /// Emits whenever the authentication status changes (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Real-time stream of the OUMMI profile that automatically updates the cache.
  Stream<OumiUser?> get userProfileStream => _auth.authStateChanges().asyncMap((User? user) async {
    if (user == null) {
      _cachedUser = null;
      return null;
    }
    
    // Load the last role from local storage if not already cached.
    if (_cachedLastRole == null) {
      await _loadLastOnboardingRole();
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final parsed = OumiUser.fromFirestore(doc);
      _cachedUser = parsed;
      return parsed;
    }
    return null;
  });

  // ---------------------------------------------------
  // 🧪 Helper: Unified Onboarding Logic
  // ---------------------------------------------------

  /// High-level check to determine if the user needs to see onboarding for their CURRENT role.
  bool get needOnboarding {
    final user = _cachedUser;
    if (user == null) return false; // Not logged in

    // Case 1: User explicitly completed onboarding for this role in Firestore.
    if (user.onboardingComplete) return false;

    // Case 2: Local state shows a role mismatch (e.g., switched from girl to pregnant).
    if (_cachedLastRole != user.role.name) return true;

    // Case 3: First-time sign-in or manual reset.
    return true;
  }

  // ---------------------------------------------------
  // 🔓 Authentication Methods
  // ---------------------------------------------------

  /// Starts the Phone OTP flow. Handles verification completed, failed, and code sent callbacks.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        verificationCompleted(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Finalizes sign-in using the 6-digit OTP code received via SMS.
  Future<UserCredential> signInWithOtpCredential(String verificationId, String smsCode) {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Handles Google Social Sign-In using the `google_sign_in` package.
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  /// Handles Apple Sign-In (iOS only, requires native setup).
  Future<User?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  /// Standard email login.
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Standard account creation.
  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Fully clears the session from both Auth providers and the local cache.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _cachedUser = null;
  }

  // ---------------------------------------------------
  // 🎯 Role & Onboarding Persistence
  // ---------------------------------------------------

  /// 🔄 Switch user's role (e.g., young_girl → pregnant)
  /// Crucial for the "Maternal Journey": data stays, only the persona changes.
  Future<void> switchRole(String newRole) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final oldRole = _cachedUser?.role.name;

    // 1️⃣ Update Firestore: role + reset onboarding for the NEW experience
    await _firestore.collection('users').doc(user.uid).update({
      'role': newRole,
      'onboardingComplete': false, // Force them to see the new role's tutorial
      'lastSync': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Persist the switch locally: last onboarding role becomes the OLD role
    // This ensures needOnboarding evaluates to true for the new role.
    if (oldRole != null) {
      await _persistLastOnboardingRole(oldRole);
    }
    
    await refreshCurrentUser();
  }

  /// ✅ Assigns the initial role and marks onboarding as pending.
  /// Calls a secure Cloud Function to set custom claims.
  Future<void> setUserRole(String roleId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // 1. Call secure Cloud Function to set Claims (Role)
    try {
      await _functions.httpsCallable('setUserRole').call({'role': roleId});
    } catch (e) {
      debugPrint("Error calling setUserRole Cloud Function: $e");
      // Fallback for dev (not secure for prod rules)
      await _firestore.collection('users').doc(user.uid).set({
        'role': roleId,
      }, SetOptions(merge: true));
    }

    // 2. Local metadata update
    await _firestore.collection('users').doc(user.uid).set({
      'onboardingComplete': false,
      'lastSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _persistLastOnboardingRole(roleId);
    await refreshCurrentUser();
  }

  /// ✅ Finalizes the onboarding flow and unlocks the main dashboard.
  Future<void> completeOnboarding(OumiUser profile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(user.uid).set(
      profile.copyWith(onboardingComplete: true).toFirestore(),
      SetOptions(merge: true),
    );

    // Sync local last_role with the newly completed role.
    await _persistLastOnboardingRole(profile.role.name);
    
    // Persist a simple flag in SharedPreferences so the splash knows onboarding is complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    await refreshCurrentUser();
  }

  /// ✅ Updates the entire user profile in Firestore.
  Future<void> updateUserProfile(OumiUser profile) async {
    await _firestore.collection('users').doc(profile.uid).set(
      profile.toFirestore(),
      SetOptions(merge: true),
    );
    await refreshCurrentUser();
  }

  /// Manually re-fetches the latest profile from the cloud.
  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _cachedUser = OumiUser.fromFirestore(doc);
    }
  }

  // ---------------------------------------------------
  // 🛠️ Local Persistence (for Router Guards)
  // ---------------------------------------------------
  
  /// Stores the last seen onboarding role in SharedPreferences. 
  /// Used by GoRouter to detect if the user's role was changed from the backend.
  Future<void> _persistLastOnboardingRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOnboardingRoleKey, role);
    _cachedLastRole = role;
  }

  /// Retrieves the locally stored role string.
  Future<String?> getLastOnboardingRole() async {
    if (_cachedLastRole != null) return _cachedLastRole;
    final prefs = await SharedPreferences.getInstance();
    _cachedLastRole = prefs.getString(_lastOnboardingRoleKey);
    return _cachedLastRole;
  }

  /// Loads the last role from SharedPreferences into memory.
  Future<void> _loadLastOnboardingRole() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedLastRole = prefs.getString(_lastOnboardingRoleKey);
  }

  /// ✅ One-time initialization to ensure Auth and Profile are ready.
  Future<void> initialise() async {
    // 1. Ensure last onboarding role is loaded from local storage
    await _loadLastOnboardingRole();
    
    // 2. Wait for Firebase Auth to provide the first user state
    final User? user = _auth.currentUser;
    if (user != null) {
      await refreshCurrentUser();
    } else {
      await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 2), 
        onTimeout: () => null
      );
      if (_auth.currentUser != null) {
        await refreshCurrentUser();
      }
    }
  }

  /// ✅ Point d'entrée principal après OTP vérifié.
  /// Met à jour Firestore et le stockage local pour les urgences.
  Future<void> initializeUser({
    required String phoneNumber,
    required String onboardingStep,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // 1. Stockage Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'phone': phoneNumber,
      'phoneVerified': true,
      'onboardingStep': onboardingStep,
      'lastSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Stockage local pour urgences hors-ligne
    await savePhoneForEmergency(phoneNumber);
    
    await refreshCurrentUser();
  }

  /// 🎯 Sauvegarde les données utilisateur avec granularité.
  Future<void> saveUserData({
    required String uid,
    required String phoneNumber,
    required String onboardingStep,
    String? role,
  }) async {
    final Map<String, dynamic> data = {
      'phone': phoneNumber,
      'phoneVerified': true,
      'onboardingStep': onboardingStep,
    };
    if (role != null) data['role'] = role;

    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    await refreshCurrentUser();
  }

  /// 🚑 Stockage local (SharedPreferences) et Cloud du téléphone.
  Future<void> savePhoneForEmergency(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone_emergency', phone);

    if (_auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'phone': phone,
        'lastEmergencySync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Récupère le téléphone stocké localement.
  Future<String?> getEmergencyPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone_emergency');
  }

  /// 📱 Démarre le processus de vérification Firebase.
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onError,
  }) async {
    // Validation format Tchad (+235) ou Guinée (+224)
    if (!phoneNumber.startsWith('+235') && !phoneNumber.startsWith('+224')) {
      throw Exception("Le numéro doit commencer par +235 (Tchad) ou +224 (Guinée)");
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolution sur certains Android
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // ---------------------------------------------------
  // 🔗 Linking & Security Logic
  // ---------------------------------------------------

  /// Establishes a technical link between two accounts (e.g., Husband -> Wife).
  /// Updates both profiles to grant reverse read consent.
  Future<void> addLinkedUser(String currentUid, String targetUid, String relation) async {
    // Current user tracks who they are linked to
    await _firestore.collection('users').doc(currentUid).update({
      'linkedUsers': FieldValue.arrayUnion([{
        'uid': targetUid,
        'relation': relation,
        'linkedAt': FieldValue.serverTimestamp(),
      }])
    });
    
    // Target user grants consent to the current user
    await _firestore.collection('users').doc(targetUid).update({
      'partnerConsent': FieldValue.arrayUnion([currentUid])
    });
  }

  /// Fetches a raw profile for any user by their UID (used in linking and guards).
  Future<OumiUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return OumiUser.fromFirestore(doc);
    }
    return null;
  }
}
