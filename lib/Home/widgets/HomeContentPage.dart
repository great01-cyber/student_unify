import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_unify_app/Home/widgets/scrolling.dart';
import '../../listings/HorizontalLendList.dart';
import '../../services/MapSelectionPage.dart';
import '../../services/NotificationService.dart';
import 'Carousel.dart';
import 'NotifcationPage.dart';


class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> with SingleTickerProviderStateMixin {
  String username = "Loading...";
  String _selectedAddress = "";
  String? _selectedCoordinates;

  bool _isStudent = false;
  bool _roleLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Enhanced color palette
  static const Color primaryPink = Color(0xFFFF6786);
  static const Color lightPink = Color(0xFFFFE5EC);
  static const Color accentPink = Color(0xFFFF9BAD);
  static const Color darkText = Color(0xFF2D3748);
  static const Color lightText = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    final name = await fetchUserName();
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('selected_address') ?? "";
    final coords = prefs.getString('selected_coordinates');
    final isStudent = await _fetchIsStudent();

    if (!mounted) return;
    setState(() {
      username = name;
      _selectedAddress = address;
      _selectedCoordinates = coords;
      _isStudent = isStudent;
      _roleLoading = false;
    });

    _animationController.forward();
  }

  Future<bool> _fetchIsStudent() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? {};
      final role = (data['roleEffective'] ?? data['role'] ?? '')
          .toString()
          .toLowerCase();

      return role == 'student';
    } catch (e) {
      debugPrint('Role fetch error: $e');
      return false;
    }
  }

  Future<void> _saveLocation(String address, String coords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_address', address);
    await prefs.setString('selected_coordinates', coords);
  }

  void _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapSelectionPage()),
    );

    if (result != null && result.contains('||') && mounted) {
      final parts = result.split('||');
      await _saveLocation(parts[1], parts[0]);

      setState(() {
        _selectedAddress = parts[1];
        _selectedCoordinates = parts[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lightPink.withOpacity(0.3),
            Colors.white,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryPink,
                  accentPink,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryPink.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with greeting and icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getGreeting(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.95),
                                      letterSpacing: 0.3,
                                      fontFamily: 'Mont'
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 26,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Notification icon with badge
                                StreamBuilder<int>(
                                  stream: NotificationService().getUnreadNotificationCount(),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.data ?? 0;

                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _buildIconButton(
                                          icon: Icons.notifications_outlined,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const NotificationPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: -4,
                                            top: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Colors.red, Color(0xFFEF4444)],
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red.withOpacity(0.4),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                Builder(
                                  builder: (context) => _buildIconButton(
                                    icon: Icons.menu_outlined,
                                    onTap: () => Scaffold.of(context).openEndDrawer(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Location card
                        GestureDetector(
                          onTap: _selectLocation,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Location",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withOpacity(0.9),
                                          letterSpacing: 0.4,
                                          fontFamily: 'Mont'
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedAddress.isEmpty
                                            ? "Tap to set location"
                                            : _selectedAddress,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          height: 1.3,
                                          fontFamily: 'Mont'
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _roleLoading
                                    ? Icons.hourglass_empty_rounded
                                    : _isStudent
                                    ? Icons.school_rounded
                                    : Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _roleLoading
                                    ? "Checking access..."
                                    : _isStudent
                                    ? "Student Access"
                                    : "Non-Student Access",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mont',
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ================= CONTENT =================
          //QuoteCarousel(),
          Expanded(
            child: _roleLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Loading your content...",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: lightText,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: primaryPink,
              onRefresh: () async {
                // Refresh the page
                setState(() {
                  _roleLoading = true;
                });
                await _loadAllData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 32),
                  child: Column(
                    children: [
                      // Lending Requests section
                      const SizedBox(height: 12),
                      const HorizontalLendRequestsList(),

                      // Student-only content
                      if (_isStudent) ...[
                        const SizedBox(height: 3),
                        _buildCategorySection('Academic and Study Materials', Icons.menu_book_rounded),
                        _buildCategorySection('Sport and Leisure Wears', Icons.sports_basketball_rounded),
                        _buildCategorySection('Tech and Electronics', Icons.devices_rounded),
                        _buildCategorySection('Clothing and wears', Icons.checkroom_rounded),
                        _buildCategorySection('Dorm and Essential things', Icons.bed_rounded),
                        _buildCategorySection('Others', Icons.more_horiz_rounded),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String categoryTitle, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        ),
        // Pass the exact category title to HorizontalItemList
        HorizontalItemList(
          key: ValueKey(categoryTitle), // Add key to force rebuild
          categoryTitle: categoryTitle,
        ),
      ],
    );
  }
}

// ================= UTILITIES =================

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Good Morning";
  if (hour < 17) return "Good Afternoon";
  if (hour < 21) return "Good Evening";
  return "Good Night";
}

Future<String> fetchUserName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return "Guest";

  if (user.displayName != null && user.displayName!.isNotEmpty) {
    return user.displayName!;
  }

  if (user.email != null && user.email!.isNotEmpty) {
    return user.email!.split('@').first;
  }

  return "User";
}