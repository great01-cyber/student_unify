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

class _HomeContentPageState extends State<HomeContentPage> {
  String username = "Loading...";
  String _selectedAddress = "";
  String? _selectedCoordinates;

  bool _isStudent = false; // 🔐 default safe
  bool _roleLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ---------------- LOAD USER + ROLE + LOCATION ----------------
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
  }

  // ---------------- FETCH ROLE FROM FIRESTORE ----------------
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

  // ---------------- LOCATION ----------------
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= HEADER =================
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${getGreeting()}, $username",
                          style: const TextStyle(
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w300,
                            fontSize: 20,
                            color: Color(0xFF1E3A8A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.notifications_outlined, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 16),
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => Scaffold.of(context).openEndDrawer(),
                              child: const Icon(Icons.menu_outlined, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location
                  GestureDetector(
                    onTap: _selectLocation,
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _selectedAddress.isEmpty
                                ? "Select your location"
                                : _selectedAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF1E3A8A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_outlined, color: Color(0xFF1E3A8A)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _roleLoading
                        ? "Checking access..."
                        : _isStudent
                        ? "Student access"
                        : "Non-student access",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ================= CONTENT =================
        Expanded(
          child: _roleLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              children: [
                // 🔓 ALWAYS visible
                const HorizontalLendRequestsList(),

                // 🔐 STUDENT-ONLY CONTENT
                if (_isStudent) ...const [
                  SizedBox(height: 16),
                  HorizontalItemList(categoryTitle: 'Academic and Study Materials'),
                  SizedBox(height: 16),
                  HorizontalItemList(categoryTitle: 'Sport and Leisure Wears'),
                  SizedBox(height: 16),
                  HorizontalItemList(categoryTitle: 'Tech and Electronics'),
                  SizedBox(height: 16),
                  HorizontalItemList(categoryTitle: 'Clothing and wears'),
                  SizedBox(height: 16),
                  HorizontalItemList(categoryTitle: 'Dorm and Essential things'),
                  SizedBox(height: 16),
                  HorizontalItemList(categoryTitle: 'Others'),
                  SizedBox(height: 32),
                ],
              ],
            ),
          ),
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
