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
  final String detailedDescription;
  final List<String> keyPoints;

  QuoteItem({
    required this.quote,
    required this.imagePath,
    required this.tagline,
    required this.gradientColors,
    required this.textColor,
    required this.taglineColor,
    required this.detailedDescription,
    required this.keyPoints,
  });
}

class QuoteCarousel extends StatefulWidget {
  const QuoteCarousel({super.key});

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  final List<QuoteItem> _items = [
    QuoteItem(
      quote: "Your used lamp could brighten someone else's study space.",
      imagePath: imageLamp,
      tagline: "Shine On!",
      gradientColors: [const Color(0xFFFFE082), const Color(0xFFFFB300)],
      textColor: const Color(0xFF5D4037),
      taglineColor: const Color(0xFF8D6E63),
      detailedDescription:
      "Every semester, countless lamps sit unused in storage while other students study in dim lighting. Your desk lamp that served you well could be the perfect solution for someone else's late-night study sessions. By sharing your lamp, you're not just decluttering—you're helping create better study environments across campus.",
      keyPoints: [
        "Desk lamps are essential for focused studying",
        "Many students can't afford quality lighting",
        "Sharing reduces electronic waste",
        "Create a brighter campus community",
      ],
    ),
    QuoteItem(
      quote: "One student's finished textbook is another's perfect head start.",
      imagePath: imageBook,
      tagline: "Knowledge is Shared.",
      gradientColors: [const Color(0xFF81C784), const Color(0xFF66BB6A)],
      textColor: const Color(0xFF1B5E20),
      taglineColor: const Color(0xFF2E7D32),
      detailedDescription:
      "Textbooks represent a massive expense for students. When you pass on your used books, you're not just saving someone money—you're helping them access the knowledge they need to succeed. Your highlighted notes and annotations might even provide valuable insights for the next reader.",
      keyPoints: [
        "Textbooks can cost hundreds per semester",
        "Your notes add extra value for future students",
        "Reduce the financial burden of education",
        "Books deserve multiple lives and readers",
      ],
    ),
    QuoteItem(
      quote:
      "The things you pass on don't just clear your clutter; they build our community.",
      imagePath: imageCommunity,
      tagline: "Building Community.",
      gradientColors: [const Color(0xFF90CAF9), const Color(0xFF42A5F5)],
      textColor: const Color(0xFF0D47A1),
      taglineColor: const Color(0xFF1565C0),
      detailedDescription:
      "Community isn't just built through events and gatherings—it's built through acts of generosity. When you share your belongings, you're creating connections and fostering a culture of mutual support. Every item you pass on strengthens the bonds between students and makes campus feel more like home.",
      keyPoints: [
        "Sharing creates meaningful connections",
        "Build a culture of generosity and trust",
        "Make campus feel more welcoming",
        "Strengthen student support networks",
      ],
    ),
    QuoteItem(
      quote:
      "Share a tool, save a trip to the store. Together, we make student life easier.",
      imagePath: imageTools,
      tagline: "Practical Help.",
      gradientColors: [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
      textColor: const Color(0xFFBF360C),
      taglineColor: const Color(0xFFD84315),
      detailedDescription:
      "Need a screwdriver for an hour? A hammer for one project? Tools are perfect for sharing because they're used occasionally but essential when needed. By lending your tools, you save fellow students time, money, and the hassle of buying items they'll rarely use.",
      keyPoints: [
        "Most tools are used infrequently",
        "Save students money on one-time purchases",
        "Reduce unnecessary consumption",
        "Build practical support systems",
      ],
    ),
    QuoteItem(
      quote: "Give your old treasures a new campus life.",
      imagePath: imageTreasure,
      tagline: "Sustainable Swaps.",
      gradientColors: [const Color(0xFFCE93D8), const Color(0xFFAB47BC)],
      textColor: const Color(0xFF4A148C),
      taglineColor: const Color(0xFF6A1B9A),
      detailedDescription:
      "That poster you loved freshman year, the coffee maker you upgraded from, the chair that doesn't fit your new apartment—these items have stories and usefulness left in them. By finding them new homes, you're practicing sustainability and helping others make their spaces feel special without breaking the bank.",
      keyPoints: [
        "Extend the life of quality items",
        "Help others personalize their spaces affordably",
        "Reduce landfill waste significantly",
        "Every reused item has environmental impact",
      ],
    ),
    QuoteItem(
      quote:
      "The greatest resource on campus isn't just the library—it's what we share.",
      imagePath: imageLibrary,
      tagline: "True Resourcefulness.",
      gradientColors: [const Color(0xFF80DEEA), const Color(0xFF26C6DA)],
      textColor: const Color(0xFF006064),
      taglineColor: const Color(0xFF00838F),
      detailedDescription:
      "Universities invest in libraries, labs, and facilities, but the most valuable resources are the ones we create together. A sharing economy among students means access to more items, knowledge, and support than any individual could afford alone. Together, we're building a library of physical resources.",
      keyPoints: [
        "Collective sharing increases access for all",
        "Create a resource-rich environment together",
        "Learn valuable lessons about community",
        "Build habits that last beyond university",
      ],
    ),
    QuoteItem(
      quote:
      "Swap, save, and succeed. Every shared item is a step toward a lighter load.",
      imagePath: imageSwap,
      tagline: "Lighter Load, Bigger Wins.",
      gradientColors: [const Color(0xFFF48FB1), const Color(0xFFEC407A)],
      textColor: const Color(0xFF880E4F),
      taglineColor: const Color(0xFFC2185B),
      detailedDescription:
      "Student life comes with enough stress—finances, deadlines, and transitions. Sharing items lightens both your physical load (less stuff to move) and your financial burden (less to buy). It's a simple way to make student life more manageable while building a supportive community.",
      keyPoints: [
        "Reduce moving stress between semesters",
        "Save money for experiences over things",
        "Focus on what truly matters in university",
        "Create sustainable student lifestyles",
      ],
    ),
  ];

  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;
  final int _duration = 4;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: _duration), (Timer timer) {
      if (mounted) {
        if (_currentPage < _items.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

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
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showDetailModal(BuildContext context, QuoteItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailModal(item: item),
    );
  }

  Widget _buildQuoteContainer(QuoteItem item) {
    return GestureDetector(
      onTap: () => _showDetailModal(context, item),
      child: Container(
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
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20.0)),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
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

// Detail Modal Widget
class _DetailModal extends StatelessWidget {
  final QuoteItem item;

  const _DetailModal({required this.item});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20.0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12.0),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image
                      _buildHeroImage(),
                      const SizedBox(height: 20),

                      // Tagline
                      _buildTagline(),
                      const SizedBox(height: 12),

                      // Quote
                      _buildQuote(),
                      const SizedBox(height: 24),

                      // Detailed Description
                      _buildDescription(),
                      const SizedBox(height: 24),

                      // Key Points
                      _buildKeyPoints(),
                      const SizedBox(height: 32),

                      // Call to Action
                      _buildCallToAction(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Image.asset(
          item.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_outlined,
                size: 80,
                color: item.textColor.withOpacity(0.5),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item.tagline,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: item.textColor,
        ),
      ),
    );
  }

  Widget _buildQuote() {
    return Text(
      item.quote,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: item.textColor,
        height: 1.4,
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Why This Matters",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: item.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.detailedDescription,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyPoints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Key Benefits",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: item.textColor,
          ),
        ),
        const SizedBox(height: 16),
        ...item.keyPoints.map((point) => _buildKeyPoint(point)),
      ],
    );
  }

  Widget _buildKeyPoint(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors,
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: item.gradientColors[1].withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            // Add your action here (e.g., navigate to sharing page)
          },
          child: Center(
            child: Text(
              "Start Sharing Today",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: item.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}