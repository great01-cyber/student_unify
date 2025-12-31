import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Firebase-integrated Badge Service
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate badges for a specific user based on their donations
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      // Get all donations where user is the donor
      final donorQuery = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .get();

      List<Donation> userDonations = donorQuery.docs
          .map((doc) => Donation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Calculate stats
      int totalDonations = userDonations.length;

      // Count unique students helped (unique receiverIds with confirmed donations)
      Set<String> uniqueStudentsHelped = userDonations
          .where((d) => d.receiverId != null && d.receiverId!.isNotEmpty)
          .map((d) => d.receiverId!)
          .toSet();
      int uniqueStudentsCount = uniqueStudentsHelped.length;

      // Get donation dates for streak calculation
      List<DateTime> donationDates = userDonations
          .map((d) => d.createdAt)
          .toList();
      donationDates.sort((a, b) => b.compareTo(a)); // Sort descending

      int currentStreak = _calculateStreak(donationDates);

      // Check if user donated within 24 hours of any donation creation
      bool hasEarlySupport = _checkEarlySupporter(userDonations);

      // Check if user has received help (check if they are a receiver)
      bool hasReceivedHelp = await _checkIfReceivedHelp(userId);

      // Generate badges with calculated data
      return _generateBadges(
        totalDonations: totalDonations,
        uniqueStudentsHelped: uniqueStudentsCount,
        currentStreak: currentStreak,
        hasEarlySupport: hasEarlySupport,
        hasReceivedHelp: hasReceivedHelp,
      );
    } catch (e) {
      print('Error getting user badges: $e');
      return _generateBadges(); // Return empty/locked badges on error
    }
  }

  // Calculate consecutive day streak
  int _calculateStreak(List<DateTime> donationDates) {
    if (donationDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Group donations by day
    Set<String> donationDays = donationDates.map((date) {
      return '${date.year}-${date.month}-${date.day}';
    }).toSet();

    for (int i = 0; i < 30; i++) {
      String dayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';

      if (donationDays.contains(dayKey)) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else {
        // Allow grace period for today/yesterday
        if (i <= 1) {
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return streak;
  }

  // Check if any donation was made within 24 hours of creation
  // (For early supporter badge - checking if user donated quickly after listing was created)
  bool _checkEarlySupporter(List<Donation> donations) {
    for (var donation in donations) {
      if (donation.receiverId != null && donation.receiverId!.isNotEmpty) {
        // Check if there's a receiver confirmation (meaning donation was completed)
        // You might want to add a "completedAt" timestamp to track when donation was actually given
        // For now, we'll check if donation was created and confirmed quickly
        if (donation.receiverConfirmed || donation.donorConfirmed) {
          // If donation has receiver and was confirmed, consider it for early supporter
          // In a real scenario, you'd track when the campaign/request was created vs when donated
          return true; // Simplified - you may want more sophisticated logic
        }
      }
    }
    return false;
  }

  // Check if user has received any donations
  Future<bool> _checkIfReceivedHelp(String userId) async {
    final receivedQuery = await _firestore
        .collection('donations')
        .where('receiverId', isEqualTo: userId)
        .limit(1)
        .get();

    return receivedQuery.docs.isNotEmpty;
  }

  // Generate badges based on calculated stats
  List<BadgeModel> _generateBadges({
    int totalDonations = 0,
    int uniqueStudentsHelped = 0,
    int currentStreak = 0,
    bool hasEarlySupport = false,
    bool hasReceivedHelp = false,
  }) {
    return [
      BadgeModel(
        id: 1,
        name: 'Peer Helper',
        description: 'Complete your first donation to unlock this badge',
        requirement: 'Make 1 donation to a fellow student',
        icon: Icons.favorite,
        unlocked: totalDonations >= 1,
        gradientColors: [Color(0xFFFB7185), Color(0xFFDB2777)],
        progress: totalDonations,
        maxProgress: 1,
      ),
      BadgeModel(
        id: 2,
        name: 'Student-to-Student',
        description: 'Build a stronger student community',
        requirement: 'Donate to 5 fellow students',
        icon: Icons.groups,
        unlocked: uniqueStudentsHelped >= 5,
        gradientColors: [Color(0xFF60A5FA), Color(0xFF4F46E5)],
        progress: uniqueStudentsHelped,
        maxProgress: 5,
      ),
      BadgeModel(
        id: 3,
        name: 'Growing Supporter',
        description: 'Your generosity is growing',
        requirement: 'Complete 10 donations',
        icon: Icons.local_florist,
        unlocked: totalDonations >= 10,
        gradientColors: [Color(0xFF86EFAC), Color(0xFF22C55E)],
        progress: totalDonations,
        maxProgress: 10,
      ),
      BadgeModel(
        id: 4,
        name: 'Committed Helper',
        description: 'Making a real difference',
        requirement: 'Complete 15 donations',
        icon: Icons.volunteer_activism,
        unlocked: totalDonations >= 15,
        gradientColors: [Color(0xFFE879F9), Color(0xFFC026D3)],
        progress: totalDonations,
        maxProgress: 15,
      ),
      BadgeModel(
        id: 5,
        name: 'Campus Champion',
        description: 'Help multiple students across campus',
        requirement: 'Complete 25 donations',
        icon: Icons.emoji_events,
        unlocked: totalDonations >= 25,
        gradientColors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
        progress: totalDonations,
        maxProgress: 25,
      ),
      BadgeModel(
        id: 6,
        name: 'Generous Heart',
        description: 'Your kindness knows no bounds',
        requirement: 'Complete 35 donations',
        icon: Icons.favorite_border,
        unlocked: totalDonations >= 35,
        gradientColors: [Color(0xFFF472B6), Color(0xFFEC4899)],
        progress: totalDonations,
        maxProgress: 35,
      ),
      BadgeModel(
        id: 7,
        name: 'Support Specialist',
        description: 'A pillar of the community',
        requirement: 'Complete 50 donations',
        icon: Icons.star_rate,
        unlocked: totalDonations >= 50,
        gradientColors: [Color(0xFF818CF8), Color(0xFF6366F1)],
        progress: totalDonations,
        maxProgress: 50,
      ),
      BadgeModel(
        id: 8,
        name: 'Elite Contributor',
        description: 'Among the top supporters',
        requirement: 'Complete 75 donations',
        icon: Icons.military_tech,
        unlocked: totalDonations >= 75,
        gradientColors: [Color(0xFF34D399), Color(0xFF059669)],
        progress: totalDonations,
        maxProgress: 75,
      ),
      BadgeModel(
        id: 9,
        name: 'Student Legend',
        description: 'The ultimate student supporter',
        requirement: 'Complete 100 donations to fellow students',
        icon: Icons.workspace_premium,
        unlocked: totalDonations >= 100,
        gradientColors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
        progress: totalDonations,
        maxProgress: 100,
      ),
      BadgeModel(
        id: 10,
        name: 'Streak Master',
        description: 'Keep your giving streak alive',
        requirement: 'Donate for 7 consecutive days',
        icon: Icons.flash_on,
        unlocked: currentStreak >= 7,
        gradientColors: [Color(0xFFFACC15), Color(0xFFF97316)],
        progress: currentStreak,
        maxProgress: 7,
      ),
      BadgeModel(
        id: 11,
        name: 'Early Supporter',
        description: 'Be among the first to help',
        requirement: 'Donate within 24 hours of campaign launch',
        icon: Icons.star,
        unlocked: hasEarlySupport,
        gradientColors: [Color(0xFFC084FC), Color(0xFFDB2777)],
        progress: hasEarlySupport ? 1 : 0,
        maxProgress: 1,
      ),
    ];
  }

  // Get donation stats for display
  Future<DonationStats> getUserStats(String userId) async {
    try {
      final donorQuery = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .get();

      List<Donation> userDonations = donorQuery.docs
          .map((doc) => Donation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      Set<String> uniqueStudentsHelped = userDonations
          .where((d) => d.receiverId != null && d.receiverId!.isNotEmpty)
          .map((d) => d.receiverId!)
          .toSet();

      List<DateTime> donationDates = userDonations
          .map((d) => d.createdAt)
          .toList();
      donationDates.sort((a, b) => b.compareTo(a));

      return DonationStats(
        totalDonations: userDonations.length,
        uniqueStudentsHelped: uniqueStudentsHelped.length,
        currentStreak: _calculateStreak(donationDates),
      );
    } catch (e) {
      print('Error getting user stats: $e');
      return DonationStats(
        totalDonations: 0,
        uniqueStudentsHelped: 0,
        currentStreak: 0,
      );
    }
  }

  // Listen to real-time badge updates
  Stream<List<BadgeModel>> watchUserBadges(String userId) {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: userId)
        .snapshots()
        .asyncMap((_) => getUserBadges(userId));
  }

  // Listen to real-time stats updates
  Stream<DonationStats> watchUserStats(String userId) {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: userId)
        .snapshots()
        .asyncMap((_) => getUserStats(userId));
  }
}

// Stats model
class DonationStats {
  final int totalDonations;
  final int uniqueStudentsHelped;
  final int currentStreak;

  DonationStats({
    required this.totalDonations,
    required this.uniqueStudentsHelped,
    required this.currentStreak,
  });
}

// Badge Model (same as before)
class BadgeModel {
  final int id;
  final String name;
  final String description;
  final String requirement;
  final IconData icon;
  final bool unlocked;
  final List<Color> gradientColors;
  final int progress;
  final int maxProgress;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.requirement,
    required this.icon,
    required this.unlocked,
    required this.gradientColors,
    this.progress = 0,
    this.maxProgress = 1,
  });
}

