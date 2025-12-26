import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Needed for the FAB icon
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_unify_app/Home/widgets/CommunityPage.dart';
import 'package:student_unify_app/services/AppUser.dart';
import '../services/ImageUploaderMixin.dart';
import 'Drawer Section/My Impact/MyImpact.dart';
import 'package:student_unify_app/Home/community.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';
import 'Drawer Section/My Listings/DonationListPage.dart';
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

// Mixin Key
const String _profileImageUrlKey = 'profileImageUrl';

// Color palette - consistent with HomeContentPage
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

// ========================================================
// USER DRAWER (Stateful and Clickable)
// ========================================================
class UserDrawer extends StatefulWidget {
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
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> with ImageUploaderMixin<UserDrawer> {
  late String _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _currentProfileImageUrl = widget.profileImageUrl;
  }

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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightPink.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Mont',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                widget.userEmail,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Mont',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),

              // Profile Picture - Clickable
              currentAccountPicture: GestureDetector(
                onTap: isUploading ? null : () => showUploadOptions(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: _currentProfileImageUrl.isNotEmpty
                            ? NetworkImage(_currentProfileImageUrl)
                            : const AssetImage("assets/images/default_user.png")
                        as ImageProvider,
                      ),
                    ),

                    if (isUploading)
                      const CircularProgressIndicator(color: Colors.white),

                    if (!isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [primaryPink, accentPink],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPink.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryPink,
                    accentPink,
                  ],
                ),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.home_rounded,
              title: 'Home',
              onTap: _navigateToHome,
            ),

            const Divider(height: 1, thickness: 1),

            _buildSectionHeader('ACTIVITY'),

            _buildDrawerItem(
              icon: Icons.list_alt_rounded,
              title: 'My Listings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyListingsPage()));
              },
            ),

            const Divider(height: 1, thickness: 1),

            _buildSectionHeader('IMPACT'),

            _buildDrawerItem(
              icon: Icons.show_chart_rounded,
              title: 'My Impact',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SustainabilityPage()));
              },
            ),

            _buildDrawerItem(
              icon: Icons.verified_user_rounded,
              title: 'My Badges',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentBadgesScreen()));
              },
            ),

            _buildDrawerItem(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Useful Tips',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardsScreen()));
              },
            ),

            const Divider(height: 1, thickness: 1),

            _buildSectionHeader('SETTINGS'),

            _buildDrawerItem(
              icon: Icons.account_circle_outlined,
              title: 'My Profile Account',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
            ),

            _buildDrawerItem(
              icon: Icons.notifications_none_rounded,
              title: 'Notification Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettings()));
              },
            ),

            _buildDrawerItem(
              icon: Icons.location_on_outlined,
              title: 'Stunify Near Me',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DonationsMapPage()));
              },
            ),

            const Divider(height: 1, thickness: 1),

            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          color: lightText,
          fontWeight: FontWeight.w700,
          fontFamily: 'Mont',
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor == null ? lightPink : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? primaryPink,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? darkText,
          fontWeight: FontWeight.w500,
          fontFamily: 'Mont',
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: lightPink.withOpacity(0.3),
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

  final List<Widget> _pages = [
    HomeContentPage(),
    SearchDonationPage(),
    CommunityPageWrapper(),
    MessagesPage(),
  ];

  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = _auth.currentUser!.uid;
    final email = _auth.currentUser!.email ?? "";

    final prefs = await SharedPreferences.getInstance();
    String localImageUrl = prefs.getString(_profileImageUrlKey) ?? "";
    String firestoreImageUrl = localImageUrl;

    try {
      final userDoc = await _firestore.collection("users").doc(uid).get();

      if (userDoc.exists && userDoc.data()!.containsKey("photoUrl")) {
        firestoreImageUrl = userDoc["photoUrl"] ?? "";

        if (firestoreImageUrl.isNotEmpty && firestoreImageUrl != localImageUrl) {
          await prefs.setString(_profileImageUrlKey, firestoreImageUrl);
        }
      }
    } catch (e) {
      print("Firestore fetch failed. Using local storage image URL. Error: $e");
    }

    return {
      "name": _auth.currentUser!.displayName ?? "Unknown User",
      "email": email,
      "profileImage": firestoreImageUrl.isNotEmpty ? firestoreImageUrl : localImageUrl,
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
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lightPink.withOpacity(0.3),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                  strokeWidth: 3,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data as Map<String, dynamic>;

        return Scaffold(
          body: _pages[_currentIndex],

          endDrawer: UserDrawer(
            key: ValueKey(data["profileImage"]),
            userName: data["name"],
            userEmail: data["email"],
            profileImageUrl: data["profileImage"],
          ),

          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [primaryPink, accentPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryPink.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _showAddItemSheet(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                CupertinoIcons.add,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}