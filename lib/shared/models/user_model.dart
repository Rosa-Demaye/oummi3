import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the various user personas in the Oummi ecosystem.
enum OumiRole { 
  girl,     // Young woman (Cycle tracking)
  pregnant, // Expecting mother
  father,   // Partner/Husband support
  doctor,   // Medical professional
  hospital, // Healthcare facility
  admin     // Platform management
}

extension OumiRoleExtension on OumiRole {
  /// Returns the human-friendly name of the role for UI display.
  String get roleDisplayName {
    switch (this) {
      case OumiRole.girl: return 'Jeune fille 👧';
      case OumiRole.pregnant: return 'Femme enceinte 🤰';
      case OumiRole.father: return 'Père / Mari 👨';
      case OumiRole.doctor: return 'Médecin 👩‍⚕️';
      case OumiRole.hospital: return 'Hôpital 🏥';
      case OumiRole.admin: return 'Administrateur 🛡️';
    }
  }

  /// String used by the router for path parameters.
  String get routeName => name;
}

/// The core User model for Oummi. 
/// This class handles profile data, roles, and onboarding status.
class OumiUser {
  final String uid;              // Unique Firebase Auth identifier
  final String? email;           // Primary email address
  final OumiRole role;           // Current user persona
  final String fullName;         // User's display name
  final String phone;            // Primary contact number
  final String region;           // Geographical region in Chad/Guinea
  final String city;             // Specific city or village
  final String? partnerPhone;    // Emergency contact for mothers
  final String? bloodGroup;      // Critical medical info for labor
  final String? emergencyContact; // Backup contact name/phone
  final String? qrCode;          // "OUMI-XXXX" ID for medical records
  final String? qrBackup;        // Alphanumeric backup for the QR ID
  final DateTime? createdAt;     // Account creation timestamp
  final DateTime? lastSync;      // Last successful cloud synchronization
  final bool onboardingComplete; // Whether user finished the guided walkthrough
  final bool phoneVerified;      // ✅ Statut vérification OTP
  final String onboardingStep;   // ✅ Étape (initial, phone_verified, role_selected, completed)
  
  /// List of UIDs that this user has granted permission to view their data.
  final List<String> partnerConsent;
  
  /// List of users this user is linked to (e.g., Husband -> Wife).
  final List<Map<String, dynamic>> linkedUsers;

  /// Flexible storage for role-specific data (e.g., gestational week).
  final Map<String, dynamic> metadata;

  OumiUser({
    required this.uid,
    this.email,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.region,
    required this.city,
    this.partnerPhone,
    this.bloodGroup,
    this.emergencyContact,
    this.qrCode,
    this.qrBackup,
    this.createdAt,
    this.lastSync,
    this.onboardingComplete = false,
    this.phoneVerified = false,
    this.onboardingStep = 'initial',
    this.partnerConsent = const [],
    this.linkedUsers = const [],
    this.metadata = const {},
  });

  /// Converts the model into a format Firestore can store.
  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'role': role.name,
        'fullName': fullName,
        'phone': phone,
        'region': region,
        'city': city,
        'partnerPhone': partnerPhone,
        'bloodGroup': bloodGroup,
        'emergencyContact': emergencyContact,
        'qrCode': qrCode,
        'qrBackup': qrBackup,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'lastSync': FieldValue.serverTimestamp(),
        'onboardingComplete': onboardingComplete,
        'phoneVerified': phoneVerified,
        'onboardingStep': onboardingStep,
        'partnerConsent': partnerConsent,
        'linkedUsers': linkedUsers,
        'metadata': metadata,
      };

  /// Returns the human-friendly name of the role for UI display.
  String get roleDisplayName {
    switch (role) {
      case OumiRole.girl: return 'Jeune fille';
      case OumiRole.pregnant: return 'Femme enceinte';
      case OumiRole.father: return 'Père / Mari';
      case OumiRole.doctor: return 'Médecin';
      case OumiRole.hospital: return 'Hôpital';
      case OumiRole.admin: return 'Administrateur';
    }
  }

  /// Logical check to determine if the user needs to see onboarding screens.
  bool get needOnboarding => !onboardingComplete;

  /// Creates a model instance from a Firestore document snapshot.
  factory OumiUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OumiUser(
      uid: doc.id,
      email: data['email'],
      role: OumiRole.values.byName(data['role'] ?? 'girl'),
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      region: data['region'] ?? '',
      city: data['city'] ?? '',
      partnerPhone: data['partnerPhone'],
      bloodGroup: data['bloodGroup'],
      emergencyContact: data['emergencyContact'],
      qrCode: data['qrCode'],
      qrBackup: data['qrBackup'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastSync: (data['lastSync'] as Timestamp?)?.toDate(),
      onboardingComplete: data['onboardingComplete'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      onboardingStep: data['onboardingStep'] ?? 'initial',
      partnerConsent: List<String>.from(data['partnerConsent'] ?? []),
      linkedUsers: List<Map<String, dynamic>>.from(data['linkedUsers'] ?? []),
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  OumiUser copyWith({
    String? uid,
    String? email,
    OumiRole? role,
    String? fullName,
    String? phone,
    String? region,
    String? city,
    String? partnerPhone,
    String? bloodGroup,
    String? emergencyContact,
    String? qrCode,
    String? qrBackup,
    DateTime? createdAt,
    DateTime? lastSync,
    bool? onboardingComplete,
    bool? phoneVerified,
    String? onboardingStep,
    List<String>? partnerConsent,
    List<Map<String, dynamic>>? linkedUsers,
    Map<String, dynamic>? metadata,
  }) {
    return OumiUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      city: city ?? this.city,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      qrCode: qrCode ?? this.qrCode,
      qrBackup: qrBackup ?? this.qrBackup,
      createdAt: createdAt ?? this.createdAt,
      lastSync: lastSync ?? this.lastSync,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      partnerConsent: partnerConsent ?? this.partnerConsent,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      metadata: metadata ?? this.metadata,
    );
  }
}
