import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/community.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';
import 'Morepage.dart';
import 'SearchPage.dart';
import 'messages.dart';

// ----------------------------------------------------
// 1. REUSABLE DRAWER WIDGET (MOVED OUTSIDE HOMEPAGE CLASS)
// ----------------------------------------------------
class UserDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;

  const UserDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Profile Picture Section (using UserAccountsDrawerHeader)
          UserAccountsDrawerHeader(
            accountName: Text(userName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            accountEmail: Text(userEmail,
                style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              // Replace 'NetworkImage' with 'AssetImage' if using a local asset
              backgroundImage: NetworkImage(profileImageUrl), // Placeholder URL
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5), // Student Unify Blue
            ),
          ),

          // 2. Home Icon
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              // Navigate to Home
              Navigator.pop(context); // Close the drawer
            },
          ),

          const Divider(),

          // 3. Activity Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: Text('ACTIVITY',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('My Listings'),
            onTap: () {
              // Navigate to My Listings
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('My Wishlist'),
            onTap: () {
              // Navigate to My Wishlist
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // 4. Impact Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: Text('IMPACT',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('My Impact'),
            onTap: () {
              // Navigate to My Impact
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('My Badges'),
            onTap: () {
              // Navigate to My Badges
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Useful Tips'),
            onTap: () {
              // Navigate to Useful Tips
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // 5. Settings Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: Text('SETTINGS',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('My Profile Account'),
            onTap: () {
              // Navigate to Profile Account Settings
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notification Settings'),
            onTap: () {
              // Navigate to Notification Settings
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Stunify Near Me'),
            onTap: () {
              // Navigate to Stunify Near Me
              Navigator.pop(context);
            },
          ),
          // The 'necessary' other one
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              // Navigate to Help & Support
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // 6. Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Implement actual FirebaseAuth.instance.signOut() here
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// HOMEPAGE WIDGET
// ----------------------------------------------------
class Homepage extends StatefulWidget {
  Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Example user data (you would replace this with actual state/provider data)
  final String _userName = 'Alex Johnson';
  final String _userEmail = 'alex.j@uni.com';
  final String _profileImageUrl =
      'https://via.placeholder.com/150'; // Use a real URL or asset

  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeContentPage(),
    SearchPage(),
    Community(),
    Message(),
  ];

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(25)),
            child: MorePage(),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddItemSheet(context);
    } else {
      int newIndex = index > 2 ? index - 1 : index;

      if (_currentIndex != newIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      // ----------------------------------------------------
      // ⬇️ DRAWER INTEGRATION ⬇️
      // ----------------------------------------------------
      endDrawer: UserDrawer(
        userName: _userName,
        userEmail: _userEmail,
        profileImageUrl: _profileImageUrl,
      ),

      // ----------------------------------------------------
      // ⬇️ BOTTOM NAVIGATION BAR INTEGRATION ⬇️
      // ----------------------------------------------------
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}