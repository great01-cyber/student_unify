import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
  });

  // Firestore -> AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // AppUser -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}