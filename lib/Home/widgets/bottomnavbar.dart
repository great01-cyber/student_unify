import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Note: Removed redundant import 'package:cupertino_icons/cupertino_icons.dart';

// Use a StatelessWidget as this widget's only job is to display the bar
// and report taps back to the parent.
class BottomNavBar extends StatelessWidget {
  // Properties required from the parent (Homepage)
  final void Function(int index) onTap;
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.onTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black, // Selected text and icon color
      unselectedItemColor: Colors.grey,
      items: const <BottomNavigationBarItem>[
        // 1. Home (Using the filled icon when active)
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.home),
          activeIcon: Icon(CupertinoIcons.house_fill), // ⬅️ FIX: Changed to filled icon
          label: 'Home',
        ),
        // 2. Search
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.search),
          activeIcon: Icon(CupertinoIcons.search),
          label: 'Search',
        ),
        // 3. Add/Create (The only icon originally using a filled variant)
        // 4. Community (Using the filled icon when active)
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_2),
          activeIcon: Icon(CupertinoIcons.person_2_fill), // ⬅️ FIX: Changed to filled icon
          label: 'Community',
        ),
        // 5. Messages (Using the filled icon when active)
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chat_bubble_2),
          activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill), // ⬅️ FIX: Changed to filled icon
          label: 'Messages',
        ),
      ],
    );
  }
}