import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// -------------------------------
// 1. SAVE FCM TOKEN TO FIRESTORE
// -------------------------------
Future<void> saveUserFCMToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'fcmToken': token,
  }, SetOptions(merge: true));
}

// -------------------------------
// 2. REQUEST NOTIFICATION PERMISSIONåå
// -------------------------------
void requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings setting = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (setting.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined notification permission');
  }
}

// -------------------------------------
// 3. LOCAL NOTIFICATION INITIALIZATION
// -------------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initInfo() async {
  // Android setup
  const AndroidInitializationSettings androidInitialize =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS setup
  const DarwinInitializationSettings iosInitialize = DarwinInitializationSettings();

  // Both platforms
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitialize,
    iOS: iosInitialize,
  );

  // Initialize plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      String? payload = response.payload;
      if (payload != null) {
        debugPrint('Tapped Notification Payload: $payload');
        // Example navigation (uncomment and adjust)
        // Navigator.pushNamed(globalContext, '/detail', arguments: payload);
      }
    },
  );

  // Listen for foreground FCM messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Received a foreground message");

    if (message.notification != null) {
      String title = message.notification!.title ?? "No Title";
      String body = message.notification!.body ?? "No Body";
      String payload = message.data.isNotEmpty ? message.data.toString() : "No Payload";

      showNotification(title, body, payload);
    }
  });
}

// --------------------------------------------
// 4. SHOW LOCAL NOTIFICATION WITH A PAYLOAD
// --------------------------------------------
Future<void> showNotification(String title, String body, String payload) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
    DateTime.now().microsecondsSinceEpoch ~/ 1000, // unique ID
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

// ------------------------------------------------
// 5. REQUIRED - HANDLE BACKGROUND FCM MESSAGES
// ------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📨 Background message received: ${message.messageId}");
}
