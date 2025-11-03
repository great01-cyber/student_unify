import 'package:flutter/material.dart';
import 'dart:ui';

class SharedItem {
  final String title;
  final String subtitle;
  final String address;
  final String price;
  final String imagePath;

  SharedItem({
    required this.title,
    required this.subtitle,
    required this.address,
    required this.price,
    required this.imagePath,
  });
}

// Dummy List of Shared Items
final List<SharedItem> dummyItems = [
  SharedItem(
    title: "Calculus Textbook",
    subtitle: "Used condition, barely marked.",
    address: "Anderson Road",
    price: "FREE",
    imagePath: 'assets/images/verified.png',
  ),
  SharedItem(
    title: "Noise Cancelling Headset",
    subtitle: "Perfect for library study.",
    address: "Campus Dorm B",
    price: "\$35",
    imagePath: 'assets/item_headset.jpg',
  ),
  SharedItem(
    title: "Mini Fridge",
    subtitle: "Great for dorm room snacks.",
    address: "Off-Campus Housing",
    price: "\$60",
    imagePath: 'assets/item_fridge.jpg',
  ),
  SharedItem(
    title: "Desk Lamp (LED)",
    subtitle: "Adjustable, 3 light modes.",
    address: "Smith Hall",
    price: "\$10",
    imagePath: 'assets/item_desk_lamp.jpg',
  ),
];
// NOTE: Remember to add the image paths (e.g., 'assets/item_calculus.jpg') to your project's assets folder.


class HorizontalItemList extends StatelessWidget {
  const HorizontalItemList({super.key});

  @override
  Widget build(BuildContext context) {
    const String categoryTitle = "Free Academic Materials"; // Define once for reuse

    return Column(
      children: [
        // Section Header Row (Title and 'All' button)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                categoryTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // 🎯 CHANGE 1: Wrap the 'All' button in a GestureDetector
              GestureDetector(
                onTap: () {
                  // Navigate to the full vertical list of this category
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerticalListPage(categoryTitle: categoryTitle, items:dummyItems,),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      "All",
                      style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // The Horizontal Scrolling List
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: dummyItems.length,
            itemBuilder: (context, index) {
              return _buildItemCard(context, dummyItems[index]);
            },
          ),
        ),
      ],
    );
  }

  // Individual Item Card Widget
  Widget _buildItemCard(BuildContext context, SharedItem item) {
    // 🎯 CHANGE 2: Wrap the entire Container in a GestureDetector
    return GestureDetector(
      onTap: () {
        // Navigate to the detailed page for this specific item
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
        );
      },
      child: Container(
        width: 160,
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
            // Image Container (remains the same)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                item.imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.photo_library, color: Colors.grey)),
                ),
              ),
            ),

            // Text content (remains the same)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item.address, style: const TextStyle(fontSize: 11, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text(item.price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// Assuming SharedItem class is available in this file or imported
// class SharedItem { ... }

class ItemDetailPage extends StatelessWidget {
  final SharedItem item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
            // 🖼️ ENLARGED IMAGE SECTION
            Hero( // Use Hero widget for a smooth transition from the list image
              tag: item.imagePath, // Unique tag for transition
              child: Image.asset(
                item.imagePath,
                width: double.infinity,
                height: 300, // Significantly enlarged
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.photo_library, size: 50, color: Colors.grey)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ TITLE AND PRICE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.price,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 📝 LITTLE DESCRIPTION (Subtitle)
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const Divider(height: 32),

                  // 📍 MAP SECTION (Placeholder)
                  const Text(
                    "Location for Pickup",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          const Icon(Icons.map, size: 40, color: Colors.blueGrey),
                          const SizedBox(height: 4),
                          Text('Map placeholder centered on: ${item.address}', style: const TextStyle(color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 📞 CONTACT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Action: Open chat or contact screen
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Message Owner to Share/Swap"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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


// NOTE: SharedItem class and dummyItems list are assumed to be available
// If VerticalListPage is in a separate file, you must import SharedItem.

class VerticalListPage extends StatelessWidget {
  final String categoryTitle;
  // We pass the full list of items from the horizontal view
  final List<SharedItem> items;

  const VerticalListPage({
    super.key,
    required this.categoryTitle,
    required this.items
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      // 🎯 The main body uses ListView.builder to show items vertically
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildVerticalListItem(context, items[index]);
        },
      ),
    );
  }

  // Individual Item Row Widget (Vertical Layout)
  Widget _buildVerticalListItem(BuildContext context, SharedItem item) {
    return GestureDetector(
      onTap: () {
        // Navigate to the item detail page when the list tile is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image on the left
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.photo_library, size: 30, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 📝 Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        item.address,
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 💰 Price on the right
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                item.price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
