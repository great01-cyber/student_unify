import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      "Study Tips",
      "Cleaning Hacks",
      "Cheap Meals",
      "DIY Repairs",
      "Opportunities",
      "Travel",
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Community",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 12),
          Icon(Icons.notifications_none, color: Colors.black),
          SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          // Categories Row
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return CategoryChip(label: categories[index]);
              },
            ),
          ),

          // Feed
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PostCard(
                  username: "Emily Johnson",
                  course: "Biology",
                  time: "2 hrs ago",
                  text:
                  "Here’s how I save £80 every month on groceries! Shop at closing time — discounts everywhere 🛒🔥",
                  imageUrl:
                  "https://images.pexels.com/photos/3770588/pexels-photo-3770588.jpeg",
                  tags: ["saving", "groceries"],
                ),
                const SizedBox(height: 16),
                PostCard(
                  username: "Daniel Thompson",
                  course: "Engineering",
                  time: "5 hrs ago",
                  text:
                  "If your heater is making noise, tighten the valve — solved mine instantly 🔧🔥",
                  tags: ["DIY", "repairs"],
                ),
                const SizedBox(height: 16),
                PostCard(
                  username: "Aisha Khalid",
                  course: "Business",
                  time: "1 day ago",
                  text:
                  "£1.80 lunch idea: Pasta + tomato sauce + spinach. Cheap, healthy, fast! 🍅🍝",
                  imageUrl:
                  "https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg",
                  tags: ["cooking", "cheapmeals"],
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        label: const Text("Post"),
        icon: const Icon(Icons.edit),
        onPressed: () {},
      ),
    );
  }
}

// ⭕ Category Chip Widget
class CategoryChip extends StatelessWidget {
  final String label;
  const CategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// 🟦 Post Card Widget
class PostCard extends StatelessWidget {
  final String username;
  final String course;
  final String time;
  final String text;
  final String? imageUrl;
  final List<String> tags;

  const PostCard({
    super.key,
    required this.username,
    required this.course,
    required this.time,
    required this.text,
    this.imageUrl,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Row
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage("assets/user.png"),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "$course • $time",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Post text
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 12),

          // Image (optional)
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl!),
            ),

          const SizedBox(height: 12),

          // Tags
          Wrap(
            spacing: 6,
            children: tags
                .map((t) => Chip(
              label: Text("#$t"),
              backgroundColor: Colors.blue.shade50,
            ))
                .toList(),
          ),

          const SizedBox(height: 10),

          // Buttons: like, comment, share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Icon(Icons.favorite_border),
              Icon(Icons.chat_bubble_outline),
              Icon(Icons.share),
              Icon(Icons.bookmark_border),
            ],
          ),
        ],
      ),
    );
  }
}
