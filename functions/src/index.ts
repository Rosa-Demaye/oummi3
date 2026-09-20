import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Triggered when a new critical emergency alert (e.g. Signal Labor) is created.
 */
export const onEmergencyAlertCreated = functions.firestore
    .document("emergencyAlerts/{userId}")
    .onCreate(async (snapshot, context) => {
      const alertData = snapshot.data();
      const userId = context.params.userId;
      if (!alertData) return;

      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userProfile = userDoc.data();
      if (!userProfile) return;

      const tokens: string[] = [];
      const partnerIds = userProfile.partnerConsent || [];
      for (const pId of partnerIds) {
        const pDoc = await admin.firestore().collection("users").doc(pId).get();
        const pData = pDoc.data();
        if (pData && pData.fcmTokens && Array.isArray(pData.fcmTokens)) {
          tokens.push(...pData.fcmTokens);
        }
      }

      if (tokens.length === 0) return;

      const payload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: "🚨 OUMMI: URGENCE ACCOUCHEMENT",
          body: `${userProfile.fullName} a signalé un début de travail. Position GPS jointe.`,
        },
        data: {
          userId: userId,
          type: "LABOR_EMERGENCY",
          latitude: String(alertData.latitude || ""),
          longitude: String(alertData.longitude || ""),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "maternal_emergency_channel",
            sound: "emergency_siren",
          },
        },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(payload);
        console.log(`Emergency alert sent to ${response.successCount} devices.`);
      } catch (error) {
        console.error("Error sending emergency push notifications:", error);
      }
    });

/**
 * Initiates a payment for teleconsultation.
 */
export const initiatePayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const userId = context.auth.uid;
  const amount = data.amount || 2500;
  const provider = data.provider || "airtel";

  const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

  const paymentData = {
    userId: userId,
    amount: amount,
    verificationCode: verificationCode,
    status: "pending",
    provider: provider,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const docRef = await admin.firestore().collection("pendingPayments").add(paymentData);

  return {
    paymentId: docRef.id,
    verificationCode: verificationCode,
  };
});

/**
 * Webhook placeholder for payment providers.
 */
export const paymentWebhook = functions.https.onRequest(async (req, res) => {
  const {paymentId, status} = req.body;
  if (status === "success") {
    await admin.firestore().collection("pendingPayments").doc(paymentId).update({
      status: "verified",
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  res.status(200).send("OK");
});

/**
 * Triggered when a new routine maternal alert is created.
 */
export const onMaternalAlertCreated = functions.firestore
    .document("users/{userId}/maternal_alerts/{alertId}")
    .onCreate(async (snapshot, context) => {
      const alertData = snapshot.data();
      const userId = context.params.userId;
      if (!alertData) return;

      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userProfile = userDoc.data();
      if (!userProfile || userProfile.consentGiven !== true) {
        await snapshot.ref.update({status: "rejected_by_server"});
        return;
      }

      const alertType = alertData.type || "emergency";
      const recipients = alertData.allRecipients || [];

      const tokens: string[] = [];
      for (const recipientRole of recipients) {
        const recipientSnap = await admin.firestore()
            .collection("users")
            .where("role", "==", recipientRole.toLowerCase())
            .get();

        recipientSnap.forEach((doc) => {
          const data = doc.data();
          if (data.fcmTokens && Array.isArray(data.fcmTokens)) {
            tokens.push(...data.fcmTokens);
          }
        });
      }

      if (tokens.length === 0) return;

      const payload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: alertType === "laborStart" ? "🚨 Nouveau Travail Signalé" : "⚠️ Alerte Médicale Urgente",
          body: `Patiente: ${userProfile.fullName}. Consultez le tableau de bord.`,
        },
        data: {
          alertId: snapshot.id,
          userId: userId,
          type: alertType,
        },
      };

      await admin.messaging().sendEachForMulticast(payload);
    });

/**
 * Assigns a role to a user using Firebase Custom Claims.
 * This ensures that Firestore security rules can reliably check the user's role.
 */
export const setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const role = data.role;
  const allowedRoles = ["girl", "pregnant", "father", "doctor", "hospital", "admin"];

  if (!role || !allowedRoles.includes(role)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid role provided.");
  }

  try {
    // 1. Set Custom Claims for Auth
    await admin.auth().setCustomUserClaims(context.auth.uid, {role: role});

    // 2. Update Firestore for UI display convenience
    await admin.firestore().collection("users").doc(context.auth.uid).set({
      role: role,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return {status: "success", role: role};
  } catch (error) {
    console.error("Error setting user role:", error);
    throw new functions.https.HttpsError("internal", "Unable to assign role.");
  }
});
