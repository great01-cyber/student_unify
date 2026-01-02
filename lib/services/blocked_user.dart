import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Block a user
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      // Add to current user's blocked list
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
        'blockedAt.$blockedUserId': FieldValue.serverTimestamp(),
      });

      // Add to blocked user's blockedBy list (so they know they're blocked)
      await _firestore.collection('users').doc(blockedUserId).update({
        'blockedBy': FieldValue.arrayUnion([currentUserId]),
      });

      debugPrint('✅ User $blockedUserId blocked by $currentUserId');
    } catch (e) {
      debugPrint('❌ Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      // Remove from current user's blocked list
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
        'blockedAt.$blockedUserId': FieldValue.delete(),
      });

      // Remove from blocked user's blockedBy list
      await _firestore.collection('users').doc(blockedUserId).update({
        'blockedBy': FieldValue.arrayRemove([currentUserId]),
      });

      debugPrint('✅ User $blockedUserId unblocked by $currentUserId');
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      rethrow;
    }
  }

  /// Check if current user has blocked another user
  Future<bool> isUserBlocked({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();

      if (!doc.exists) return false;

      final data = doc.data();
      final blockedUsers = List<String>.from(data?['blockedUsers'] ?? []);

      return blockedUsers.contains(otherUserId);
    } catch (e) {
      debugPrint('❌ Error checking block status: $e');
      return false;
    }
  }

  /// Check if current user is blocked by another user
  Future<bool> isBlockedBy({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();

      if (!doc.exists) return false;

      final data = doc.data();
      final blockedBy = List<String>.from(data?['blockedBy'] ?? []);

      return blockedBy.contains(otherUserId);
    } catch (e) {
      debugPrint('❌ Error checking if blocked by user: $e');
      return false;
    }
  }

  /// Check if there's any blocking relationship (either direction)
  Future<Map<String, bool>> checkBlockingStatus({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();

      final currentUserData = currentUserDoc.data();
      final otherUserData = otherUserDoc.data();

      final blockedByMe = List<String>.from(currentUserData?['blockedUsers'] ?? [])
          .contains(otherUserId);

      final blockedByThem = List<String>.from(otherUserData?['blockedUsers'] ?? [])
          .contains(currentUserId);

      return {
        'blockedByMe': blockedByMe,
        'blockedByThem': blockedByThem,
        'anyBlocking': blockedByMe || blockedByThem,
      };
    } catch (e) {
      debugPrint('❌ Error checking blocking status: $e');
      return {
        'blockedByMe': false,
        'blockedByThem': false,
        'anyBlocking': false,
      };
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return [];

      final data = doc.data();
      return List<String>.from(data?['blockedUsers'] ?? []);
    } catch (e) {
      debugPrint('❌ Error getting blocked users: $e');
      return [];
    }
  }

  /// Stream of blocking status for real-time updates
  Stream<Map<String, bool>> blockingStatusStream({
    required String currentUserId,
    required String otherUserId,
  }) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return {
          'blockedByMe': false,
          'blockedByThem': false,
          'anyBlocking': false,
        };
      }

      final currentUserData = snapshot.data();
      final blockedByMe = List<String>.from(currentUserData?['blockedUsers'] ?? [])
          .contains(otherUserId);

      // Check if blocked by them
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      final otherUserData = otherUserDoc.data();
      final blockedByThem = List<String>.from(otherUserData?['blockedUsers'] ?? [])
          .contains(currentUserId);

      return {
        'blockedByMe': blockedByMe,
        'blockedByThem': blockedByThem,
        'anyBlocking': blockedByMe || blockedByThem,
      };
    });
  }
}