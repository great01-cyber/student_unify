import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTANT: Ensure these imports point to your actual models ---
import '../../Models/DonateModel.dart'; // Assume this is the correct path
import '../../Models/ExchnageModel.dart';// Must be implemented
import '../../Models/LendPage.dart';
import '../../Models/SellModel.dart';   // Must be implemented
import '../../Models/borrowPage.dart';  // Must be implemented

// ------------------- ENUM AND HELPER WIDGETS -------------------

// 1. Define Listing Type Enum
enum ListingType { borrow, lend, donate, exchange, sell }

// 2. Fallback Image Widget (Helper)
Widget _imageFallback() {
  return Container(
    height: 100,
    width: double.infinity,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
    ),
  );
}

// 3. Helper to determine the Firestore collection based on ListingType
String _getCollectionName(ListingType type) {
  switch (type) {
    case ListingType.lend: return 'lends';
    case ListingType.borrow: return 'borrow_requests';
    case ListingType.exchange: return 'exchanges';
    case ListingType.sell: return 'sales';
    case ListingType.donate: default: return 'donations';
  }
}

// 4. Helper to map raw data to the correct Model instance
dynamic _mapToModel(Map<String, dynamic> data, ListingType type) {
  // Ensure 'id' is present for detail pages
  data['id'] = data['id'] ?? data['docId'];

  switch (type) {
    case ListingType.lend:
      return LendModel.fromJson(data);
    case ListingType.exchange:
      return ExchangeModel.fromJson(data);
    case ListingType.sell:
      return SellModel.fromJson(data);
    case ListingType.borrow:
      return BorrowModel.fromJson(data);
    case ListingType.donate:
    default:
      return Donation.fromJson(data);
  }
}


// ------------------- ItemDetailPage (Generalized) -------------------
class ItemDetailPage extends StatelessWidget {
  final dynamic item;
  final ListingType listingType; // 🎯 FIX: Now a final field

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.listingType // Required and initialized
  });

  @override
  Widget build(BuildContext context) {
    // Access properties dynamically, assuming all models have title, category, etc.
    final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty) ? item.imageUrls.first : null;

    // Determine the price display based on listing type and model properties
    String priceText;
    Color priceColor;

    if (listingType == ListingType.donate) {
      priceText = 'FREE';
      priceColor = Colors.teal;
    } else if (listingType == ListingType.sell) {
      final double price = item.price as double? ?? 0.0;
      priceText = price > 0 ? '£${price.toStringAsFixed(2)}' : 'Selling (Free)';
      priceColor = Colors.purple;
    } else {
      // General non-monetary items (Lend, Borrow, Exchange)
      priceText = listingType.name.toUpperCase();
      priceColor = Colors.blueGrey;
    }

    return Scaffold(
      appBar: AppBar(title: Text(item.title), backgroundColor: Colors.white, foregroundColor: Colors.deepPurple, elevation: 0),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // big image
          if (imageUrl != null)
            Image.network(imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 300, color: Colors.grey[200], child: const Center(child: Icon(Icons.photo_library, size: 50))))
          else
            Container(height: 300, color: Colors.grey[200], child: const Center(child: Icon(Icons.photo_library, size: 50))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                Text(priceText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: priceColor)),
              ]),
              const SizedBox(height: 8),
              Text(item.category ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 12),
              Text(item.description ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text("Location for Pickup", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // ... Map placeholder
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                  label: Text("Message Owner to ${listingType.name.toUpperCase()}"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}


// ------------------- Modified Item Card Widget -------------------
Widget _buildItemCard(BuildContext context, dynamic item, ListingType type) {
  // --- 1. Defensive image access (from previous fix) ---
  final rawImageUrls = item.imageUrls;
  List<String> urls = [];
  if (rawImageUrls is List) {
    urls = List<String>.from(rawImageUrls.map((e) => e.toString()));
  }
  final imageUrl = (urls.isNotEmpty && urls.first.isNotEmpty) ? urls.first : null;

  // --- 2. Dynamic Text and Color Setup ---
  String actionText;
  Color actionColor;

  double? price;
  try { price = item.price as double?; } catch (e) { price = null; }

  switch (type) {
    case ListingType.lend:
      actionText = 'Lending this Item';
      actionColor = Colors.green.shade700;
      break;
    case ListingType.donate:
      actionText = 'FREE';
      actionColor = Colors.teal.shade700;
      break;
    case ListingType.sell:
      actionText = price != null && price! > 0 ? '£${price.toStringAsFixed(2)}' : 'Selling (Free)';
      actionColor = Colors.purple.shade700;
      break;
    case ListingType.exchange:
      actionText = 'Exchanging this Item';
      actionColor = Colors.orange.shade700;
      break;
    case ListingType.borrow:
    default:
      actionText = 'Borrow this Item';
      actionColor = Colors.blue.shade700;
      break;
  }

  return GestureDetector(
    onTap: () {
      // 🎯 CORRECT NAVIGATION: Pass the item and the required 'type'
      Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailPage(item: item, listingType: type)));
    },
    child: Container(
      // ... (rest of the Item Card UI, unchanged)
      width: 160,
      // ... (style and layout)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image/Fallback Section (using imageUrl) ---
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: imageUrl != null
                ? Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) return child; return Container(height: 100, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))); }, errorBuilder: (context, error, stackTrace) => _imageFallback(),)
                : _imageFallback(),
          ),
          // --- Details Section ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                // Location Row
                Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.blueGrey), const SizedBox(width: 4), Expanded(child: Text(item.locationAddress ?? 'Unknown', style: const TextStyle(fontSize: 11, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),]),
                const SizedBox(height: 4),
                // --- Dynamic Action/Type Text ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: actionColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(actionText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: actionColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


