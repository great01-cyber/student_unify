import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatNotificationHandler {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Initialize notification handlers
  static Future<void> initialize() async {
    // Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessageTap(message);
      }
    });
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Only show notification if it's a chat message
    if (data['type'] == 'chat_message') {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFF6786),
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data['chatId'],
      );
    }
  }

  /// Handle background message tap (when notification is tapped)
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'chat_message') {
      final chatId = data['chatId'];
      final senderId = data['senderId'];
      final senderName = data['senderName'];

      // Navigate to chat
      // You'll need to handle navigation based on your app's navigation structure
      debugPrint('Navigate to chat: $chatId with $senderName');
    }
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final chatId = response.payload;
    if (chatId != null) {
      debugPrint('Navigate to chat: $chatId');
      // Navigate to chat page
      // You'll need to implement navigation based on your app structure
    }
  }

  /// Save FCM token to Firestore
  static Future<void> saveFCMToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        debugPrint('FCM Token saved: $token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Listen for token refresh
  static void listenToTokenRefresh(String userId) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': newToken});
    });
  }
}
