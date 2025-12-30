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

// Color palette - consistent with the app
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

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

  void _pickImageSource(StateSetter setDialogState, File? Function() getSelectedImage, void Function(File?) setSelectedImage) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFamily: 'Mont',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () async {
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
                ),
                _buildImageSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () async {
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
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryPink, accentPink],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryPink.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: 'Mont',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(Post post) {
    final TextEditingController commentController = TextEditingController();
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
              // Header
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryPink, accentPink],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.comment_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mont',
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),

              // Comments List
              Expanded(
                child: StreamBuilder(
                  stream: _firestore
                      .collection('posts')
                      .doc(post.id)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                        ),
                      );
                    }

                    final comments = snapshot.data!.docs;

                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 60,
                              color: lightText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                color: lightText,
                                fontSize: 16,
                                fontFamily: 'Mont',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        final data = comments[index].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lightPink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: lightPink, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: lightPink,
                                  child: Text(
                                    data['username'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: primaryPink,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mont',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['username'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        fontFamily: 'Mont',
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['text'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Mont',
                                        color: darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: lightPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: lightPink),
                        ),
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(
                              fontFamily: 'Mont',
                              color: lightText,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontFamily: 'Mont'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryPink, accentPink],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryPink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () async {
                          final commentText = commentController.text.trim();
                          if (commentText.isEmpty) return;

                          try {
                            await _firestore
                                .collection('posts')
                                .doc(post.id)
                                .collection('comments')
                                .add({
                              'username': widget.currentUser.displayName ?? 'Anonymous',
                              'userId': widget.currentUser.uid,
                              'text': commentText,
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            await _firestore
                                .collection('posts')
                                .doc(post.id)
                                .update({
                              'comments': FieldValue.increment(1),
                            });

                            commentController.clear();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error posting comment: $e')),
                            );
                          }
                        },
                      ),
                    ),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isUploading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isUploading ? lightText : Colors.red,
                            fontFamily: 'Mont',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'Create Post',
                        style: TextStyle(
                          fontFamily: 'Mont',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                          if (textController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter some text'),
                                backgroundColor: primaryPink,
                              ),
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
                                const SnackBar(
                                  content: Text('Post created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isUploading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Post',
                          style: TextStyle(
                            fontFamily: 'Mont',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 20, color: lightPink),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text Field
                        Container(
                          decoration: BoxDecoration(
                            color: lightPink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: lightPink),
                          ),
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              labelText: 'What\'s on your mind?',
                              labelStyle: TextStyle(
                                fontFamily: 'Mont',
                                color: primaryPink,
                              ),
                              hintText: 'Share your thoughts...',
                              hintStyle: TextStyle(
                                fontFamily: 'Mont',
                                color: lightText,
                              ),
                              contentPadding: EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontFamily: 'Mont'),
                            maxLines: 5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Image Display
                        if (selectedImage != null) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  selectedImage!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedImage = null;
                                      });
                                    },
                                    color: Colors.white,
                                    iconSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Add Image Button
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
                          icon: Icon(
                            selectedImage == null ? Icons.add_photo_alternate_rounded : Icons.edit_rounded,
                            color: primaryPink,
                          ),
                          label: Text(
                            selectedImage == null ? 'Add Image' : 'Change Image',
                            style: const TextStyle(
                              fontFamily: 'Mont',
                              fontWeight: FontWeight.w600,
                              color: primaryPink,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: primaryPink, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tags Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [primaryPink, accentPink],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tag_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Select Tags',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                fontFamily: 'Mont',
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .where((cat) => cat != "All")
                              .map((tag) {
                            final isSelected = selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontFamily: 'Mont',
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : darkText,
                                ),
                              ),
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
                              selectedColor: primaryPink,
                              backgroundColor: lightPink.withOpacity(0.3),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? primaryPink : lightPink,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPink, accentPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Community",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Mont',
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.white),
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
            icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
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
          // Categories Row
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
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

          // Feed
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: primaryPink),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading posts',
                          style: TextStyle(
                            fontFamily: 'Mont',
                            fontSize: 16,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPink,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add_rounded,
                          size: 80,
                          color: lightText.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedCategory == "All"
                              ? 'No posts yet'
                              : 'No posts in $selectedCategory',
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Mont',
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedCategory == "All"
                              ? 'Be the first to share something!'
                              : 'Try selecting a different category',
                          style: TextStyle(
                            color: lightText,
                            fontFamily: 'Mont',
                          ),
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
                      ),
                      onEdit: () {},
                      onDelete: () {},
                      currentUserId: '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        backgroundColor: primaryPink,
        elevation: 6,
        label: const Text(
          "Create Post",
          style: TextStyle(
            fontFamily: 'Mont',
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: const Icon(Icons.edit_rounded),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [primaryPink, accentPink])
              : null,
          color: isSelected ? null : lightPink.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryPink : lightPink,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryPink.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Mont',
              color: isSelected ? Colors.white : darkText,
              fontSize: 14,
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
    required this.onBookmark,
    required void Function() onEdit,
    required void Function() onDelete,
    required String currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightPink.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Row
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: lightPink, width: 2),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: lightPink,
                  backgroundImage: post.userPhotoUrl != null
                      ? NetworkImage(post.userPhotoUrl!)
                      : null,
                  child: post.userPhotoUrl == null
                      ? Text(
                    post.username.isNotEmpty
                        ? post.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: primaryPink,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mont',
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mont',
                        fontSize: 15,
                        color: darkText,
                      ),
                    ),
                    Text(
                      "${post.university} • $relativeTime",
                      style: TextStyle(
                        color: lightText,
                        fontSize: 13,
                        fontFamily: 'Mont',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: lightText),
            ],
          ),

          const SizedBox(height: 14),

          // Post text
          Text(
            post.text,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'Mont',
              color: darkText,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Image
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [lightPink.withOpacity(0.3), lightPink.withOpacity(0.1)],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: lightPink.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(Icons.image_rounded, size: 50, color: primaryPink.withOpacity(0.5)),
                    ),
                  );
                },
              ),
            ),

          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            const SizedBox(height: 14),

          // Tags
          if (post.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags
                  .map((t) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#$t",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Mont',
                    fontWeight: FontWeight.w600,
                    color: primaryPink,
                  ),
                ),
              ))
                  .toList(),
            ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: post.likes > 0 ? post.likes.toString() : null,
                color: post.isLiked ? Colors.red : lightText,
                onTap: onLike,
              ),
              _ActionButton(
                icon: Icons.chat_bubble_rounded,
                label: post.comments > 0 ? post.comments.toString() : null,
                color: lightText,
                onTap: onComment,
              ),
              _ActionButton(
                icon: Icons.share_rounded,
                color: lightText,
                onTap: onShare,
              ),
              _ActionButton(
                icon: post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: post.isBookmarked ? primaryPink : lightText,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Mont',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== COMMENT PAGE WIDGET (Kept for compatibility) ==========
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

      await _firestore.collection('posts').doc(widget.post.id).update({
        'comments': FieldValue.increment(1),
      });

      if (mounted) {
        _commentController.clear();
      }
    } catch (e) {
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
              fontWeight: FontWeight.w700,
              fontFamily: 'Mont',
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: _getCommentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Be the first to comment!',
                    style: TextStyle(
                      color: lightText,
                      fontFamily: 'Mont',
                    ),
                  ),
                );
              }

              final comments = snapshot.data!;
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lightPink,
                      child: Text(
                        comment.username[0].toUpperCase(),
                        style: TextStyle(
                          color: primaryPink,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ),
                    title: Text(
                      comment.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Mont',
                      ),
                    ),
                    subtitle: Text(
                      comment.text,
                      style: const TextStyle(fontFamily: 'Mont'),
                    ),
                    trailing: Text(
                      '${(DateTime.now().difference(comment.createdAt.toDate()).inMinutes)}m ago',
                      style: const TextStyle(
                        fontSize: 12,
                        color: lightText,
                        fontFamily: 'Mont',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        Padding(
          padding: MediaQuery.of(context).viewInsets.copyWith(top: 8, bottom: 8),
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: const TextStyle(fontFamily: 'Mont'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, color: primaryPink),
                onPressed: _submitComment,
              ),
            ),
            style: const TextStyle(fontFamily: 'Mont'),
            onSubmitted: (_) => _submitComment(),
          ),
        ),
      ],
    );
  }
}