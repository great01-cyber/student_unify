import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Models/DonateModel.dart';
import 'Drawer Section/My Listings/Listings.dart';

class SearchDonationPage extends StatefulWidget {
  const SearchDonationPage({super.key});

  @override
  State<SearchDonationPage> createState() => _SearchDonationPageState();
}

class _SearchDonationPageState extends State<SearchDonationPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Donations"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // 🔍 Search Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search items (e.g. chair, books, laptop)...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // 🔥 Real-time search results
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("donations")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // 🔎 Filter the results locally
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data["title"] ?? "").toString().toLowerCase();
                  final description = (data["description"] ?? "").toString().toLowerCase();

                  if (searchQuery.isEmpty) return true; // show all

                  return title.contains(searchQuery) ||
                      description.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // 📌 Convert to Donation models
                final items = filteredDocs.map((doc) {
                  final data = Map<String, dynamic>.from(doc.data());
                  data["id"] = doc.id;
                  return Donation.fromJson(data);
                }).toList();

                // 📌 Use your vertical list design
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _verticalListItem(context, items[index]),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // Existing vertical list widget (already similar to what you have)
  // ----------------------------------------------------------------------
  Widget _verticalListItem(BuildContext context, Donation item) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => ItemDetailPage(item: item),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.photo_library, size: 30),
                ),
              )
                  : Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.photo_library, size: 30),
              ),
            ),

            const SizedBox(width: 12),

            // TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item.description ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        item.locationAddress ?? "",
                        style:
                        const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PRICE
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 6),
              child: Text(
                item.price == null || item.price == 0
                    ? "FREE"
                    : "£${item.price!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
