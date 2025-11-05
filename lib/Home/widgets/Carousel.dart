import 'dart:async';

import 'package:flutter/material.dart';
const String imageLamp = "assets/images/verified.png";
const String imageBook = "assets/images/verified.png";
const String imageCommunity = "assets/images/verified.png";
const String imageTools = "assets/images/verified.png";
const String imageTreasure = "assets/images/verified.png";
const String imageLibrary = "assets/images/verified.png";
const String imageSwap = "assets/images/verified.png";

class QuoteItem {
  final String quote;
  final String imagePath;
  final String tagline;

  QuoteItem({required this.quote, required this.imagePath, required this.tagline});
}

class QuoteCarousel extends StatefulWidget {
  const QuoteCarousel({super.key});

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  // Full list of 7 quotes
  final List<QuoteItem> _items = [
    QuoteItem(
      quote: "Your used lamp could brighten someone else's study space.",
      imagePath: imageLamp,
      tagline: "Shine On!",
    ),
    QuoteItem(
      quote: "One student's finished textbook is another's perfect head start.",
      imagePath: imageBook,
      tagline: "Knowledge is Shared.",
    ),
    QuoteItem(
      quote: "The things you pass on don't just clear your clutter; they build our community.",
      imagePath: imageCommunity,
      tagline: "Building Community.",
    ),
    QuoteItem(
      quote: "Share a tool, save a trip to the store. Together, we make student life easier.",
      imagePath: imageTools,
      tagline: "Practical Help.",
    ),
    QuoteItem(
      quote: "Give your old treasures a new campus life.",
      imagePath: imageTreasure,
      tagline: "Sustainable Swaps.",
    ),
    QuoteItem(
      quote: "The greatest resource on campus isn't just the library—it's what we share.",
      imagePath: imageLibrary,
      tagline: "True Resourcefulness.",
    ),
    QuoteItem(
      quote: "Swap, save, and succeed. Every shared item is a step toward a lighter load.",
      imagePath: imageSwap,
      tagline: "Lighter Load, Bigger Wins.",
    ),
  ];

  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;
  final int _duration = 4; // seconds per slide

  @override
  void initState() {
    super.initState();
    // Start the automatic scrolling timer
    _timer = Timer.periodic(Duration(seconds: _duration), (Timer timer) {
      if (mounted) { // Check if the widget is still in the tree
        if (_currentPage < _items.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0; // Loop back to the first page
        }

        // Animate the PageView to the next page
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Always cancel the timer to prevent memory leaks
    _pageController.dispose();
    super.dispose();
  }

  // The Custom Quote Container Widget
  Widget _buildQuoteContainer(QuoteItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0FF), // Light background for contrast
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          // Left side: Image Container
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20.0)),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback for missing images
                  return Container(
                    color: Colors.blueGrey.shade100,
                    child: Center(
                      child: Text(
                        item.imagePath.replaceAll('assets/', '').replaceAll('.jpg', ''), // Display image name
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Right side: Quote Text
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.quote,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.tagline,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // Slightly reduced height to fit better
      child: PageView.builder(
        controller: _pageController,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildQuoteContainer(item);
        },
      ),
    );
  }
}
// ---