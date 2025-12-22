import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_unify_app/Home/widgets/scrolling.dart';
import '../../listings/HorizontalLendList.dart';
import '../../services/MapSelectionPage.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

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
            const Color(0xFFFAFAFA),
            const Color(0xFFF5F5F5),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // ================= ENHANCED HEADER =================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E3A8A),
                  const Color(0xFF2563EB),
                  const Color(0xFF3B82F6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting row
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
                                      fontFamily: 'Comfortaa',
                                      fontWeight: FontWeight.w300,
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontFamily: 'Comfortaa',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 24,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildIconButton(
                                  icon: Icons.notifications_outlined,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 12),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Location",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'Comfortaa',
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white.withOpacity(0.8),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedAddress.isEmpty
                                            ? "Tap to set location"
                                            : _selectedAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Comfortaa',
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isStudent
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isStudent
                                  ? Colors.greenAccent.withOpacity(0.5)
                                  : Colors.orangeAccent.withOpacity(0.5),
                              width: 1,
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
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _roleLoading
                                    ? "Checking access..."
                                    : _isStudent
                                    ? "Student Access"
                                    : "Non-Student Access",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Comfortaa',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
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

          // ================= ENHANCED CONTENT =================
          Expanded(
            child: _roleLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading your content...",
                    style: TextStyle(
                      fontFamily: 'Comfortaa',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Always visible section
                    _buildSectionHeader("Lending Requests", Icons.handshake_rounded),
                    const HorizontalLendRequestsList(),

                    // Student-only content
                    if (_isStudent) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader("Categories", Icons.category_rounded),
                      const SizedBox(height: 8),
                      _buildCategorySection('Academic and Study Materials', Icons.book_rounded),
                      _buildCategorySection('Sport and Leisure Wears', Icons.sports_basketball_rounded),
                      _buildCategorySection('Tech and Electronics', Icons.devices_rounded),
                      _buildCategorySection('Clothing and wears', Icons.checkroom_rounded),
                      _buildCategorySection('Dorm and Essential things', Icons.bed_rounded),
                      _buildCategorySection('Others', Icons.more_horiz_rounded),
                      const SizedBox(height: 32),
                    ],
                  ],
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Comfortaa',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String categoryTitle, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                categoryTitle,
                style: const TextStyle(
                  fontFamily: 'Comfortaa',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
        HorizontalItemList(categoryTitle: categoryTitle),
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