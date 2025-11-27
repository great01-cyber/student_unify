import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: Adjust these imports to match your actual file structure
import 'package:student_unify_app/Home/widgets/scrolling.dart';
import '../../services/MapSelectionPage.dart';
import 'Carousel.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  _HomeContentPageState createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  String username = "Loading...";
  String _selectedAddress = "";
  String? _selectedCoordinates;

  @override
  void initState() {
    super.initState();
    loadUser();
    loadSavedLocation(); // Load saved location when page initializes
  }

  // ---------------- Load saved location ----------------
  void loadSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAddress = prefs.getString('selected_address') ?? "";
      _selectedCoordinates = prefs.getString('selected_coordinates');
    });
  }

  // ---------------- Save location ----------------
  void saveLocation(String address, String coords) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_address', address);
    await prefs.setString('selected_coordinates', coords);
  }

  // ---------------- Load username ----------------
  void loadUser() async {
    username = await fetchUserName();
    setState(() {});
  }

  // ---------------- Navigate to MapSelectionPage ----------------
  void _selectLocation() async {
    final String? returnValue = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapSelectionPage(),
      ),
    );

    if (returnValue != null && returnValue.contains('||')) {
      final parts = returnValue.split('||');
      final coords = parts[0];
      final address = parts[1];

      setState(() {
        _selectedAddress = address;
        _selectedCoordinates = coords;
      });

      // Save to SharedPreferences
      saveLocation(address, coords);

      print('New location saved: $_selectedCoordinates ($address)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ----------------- HEADER SECTION ---------------------
        Stack(
          children: [
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Top row: Greeting + icons
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
                            const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(width: 16),
                            Builder(
                              builder: (context) => GestureDetector(
                                onTap: () => Scaffold.of(context).openEndDrawer(),
                                child: const Icon(
                                  Icons.menu_outlined,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Location row
                    GestureDetector(
                      onTap: _selectLocation,
                      child: Row(
                        children: [
                          const Icon(Icons.pin_drop_outlined, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _selectedAddress.isEmpty ? "Select your location" : _selectedAddress,
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),

        const QuoteCarousel(),
        const SizedBox(height: 16),

        // ---------------- SCROLLABLE CONTENT -------------------
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: const [
                HorizontalItemList(categoryTitle: 'Free Academic and Study Materials'),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Sport and Leisure Wears'),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Free Tech and Electronics'),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Free clothing and wears'),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Dorm and Essential things'),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Others'),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- UTILITY FUNCTIONS ----------------

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Good Morning";
  if (hour < 17) return "Good Afternoon";
  if (hour < 21) return "Good Evening";
  return "Good Night";
}

Future<String> fetchUserName() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String? name = user.displayName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return "User";
  }
  return "Guest";
}
