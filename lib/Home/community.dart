import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:student_unify_app/Home/widgets/LikePage.dart';
import 'package:student_unify_app/Home/widgets/bookmarked.dart';

import '../Models/Comment.dart';
import '../Models/PostModel.dart';
import '../services/AppUser.dart';


class CommunityPageContent extends StatefulWidget {
  final AppUser currentUser;

  const CommunityPageContent({super.key, required this.currentUser});

  @override
  State<CommunityPageContent> createState() => _CommunityPageContentState();
}

class _CommunityPageContentState extends State<CommunityPageContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> categories = [
    "All",
    "Study Tips",
    "Cleaning Hacks",
    "Cheap Meals",
    "DIY Repairs",
    "Opportunities",
    "Travel",
  ];

  int selectedCategoryIndex = 0;
  String selectedCategory = "All";

  void _toggleLike(String postId, bool currentLikedState, int currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    try {
      if (currentLikedState) {
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid])
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _toggleBookmark(String postId, bool isBookmarked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final postRef = _firestore.collection('posts').doc(postId);

      await postRef.update({
        'bookmarks': isBookmarked
            ? FieldValue.arrayRemove([user.uid])
            : FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      print("🔥 Error toggling bookmark: $e");
    }
  }

  // ✅ FIXED: Image source picker with proper parameter type
  void _pickImageSource(StateSetter setDialogState, File? Function() getSelectedImage, void Function(File?) setSelectedImage) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: 150,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setDialogState(() {
                        setSelectedImage(File(image.path));
                      });
                    }
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setDialogState(() {
                        setSelectedImage(File(image.path));
                      });
                    }
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(Post post) {
    final TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Optional header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              // The StreamBuilder goes here
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post.id)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final comments = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        final data = comments[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(data['username'][0].toUpperCase()),
                          ),
                          title: Text(data['username']),
                          subtitle: Text(data['text']),
                        );
                      },
                    );
                  },
                ),
              ),

              // Optional input to add a new comment
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController, // define this controller in your CommentPage
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        final commentText = _commentController.text.trim();
                        if (commentText.isEmpty) return;

                        try {
                          // Add comment to Firestore
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(post.id) // the current post
                              .collection('comments')
                              .add({
                            'username': widget.currentUser.displayName ?? 'Anonymous',
                            'userId': widget.currentUser.uid,
                            'text': commentText,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          // Increment comment count in the post document
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(post.id)
                              .update({
                            'comments': FieldValue.increment(1),
                          });

                          // Clear the TextField after sending
                          _commentController.clear();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error posting comment: $e')),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _sharePost(Post post) async {
    final shareText = "Check out this post from the community: \"${post.text}\"";
    await Share.share(
      shareText,
      subject: 'Community Post: ${post.tags.join(', ')}',
    );
  }

  Future<String?> _uploadImageToStorage(File imageFile, String postId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('community_posts')
          .child(postId)
          .child('post_image.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image to storage: $e');
      return null;
    }
  }

  void _createPost() async {
    final TextEditingController textController = TextEditingController();
    File? selectedImage;
    List<String> selectedTags = [];
    bool isUploading = false;

    // 1. Replace showDialog with showModalBottomSheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial for full screen and keyboard handling
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {

          // 2. Wrap content in a Container that defines the sheet's size and shape
          return Container(
            // Set sheet height to take up 90% of the screen
            height: MediaQuery.of(context).size.height * 0.9,
            // Add padding for the keyboard push-up
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),

            // 3. New Column structure for Header + Scrollable Content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header/Drag Handle ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // --- Title & Action Buttons (Replacing AlertDialog Title/Actions) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isUploading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                      const Text(
                        'Create Post',
                        style: TextStyle(
                            fontFamily: 'Mont',
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      // Post Button with Upload Logic
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                          // --- POST SUBMISSION LOGIC (UNCHANGED) ---
                          if (textController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter some text')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                          });

                          try {
                            final docRef = _firestore.collection('posts').doc();
                            String? imageUrl;
                            if (selectedImage != null) {
                              imageUrl = await _uploadImageToStorage(selectedImage!, docRef.id);
                            }

                            await docRef.set({
                              'id': docRef.id,
                              'userId': widget.currentUser.uid,
                              'username': widget.currentUser.displayName ?? 'Anonymous',
                              'userPhotoUrl': widget.currentUser.photoUrl,
                              'university': widget.currentUser.university,
                              'createdAt': FieldValue.serverTimestamp(),
                              'text': textController.text.trim(),
                              'imageUrl': imageUrl,
                              'tags': selectedTags,
                              'likes': 0,
                              'comments': 0,
                              'likedBy': [],
                              'bookmarks': [],
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post created successfully!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating post: $e')),
                              );
                            }
                          } finally {
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                        },
                        // Loading Indicator (UNCHANGED)
                        child: isUploading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Post'),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 20),

                // 4. Scrollable Content (Takes up remaining space using Expanded)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Allows Column to size itself based on children
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Text (UNCHANGED)
                        TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            labelText: 'What\'s on your mind?',
                            border: OutlineInputBorder(),
                            hintText: 'Share your thoughts...',
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        // Image Display (The part that caused the LayoutBuilder issue)
                        if (selectedImage != null) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  width: double.infinity, // Now works great inside Expanded/SingleChildScrollView
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImage = null;
                                    });
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Add Image Button (UNCHANGED)
                        OutlinedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () {
                            _pickImageSource(
                              setDialogState,
                                  () => selectedImage,
                                  (file) => selectedImage = file,
                            );
                          },
                          icon: const Icon(Icons.image),
                          label: Text(
                            style: TextStyle(fontFamily: 'Mont'),
                              selectedImage == null ? 'Add Image' : 'Change Image'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tags Selection (UNCHANGED)
                        const Text(
                          'Select Tags',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .where((cat) => cat != "All")
                              .map((tag) {
                            final isSelected = selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: isUploading
                                  ? (_) {}
                                  : (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedTags.add(tag);
                                  } else {
                                    selectedTags.remove(tag);
                                  }
                                });
                              },
                              selectedColor: Colors.blueAccent.withOpacity(0.3),
                              checkmarkColor: Colors.blueAccent,
                            );
                          }).toList(),
                        ),

                        // Final padding to ensure bottom items are visible above the keyboard
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Stream<List<Post>> _getPostsStream() {
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (selectedCategory != "All") {
      query = query.where('tags', arrayContains: selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  String _getRelativeTime(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Community",
          style: TextStyle(
            color: Colors.pinkAccent,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mont'
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedPostsPage(currentUser: widget.currentUser),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookmarkedPostsPage(currentUser: widget.currentUser),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories Row - Scrollable
          Container(
            height: 60,
            color: Colors.grey[100],
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return CategoryChip(
                  label: categories[index],
                  isSelected: selectedCategoryIndex == index,
                  onTap: () {
                    setState(() {
                      selectedCategoryIndex = index;
                      selectedCategory = categories[index];
                    });
                  },
                );
              },
            ),
          ),

          // Feed from Firebase - Scrollable with Filtering
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          selectedCategory == "All"
                              ? 'No posts yet'
                              : 'No posts in $selectedCategory',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedCategory == "All"
                              ? 'Be the first to share something!'
                              : 'Try selecting a different category',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final posts = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return PostCard(
                      post: posts[index],
                      relativeTime: _getRelativeTime(posts[index].createdAt),
                      onLike: () => _toggleLike(
                        posts[index].id,
                        posts[index].isLiked,
                        posts[index].likes,
                      ),
                      onComment: () => _openComments(posts[index]),
                      onShare: () => _sharePost(posts[index]),
                      onBookmark: () => _toggleBookmark(
                        posts[index].id,
                        posts[index].isBookmarked,
                      ), onEdit: () {  }, onDelete: () {  }, currentUserId: '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        label: const Text("Post"),
        icon: const Icon(Icons.edit),
        onPressed: _createPost,
      ),
    );
  }
}

