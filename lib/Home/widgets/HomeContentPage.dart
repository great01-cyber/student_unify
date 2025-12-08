import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for general icon compatibility
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: Adjust these imports to match your actual file structure
import 'package:student_unify_app/Home/widgets/scrolling.dart';
import '../../listings/HorizontalLendList.dart';
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
    _loadAllData(); // Combined data loading into one function
  }

  // Combine async loading for safety
  void _loadAllData() async {
    // Check if the widget is mounted before setting initial state
    if (!mounted) return;

    // Load user data
    username = await fetchUserName();

    // Load location data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('selected_address') ?? "";
    final coords = prefs.getString('selected_coordinates');

    // Only call setState once after all initial data is loaded
    if (mounted) {
      setState(() {
        _selectedAddress = address;
        _selectedCoordinates = coords;
        this.username = username; // Update the state variable
      });
    }
  }

  // ---------------- Save location ----------------
  void saveLocation(String address, String coords) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_address', address);
    await prefs.setString('selected_coordinates', coords);
  }

  // ---------------- Navigate to MapSelectionPage ----------------
  void _selectLocation() async {
    final String? returnValue = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapSelectionPage(),
      ),
    );

    if (returnValue != null && mounted && returnValue.contains('||')) {
      final parts = returnValue.split('||');
      final coords = parts[0];
      final address = parts[1];

      // Save to SharedPreferences immediately
      saveLocation(address, coords);

      setState(() {
        _selectedAddress = address;
        _selectedCoordinates = coords;
      });

      debugPrint('New location saved: $_selectedCoordinates ($address)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ----------------- HEADER SECTION (Simplified) ---------------------
        Container(
          // Use Container for the background and rounded corners
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            // Use Padding for horizontal spacing
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Greeting + icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          // Use the state variable
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
                          // Builder is still necessary here to access the Scaffold context
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

                  // Placeholder spacing for the height of the removed stack/container
                  const SizedBox(height: 30 - 12),
                ],
              ),
            ),
          ),
        ),

        //const QuoteCarousel(),
        const SizedBox(height: 16),


        // ---------------- SCROLLABLE CONTENT -------------------
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: const [
                HorizontalLendRequestsList(),
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
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- UTILITY FUNCTIONS ----------------
// Keep utility functions outside the class

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
    // Return the email if displayName is missing
    String? email = user.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first; // Use part of the email as username
    }
    return "User";
  }
  return "Guest";
}