import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final bool emailVerified;

  final String? displayName;
  final String? photoUrl;

  /// Personal email for account recovery and alumni updates
  final String? personalEmail;

  final String university;

  /// Expected graduation year
  final int? graduationYear;

  /// Multiple device tokens support
  final List<String> fcmTokens;

  /// Location (optional)
  final double? latitude;
  final double? longitude;

  /// Role: "student" | "nonStudent"
  final String role;

  /// ✅ NEW: Effective role that accounts for verification status
  /// - "student" = verified student with full access
  /// - "pendingStudent" = unverified student (limited/no access)
  /// - "nonStudent" = non-student user
  final String roleEffective;

  /// Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.role,
    required this.roleEffective,
    required this.createdAt,
    required this.university,
    required this.fcmTokens,
    this.displayName,
    this.photoUrl,
    this.personalEmail,
    this.graduationYear,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  /// Convenience getters
  bool get isStudent => roleEffective.toLowerCase() == 'student';
  bool get isPendingStudent => roleEffective.toLowerCase() == 'pendingstudent';
  bool get isVerifiedStudent => isStudent && emailVerified;

  // 🔹 Firestore → AppUser
  factory AppUser.fromMap(Map<String, dynamic> map, {required String uid}) {
    final role = map['role'] as String? ?? 'nonStudent';
    final emailVerified = map['emailVerified'] as bool? ?? false;

    // ✅ Calculate roleEffective if not present
    String roleEffective = map['roleEffective'] as String? ?? role;

    // If role is student but email isn't verified, ensure roleEffective is pendingStudent
    if (role.toLowerCase() == 'student' && !emailVerified && roleEffective != 'pendingStudent') {
      roleEffective = 'pendingStudent';
    }

    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      emailVerified: emailVerified,
      role: role,
      roleEffective: roleEffective,

      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      personalEmail: map['personalEmail'] as String?,
      university: map['university'] as String? ?? '',
      graduationYear: map['graduationYear'] as int?,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? const <String>[]),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),

      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // 🔹 AppUser → Firestore
  Map<String, dynamic> toMap({bool isCreating = false}) {
    return {
      'email': email,
      'emailVerified': emailVerified,
      'role': role,
      'roleEffective': roleEffective,

      'displayName': displayName,
      'photoUrl': photoUrl,
      'personalEmail': personalEmail,
      'university': university,
      'graduationYear': graduationYear,
      'fcmTokens': fcmTokens,
      'latitude': latitude,
      'longitude': longitude,

      'createdAt': isCreating
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // 🔹 copyWith (for updates)
  AppUser copyWith({
    String? email,
    bool? emailVerified,
    String? role,
    String? roleEffective,
    String? displayName,
    String? photoUrl,
    String? personalEmail,
    String? university,
    int? graduationYear,
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
      role: role ?? this.role,
      roleEffective: roleEffective ?? this.roleEffective,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      personalEmail: personalEmail ?? this.personalEmail,
      university: university ?? this.university,
      graduationYear: graduationYear ?? this.graduationYear,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}