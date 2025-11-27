import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Models/DonateModel.dart';
import '../../widgets/scrolling.dart';
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
        stream: _donationCollection
            .where('donorId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
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
            data['id'] = data['id'] ?? doc.id; // Use Firestore document ID
            return Donation.fromJson(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: items.length,
            itemBuilder: (context, index) => _verticalListItem(context, items[index]),
          );
        },
      ),
    );
  }

  // ------------------- Vertical List Item Widget -------------------
  Widget _verticalListItem(BuildContext context, Donation item) {
    final String docId = item.id ?? 'missing_id';
    final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty) ? item.imageUrls.first : null;

    return GestureDetector(
      // 1. Navigate to Detail Page on tap
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(item: item))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.photo_library, size: 30)))
                  : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.photo_library, size: 30)),
            ),

            const SizedBox(width: 12),

            // Text Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item.description ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.blueGrey), const SizedBox(width: 4), Text(item.locationAddress ?? '', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))]),
                ],
              ),
            ),

            // Delete Button and Price/Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 2. Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                  onPressed: (docId != 'unknown')
                      ? () => _deleteListing(context, docId, item.title)
                      : null, // Disable delete if ID is missing
                ),

                // Price/Status
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 10.0),
                  child: Text(
                      item.price != null && item.price! > 0 ? '£${item.price!.toStringAsFixed(2)}' : 'FREE',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.teal)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}