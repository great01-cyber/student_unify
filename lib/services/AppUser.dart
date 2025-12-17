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
  factory AppUser.fromMap(Map<String, dynamic> map, {required String uid}) {
    return AppUser(
      uid: uid,
      email: map['email'] as String,
      emailVerified: map['emailVerified'] as bool? ?? false,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      university: map['university'] as String? ?? '',
      city: map['city'] as String? ?? '',
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
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
