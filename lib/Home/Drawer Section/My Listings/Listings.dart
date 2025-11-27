import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../Models/DonateModel.dart';
// 🎯 Import the new, reusable list / Ensure this path is correct
import '../../widgets/scrolling.dart'; // ⚠️ Ensure this path is correct and necessary

// Assuming ItemDetailPage is defined elsewhere
class ItemDetailPage extends StatelessWidget {
  final Donation item;
  const ItemDetailPage({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(item.title)), body: Center(child: Text('Details for ${item.title}')));
  }
}

// ------------------- Helper: Get Current User ID -------------------
String getCurrentUserId() {
  // ⚠️ Replace with actual Firebase Auth logic
  return FirebaseAuth.instance.currentUser?.uid ?? 'TEST_USER_ID_FALLBACK';
}

// ------------------- MyDonationListingsPage -------------------
class MyDonationListingsPage extends StatelessWidget {
  const MyDonationListingsPage({super.key});

  static final CollectionReference<Map<String, dynamic>> _donationCollection =
  FirebaseFirestore.instance.collection('donations');

  // Function to handle item deletion
  Future<void> _deleteListing(BuildContext context, String docId, String title) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete your listing: "$title"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        await _donationCollection.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing "$title" deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete listing: $e')),
        );
      }
    }
  }

  // --- Widget for Delete Button ---
  Widget _buildDeleteButton(BuildContext context, String docId, String title) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
      onPressed: (docId != 'unknown_doc_id')
          ? () => _deleteListing(context, docId, title)
          : null, // Disable delete if ID is missing
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donation Listings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // 🎯 KEY FILTER: Filter by the current user's ID
        stream: FirebaseFirestore.instance
            .collection("donations")
            .where("donorId", isEqualTo: currentUserId)   // Changed filter key from "id" to "donorId" based on new Donate form logic
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.volunteer_activism_outlined, size: 60, color: Colors.teal),
                  SizedBox(height: 10),
                  Text('You haven\'t listed any items for donation yet.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          final items = docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            // Use the Firestore document ID for deletion/unique reference
            data['id'] = doc.id;
            return Donation.fromJson(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final String docId = item.id ?? 'unknown_doc_id';
            },
          );
        },
      ),
    );
  }
}