// ========== CATEGORY CHIP WIDGET ==========
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// ========== POST CARD WIDGET ==========
class PostCard extends StatelessWidget {
  final Post post;
  final String relativeTime;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;

  const PostCard({
    super.key,
    required this.post,
    required this.relativeTime,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark, required void Function() onEdit, required void Function() onDelete, required String currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                backgroundImage: post.userPhotoUrl != null
                    ? NetworkImage(post.userPhotoUrl!)
                    : null,
                child: post.userPhotoUrl == null
                    ? Text(
                  post.username.isNotEmpty
                      ? post.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${post.university} • $relativeTime",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),

          const SizedBox(height: 12),

          // Post text
          Text(
            post.text,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 12),

          // ✅ IMPROVED Image Display - Handles any size
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            const SizedBox(height: 12),

          // Tags
          if (post.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.tags
                  .map((t) => Chip(
                label: Text(
                  "#$t",
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ))
                  .toList(),
            ),

          const SizedBox(height: 10),

          // Buttons: like, comment, share, bookmark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: post.likes > 0 ? post.likes.toString() : null,
                color: post.isLiked ? Colors.red : Colors.grey[700],
                onTap: onLike,
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: post.comments > 0 ? post.comments.toString() : null,
                color: Colors.grey[700],
                onTap: onComment,
              ),
              _ActionButton(
                icon: Icons.share,
                color: Colors.grey[700],
                onTap: onShare,
              ),
              _ActionButton(
                icon:
                post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: post.isBookmarked ? Colors.blueAccent : Colors.grey[700],
                onTap: onBookmark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== ACTION BUTTON WIDGET ==========
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== COMMENT PAGE WIDGET ==========
class CommentPage extends StatefulWidget {
  final Post post;
  final AppUser currentUser;

  const CommentPage({super.key, required this.post, required this.currentUser});
  Future<void> addComment(String postId, String commentText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'id': commentRef.id,
      'userId': user.uid,
      'username': user.displayName ?? 'Anonymous',
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Also increment comment counter
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'comments': FieldValue.increment(1)});
  }


  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      // 1. Add the new comment document (Asynchronous)
      await _firestore
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .add({
        'userId': widget.currentUser.uid,
        'username': widget.currentUser.displayName ?? 'Student',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment the comment count on the parent post (Asynchronous)
      await _firestore.collection('posts').doc(widget.post.id).update({
        'comments': FieldValue.increment(1),
      });

      // 3. UI interaction must be preceded by a mounted check.
      if (mounted) {
        _commentController.clear();
        // Optionally, you might want to automatically close the keyboard here.
        // FocusScope.of(context).unfocus();
      }
    } catch (e) {
      // Error handling block correctly uses 'if (mounted)'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting comment: $e')),
        );
      }
    }
  }

  Stream<List<Comment>> _getCommentsStream() {
    return _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comment.fromMap(doc.data());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${widget.post.comments} Comments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: _getCommentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Be the first to comment!',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              final comments = snapshot.data!;
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(comment.username[0].toUpperCase()),
                    ),
                    title: Text(comment.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(comment.text),
                    trailing: Text(
                      '${(DateTime.now().difference(comment.createdAt.toDate()).inMinutes)}m ago',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),

        Padding(
          padding:
          MediaQuery.of(context).viewInsets.copyWith(top: 8, bottom: 8),
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: _submitComment,
              ),
            ),
            onSubmitted: (_) => _submitComment(),
          ),
        ),
      ],
    );
  }
}

