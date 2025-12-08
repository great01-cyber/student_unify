import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Models/DonateModel.dart';
import 'chatpage.dart'; // <- your Donation model (Donation.fromJson)

// ------------------- ENUM AND HELPER WIDGETS (Moved outside for reusability) -------------------

// 1. Define Listing Type Enum
enum ListingType {donate, Request}

// 2. Fallback Image Widget (Helper)
Widget _imageFallback() {
  return Container(
    height: 150,
    width: double.infinity,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
    ),
  );
}

// 3. Modified Item Card Widget
Widget _buildItemCard(
    BuildContext context,
    dynamic item,
    ListingType type,
    ) {
  final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty)
      ? item.imageUrls.first
      : null;

  // Extract price safely
  double? price;
  try {
    price = item.price as double?;
  } catch (e) {
    price = null;
  }

  // Determine action text and color based on listing type
  final String actionText;
  final Color actionColor;

  switch (type) {
    case ListingType.Request:
      actionText = 'Request an Item';
      actionColor = Colors.green.shade700;
      break;
    case ListingType.donate:
      actionText = 'FREE';
      actionColor = Colors.teal.shade700;
      break;
    /*case ListingType.sell:
      actionText = price != null && price! > 0
          ? '£${price.toStringAsFixed(2)}'
          : 'Selling (Free)';
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
      break;*/
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemDetailPage(item: item as Donation),
        ),
      );
    },
    child: Container(
      width: 160,
      height: 303,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(imageUrl),
          const SizedBox(height: 6),
          _buildDetailsSection(item, actionText, actionColor),
        ],
      ),
    ),
  );
}

// Image section with loading and error handling
Widget _buildImageSection(String? imageUrl) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
    child: imageUrl != null
        ? Image.network(
      imageUrl,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 100,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _imageFallback(),
    )
        : _imageFallback(),
  );
}

// Details section with item info and donator
Widget _buildDetailsSection(
    dynamic item,
    String actionText,
    Color actionColor,
    ) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemInfo(item),
        const SizedBox(height: 4),
        _buildLocationInfo(item),
        const SizedBox(height: 4),
        _buildActionLabel(actionText, actionColor),
        const SizedBox(height: 6),
        _buildDonatorInfo(item.donorId),
      ],
    ),
  );
}

// Item title and category
Widget _buildItemInfo(dynamic item) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        item.category,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// Location info with icon
Widget _buildLocationInfo(dynamic item) {
  return Row(
    children: [
      const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          item.locationAddress ?? 'Unknown',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.blueGrey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// Action label (price/status)
Widget _buildActionLabel(String actionText, Color actionColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: actionColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      actionText,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: actionColor,
      ),
    ),
  );
}

// Donator information with avatar
Widget _buildDonatorInfo(String donorId) {
  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance.collection('users').doc(donorId).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 20,
          child: LinearProgressIndicator(minHeight: 2),
        );
      }

      if (snapshot.hasError ||
          !snapshot.hasData ||
          snapshot.data!.data() == null) {
        return const SizedBox();
      }

      final userData = snapshot.data!.data()!;
      final donatorName = userData['displayName'] ?? 'Unknown';
      final donatorUniversity = userData['university'] ?? 'Unknown';
      final photoUrl = userData['photoUrl'] ?? '';

      return Row(
        children: [
          _buildDonatorAvatar(photoUrl),
          const SizedBox(width: 6),
          Expanded(
            child: _buildDonatorDetails(donatorName, donatorUniversity),
          ),
        ],
      );
    },
  );
}

// Donator avatar
Widget _buildDonatorAvatar(String photoUrl) {
  return CircleAvatar(
    radius: 10,
    backgroundColor: Colors.grey[300],
    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
    child: photoUrl.isEmpty
        ? const Icon(Icons.person, size: 5, color: Colors.white)
        : null,
  );
}

// Donator name and university
Widget _buildDonatorDetails(String name, String university) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w100,
          color: Colors.black,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        university,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.blueGrey,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}




// ------------------- HorizontalItemList -------------------
class HorizontalItemList extends StatelessWidget {
  final String categoryTitle;
  const HorizontalItemList({super.key, required this.categoryTitle});

  static final CollectionReference<Map<String, dynamic>> _donationCollection =
  FirebaseFirestore.instance.collection('donations');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(categoryTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, fontFamily: 'Comfortaa',

                color: Color(0xFF1E3A8A),)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerticalListPage(categoryTitle: categoryTitle),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text("All", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w300, fontFamily: 'Comfortaa',)),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_right, color: Color(0xFF1E3A8A), size: 20),
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
            stream: _donationCollection
                .where('category', isEqualTo: categoryTitle)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error loading items: ${snapshot.error}'));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No items in this category yet.'));

              final items = docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = data['id'] ?? doc.id;
                return Donation.fromJson(data);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                // 🎯 CALLING the shared helper function with the correct type
                _buildItemCard(context, items[index], ListingType.donate),
              );
            },
          ),
        ),
      ],
    );
  }
}


class ItemDetailPage extends StatelessWidget {
  final Donation item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty)
        ? item.imageUrls.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big image
            if (imageUrl != null)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.photo_library, size: 50),
                  ),
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.photo_library, size: 50),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        item.price != null && item.price! > 0
                            ? '£${item.price!.toStringAsFixed(2)}'
                            : 'FREE',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Location for Pickup",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map,
                            size: 40,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Map placeholder: ${item.locationAddress ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              receiverId: item.donorId,
                              receiverName: item.donorName,
                              receiverPhoto: item.donorPhoto,
                              donation: item,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Message"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- VerticalListPage (fetch full list for category) -------------------
class VerticalListPage extends StatelessWidget {
  final String categoryTitle;
  const VerticalListPage({super.key, required this.categoryTitle});

  static final CollectionReference<Map<String, dynamic>> _donationCollection =
  FirebaseFirestore.instance.collection('donations');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle), backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _donationCollection.where('category', isEqualTo: categoryTitle).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No items'));

          final items = docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = data['id'] ?? doc.id;
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

  Widget _verticalListItem(BuildContext context, Donation item) {
    final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty) ? item.imageUrls.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(item: item))),
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
          // Note: price logic remains here for vertical list, showing FREE/£X.XX
          Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(item.price != null && item.price! > 0 ? '£${item.price!.toStringAsFixed(2)}' : 'FREE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent))),
        ]),
      ),
    );
  }
}