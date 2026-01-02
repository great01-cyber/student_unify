import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UnreadMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of total unread messages count
  Stream<int> getUnreadMessagesCount() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;
        totalUnread += unreadCount as int;
      }

      return totalUnread;
    });
  }
}