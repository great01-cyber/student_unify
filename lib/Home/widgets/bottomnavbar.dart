import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/widgets/badgeIconReuseableIcon.dart';
import 'package:student_unify_app/services/UnreadMessageService.dart';

// Color palette - consistent with HomeContentPage
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

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

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: primaryPink.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: primaryPink,
            unselectedItemColor: lightText,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Mont',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Mont',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: <BottomNavigationBarItem>[
              // 1. Home
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: CupertinoIcons.home,
                  isActive: currentIndex == 0,
                ),
                activeIcon: _buildNavIcon(
                  icon: CupertinoIcons.house_fill,
                  isActive: true,
                ),
                label: 'Home',
              ),

              // 2. Search
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: CupertinoIcons.search,
                  isActive: currentIndex == 1,
                ),
                activeIcon: _buildNavIcon(
                  icon: CupertinoIcons.search,
                  isActive: true,
                ),
                label: 'Search',
              ),

              // 3. Community
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  icon: CupertinoIcons.person_2,
                  isActive: currentIndex == 2,
                ),
                activeIcon: _buildNavIcon(
                  icon: CupertinoIcons.person_2_fill,
                  isActive: true,
                ),
                label: 'Community',
              ),

              // 4. Messages with badge
              BottomNavigationBarItem(
                icon: BadgeIcon(
                  count: unreadCount,
                  child: _buildNavIcon(
                    icon: CupertinoIcons.chat_bubble_2,
                    isActive: currentIndex == 3,
                  ),
                ),
                activeIcon: BadgeIcon(
                  count: unreadCount,
                  child: _buildNavIcon(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    isActive: true,
                  ),
                ),
                label: 'Messages',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? lightPink.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }
}