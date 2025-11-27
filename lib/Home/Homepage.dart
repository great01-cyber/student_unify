import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/community.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';
import 'Drawer Section/My Impact/MyImpact.dart';
import 'Drawer Section/My Listings/Listings.dart';
import 'Drawer Section/My Wishlist/Wishlist.dart';
import 'Drawer Section/My profile account/MyProfileAccount.dart';
import 'Drawer Section/My rewards/MyRewards.dart';
import 'Drawer Section/Notification Settings/NotificationSettings.dart';
import 'Drawer Section/Stunifiers Near Me/Stunifiers.dart';
import 'Drawer Section/Useful Tips/UsefulTips.dart';
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
              color: Color(0xFFFF6786), // Student Unify Blue
            ),
          ),

          // 2. Home Icon
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Homepage()),
              );
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
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyDonationListingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('My Wishlist'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyWishlist()),
              );
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
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SustainabilityPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('My Badges'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Myrewards()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Useful Tips'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FlashcardsScreen()),
              );
            },
          ),

          const Divider(),

          // 5. Settings Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: Text('Settings',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('My Profile Account'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Myprofileaccount()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notification Settings'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Notificationsettings()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Stunify Near Me'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Stunifiers()),
              );
            },
          ),
          // The 'necessary' other one
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Stunifiers()),
              );
            },
          ),

          const Divider(),

          // 6. Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Homepage()),
              );
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
    SearchDonationPage(),
    CommunityPage(),
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