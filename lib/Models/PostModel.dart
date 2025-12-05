import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Post {
  final String id;
  final String userId; // links to AppUser.uid
  final String username;
  final String? userPhotoUrl;
  final String university;
  final Timestamp createdAt;

  final String text;
  final String? imageUrl;
  final List<String> tags;

  final int likes;
  final int comments;
  final bool isLiked;
  final bool isBookmarked;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.university,
    required this.createdAt,
    required this.text,
    this.userPhotoUrl,
    this.imageUrl,
    required this.tags,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  // -----------------------------
  // COPY WITH
  // -----------------------------
  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? university,
    Timestamp? createdAt,
    String? text,
    String? imageUrl,
    List<String>? tags,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      university: university ?? this.university,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // -----------------------------
  // TO MAP (Firestore)
  // -----------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'university': university,
      'createdAt': createdAt,
      'text': text,
      'imageUrl': imageUrl,
      'tags': tags,
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
    };
  }

  // -----------------------------
  // FROM MAP (Firestore)
  // -----------------------------
  factory Post.fromMap(Map<String, dynamic> map) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    final List likedBy = map['likedBy'] ?? [];
    final List bookmarks = map['bookmarks'] ?? [];

    return Post(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      university: map['university'] ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      tags: List<String>.from(map['tags'] ?? []),

      // 🔥 TRUE number of likes
      likes: likedBy.length,

      // 🔥 TRUE number of comments
      comments: map['comments'] ?? 0,

      // 🔥 FIXED — compute booleans from the arrays
      isLiked: likedBy.contains(currentUserId),
      isBookmarked: bookmarks.contains(currentUserId),
    );
  }

  // -----------------------------
  // JSON (Optional)
  // -----------------------------
  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) =>
      Post.fromMap(json.decode(source));
}
