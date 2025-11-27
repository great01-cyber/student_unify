import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/widgets/scrolling.dart';

import 'Carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  _HomeContentPageState createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  String username = "Loading...";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    username = await fetchUserName();
    setState(() {}); // update UI
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
                color: Colors.blueGrey,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${getGreeting()}, $username",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),

                            Builder(
                              builder: (context) => GestureDetector(
                                onTap: () =>
                                    Scaffold.of(context).openEndDrawer(),
                                child: const Icon(
                                  Icons.menu_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: const [
                        Icon(Icons.pin_drop_outlined, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          "Anderson Road",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down_outlined, color: Colors.white),
                      ],
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
                HorizontalItemList(
                    categoryTitle: 'Free Academic and Study Materials'),
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
