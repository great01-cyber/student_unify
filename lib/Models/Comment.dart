import 'package:cloud_firestore/cloud_firestore.dart';// Place this in your models directory or in the same file for quick testing
class Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final Timestamp createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      username: map['username'] as String,
      text: map['text'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }
}