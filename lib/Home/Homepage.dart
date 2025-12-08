import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Needed for the FAB icon
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <<< NEW IMPORT
import 'package:student_unify_app/Home/widgets/CommunityPage.dart';
import 'package:student_unify_app/services/AppUser.dart';
import '../services/ImageUploaderMixin.dart';
import 'Drawer Section/My Impact/MyImpact.dart';
import 'package:student_unify_app/Home/community.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';
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

// Mixin Key (Repeated here for clarity, assuming shared_preferences is used only for image)
const String _profileImageUrlKey = 'profileImageUrl';


// ========================================================
// USER DRAWER (Stateful and Clickable) - NO CHANGES
// ========================================================
class UserDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl; // Initial URL

  const UserDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
  });

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> with ImageUploaderMixin<UserDrawer> {
  // Local state variable to hold the image URL, allowing immediate UI update
  late String _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _currentProfileImageUrl = widget.profileImageUrl;
  }

  // Method called by the Mixin after a successful upload
  void updateProfileData(String newUrl) {
    if(mounted) {
      setState(() {
        _currentProfileImageUrl = newUrl;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pop(context);
      MaterialPageRoute(builder: (context) => Homepage());
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              widget.userName,
              style: const TextStyle(
                  color: Colors.black45,
                  fontFamily: 'Mont'
              ),
            ),
            accountEmail: Text(
              widget.userEmail,
              style: const TextStyle(color: Colors.black45, fontFamily: 'Mont'),
            ),

            // Profile Picture - Clickable
            currentAccountPicture: GestureDetector(
              onTap: isUploading ? null : () => showUploadOptions(context),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: _currentProfileImageUrl.isNotEmpty
                        ? NetworkImage(_currentProfileImageUrl)
                        : const AssetImage("assets/images/default_user.png")
                    as ImageProvider,
                  ),

                  if (isUploading)
                    const CircularProgressIndicator(color: Colors.white),

                  if (!isUploading)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Color(0xFFFF6786),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            decoration: const BoxDecoration(
              color: Colors.white10,
            ),
          ),

          // ... rest of your list tiles ...

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: _navigateToHome,
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('ACTIVITY', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold,fontFamily: 'Mont')),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('My Listings',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontFamily: 'Mont'),),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => MyDonationListingsPage()));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('IMPACT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('My Impact',style: TextStyle(color: Colors.black, fontFamily: 'Mont')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SustainabilityPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('My Badges',style: TextStyle(color: Colors.black, fontFamily: 'Mont')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Myrewards()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Useful Tips',style: TextStyle(color: Colors.black, fontFamily: 'Mont')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardsScreen()));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Settings', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('My Profile Account',style: TextStyle(color: Colors.black, fontFamily: 'Mont')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Myprofileaccount()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notification Settings', style: TextStyle(color: Colors.black, fontFamily: 'Mont')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Notificationsettings()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Stunify Near Me',style: TextStyle(color: Colors.black, fontFamily: 'Mont')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Stunifiers()));
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
// HOMEPAGE (Data Loader - Uses Local Storage as Fallback)
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

  // 🔑 FIX 1: Removed the 'MorePage' (Index 2) from the pages list
  final List<Widget> _pages = [
    HomeContentPage(),      // Index 0
    SearchDonationPage(),   // Index 1
    CommunityPageWrapper(), // Index 2
    MessagesPage(),              // Index 3
  ];


  // --- MODIFIED DATA LOAD FUNCTION FOR PERSISTENCE ---
  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = _auth.currentUser!.uid;
    final email = _auth.currentUser!.email ?? "";

    final prefs = await SharedPreferences.getInstance();
    String localImageUrl = prefs.getString(_profileImageUrlKey) ?? ""; // 1. Get local URL

    String firestoreImageUrl = localImageUrl; // Start with local URL as fallback

    try {
      final userDoc = await _firestore.collection("users").doc(uid).get();

      // 2. Get Firestore URL
      if (userDoc.exists && userDoc.data()!.containsKey("photoUrl")) {
        firestoreImageUrl = userDoc["photoUrl"] ?? "";

        // 3. If Firestore URL is different, update local storage
        if (firestoreImageUrl.isNotEmpty && firestoreImageUrl != localImageUrl) {
          await prefs.setString(_profileImageUrlKey, firestoreImageUrl);
        }
      }
    } catch (e) {
      // If Firestore fetch fails (e.g., network error), use the localImageUrl (already set)
      print("Firestore fetch failed. Using local storage image URL. Error: $e");
    }

    return {
      "name": _auth.currentUser!.displayName ?? "Unknown User",
      "email": email,
      "profileImage": firestoreImageUrl.isNotEmpty ? firestoreImageUrl : localImageUrl,
    };
  }
  // ---------------------------------------------------


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

  // 🔑 FIX 2: Simplified _onItemTapped logic
  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
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
            // Use a unique key to force the drawer to rebuild if the URL changes
            // from an external source (like a full app restart or fresh fetch)
            key: ValueKey(data["profileImage"]),
            userName: data["name"],
            userEmail: data["email"],
            profileImageUrl: data["profileImage"],
          ),

          // 🔑 FIX 3: Added FloatingActionButton for the 'Add/More' modal
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemSheet(context),
            child: const Icon(CupertinoIcons.add), // Using CupertinoIcons.add
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          // 🔑 FIX 4: BottomNavBar now contains only the 4 navigational items
          // NOTE: Assumes bottomnavbar.dart has been updated to 4 items.
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}