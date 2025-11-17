import 'package:flutter/material.dart';

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

// 3. Dynamic Item Card Widget (MUST be outside a class and not start with an underscore)
// Changing the name to 'buildItemCard' makes it public and reusable.
Widget buildItemCard(BuildContext context, dynamic item, ListingType type) {
  // Assuming the item object passed has 'title', 'category', 'locationAddress', and 'imageUrls'
  final List<dynamic>? images = item["imageUrls"] as List<dynamic>?;

  final String? imageUrl =
  (images != null && images.isNotEmpty && (images.first as String).isNotEmpty)
      ? images.first as String
      : null;

  String actionText;
  Color actionColor;

  double? price;
  try {
    price = item.price as double?;
  } catch (e) {
    price = null;
  }

  // --- Logic to determine Action Text and Color ---
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

  // --- The Widget Structure (using the logic above) ---
  return GestureDetector(
    onTap: () {
      // You'll need to handle navigation here based on the 'item' and 'type'
    },
    child: Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: imageUrl != null
                ? Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(height: 100, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
              },
              errorBuilder: (context, error, stackTrace) => _imageFallback(),
            )
                : _imageFallback(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(item.locationAddress ?? 'Unknown', style: const TextStyle(fontSize: 11, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                Container(
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
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}