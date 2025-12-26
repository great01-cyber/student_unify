import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _isLoading = true;

  // Notification preferences
  bool _allNotifications = true;
  bool _newDonations = true;
  bool _nearbyItems = true;
  bool _messages = true;
  bool _priceDrops = false;
  bool _favorites = true;
  bool _campaignUpdates = true;
  bool _systemNotifications = true;

  // Push notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  // Sound and vibration
  bool _sound = true;
  bool _vibration = true;

  // Quiet hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = TimeOfDay(hour: 7, minute: 0);

  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _allNotifications = data['allNotifications'] ?? true;
          _newDonations = data['newDonations'] ?? true;
          _nearbyItems = data['nearbyItems'] ?? true;
          _messages = data['messages'] ?? true;
          _priceDrops = data['priceDrops'] ?? false;
          _favorites = data['favorites'] ?? true;
          _campaignUpdates = data['campaignUpdates'] ?? true;
          _systemNotifications = data['systemNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? false;
          _sound = data['sound'] ?? true;
          _vibration = data['vibration'] ?? true;
          _quietHoursEnabled = data['quietHoursEnabled'] ?? false;

          if (data['quietHoursStart'] != null) {
            final start = data['quietHoursStart'].split(':');
            _quietHoursStart = TimeOfDay(
              hour: int.parse(start[0]),
              minute: int.parse(start[1]),
            );
          }

          if (data['quietHoursEnd'] != null) {
            final end = data['quietHoursEnd'].split(':');
            _quietHoursEnd = TimeOfDay(
              hour: int.parse(end[0]),
              minute: int.parse(end[1]),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_userId == null) return;

    try {
      final settings = {
        'allNotifications': _allNotifications,
        'newDonations': _newDonations,
        'nearbyItems': _nearbyItems,
        'messages': _messages,
        'priceDrops': _priceDrops,
        'favorites': _favorites,
        'campaignUpdates': _campaignUpdates,
        'systemNotifications': _systemNotifications,
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'sound': _sound,
        'vibration': _vibration,
        'quietHoursEnabled': _quietHoursEnabled,
        'quietHoursStart': '${_quietHoursStart.hour}:${_quietHoursStart.minute}',
        'quietHoursEnd': '${_quietHoursEnd.hour}:${_quietHoursEnd.minute}',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('notifications')
          .set(settings, SetOptions(merge: true));

      _showSnackBar('Settings saved successfully!');

      // Update FCM token subscription based on push notification setting
      if (_pushNotifications) {
        await _subscribeToPushNotifications();
      } else {
        await _unsubscribeFromPushNotifications();
      }

    } catch (e) {
      _showSnackBar('Error saving settings: $e', isError: true);
    }
  }

  Future<void> _subscribeToPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: _sound,
      );

      // Get FCM token
      final token = await messaging.getToken();

      if (token != null && _userId != null) {
        // Save token to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      }
    } catch (e) {
      debugPrint('Error subscribing to push notifications: $e');
    }
  }

  Future<void> _unsubscribeFromPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null && _userId != null) {
        // Remove token from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }

      await messaging.deleteToken();
    } catch (e) {
      debugPrint('Error unsubscribing from push notifications: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1E3A8A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(
            'Notification Settings',
            style: TextStyle(
              fontFamily: 'Mont',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontFamily: 'Mont',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header Card
          _buildHeaderCard(),

          SizedBox(height: 16),

          // Master Toggle
          _buildSectionCard(
            title: 'Master Control',
            icon: Icons.notifications_active,
            children: [
              _buildSwitchTile(
                title: 'All Notifications',
                subtitle: 'Enable or disable all notifications',
                value: _allNotifications,
                onChanged: (value) {
                  setState(() {
                    _allNotifications = value;
                    if (!value) {
                      // Turn off all other notifications
                      _newDonations = false;
                      _nearbyItems = false;
                      _messages = false;
                      _priceDrops = false;
                      _favorites = false;
                      _campaignUpdates = false;
                      _systemNotifications = false;
                    }
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // Notification Types
          _buildSectionCard(
            title: 'Notification Types',
            icon: Icons.category,
            children: [
              _buildSwitchTile(
                title: 'New Donations',
                subtitle: 'Get notified when new items are posted',
                value: _newDonations,
                onChanged: _allNotifications
                    ? (value) => setState(() => _newDonations = value)
                    : null,
                icon: Icons.new_releases,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Nearby Items',
                subtitle: 'Alerts for donations near your location',
                value: _nearbyItems,
                onChanged: _allNotifications
                    ? (value) => setState(() => _nearbyItems = value)
                    : null,
                icon: Icons.location_on,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Messages',
                subtitle: 'New messages from other users',
                value: _messages,
                onChanged: _allNotifications
                    ? (value) => setState(() => _messages = value)
                    : null,
                icon: Icons.message,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Price Drops',
                subtitle: 'When items you\'re watching drop in price',
                value: _priceDrops,
                onChanged: _allNotifications
                    ? (value) => setState(() => _priceDrops = value)
                    : null,
                icon: Icons.trending_down,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Favorites',
                subtitle: 'Updates on your favorite items',
                value: _favorites,
                onChanged: _allNotifications
                    ? (value) => setState(() => _favorites = value)
                    : null,
                icon: Icons.favorite,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Campaign Updates',
                subtitle: 'Updates on campaigns you support',
                value: _campaignUpdates,
                onChanged: _allNotifications
                    ? (value) => setState(() => _campaignUpdates = value)
                    : null,
                icon: Icons.campaign,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'System Notifications',
                subtitle: 'Important app updates and announcements',
                value: _systemNotifications,
                onChanged: _allNotifications
                    ? (value) => setState(() => _systemNotifications = value)
                    : null,
                icon: Icons.info,
              ),
            ],
          ),

          SizedBox(height: 16),

          // Delivery Methods
          _buildSectionCard(
            title: 'Delivery Methods',
            icon: Icons.send,
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive notifications on this device',
                value: _pushNotifications,
                onChanged: _allNotifications
                    ? (value) => setState(() => _pushNotifications = value)
                    : null,
                icon: Icons.phone_android,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Receive notifications via email',
                value: _emailNotifications,
                onChanged: _allNotifications
                    ? (value) => setState(() => _emailNotifications = value)
                    : null,
                icon: Icons.email,
              ),
            ],
          ),

          SizedBox(height: 16),

          // Sound & Vibration
          _buildSectionCard(
            title: 'Sound & Vibration',
            icon: Icons.volume_up,
            children: [
              _buildSwitchTile(
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _sound,
                onChanged: _allNotifications && _pushNotifications
                    ? (value) => setState(() => _sound = value)
                    : null,
                icon: Icons.music_note,
              ),
              Divider(height: 1),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: _vibration,
                onChanged: _allNotifications && _pushNotifications
                    ? (value) => setState(() => _vibration = value)
                    : null,
                icon: Icons.vibration,
              ),
            ],
          ),

          SizedBox(height: 16),

          // Quiet Hours
          _buildSectionCard(
            title: 'Quiet Hours',
            icon: Icons.bedtime,
            children: [
              _buildSwitchTile(
                title: 'Enable Quiet Hours',
                subtitle: 'Mute notifications during specific hours',
                value: _quietHoursEnabled,
                onChanged: _allNotifications
                    ? (value) => setState(() => _quietHoursEnabled = value)
                    : null,
              ),
              if (_quietHoursEnabled) ...[
                Divider(height: 1),
                _buildTimeTile(
                  title: 'Start Time',
                  time: _quietHoursStart,
                  onTap: () => _selectTime(context, true),
                ),
                Divider(height: 1),
                _buildTimeTile(
                  title: 'End Time',
                  time: _quietHoursEnd,
                  onTap: () => _selectTime(context, false),
                ),
              ],
            ],
          ),

          SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mont',
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // Test Notification Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _allNotifications && _pushNotifications
                  ? () {
                _showSnackBar('Test notification sent!');
                // Here you would trigger a test notification
              }
                  : null,
              icon: Icon(Icons.notifications_active),
              label: Text('Send Test Notification'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF1E3A8A),
                side: BorderSide(color: Color(0xFF1E3A8A)),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Updated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Mont',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize your notification preferences',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF1E3A8A), size: 20),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Mont',
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    IconData? icon,
  }) {
    final isEnabled = onChanged != null;

    return ListTile(
      leading: icon != null
          ? Icon(
        icon,
        color: isEnabled ? Color(0xFF1E3A8A) : Colors.grey[400],
        size: 24,
      )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isEnabled ? Color(0xFF1F2937) : Colors.grey[400],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isEnabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF1E3A8A),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(Icons.access_time, color: Color(0xFF1E3A8A), size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFF1E3A8A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time.format(context),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}