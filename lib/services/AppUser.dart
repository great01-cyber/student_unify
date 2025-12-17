import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final bool emailVerified;

  final String? displayName;
  final String? photoUrl;

  final String university;
  final String city;

  /// Multiple device tokens support
  final List<String> fcmTokens;

  /// Location (optional)
  final double? latitude;
  final double? longitude;

  /// Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    required this.university,
    required this.city,
    required this.fcmTokens,
    this.displayName,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  // 🔹 Firestore → AppUser
  factory AppUser.fromMap(Map<String, dynamic> map, {String? uid}) {
    return AppUser(
      uid: uid ?? map['uid'] ?? '', // Try to get from parameter first, then from map
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      university: map['university'] ?? '',
      city: map['city'] ?? '',
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      photoUrl: map['photoUrl'],
    );
  }

  // 🔹 AppUser → Firestore
  Map<String, dynamic> toMap({bool isCreating = false}) {
    return {
      'email': email,
      'emailVerified': emailVerified,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'university': university,
      'city': city,
      'fcmTokens': fcmTokens,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt':
      isCreating ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // 🔹 copyWith (for updates)
  AppUser copyWith({
    String? email,
    bool? emailVerified,
    String? displayName,
    String? photoUrl,
    String? university,
    String? city,
    List<String>? fcmTokens,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      university: university ?? this.university,
      city: city ?? this.city,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
