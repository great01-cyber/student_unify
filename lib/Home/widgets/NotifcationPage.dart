import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

// Color palette - consistent with the app
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAsUnread(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': false});
    } catch (e) {
      debugPrint('Error marking notification as unread: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: primaryPink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: primaryPink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: lightText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: primaryPink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Stream<QuerySnapshot> _getNotificationsStream(String filter) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    var query = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (filter == 'unread') {
      query = query.where('isRead', isEqualTo: false) as Query<Map<String, dynamic>>;
    } else if (filter == 'read') {
      query = query.where('isRead', isEqualTo: true) as Query<Map<String, dynamic>>;
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPink, accentPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, color: primaryPink, size: 20),
                    SizedBox(width: 12),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Read'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList('all'),
          _buildNotificationList('unread'),
          _buildNotificationList('read'),
        ],
      ),
    );
  }

  Widget _buildNotificationList(String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationsStream(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: lightText),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: TextStyle(fontSize: 16, color: lightText),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightPink.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: primaryPink.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  filter == 'unread'
                      ? 'No unread notifications'
                      : filter == 'read'
                      ? 'No read notifications'
                      : 'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll notify you when something new arrives',
                  style: TextStyle(fontSize: 14, color: lightText),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final notification = doc.data() as Map<String, dynamic>;
            return _buildNotificationCard(doc.id, notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(String notificationId, Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? 'general';
    final timestamp = notification['timestamp'] as Timestamp?;

    String timeAgo = 'Just now';
    if (timestamp != null) {
      timeAgo = timeago.format(timestamp.toDate());
    }

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade300, Colors.red.shade600],
          ),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Notification'),
            content: const Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: lightText)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notificationId);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : lightPink.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : primaryPink.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!isRead) {
                _markAsRead(notificationId);
              }
              // Handle navigation based on notification type here
              // Example: Navigator.push(context, MaterialPageRoute(...))
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getNotificationGradient(type),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPink.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                  color: darkText,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: primaryPink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 14,
                            color: lightText,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: lightText.withOpacity(0.8),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: lightText,
                                size: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (value) {
                                if (value == 'mark_read') {
                                  _markAsRead(notificationId);
                                } else if (value == 'mark_unread') {
                                  _markAsUnread(notificationId);
                                } else if (value == 'delete') {
                                  _deleteNotification(notificationId);
                                }
                              },
                              itemBuilder: (context) => [
                                if (!isRead)
                                  const PopupMenuItem(
                                    value: 'mark_read',
                                    child: Row(
                                      children: [
                                        Icon(Icons.done_rounded, color: primaryPink, size: 18),
                                        SizedBox(width: 12),
                                        Text('Mark as read'),
                                      ],
                                    ),
                                  ),
                                if (isRead)
                                  const PopupMenuItem(
                                    value: 'mark_unread',
                                    child: Row(
                                      children: [
                                        Icon(Icons.markunread_rounded, color: primaryPink, size: 18),
                                        SizedBox(width: 12),
                                        Text('Mark as unread'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                      SizedBox(width: 12),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'request':
        return Icons.handshake_rounded;
      case 'approval':
        return Icons.check_circle_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'badge':
        return Icons.verified_user_rounded;
      case 'community':
        return Icons.people_rounded;
      case 'listing':
        return Icons.list_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  List<Color> _getNotificationGradient(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];
      case 'request':
        return [primaryPink, accentPink];
      case 'approval':
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case 'reminder':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'badge':
        return [const Color(0xFFEF4444), const Color(0xFFF87171)];
      case 'community':
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
      case 'listing':
        return [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
      default:
        return [primaryPink, accentPink];
    }
  }
}