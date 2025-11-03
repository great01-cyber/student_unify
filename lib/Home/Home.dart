import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/widgets/Carousel.dart';
import 'package:student_unify_app/Home/widgets/HomeContentPage.dart';
import 'package:student_unify_app/Home/widgets/bottomnavbar.dart';
import 'package:student_unify_app/Home/widgets/scrolling.dart';
// Note: Assuming QuoteCarousel and HorizontalItemList are imported correctly

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0; // 1. State to track the active tab

  // 2. List of all the main pages in your app
  final List<Widget> _pages = [
    // Index 0: Home (Your complex header/carousel/list view structure)
    const HomeContentPage(),

    // Index 1: Search
    const Center(child: Text('Search Page')),

    // Index 2: More/Add Item
    const Center(child: Text('Add Item / More Options Page')),

    // Index 3: Community
    const Center(child: Text('Community Feed')),

    // Index 4: Messages
    const Center(child: Text('Messages List')),
  ];

  // 3. Callback function to update the index
  void _onItemTapped(int index) {
    setState(() {
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
        // Drawer content remains the same
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurpleAccent),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: Icon(Icons.home), title: Text('Home')),
            ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
            ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
          ],
        ),
      ),
    );
  }
}