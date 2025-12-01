import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Your imports
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


// ========================================================
// REUSABLE DRAWER — FETCHES REAL USER DATA FROM FIREBASE
// ========================================================
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
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              userEmail,
              style: const TextStyle(color: Colors.white70),
            ),

            // Profile Picture
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : const AssetImage("assets/images/default_user.png")
              as ImageProvider,
            ),

            decoration: const BoxDecoration(
              color: Color(0xFFFF6786),
            ),
          ),

          // -----------------------------------------
          // MENU ITEMS
          // -----------------------------------------
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => Homepage()),
              );
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'ACTIVITY',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('My Listings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => MyDonationListingsPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('My Wishlist'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MyWishlist()),
              );
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'IMPACT',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('My Impact'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SustainabilityPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('My Badges'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Myrewards()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Useful Tips'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const FlashcardsScreen()),
              );
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Settings',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),

          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('My Profile Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Myprofileaccount()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notification Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Notificationsettings()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Stunify Near Me'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Stunifiers()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
        ],
      ),
    );
  }
}


// ========================================================
// HOMEPAGE — LOADS USER DATA FROM FIRESTORE
// ========================================================
class Homepage extends StatefulWidget {
  Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeContentPage(),
    SearchDonationPage(),
    CommunityPage(),
    Message(),
  ];

  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = _auth.currentUser!.uid;
    final email = _auth.currentUser!.email ?? "";

    final userDoc = await _firestore.collection("users").doc(uid).get();

    return {
      "name": userDoc["displayName"] ?? "Unknown User",
      "email": email,
      "profileImage": userDoc["photoUrl"] ?? "",
    };
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
        setState(() => _currentIndex = newIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data as Map<String, dynamic>;

        return Scaffold(
          body: _pages[_currentIndex],

          endDrawer: UserDrawer(
            userName: data["name"],
            userEmail: data["email"],
            profileImageUrl: data["profileImage"],
          ),

          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
