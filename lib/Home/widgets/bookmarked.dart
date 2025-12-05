import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../../Models/PostModel.dart';
import '../../services/AppUser.dart';
import '../community.dart';
// NOTE: Adjust imports as necessary for your project structure

class BookmarkedPostsPage extends StatefulWidget {
  final AppUser currentUser;

  const BookmarkedPostsPage({super.key, required this.currentUser});

  @override
  State<BookmarkedPostsPage> createState() => _BookmarkedPostsPageState();
}

class _BookmarkedPostsPageState extends State<BookmarkedPostsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String _currentUserId; // Initialized in initState

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_currentUserId.isEmpty) {
      debugPrint("Error: Current user ID is empty.");
    }
  }

  // --- 1. Database Stream Function ---
  Stream<List<Post>> _getBookmarkedPostsStream() {
    if (_currentUserId.isEmpty) {
      return Stream.value([]);
    }

    // Query: Filter posts where the user's ID is in the 'bookmarks' array
    Query query = _firestore
        .collection('posts')
        .where('bookmarks', arrayContains: _currentUserId) // The essential filter
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // --- 2. Helper Functions (Placeholders for required methods) ---

  // Utility to convert timestamp to readable format
  String _getRelativeTime(Timestamp? timestamp) {
    if (timestamp == null) return 'unknown time';
    // Implementation needed here
    return '1h ago';
  }

  // Define the required callback functions for PostCard
  void _toggleLike(String postId, bool isLiked, int currentLikes) {
    debugPrint('Toggle like for $postId');
  }

  void _openComments(Post post) {
    //debugPrint('Open comments for $postId');
  }

  void _sharePost(Post post) {
    //debugPrint('Share post $postId');
  }

  void _toggleBookmark(String postId, bool isBookmarked) {
    debugPrint('Toggle bookmark for $postId');
  }

  void _editPost(Post post) {
    //debugPrint('Edit post $postId');
  }

  void _deletePost(String postId) {
    debugPrint('Delete post $postId');
  }


  // --- 3. Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookmarked Posts 🔖"),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Post>>(
        stream: _getBookmarkedPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data;

          if (posts == null || posts.isEmpty) {
            // Empty state message
            return const Center(
              child: Text(
                'You have no bookmarked posts.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // List View Builder with PostCard
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = posts[index];

              // Pass all required data and callbacks to PostCard
              return PostCard(
                post: post,
                currentUserId: _currentUserId,
                relativeTime: _getRelativeTime(post.createdAt),

                onLike: () => _toggleLike(post.id, post.isLiked, post.likes),
                onComment: () => _openComments(post),
                onShare: () => _sharePost(post),
                onBookmark: () => _toggleBookmark(post.id, post.isBookmarked),
                onEdit: () => _editPost(post),
                onDelete: () => _deletePost(post.id),
              );
            },
          );
        },
      ),
    );
  }
}