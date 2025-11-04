import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/community.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';

import 'MorePage.dart';
import 'Morepage.dart' hide Morepage;
import 'SearchPage.dart';
import 'messages.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // We track the index for the four main tabs (Home, Search, Community, Messages).
  int _currentIndex = 0;

  // List contains only the 4 pages accessible via the body widget.h
  final List<Widget> _pages = const [
    // Index 0: Home (Maps to BottomNavBar Index 0)
    HomeContentPage(),

    // Index 1: Search (Maps to BottomNavBar Index 1)
    SearchPage(),

    // Index 2: Community (Maps to BottomNavBar Index 3)
    Community(),

    // Index 3: Messages (Maps to BottomNavBar Index 4)
    Message(),
  ];

  // Function to show the AddItemPage as a full-height Modal Bottom Sheet
  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // 1. Allows the sheet to take up almost the full scr
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return const FractionallySizedBox(
          // 2. Defines the sheet height (95% of screen height)
          heightFactor: 0.55,
          child: ClipRRect(
            // 3. Adds the characteristic rounded top corners of a sheet
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            // 4. Content is your AddItemPage
            child:  Morepage(),
          ),
        );
      },
    );
  }

  // 3. Callback function to update the index and handle custom navigation
  void _onItemTapped(int index) {
    if (index == 2) {
      // Index 2 is the 'Add Item' button: trigger the Modal Bottom Sheet
      _showAddItemSheet(context);
    } else {
      // Map the 5-item BottomNavBar index (0, 1, 3, 4) to the 4-item _pages list (0, 1, 2, 3)
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
      // The body changes based on the selected tab
      body: _pages[_currentIndex],

      // ----------------------------------------------------
      // ⬇️ BOTTOM NAVIGATION BAR INTEGRATION ⬇️
      // ----------------------------------------------------
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),endDrawer: Drawer(
      // Drawer content remains the same
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1E88E5)),
            child: Text(
                'Student Unify',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
          ),
          ListTile(leading: const Icon(Icons.person), title: const Text('My Profile'), onTap: () {}),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () {
            // TODO: Implement actual FirebaseAuth.instance.signOut() here
          }),
        ],
      ),
    ),
    );
  }
}