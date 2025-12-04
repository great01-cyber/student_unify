import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../Models/PostModel.dart';
import 'AppUser.dart';

class PostService {
  final _posts = FirebaseFirestore.instance.collection("posts");
  final _storage = FirebaseStorage.instance;

  // Upload image to Firebase Storage
  Future<String?> uploadImage(File? file, String postId) async {
    if (file == null) return null;

    final ref = _storage.ref().child("post_images/$postId.jpg");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Create a post
  Future<void> createPost({
    required AppUser user,
    required String text,
    File? imageFile,
    List<String> tags = const [],
  }) async {
    final postId = _posts.doc().id;

    // Upload image if exists
    final imageUrl = await uploadImage(imageFile, postId);

    final post = Post(
      id: postId,
      userId: user.uid,
      username: user.displayName ?? user.email.split('@')[0],
      userPhotoUrl: user.photoUrl,
      university: user.university,
      createdAt: Timestamp.now(),
      text: text,
      imageUrl: imageUrl,
      tags: tags,
      likes: 0,
      comments: 0,
      isLiked: false,
      isBookmarked: false,
    );

    await _posts.doc(postId).set(post.toMap());
  }
}
