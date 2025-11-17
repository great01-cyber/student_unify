import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_unify_app/Home/widgets/scrolling.dart' hide ListingType;// 🎯 Import the correct model
import '../../Models/LendPage.dart';
import 'listings_utils.dart';
 // 🎯 Import the shared enum/card function

// Assuming the shared functions (ListingType, _buildItemCard) are accessible.
// If not, place them in a separate utility file and import them here.
// For this example, we'll assume they are accessible or copied here.
// We'll reuse the _buildItemCard function from the previous output.

class HorizontalLendList extends StatelessWidget {
  final String categoryTitle;
  const HorizontalLendList({super.key, required this.categoryTitle});

  // 🎯 CHANGE 1: Reference the 'lends' collection
  static final CollectionReference<Map<String, dynamic>> _lendCollection =
  FirebaseFirestore.instance.collection('lends');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (Unchanged)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(categoryTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  // NOTE: You'll need a VerticalLendListPage here
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => VerticalLendListPage(categoryTitle: categoryTitle),
                  //   ),
                  // );
                },
                child: Row(
                  children: const [
                    Text("All", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_right, color: Colors.teal, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal list from Firestore
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _lendCollection // 🎯 CHANGE 2: Use the 'lends' collection reference
                .where('category', isEqualTo: categoryTitle)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error loading items: ${snapshot.error}'));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No items for lending yet.'));

              final items = docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = data['id'] ?? doc.id;
                // 🎯 CHANGE 3: Use LendModel.fromJson()
                return LendModel.fromJson(data);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                itemCount: items.length,
                // 🎯 CHANGE 4: Pass the correct ListingType.lend
                itemBuilder: (context, index) => buildItemCard(context, items[index], ListingType.lend),
              );
            },
          ),
        ),
      ],
    );
  }
}
// Note: You must ensure ListingType and _buildItemCard are globally accessible
// or copied into this file for it to compile.