// Import your Donation model (this would be in a separate file)
class Donation {
  final String? id;
  final String donorId;
  final String category;
  final String title;
  final String description;
  final double? price;
  final double? kg;
  final List<String> imageUrls;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? instructions;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final String donorPhoto;
  final String donorName;
  final String ownerId;
  final String ownerName;
  final String? receiverId;
  final bool donorConfirmed;
  final DateTime? donorConfirmedDate;
  final bool receiverConfirmed;
  final DateTime? receiverConfirmedDate;

  Donation({
    this.id,
    required this.donorId,
    required this.category,
    required this.title,
    required this.description,
    this.price,
    this.kg,
    this.imageUrls = const [],
    this.availableFrom,
    this.availableUntil,
    this.instructions,
    this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
    required this.ownerId,
    required this.ownerName,
    required this.donorName,
    required this.donorPhoto,
    this.receiverId,
    this.donorConfirmed = false,
    this.donorConfirmedDate,
    this.receiverConfirmed = false,
    this.receiverConfirmedDate,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id']?.toString(),
      donorId: map['donorId'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      kg: map['kg'] != null ? (map['kg'] as num).toDouble() : null,
      imageUrls: map['imageUrls'] is String
          ? List<String>.from(map['imageUrls'])
          : List<String>.from(map['imageUrls'] ?? []),
      availableFrom: map['availableFrom'] == null
          ? null
          : (map['availableFrom'] is Timestamp
          ? (map['availableFrom'] as Timestamp).toDate()
          : DateTime.parse(map['availableFrom'])),
      availableUntil: map['availableUntil'] == null
          ? null
          : (map['availableUntil'] is Timestamp
          ? (map['availableUntil'] as Timestamp).toDate()
          : DateTime.parse(map['availableUntil'])),
      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'])),
      instructions: map['instructions'],
      locationAddress: map['locationAddress'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      ownerId: map['ownerId'] ?? "",
      ownerName: map['ownerName'] ?? "Unknown",
      donorName: map['donorName'] ?? "Unknown Donor",
      donorPhoto: map['donorPhoto'] ?? "",
      receiverId: map['receiverId'],
      donorConfirmed: map['donorConfirmed'] ?? false,
      donorConfirmedDate: map['donorConfirmedDate'] == null
          ? null
          : (map['donorConfirmedDate'] is Timestamp
          ? (map['donorConfirmedDate'] as Timestamp).toDate()
          : DateTime.parse(map['donorConfirmedDate'])),
      receiverConfirmed: map['receiverConfirmed'] ?? false,
      receiverConfirmedDate: map['receiverConfirmedDate'] == null
          ? null
          : (map['receiverConfirmedDate'] is Timestamp
          ? (map['receiverConfirmedDate'] as Timestamp).toDate()
          : DateTime.parse(map['receiverConfirmedDate'])),
    );
  }
}