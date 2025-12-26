import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  /// Send notification when someone sends a message
  Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
  }) async {
    await sendNotification(
      userId: recipientId,
      title: 'New message from $senderName',
      body: messagePreview,
      type: 'message',
      data: {'senderId': _auth.currentUser?.uid},
    );
  }

  /// Send notification when someone makes a lending request
  Future<void> sendLendingRequestNotification({
    required String ownerId,
    required String requesterName,
    required String itemName,
    String? requestId,
  }) async {
    await sendNotification(
      userId: ownerId,
      title: 'New lending request',
      body: '$requesterName wants to borrow your $itemName',
      type: 'request',
      data: {'requestId': requestId, 'requesterId': _auth.currentUser?.uid},
    );
  }

  /// Send notification when a request is approved
  Future<void> sendRequestApprovedNotification({
    required String requesterId,
    required String itemName,
    String? requestId,
  }) async {
    await sendNotification(
      userId: requesterId,
      title: 'Request approved!',
      body: 'Your request to borrow $itemName has been approved',
      type: 'approval',
      data: {'requestId': requestId},
    );
  }

  /// Send notification when a request is declined
  Future<void> sendRequestDeclinedNotification({
    required String requesterId,
    required String itemName,
    String? requestId,
  }) async {
    await sendNotification(
      userId: requesterId,
      title: 'Request declined',
      body: 'Your request to borrow $itemName has been declined',
      type: 'request',
      data: {'requestId': requestId},
    );
  }

  /// Send notification when user earns a badge
  Future<void> sendBadgeEarnedNotification({
    required String userId,
    required String badgeName,
    String? badgeId,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'New badge earned! 🎉',
      body: 'Congratulations! You\'ve earned the $badgeName badge',
      type: 'badge',
      data: {'badgeId': badgeId},
    );
  }

  /// Send notification for community posts
  Future<void> sendCommunityNotification({
    required String userId,
    required String title,
    required String body,
    String? postId,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'community',
      data: {'postId': postId},
    );
  }

  /// Send reminder notification
  Future<void> sendReminderNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'reminder',
      data: data,
    );
  }

  /// Get unread notification count for current user
  Stream<int> getUnreadNotificationCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final unreadNotifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final notifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();

    final batch = _firestore.batch();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}