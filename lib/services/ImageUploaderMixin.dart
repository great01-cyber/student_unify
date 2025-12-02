import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <<< NEW IMPORT

// Mixin Key for SharedPreferences
const String _profileImageUrlKey = 'profileImageUrl';

mixin ImageUploaderMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;

  void showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not logged in.")));
      return;
    }

    final pickedFile = await _picker.pickImage(source: source, imageQuality: 75);

    if (pickedFile != null) {
      (this as dynamic).setState(() => _isUploading = true);
      try {
        File imageFile = File(pickedFile.path);

        // 1. Upload to Firebase Storage
        final storageRef = _storage
            .ref()
            .child('user_profiles')
            .child('${user.uid}.jpg');

        await storageRef.putFile(imageFile);

        // 2. Get the new download URL
        final newUrl = await storageRef.getDownloadURL();

        // 3. Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': newUrl,
        });

        // 4. Update Firebase Auth profile
        await user.updatePhotoURL(newUrl);

        // 5. Save the new URL to SharedPreferences for persistence <<< NEW PERSISTENCE STEP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImageUrlKey, newUrl);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));

        // 6. Update the local state of the UserDrawer
        (this as dynamic).updateProfileData(newUrl);

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image. Check permissions.")));
        }
      } finally {
        (this as dynamic).setState(() => _isUploading = false);
      }
    }
  }

  bool get isUploading => _isUploading;
}