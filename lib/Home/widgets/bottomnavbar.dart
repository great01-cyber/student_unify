import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/widgets/badgeIconReuseableIcon.dart';
import 'package:student_unify_app/services/UnreadMessageService.dart';



class BottomNavBar extends StatelessWidget {
  final void Function(int index) onTap;
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.onTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final unreadService = UnreadMessageService();

    return StreamBuilder<int>(
      stream: unreadService.getUnreadMessagesCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          items: <BottomNavigationBarItem>[
            // 1. Home
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'Home',
            ),
            // 2. Search
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              activeIcon: Icon(CupertinoIcons.search),
              label: 'Search',
            ),
            // 3. Community
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_2),
              activeIcon: Icon(CupertinoIcons.person_2_fill),
              label: 'Community',
            ),
            // 4. Messages with badge
            BottomNavigationBarItem(
              icon: BadgeIcon(
                count: unreadCount,
                child: const Icon(CupertinoIcons.chat_bubble_2),
              ),
              activeIcon: BadgeIcon(
                count: unreadCount,
                child: const Icon(CupertinoIcons.chat_bubble_2_fill),
              ),
              label: 'Messages',
            ),
          ],
        );
      },
    );
  }
}