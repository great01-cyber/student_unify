import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/AppUser.dart';
import '../community.dart';

class CommunityPageWrapper extends StatelessWidget {
  const CommunityPageWrapper({super.key});

  // Function to fetch the AppUser (assuming you have one)
  Future<AppUser?> _fetchAppUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      // ✅ FIX: Added the required uid parameter
      return AppUser.fromMap(doc.data()!, uid: firebaseUser.uid);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>( // Using FutureBuilder for simplicity
      future: _fetchAppUser(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error/Missing Data State
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Please log in to view the community.'));
        }

        // 3. Success State: loadedUser is valid
        final AppUser loadedUser = snapshot.data!; // This is where loadedUser is defined.

        // 4. Pass the valid data to the Content widget
        return CommunityPageContent(currentUser: loadedUser); // ✅ Correct use!
      },
    );
  }
}