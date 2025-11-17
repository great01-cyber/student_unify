import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'listings_utils.dart';
// import 'package:your_app/Models/DonateModel.dart';
// ... all your models

// Define the collections map
const Map<ListingType, String> _collectionMap = {
  ListingType.lend: 'lends',
  ListingType.borrow: 'borrow_requests',
  ListingType.exchange: 'exchanges',
  ListingType.sell: 'sales',
  ListingType.donate: 'donations',
};

class UnifiedCategoryFeed extends StatelessWidget {
  final String categoryTitle;

  const UnifiedCategoryFeed({
    super.key,
    required this.categoryTitle,
  });

  // 1. Function to fetch data from ALL collections for a single category
  Future<List<Map<String, dynamic>>> _fetchCategoryItems() async {
    final firestore = FirebaseFirestore.instance;
    final List<Future<QuerySnapshot>> futures = [];
    final List<Map<String, dynamic>> allItems = [];

    // Create a list of Futures, one for each collection query
    _collectionMap.forEach((type, collectionName) {
      final query = firestore.collection(collectionName)
          .where('category', isEqualTo: categoryTitle)
          .limit(2); // Limit items per collection to keep the horizontal list short
      futures.add(query.get());
    });

    // Wait for all queries to complete
    final List<QuerySnapshot> results = await Future.wait(futures);

    // 2. Process results and identify the ListingType for each item
    for (int i = 0; i < results.length; i++) {
      final QuerySnapshot snapshot = results[i];
      final ListingType type = _collectionMap.keys.toList()[i];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = data['id'] ?? doc.id;
        data['listingType'] = type.index; // 🎯 Tag the item with its source type (index)
        allItems.add(data);
      }
    }

    // Sort items by creation date (optional but recommended)
    allItems.sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));

    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (Optional: Can remove if you only want the title)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            categoryTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Horizontal list using FutureBuilder
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchCategoryItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final List<Map<String, dynamic>> rawItems = snapshot.data ?? [];
              if (rawItems.isEmpty) {
                return const Center(child: Text('No items found in this category.'));
              }

              // Map raw data (with 'listingType' tag) to your actual model instance
              final items = rawItems.map((data) {
                final type = ListingType.values[data['listingType'] as int];
                // Use your existing _mapToModel helper, which you need to define.
                return _mapToModel(data, type);
              }).toList();


              return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData = rawItems[index];
                    // 🎯 Retrieve the tagged ListingType
                    final type = ListingType.values[itemData['listingType'] as int];
                    // Pass the item and its true type to the card for correct labeling
                    return buildItemCard(context, items[index], type);
                  }
              );
            },
          ),
        ),
        const SizedBox(height: 16), // Separator for categories
      ],
    );
  }
}

// NOTE: You must redefine _mapToModel and _buildItemCard to handle the new tagging:
dynamic _mapToModel(Map<String, dynamic> data, ListingType type) {
  // This function must take the raw data and convert it into the specific model
  // instance (LendModel, DonateModel, etc.) based on the 'type'.
  // e.g., if (type == ListingType.lend) return LendModel.fromJson(data);
  return data;
}