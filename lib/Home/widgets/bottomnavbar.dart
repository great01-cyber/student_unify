import 'package:flutter/material.dart';

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
    // The widget must return only the BottomNavigationBar, NOT a Scaffold.
    return BottomNavigationBar(
      // Use the properties passed from the parent widget
      currentIndex: currentIndex,
      onTap: onTap,

      type: BottomNavigationBarType.fixed, // Essential for 4+ items
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,

      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'More',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Messages',
        ),
      ],
    );
  }
}