// ------------------- HorizontalItemList (Generalized) -------------------
// Renamed to HorizontalCategoryFeed to reflect multi-feature logic if implemented later
class HorizontalItemList extends StatelessWidget {
  final String categoryTitle;
  final ListingType listingType; // 🎯 FIX: Added the missing field

  const HorizontalItemList({
    super.key,
    required this.categoryTitle,
    required this.listingType, // Required and initialized
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 FIX: Determine collection based on the passed listingType
    final collectionName = _getCollectionName(listingType);
    final CollectionReference<Map<String, dynamic>> collection =
    FirebaseFirestore.instance.collection(collectionName);

    final Color headerColor = listingType == ListingType.donate ? Colors.teal : Colors.deepPurple;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(categoryTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  // 🎯 FIX: Pass listingType to the VerticalListPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerticalListPage(
                        categoryTitle: categoryTitle,
                        listingType: listingType,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text("All", style: TextStyle(color: headerColor, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_right, color: headerColor, size: 20),
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
            stream: collection
                .where('category', isEqualTo: categoryTitle)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error loading items: ${snapshot.error}'));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return Center(child: Text('No items in this category yet.'));

              final items = docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = data['id'] ?? doc.id;
                // 🎯 FIX: Map to the correct model based on listingType
                return _mapToModel(data, listingType);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                // CALLING the shared helper function with the correct type
                _buildItemCard(context, items[index], listingType),
              );
            },
          ),
        ),
      ],
    );
  }
}


// ------------------- VerticalListPage (Generalized) -------------------
class VerticalListPage extends StatelessWidget {
  final String categoryTitle;
  final ListingType listingType; // 🎯 FIX: Defined here

  const VerticalListPage({super.key, required this.categoryTitle, required this.listingType}); // Initialized here

  @override
  Widget build(BuildContext context) {
    // 🎯 FIX: Determine collection based on the passed listingType
    final collectionName = _getCollectionName(listingType);
    final CollectionReference<Map<String, dynamic>> collection =
    FirebaseFirestore.instance.collection(collectionName);

    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle), backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.where('category', isEqualTo: categoryTitle).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No items'));

          final items = docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = data['id'] ?? doc.id;
            // 🎯 FIX: Map to the correct model based on listingType
            return _mapToModel(data, listingType);
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

  Widget _verticalListItem(BuildContext context, dynamic item) { // Accepts dynamic item
    final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty) ? item.imageUrls.first : null;

    // Determine price text for display
    String priceText = '';
    if (listingType == ListingType.donate) {
      priceText = 'FREE';
    } else if (listingType == ListingType.sell) {
      final double price = item.price as double? ?? 0.0;
      priceText = price > 0 ? '£${price.toStringAsFixed(2)}' : 'Selling';
    } else {
      priceText = listingType.name.toUpperCase();
    }

    return GestureDetector(
      // 🎯 FIX: Pass the item and the required 'listingType'
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(item: item, listingType: listingType,))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))]),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: imageUrl != null ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover) : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.photo_library, size: 30))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(item.description ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.blueGrey), const SizedBox(width: 4), Text(item.locationAddress ?? '', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))]),
          ])),
          // Display the determined price/type text
          Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(priceText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent))),
        ]),
      ),
    );
  }
}