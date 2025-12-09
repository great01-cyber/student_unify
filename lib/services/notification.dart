import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ----------------------------------------------------
// 1. SAVE TOKEN SAFELY (WAIT UNTIL APNs TOKEN IS READY)
// ----------------------------------------------------
Future<void> saveUserFCMToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ----- iOS FIX -----
  // Wait until APNs token is available
  String? token;

  while (token == null) {
    try {
      token = await messaging.getToken();
    } catch (_) {
      await Future.delayed(Duration(seconds: 2)); // Wait and retry
    }
  }

  print("🔥 Final FCM Token: $token");

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({'fcmToken': token}, SetOptions(merge: true));
}

// ----------------------------------------------------
// 2. REQUEST PERMISSION + HANDLE TOKEN REFRESH
// ----------------------------------------------------
void requestPermissionAndListenForToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('Authorization status: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');

    // Save initial token
    saveUserFCMToken();

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("🔁 Token refreshed: $newToken");
      saveUserFCMToken();
    });
  }
}

// ----------------------------------------------------
// 3. LOCAL NOTIFICATION INITIALIZATION
// ----------------------------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initInfo() async {
  const AndroidInitializationSettings androidInitialize =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitialize =
  DarwinInitializationSettings();

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: androidInitialize,
    iOS: iosInitialize,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      String? payload = response.payload;
      if (payload != null) {
        debugPrint('Tapped Notification Payload: $payload');
      }
    },
  );

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Received a foreground message");

    if (message.notification != null) {
      showNotification(
        message.notification!.title ?? "No Title",
        message.notification!.body ?? "No Body",
        message.data.isNotEmpty ? message.data.toString() : "No Payload",
      );
    }
  });
}

// ----------------------------------------------------
// 4. SHOW LOCAL NOTIFICATION
// ----------------------------------------------------
Future<void> showNotification(
    String title, String body, String payload) async {
  int id = DateTime.now().millisecondsSinceEpoch % 2147483647;

  const AndroidNotificationDetails androidDetails =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
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
  print("📨 Background message received: ${message.messageId}");
}
