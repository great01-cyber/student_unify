// ============================================
// notification_service.dart (CLEANED)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago; // Still needed for UI code
import 'package:flutter/material.dart';

// Assuming Donation and ItemDetailPage are imported elsewhere if needed

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // *** Distance calculation functions and _createNotification are REMOVED ***
  // *** This logic now lives ONLY in the Cloud Function ***

  /// Triggers a Cloud Function to find nearby users and send notifications.
  Future<void> triggerNearbyNotification({
    required String donationId,
    required Map<String, dynamic> donationData,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 💡 NEW LOGIC: Writes a request document to be processed by a Cloud Function.
      await _firestore.collection('notification_requests').add({
        'donationId': donationId,
        'donorId': currentUser.uid,
        'donationData': donationData,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification trigger successfully written for donation: $donationId');
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Get unread notification count for current user
  Future<int> getUnreadCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  /// Stream of notifications for current user
  Stream<QuerySnapshot> getUserNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}