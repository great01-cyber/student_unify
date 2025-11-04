import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0; // 1. State to track the active tab

  // 2. List of all the main pages in your app
  final List<Widget> _pages = const [
    // Index 0: Home
    HomeContentPage(),

    SearchPage(),

    // Index 2: More/Add Item - Now uses the actual AddItemPage widget
    AddItemPage(),

    // Index 3: Community - Now uses the actual CommunityPage widget
    CommunityPage(),

    // Index 4: Messages - Now uses the actual MessagesPage widget
    MessagesPage(),
  ];

  // 3. Callback function to update the index
  void _onItemTapped(int index) {
    setState(() {
      // This is the core navigation logic: changing _currentIndex
      // automatically swaps the widget displayed in the body: _pages[_currentIndex]
      _currentIndex = index;
    });
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
      // The drawer content has been updated for better aesthetics
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