# Firestore Security Rules

Copy and paste these rules into your Firebase Console under **Firestore Database > Rules**.

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Helper to check if user has a specific role
    function hasRole(role) {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }

    // Helper to check if a patient has granted consent to the current user
    function hasPatientConsent(patientId) {
      let patient = get(/databases/$(database)/documents/users/$(patientId)).data;
      return request.auth.uid in patient.partnerConsent;
    }

    // User Profile Rules
    match /users/{userId} {
      allow read: if request.auth != null &&
        (request.auth.uid == userId || hasPatientConsent(userId));

      allow write: if request.auth != null && request.auth.uid == userId;

      // Allow searching for users by QR code during linking
      allow list: if request.auth != null && request.query.limit <= 1;
    }

    // Maternal Records Rules (Cycle, Pregnancy, Alerts)
    match /users/{userId}/cycle_records/{recordId} {
      allow read: if request.auth != null && (request.auth.uid == userId || hasPatientConsent(userId));
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /users/{userId}/pregnancy_records/{recordId} {
      allow read: if request.auth != null && (request.auth.uid == userId || hasPatientConsent(userId));
      allow write: if request.auth != null && (request.auth.uid == userId || hasRole('doctor'));
    }

    match /users/{userId}/maternal_alerts/{alertId} {
      allow read: if request.auth != null && (request.auth.uid == userId || hasRole('doctor') || hasRole('hospital'));
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Booking Rules
    match /bookings/{bookingId} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid || hasRole('hospital'));
      allow write: if request.auth != null;
    }

    // Hospital Availability (Public Read)
    match /hospitals/{hospitalId} {
      allow read: if true;
      allow write: if request.auth != null && hasRole('hospital');
    }
  }
}
```
