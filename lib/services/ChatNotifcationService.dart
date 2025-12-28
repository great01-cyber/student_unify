import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a chat notification to the receiver
  Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    String? itemTitle,
    String? itemImage,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();

      if (!receiverDoc.exists) {
        debugPrint('Receiver user not found');
        return;
      }

      final receiverData = receiverDoc.data();
      final fcmToken = receiverData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('Receiver has no FCM token');
        return;
      }

      // Create notification data
      final notificationData = {
        'token': fcmToken,
        'notification': {
          'title': senderName,
          'body': messageText.length > 100
              ? '${messageText.substring(0, 100)}...'
              : messageText,
          'imageUrl': itemImage,
        },
        'data': {
          'type': 'chat_message',
          'chatId': chatId,
          'senderId': _auth.currentUser?.uid ?? '',
          'senderName': senderName,
          'itemTitle': itemTitle ?? '',
          'clickAction': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': 'chat_messages',
            'sound': 'default',
            'color': '#FF6786',
            'icon': '@mipmap/ic_launcher',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      // Call Cloud Function to send notification
      await _firestore.collection('mail').add({
        'to': receiverDoc.id,
        'message': notificationData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also create in-app notification
      await _createInAppNotification(
        receiverId: receiverId,
        senderName: senderName,
        messageText: messageText,
        chatId: chatId,
        itemTitle: itemTitle,
      );

      debugPrint('Chat notification sent successfully');
    } catch (e) {
      debugPrint('Error sending chat notification: $e');
    }
  }

  /// Create in-app notification in Firestore
  Future<void> _createInAppNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    String? itemTitle,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'title': 'New message from $senderName',
        'body': messageText.length > 100
            ? '${messageText.substring(0, 100)}...'
            : messageText,
        'type': 'chat_message',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'chatId': chatId,
          'senderId': _auth.currentUser?.uid ?? '',
          'senderName': senderName,
          'itemTitle': itemTitle ?? '',
        },
      });
    } catch (e) {
      debugPrint('Error creating in-app notification: $e');
    }
  }

  /// Update unread message count for badge
  Future<void> updateUnreadCount({
    required String userId,
    required int increment,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'unreadMessagesCount': FieldValue.increment(increment),
      });
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }

  /// Clear unread count when chat is opened
  Future<void> clearUnreadCount({
    required String userId,
    required String chatId,
  }) async {
    try {
      // Reset unread count for this specific chat
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      debugPrint('Error clearing unread count: $e');
    }
  }
}