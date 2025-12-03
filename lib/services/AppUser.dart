import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final String university;
  final String fcmToken;
  final String city;

  // ✅ Add latitude and longitude
  final double? latitude;
  final double? longitude;

  AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    required this.university,
    required this.fcmToken,
    required this.city,
    this.displayName,
    this.photoUrl,
    this.latitude,
    this.longitude,
  });

  // Firestore → AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      university: map['university'] as String? ?? '',
      fcmToken: map['fcmToken'] as String? ?? '',
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  // AppUser → Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'university': university,
      'fcmToken': fcmToken,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
