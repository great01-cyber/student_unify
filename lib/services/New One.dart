// ============================================
// notification_service.dart
// Add this as a new file in your services folder
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Import your existing pages
import '../Home/Drawer Section/My Listings/Listings.dart';
import '../Models/DonateModel.dart'; // Your Donation modelrt';
import 'dart:math' show cos, sqrt, asin;

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate distance between two coordinates in kilometers using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  double sin(double value) {
    double result = value;
    double term = value;
    for (int i = 1; i <= 10; i++) {
      term *= -value * value / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  // Convert kilometers to miles
  double _kmToMiles(double km) {
    return km * 0.621371;
  }

  /// Send notifications to nearby users when a new donation is posted
  Future<int> notifyNearbyUsers({
    required String donationId,
    required Map<String, dynamic> donationData,
    double maxDistanceKm = 16.0, // ~10 miles
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;

      final double? donationLat = donationData['latitude'] as double?;
      final double? donationLng = donationData['longitude'] as double?;

      if (donationLat == null || donationLng == null) {
        print('No coordinates available for donation');
        return 0;
      }

      // Get all users with location data
      final usersSnapshot = await _firestore
          .collection('users')
          .where('latitude', isNull: false)
          .where('longitude', isNull: false)
          .get();

      int notificationsSent = 0;
      final List<Future<void>> notificationFutures = [];

      for (var userDoc in usersSnapshot.docs) {
        // Skip the donor themselves
        if (userDoc.id == currentUser.uid) continue;

        final userData = userDoc.data();
        final double? userLat = userData['latitude'] as double?;
        final double? userLng = userData['longitude'] as double?;

        if (userLat == null || userLng == null) continue;

        // Calculate distance in kilometers
        final distanceKm = _calculateDistance(
          donationLat,
          donationLng,
          userLat,
          userLng,
        );

        // If user is within range, send notification
        if (distanceKm <= maxDistanceKm) {
          final distanceMiles = _kmToMiles(distanceKm);

          notificationFutures.add(
              _createNotification(
                userId: userDoc.id,
                donationId: donationId,
                donationData: donationData,
                distanceMiles: distanceMiles,
              )
          );
          notificationsSent++;
        }
      }

      // Send all notifications in parallel
      await Future.wait(notificationFutures);

      return notificationsSent;
    } catch (e) {
      print('Error sending notifications: $e');
      return 0;
    }
  }

  /// Create a notification document for a specific user
  Future<void> _createNotification({
    required String userId,
    required String donationId,
    required Map<String, dynamic> donationData,
    required double distanceMiles,
  }) async {
    final notification = {
      'userId': userId,
      'donationId': donationId,
      'type': 'new_donation_nearby',
      'title': 'Hey Student! New Listings Around You',
      'message': '${donationData['title']} is ${distanceMiles.toStringAsFixed(1)} miles from you',
      'category': donationData['category'] ?? 'Unknown',
      'donationTitle': donationData['title'] ?? 'Item',
      'distance': distanceMiles,
      'imageUrl': (donationData['imageUrls'] as List?)?.isNotEmpty == true
          ? donationData['imageUrls'][0]
          : null,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'donorName': donationData['donorName'] ?? 'Someone',
    };

    await _firestore.collection('notifications').add(notification);
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


// ============================================
// notifications_page.dart
// Create this as a new page
// ============================================



class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearAllDialog,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notifications',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildNotificationCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified when new items\nare posted near you',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String notificationId, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final String imageUrl = data['imageUrl'] ?? '';
    final String title = data['title'] ?? 'New Listing';
    final String message = data['message'] ?? '';
    final String donationId = data['donationId'] ?? '';
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;

    String timeAgo = 'Just now';
    if (timestamp != null) {
      timeAgo = timeago.format(timestamp.toDate());
    }

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: isRead ? 1 : 3,
        color: isRead ? Colors.white : Colors.teal.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? Colors.grey.shade200 : Colors.teal.shade200,
            width: isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notificationId, donationId),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackImage();
                    },
                  )
                      : _buildFallbackImage(),
                ),
                const SizedBox(width: 12),

                // Notification content
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
                                fontFamily: 'Quicksand',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        color: Colors.teal.shade400,
        size: 30,
      ),
    );
  }

  Future<void> _handleNotificationTap(
      String notificationId,
      String donationId,
      ) async {
    // Mark notification as read
    await _notificationService.markAsRead(notificationId);

    // Fetch the donation document
    try {
      final donationDoc = await _firestore
          .collection('donations')
          .doc(donationId)
          .get();

      if (!donationDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This item is no longer available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Convert to Donation model
      final donationData = donationDoc.data()!;
      donationData['id'] = donationDoc.id;
      final donation = Donation.fromJson(donationData);

      // Navigate to ItemDetailPage
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: donation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear All Notifications',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        content: const Text(
          'Are you sure you want to delete all notifications?',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllNotifications();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId',
          isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


// ============================================
// UPDATED _submitForm() for donate.dart
// Replace your existing _submitForm() method
// ============================================

/*
Future<void> _submitForm() async {
  if (_isSubmitting) return;
  if (!_formKey.currentState!.validate()) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You must be signed in to post a donation.'),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return;
  }

  if (_images.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please add at least one image.',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return;
  }

  if (_selectedLocationInfo == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please confirm your location.',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false,
      child: const Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    String? donorName = user.displayName;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        donorName = userDoc.data()?['displayName'] as String? ?? user.displayName;
      }
    } catch (e) {}

    final String docId = _firestore.collection('donations').doc().id;
    final imageUrls = await _uploadImagesToFirebase(docId);

    final newDonation = Donation(
      id: docId,
      category: _selectedCategory ?? 'Unspecified',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text),
      kg: double.tryParse(_kgController.text),
      imageUrls: imageUrls,
      availableFrom: _availableFrom,
      availableUntil: _availableUntil,
      instructions: _instructionsController.text.trim(),
      locationAddress: _selectedLocationInfo,
      latitude: _selectedLatLng?.latitude,
      longitude: _selectedLatLng?.longitude,
      donorId: user.uid,
    );

    final Map<String, dynamic> donationData = newDonation.toJson();
    donationData['donorId'] = user.uid;
    donationData['donorEmail'] = user.email;
    donationData['donorName'] = donorName;

    await _firestore.collection('donations').doc(docId).set(donationData);

    final locString = _selectedLatLng != null
        ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
        : (_selectedLocationInfo ?? '');
    await _persistLocationString(locString);

    // 🎯 Send notifications to nearby users
    final notificationService = NotificationService();
    final notificationCount = await notificationService.notifyNearbyUsers(
      donationId: docId,
      donationData: donationData,
      maxDistanceKm: 16.0, // ~10 miles
    );

    if (mounted) {
      Navigator.of(context).pop();
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Donation submitted! $notificationCount nearby students notified.',
            style: const TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    setState(() {
      _images.clear();
      _selectedCategory = null;
      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _kgController.clear();
      _instructionsController.clear();
    });
  } catch (e, st) {
    if (mounted) {
      Navigator.of(context).pop();
    }

    setState(() => _isSubmitting = false);

    debugPrint('Upload/save error: $e\n$st');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit donation: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
*/