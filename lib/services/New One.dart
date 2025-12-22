import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Triggers nearby notifications for donations or lend requests
  ///
  /// [donationId] - The ID of the donation/lend item
  /// [donationData] - The full data of the item
  /// [notificationType] - Either 'donation' or 'lend'
  ///
  /// For donations: Only students receive notifications
  /// For lends: Both students and non-students receive notifications
  Future<void> triggerNearbyNotification({
    required String donationId,
    required Map<String, dynamic> donationData,
    String notificationType = 'donation', // ✅ Default to 'donation' for backward compatibility
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user');
        return;
      }

      // Create notification request document
      await _firestore.collection('notification_requests').add({
        'donorId': user.uid,
        'donationId': donationId,
        'donationData': donationData,
        'notificationType': notificationType, // ✅ Pass the type to Cloud Function
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification request created for $notificationType (ID: $donationId)');
    } catch (e) {
      debugPrint('❌ Failed to trigger notifications: $e');
      rethrow; // Let the caller handle the error
    }
  }
}