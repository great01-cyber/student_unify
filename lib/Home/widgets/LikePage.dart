import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../../Models/PostModel.dart';
import '../../services/AppUser.dart';
import '../community.dart';
// NOTE: Adjust imports as necessary for your project structure

class LikedPostsPage extends StatefulWidget {
  final AppUser currentUser;

  const LikedPostsPage({super.key, required this.currentUser});

  @override
  State<LikedPostsPage> createState() => _LikedPostsPageState();
}

class _LikedPostsPageState extends State<LikedPostsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String _currentUserId; // Initialized in initState

  @override
  void initState() {
    super.initState();
    // Safely get the current authenticated user's ID
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_currentUserId.isEmpty) {
      // Handle case where user is not logged in if this page is somehow reached
      // You might want to navigate back or show an error.
      debugPrint("Error: Current user ID is empty.");
    }
  }

  // --- 1. Database Stream Function ---
  Stream<List<Post>> _getLikedPostsStream() {
    if (_currentUserId.isEmpty) {
      return Stream.value([]); // Return empty stream if no user is logged in
    }

    // Query: Filter posts where the user's ID is in the 'likedBy' array
    Query query = _firestore
        .collection('posts')
        .where('likedBy', arrayContains: _currentUserId) // The essential filter
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Post.fromMap should correctly calculate post.isLiked and post.isBookmarked
        // based on the presence of _currentUserId in the respective arrays.
        return Post.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // --- 2. Helper Functions (Placeholders for required methods) ---

  // Utility to convert timestamp to readable format
  String _getRelativeTime(Timestamp? timestamp) {
    if (timestamp == null) return 'unknown time';
    // Implementation needed here (e.g., using timeago package)
    return '1h ago';
  }

  // Define the required callback functions for PostCard
  void _toggleLike(String postId, bool isLiked, int currentLikes) {
    // Logic to update Firestore (arrayUnion/arrayRemove, increment/decrement)
    debugPrint('Toggle like for $postId');
  }

  void _openComments(Post post) {
    // Logic to navigate to the comments page

  }

  void _sharePost(Post post) {

  }

  void _toggleBookmark(String postId, bool isBookmarked) {
    // Logic to update Firestore bookmarks array
    debugPrint('Toggle bookmark for $postId');
  }

  void _editPost(Post post) {
    // Logic for editing a post (optional for liked page, but needed by PostCard)

  }

  void _deletePost(String postId) {
    // Logic for deleting a post (optional for liked page, but needed by PostCard)
    debugPrint('Delete post $postId');
  }


  // --- 3. Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liked Posts ❤️"),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Post>>(
        stream: _getLikedPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Handle database query errors
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data;

          if (posts == null || posts.isEmpty) {
            // Empty state message
            return const Center(
              child: Text(
                'You haven\'t liked any posts yet.',
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

              // 🔑 FIX: Correctly pass all required data and callbacks to PostCard
              return PostCard(
                post: post,
                currentUserId: _currentUserId,
                relativeTime: _getRelativeTime(post.createdAt),

                // Pass the callback functions
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