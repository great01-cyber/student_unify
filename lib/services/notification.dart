import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ----------------------------------------------------
// 0. GLOBAL LOCAL NOTIFICATIONS PLUGIN
// ----------------------------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Optional: keep a reference to the channel (Android only)
const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.max,
);

// ----------------------------------------------------
// 1. SAVE TOKEN SAFELY (WAIT UNTIL APNs TOKEN IS READY)
// ----------------------------------------------------
Future<void> saveUserFCMToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final messaging = FirebaseMessaging.instance;

  // On iOS, token may be null until APNs token is ready.
  String? token;

  // Try a few times instead of infinite loop (safer)
  for (int i = 0; i < 15; i++) {
    try {
      token = await messaging.getToken();
      if (token != null && token.isNotEmpty) break;
    } catch (_) {
      // ignore and retry
    }
    await Future.delayed(const Duration(seconds: 2));
  }

  if (token == null || token.isEmpty) {
    debugPrint("❌ Could not get FCM token (still null).");
    return;
  }

  debugPrint("🔥 Final FCM Token: $token");

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({
    'fcmTokens': FieldValue.arrayUnion([token]),
    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

// ----------------------------------------------------
// 2. REQUEST PERMISSION + iOS FOREGROUND PRESENTATION + TOKEN REFRESH
// ----------------------------------------------------
Future<void> requestPermissionAndListenForToken() async {
  final messaging = FirebaseMessaging.instance;

  // iOS: request permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  debugPrint('Authorization status: ${settings.authorizationStatus}');

  // iOS: allow notifications to show while app is in foreground
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    debugPrint('✅ User granted permission');

    // Save token once permission is granted
    await saveUserFCMToken();

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("🔁 Token refreshed: $newToken");
      await saveUserFCMToken();
    });
  } else {
    debugPrint('❌ User declined or has not accepted permission');
  }
}

// ----------------------------------------------------
// 3. LOCAL NOTIFICATION INITIALIZATION (ANDROID + iOS)
// ----------------------------------------------------
Future<void> initInfo() async {
  // Android init
  const AndroidInitializationSettings androidInitialize =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS init
  const DarwinInitializationSettings iosInitialize = DarwinInitializationSettings(
    requestAlertPermission: false, // we request via FirebaseMessaging
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitialize,
    iOS: iosInitialize,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        debugPrint('Tapped Notification Payload: $payload');
      }
    },
  );

  // Create Android channel (required for Android 8+)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_highImportanceChannel);

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Received a foreground message");

    final notification = message.notification;
    if (notification != null) {
      showNotification(
        notification.title ?? "No Title",
        notification.body ?? "No Body",
        message.data.isNotEmpty ? message.data.toString() : "No Payload",
      );
    }
  });

  // When user taps notification and opens app from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("📲 Notification opened from background: ${message.messageId}");
    // Handle navigation using message.data if needed
  });

  // If app was terminated and opened via a notification tap
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint("🚀 App opened from terminated state via notification: ${initialMessage.messageId}");
    // Handle navigation using initialMessage.data if needed
  }
}

// ----------------------------------------------------
// 4. SHOW LOCAL NOTIFICATION (ANDROID + iOS)
// ----------------------------------------------------
Future<void> showNotification(String title, String body, String payload) async {
  final int id = DateTime.now().millisecondsSinceEpoch % 2147483647;

  // Android details
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  // iOS details
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

// ----------------------------------------------------
// 5. REQUIRED BACKGROUND HANDLER
// ----------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // NOTE: Make sure Firebase.initializeApp() is called in main()
  // before using messaging in background (typically done in main.dart).
  debugPrint("📨 Background message received: ${message.messageId}");
}
