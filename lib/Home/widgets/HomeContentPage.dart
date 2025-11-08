import 'package:flutter/material.dart';
import 'package:student_unify_app/Home/widgets/scrolling.dart';

import 'Carousel.dart';

class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This Column defines the entire body content for the Home tab
    return Column(
      children: [
        // -----------------------------------------------------------
        // 1. FIXED HEADER SECTION (Header/Greeting/Address)
        // -----------------------------------------------------------
        Stack(
          children: [
            // 🟣 Semi-transparent Header Background
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
            // 🧱 Foreground Content (Header)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Top Row (Greeting + Icons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("Good Morning, Ujah Obinna", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                        Row(children: [const Icon(Icons.notifications_outlined, color: Colors.white), const SizedBox(width: 16),
                          // The Builder/GestureDetector for the Drawer MUST reference the main Scaffold
                          Builder(builder: (context) => GestureDetector(onTap: () => Scaffold.of(context).openEndDrawer(), child: const Icon(Icons.menu_outlined, color: Colors.white))),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 📍 Address Row
                    Row(children: const [
                      Icon(Icons.pin_drop_outlined, color: Colors.white), SizedBox(width: 5),
                      Text("Anderson Road", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                      Icon(Icons.arrow_drop_down_outlined, color: Colors.white),
                    ]),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
        const QuoteCarousel(),
        const SizedBox(height: 16),

        // -----------------------------------------------------------
        // 2. SCROLLABLE ITEM LISTS SECTION (Takes up remaining space)
        // -----------------------------------------------------------
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: const [
                HorizontalItemList(categoryTitle: 'Free Academic and Study Materials',),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Sport and Leisure Wears',),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Free Tech and Electronics',),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Free clothing and wears',),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Dorm and Essential things',),
                SizedBox(height: 16),
                HorizontalItemList(categoryTitle: 'Others',),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}