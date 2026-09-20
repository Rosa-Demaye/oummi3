import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oummi3/main.dart';
import 'package:oummi3/shared/models/user_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A critical service for managing maternal emergencies and labor signals.
/// 
/// It integrates:
/// - High-priority local notifications.
/// - USSD dialer integration for cellular-based alerts.
/// - High-precision GPS tracking.
/// - Offline-ready cloud queuing.
class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String emergencyBoxName = 'emergency_settings';

  /// Initializes local notification channels and requests GPS permissions.
  Future<void> init() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    // 2. Ensure GPS permissions are requested early
    await Geolocator.requestPermission();
  }

  /// Triggers the full emergency flow: Local alert, USSD, and Cloud Queue.
  /// Works even in low-connectivity areas by queuing the Firestore update.
  Future<void> signalLabor(OumiUser user) async {
    // 1. Set local flag for background monitoring/recovery
    final box = await Hive.openBox(emergencyBoxName);
    await box.put('isEmergency', true);
    await box.put('lastEmergencyTime', DateTime.now().toIso8601String());

    // 2. Trigger Local Notification (Instant feedback for the user)
    await _showLocalEmergencyNotification();

    // 3. Launch USSD Gateway (Example: *150# for mobile money/ambulance)
    final Uri ussdUri = Uri.parse('tel:*150%23'); // Encode # as %23
    if (await canLaunchUrl(ussdUri)) {
      await launchUrl(ussdUri);
    }

    // 4. Get current GPS coordinates with a 5-second timeout
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('GPS Error during labor signal: $e');
    }

    // 5. Queue Firestore write via SyncService (Persistent Offline)
    await globalSyncService.performWrite(
      collection: 'emergencyAlerts',
      docId: user.uid,
      data: {
        'userId': user.uid,
        'fullName': user.fullName,
        'qrCode': user.qrCode,
        'phone': user.phone,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'status': 'active',
        'type': 'labor_signal',
        'timestamp': DateTime.now().toIso8601String(),
        'medicalSummary': 'Signalement de début de travail (Accouchement imminent)',
      },
    );
  }

  /// Displays an urgent, red-themed system notification.
  Future<void> _showLocalEmergencyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'emergency_channel',
      'Alertes Urgentes',
      channelDescription: 'Canal pour les signaux d\'accouchement',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFFE53935), // Urgent Red
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      0,
      '🚨 SIGNAL LABOR ACTIVÉ',
      'Services d\'urgence notifiés. Gardez votre téléphone à portée.',
      platformChannelSpecifics,
    );
  }
}
