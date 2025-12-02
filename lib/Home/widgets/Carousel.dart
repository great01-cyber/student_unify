import 'dart:async';

import 'package:flutter/material.dart';
const String imageLamp = "assets/images/lamp.png";
const String imageBook = "assets/images/books.png";
const String imageCommunity = "assets/images/partners.png";
const String imageTools = "assets/images/collaboration.png";
const String imageTreasure = "assets/images/empathy.png";
const String imageLibrary = "assets/images/library.png";
const String imageSwap = "assets/images/borrow.png";

class QuoteItem {
  final String quote;
  final String imagePath;
  final String tagline;
  final List<Color> gradientColors;
  final Color textColor;
  final Color taglineColor;

  QuoteItem({
    required this.quote,
    required this.imagePath,
    required this.tagline,
    required this.gradientColors,
    required this.textColor,
    required this.taglineColor,
  });
}

class QuoteCarousel extends StatefulWidget {
  const QuoteCarousel({super.key});

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  // Full list of 7 quotes with unique color schemes
  final List<QuoteItem> _items = [
    QuoteItem(
      quote: "Your used lamp could brighten someone else's study space.",
      imagePath: imageLamp,
      tagline: "Shine On!",
      gradientColors: [const Color(0xFFFFE082), const Color(0xFFFFB300)], // Warm yellow/amber
      textColor: const Color(0xFF5D4037),
      taglineColor: const Color(0xFF8D6E63),
    ),
    QuoteItem(
      quote: "One student's finished textbook is another's perfect head start.",
      imagePath: imageBook,
      tagline: "Knowledge is Shared.",
      gradientColors: [const Color(0xFF81C784), const Color(0xFF66BB6A)], // Fresh green
      textColor: const Color(0xFF1B5E20),
      taglineColor: const Color(0xFF2E7D32),
    ),
    QuoteItem(
      quote: "The things you pass on don't just clear your clutter; they build our community.",
      imagePath: imageCommunity,
      tagline: "Building Community.",
      gradientColors: [const Color(0xFF90CAF9), const Color(0xFF42A5F5)], // Sky blue
      textColor: const Color(0xFF0D47A1),
      taglineColor: const Color(0xFF1565C0),
    ),
    QuoteItem(
      quote: "Share a tool, save a trip to the store. Together, we make student life easier.",
      imagePath: imageTools,
      tagline: "Practical Help.",
      gradientColors: [const Color(0xFFFF8A65), const Color(0xFFFF7043)], // Coral orange
      textColor: const Color(0xFFBF360C),
      taglineColor: const Color(0xFFD84315),
    ),
    QuoteItem(
      quote: "Give your old treasures a new campus life.",
      imagePath: imageTreasure,
      tagline: "Sustainable Swaps.",
      gradientColors: [const Color(0xFFCE93D8), const Color(0xFFAB47BC)], // Purple
      textColor: const Color(0xFF4A148C),
      taglineColor: const Color(0xFF6A1B9A),
    ),
    QuoteItem(
      quote: "The greatest resource on campus isn't just the library—it's what we share.",
      imagePath: imageLibrary,
      tagline: "True Resourcefulness.",
      gradientColors: [const Color(0xFF80DEEA), const Color(0xFF26C6DA)], // Turquoise
      textColor: const Color(0xFF006064),
      taglineColor: const Color(0xFF00838F),
    ),
    QuoteItem(
      quote: "Swap, save, and succeed. Every shared item is a step toward a lighter load.",
      imagePath: imageSwap,
      tagline: "Lighter Load, Bigger Wins.",
      gradientColors: [const Color(0xFFF48FB1), const Color(0xFFEC407A)], // Pink
      textColor: const Color(0xFF880E4F),
      taglineColor: const Color(0xFFC2185B),
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
        gradient: LinearGradient(
          colors: item.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: item.gradientColors[1].withOpacity(0.4),
            blurRadius: 12.0,
            offset: const Offset(0, 6),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.gradientColors[0].withOpacity(0.3),
                          item.gradientColors[1].withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: item.textColor.withOpacity(0.5),
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
                      color: item.textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.tagline,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: item.taglineColor,
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