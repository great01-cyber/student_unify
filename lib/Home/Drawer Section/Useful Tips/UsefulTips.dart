import 'package:flutter/material.dart';
import 'dart:math';

// Helper class for tip data
class TipCard {
  final String front;
  final String back;
  final String category;
  final List<int> colors;
  final IconData icon;

  TipCard({
    required this.front,
    required this.back,
    required this.category,
    required this.colors,
    required this.icon,
  });
}

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool isFlipped = false;
  late AnimationController flipController;
  late Animation<double> flipAnimation;

  final List<TipCard> tips = [
    // Food & Groceries
    TipCard(
      front: "Cook in Batches",
      back: "Meal prep on Sundays. Cook large portions and freeze meals. Save £200+ monthly versus eating out daily. Use apps like Meal Prep Pro for recipes.",
      category: "Food",
      colors: [0xFF10B981, 0xFF059669],
      icon: Icons.restaurant_menu,
    ),
    TipCard(
      front: "Yellow Sticker Shopping",
      back: "Shop after 7pm for heavily reduced items nearing expiry. Freeze fresh items immediately. Can save 50-70% on groceries!",
      category: "Food",
      colors: [0xFFF59E0B, 0xFFD97706],
      icon: Icons.local_offer,
    ),
    TipCard(
      front: "Supermarket Own Brands",
      back: "Switch to store brands for basics. Often made in same factories as premium brands. Save £30-50 weekly on identical products.",
      category: "Food",
      colors: [0xFF8B5CF6, 0xFF7C3AED],
      icon: Icons.shopping_cart,
    ),
    TipCard(
      front: "Too Good To Go App",
      back: "Get restaurant meals for £3-4 instead of £15+. Download the app and grab surprise bags from cafes and restaurants near campus.",
      category: "Food",
      colors: [0xFF14B8A6, 0xFF0D9488],
      icon: Icons.takeout_dining,
    ),

    // Student Discounts
    TipCard(
      front: "Student Discounts",
      back: "Always ask for student discounts! Use UNiDAYS, Student Beans, and your NUS card. Get 10-20% off at hundreds of stores.",
      category: "Savings",
      colors: [0xFF3B82F6, 0xFF2563EB],
      icon: Icons.card_giftcard,
    ),
    TipCard(
      front: "Amazon Prime Student",
      back: "Get 6 months free Prime, then 50% off. Free next-day delivery, Prime Video, and exclusive deals worth hundreds yearly.",
      category: "Savings",
      colors: [0xFFFF9800, 0xFFF57C00],
      icon: Icons.shopping_bag,
    ),
    TipCard(
      front: "Spotify & Apple Music",
      back: "Students pay £5.99/month instead of £10.99. Some unis offer free Spotify through student union deals. Check your perks!",
      category: "Entertainment",
      colors: [0xFF1DB954, 0xFF1AA34A],
      icon: Icons.music_note,
    ),

    // Books & Education
    TipCard(
      front: "Library Resources",
      back: "Borrow textbooks, tech equipment, and laptops from your library. Many libraries have book scanners too. Save £500+ yearly.",
      category: "Education",
      colors: [0xFF6366F1, 0xFF4F46E5],
      icon: Icons.local_library,
    ),
    TipCard(
      front: "Buy Used Textbooks",
      back: "Use AbeBooks, Ziffit, or campus Facebook groups. Sell back after exams. Can get books for 30-50% less than new.",
      category: "Education",
      colors: [0xFF06B6D4, 0xFF0891B2],
      icon: Icons.menu_book,
    ),
    TipCard(
      front: "Digital Textbooks",
      back: "Rent eTextbooks for £10-20 instead of buying for £60+. Use VitalSource or Amazon Kindle. Share account with coursemates (shh!).",
      category: "Education",
      colors: [0xFFEC4899, 0xFFDB2777],
      icon: Icons.tablet_mac,
    ),
    TipCard(
      front: "Open Educational Resources",
      back: "Use OpenStax, Project Gutenberg, and Khan Academy for free textbooks and courses. Completely legal and saves hundreds!",
      category: "Education",
      colors: [0xFF10B981, 0xFF059669],
      icon: Icons.school,
    ),

    // Transportation
    TipCard(
      front: "Railcard Savings",
      back: "16-25 Railcard saves 1/3 on train fares. Costs £30/year but pays for itself in 2-3 trips. Annual card saves even more!",
      category: "Transport",
      colors: [0xFFEF4444, 0xFFDC2626],
      icon: Icons.train,
    ),
    TipCard(
      front: "Bike Instead of Bus",
      back: "Buy a secondhand bike for £50-100. Save £40-60 monthly on transport. Plus free exercise and faster commute!",
      category: "Transport",
      colors: [0xFF22C55E, 0xFF16A34A],
      icon: Icons.pedal_bike,
    ),
    TipCard(
      front: "Walk or Cycle",
      back: "Live within 30 minutes walk of campus. Save £500+ yearly on buses. Get fit, clear your mind, and wake up naturally.",
      category: "Transport",
      colors: [0xFF84CC16, 0xFF65A30D],
      icon: Icons.directions_walk,
    ),

    // Entertainment
    TipCard(
      front: "Free Museum Days",
      back: "Most UK museums are FREE! Use student nights at galleries, theatres offer student rush tickets. Culture doesn't have to be expensive.",
      category: "Entertainment",
      colors: [0xFF8B5CF6, 0xFF7C3AED],
      icon: Icons.museum,
    ),
    TipCard(
      front: "Campus Events",
      back: "Free comedy shows, concerts, workshops at student union. Often with free food! Check your SU events calendar weekly.",
      category: "Entertainment",
      colors: [0xFFF59E0B, 0xFFD97706],
      icon: Icons.celebration,
    ),
    TipCard(
      front: "Student Cinema",
      back: "Odeon, Vue, and Cineworld offer £5-7 student tickets. Some unis have campus cinemas for £3-4. Save £8+ per visit!",
      category: "Entertainment",
      colors: [0xFFEC4899, 0xFFDB2777],
      icon: Icons.movie,
    ),

    // Money Management
    TipCard(
      front: "Budget Apps",
      back: "Use Monzo, Starling, or Emma to track spending. Set savings goals and spending limits. Awareness = savings!",
      category: "Finance",
      colors: [0xFF3B82F6, 0xFF2563EB],
      icon: Icons.account_balance_wallet,
    ),
    TipCard(
      front: "50/30/20 Rule",
      back: "50% needs (rent, food), 30% wants (fun), 20% savings. Adjust for student life but keep the principle. Plan your loan!",
      category: "Finance",
      colors: [0xFF06B6D4, 0xFF0891B2],
      icon: Icons.pie_chart,
    ),
    TipCard(
      front: "Emergency Fund",
      back: "Save £500-1000 for emergencies. Broken laptop? Unexpected travel? You're covered. Start with £5/week if needed.",
      category: "Finance",
      colors: [0xFFEF4444, 0xFFDC2626],
      icon: Icons.savings,
    ),

    // Housing
    TipCard(
      front: "Share Bulk Buys",
      back: "Split Costco membership with housemates. Buy toilet paper, pasta, rice in bulk. Save 40% on household essentials.",
      category: "Housing",
      colors: [0xFF10B981, 0xFF059669],
      icon: Icons.home,
    ),
    TipCard(
      front: "Energy Saving",
      back: "Use draft excluders, turn heating down 1°C, switch to LED bulbs. Save £200+ yearly on bills. Every degree counts!",
      category: "Housing",
      colors: [0xFF84CC16, 0xFF65A30D],
      icon: Icons.lightbulb,
    ),
    TipCard(
      front: "Compare Utilities",
      back: "Use MoneySuperMarket, Uswitch for best deals. Switch providers annually. Student houses can save £300+ on energy.",
      category: "Housing",
      colors: [0xFFF59E0B, 0xFFD97706],
      icon: Icons.compare_arrows,
    ),

    // Tech & Gadgets
    TipCard(
      front: "Student Software",
      back: "Get FREE Microsoft Office, Adobe Creative Cloud discounts, GitHub Pro. Your uni email unlocks hundreds in free software!",
      category: "Technology",
      colors: [0xFF6366F1, 0xFF4F46E5],
      icon: Icons.computer,
    ),
    TipCard(
      front: "Refurbished Tech",
      back: "Buy certified refurbished from Apple, Dell, or Amazon Renewed. Like new, 1-year warranty, 40-60% cheaper than new.",
      category: "Technology",
      colors: [0xFF8B5CF6, 0xFF7C3AED],
      icon: Icons.laptop_mac,
    ),
    TipCard(
      front: "Sell Old Electronics",
      back: "Use Music Magpie, CeX, or Facebook Marketplace. That old phone/laptop is worth £50-200. Declutter AND earn!",
      category: "Technology",
      colors: [0xFF14B8A6, 0xFF0D9488],
      icon: Icons.phone_android,
    ),

    // Extra Income
    TipCard(
      front: "Campus Jobs",
      back: "Library assistant, student ambassador, tour guide. Flexible hours, understanding managers, 10-15 hours weekly = £400-600/month.",
      category: "Income",
      colors: [0xFF10B981, 0xFF059669],
      icon: Icons.work,
    ),
    TipCard(
      front: "Tutoring",
      back: "Tutor GCSE/A-Level students at £15-25/hour. Use MyTutor, Tutor House, or advertise locally. Share your knowledge, earn well!",
      category: "Income",
      colors: [0xFF3B82F6, 0xFF2563EB],
      icon: Icons.school,
    ),
    TipCard(
      front: "Sell Class Notes",
      back: "Upload notes to Stuvia, Nexus Notes, or OneClass. Earn passive income from notes you've already made. £50-200/semester possible!",
      category: "Income",
      colors: [0xFFEC4899, 0xFFDB2777],
      icon: Icons.note,
    ),

    // Health & Wellness
    TipCard(
      front: "Gym Membership",
      back: "Use FREE university gym or pay £15-20/month vs £40+ commercial. Many unis offer classes, pool, and equipment included.",
      category: "Health",
      colors: [0xFFEF4444, 0xFFDC2626],
      icon: Icons.fitness_center,
    ),
    TipCard(
      front: "Mental Health Support",
      back: "FREE counseling through university services. Use Student Minds, Togetherall, or campus wellbeing programs. Your health matters!",
      category: "Health",
      colors: [0xFF8B5CF6, 0xFF7C3AED],
      icon: Icons.favorite,
    ),
    TipCard(
      front: "Cook Healthy",
      back: "Batch cook healthy meals = cheaper AND healthier than takeaways. £3 homemade curry vs £12 delivery. Your body and wallet thank you!",
      category: "Health",
      colors: [0xFF22C55E, 0xFF16A34A],
      icon: Icons.restaurant,
    ),
  ];

  @override
  void initState() {
    super.initState();
    flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    flipController.dispose();
    super.dispose();
  }

  void flipCard() {
    if (isFlipped) {
      flipController.reverse();
    } else {
      flipController.forward();
    }
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  void onCardDismissed() {
    if (currentIndex < tips.length - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
        flipController.reset();
      });
    }
  }

  void skipCard() => onCardDismissed();

  void goBackCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isFlipped = false;
        flipController.reset();
      });
    }
  }

  Widget _buildFront(TipCard tip) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(tip.colors[0]), Color(tip.colors[1])],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(tip.icon, size: 70, color: Colors.white),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tip.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  tip.front,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Mont',
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tap to reveal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(TipCard tip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Gradient accent at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(tip.colors[0]).withOpacity(0.1),
                    Color(tip.colors[1]).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(tip.colors[0]), Color(tip.colors[1])],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tip.icon, size: 40, color: Colors.white),
                ),
                SizedBox(height: 24),
                Text(
                  tip.back,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(tip.colors[0]).withOpacity(0.1),
                        Color(tip.colors[1]).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_right,
                        color: Color(tip.colors[0]),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Swipe for next tip',
                        style: TextStyle(
                          color: Color(tip.colors[0]),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableCard(int index, double screenWidth) {
    final tip = tips[index];
    final bool isCurrentCard = index == currentIndex;
    final int stackDepth = index - currentIndex;

    final double scale = (stackDepth).clamp(0, 2) * -0.04 + 1.0;
    final double offset = (stackDepth).clamp(0, 2) * 12.0;

    return KeyedSubtree(
      key: ValueKey(tip.front),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(0.0, offset)
          ..scale(scale),
        alignment: Alignment.center,
        child: isCurrentCard
            ? _TopCard(
          tip: tip,
          screenWidth: screenWidth,
          onDismissed: onCardDismissed,
          flipCard: flipCard,
          isFlipped: isFlipped,
          flipAnimation: flipAnimation,
          buildFront: _buildFront,
          buildBack: _buildBack,
        )
            : _StackedCard(tip: tip, buildFront: _buildFront),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final progress = (currentIndex + 1) / tips.length;

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "Student Money Tips",
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Mont',
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${currentIndex + 1} of ${tips.length}",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),

            // Instructions
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInstruction(Icons.touch_app, 'Tap to flip'),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _buildInstruction(Icons.swipe, 'Swipe to next'),
                ],
              ),
            ),

            Spacer(),

            // Cards Stack
            SizedBox(
              height: 500,
              child: currentIndex < tips.length
                  ? Stack(
                alignment: Alignment.topCenter,
                children: List.generate(
                  min(tips.length - currentIndex, 3),
                      (index) => _buildDraggableCard(
                      currentIndex + index, screenWidth),
                ).reversed.toList(),
              )
                  : _buildCompletionScreen(),
            ),

            Spacer(),

            // Navigation Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  FloatingActionButton(
                    heroTag: 'back',
                    onPressed: currentIndex > 0 ? goBackCard : null,
                    backgroundColor: currentIndex > 0 ? Colors.white : Colors.grey[300],
                    elevation: currentIndex > 0 ? 4 : 0,
                    child: Icon(
                      Icons.arrow_back,
                      color: currentIndex > 0 ? Color(0xFF1F2937) : Colors.grey[500],
                    ),
                  ),

                  // Next Button
                  FloatingActionButton(
                    heroTag: 'next',
                    onPressed: currentIndex < tips.length - 1 ? skipCard : null,
                    backgroundColor: currentIndex < tips.length - 1
                        ? Color(0xFF10B981)
                        : Colors.grey[300],
                    elevation: currentIndex < tips.length - 1 ? 4 : 0,
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF10B981)),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.celebration, size: 80, color: Colors.white),
          ),
          SizedBox(height: 24),
          Text(
            'All Tips Completed! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Mont',
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You\'ve learned ${tips.length} money-saving tips!\nStart applying them today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                currentIndex = 0;
                isFlipped = false;
                flipController.reset();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Start Over'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// TOP CARD (Draggable + Flippable)
// -----------------------------------------------------------

class _TopCard extends StatefulWidget {
  final TipCard tip;
  final double screenWidth;
  final VoidCallback onDismissed;
  final VoidCallback flipCard;
  final bool isFlipped;
  final Animation<double> flipAnimation;
  final Widget Function(TipCard) buildFront;
  final Widget Function(TipCard) buildBack;

  const _TopCard({
    required this.tip,
    required this.screenWidth,
    required this.onDismissed,
    required this.flipCard,
    required this.isFlipped,
    required this.flipAnimation,
    required this.buildFront,
    required this.buildBack,
  });

  @override
  State<_TopCard> createState() => _TopCardState();
}

class _TopCardState extends State<_TopCard>
    with SingleTickerProviderStateMixin {
  Offset position = Offset.zero;
  late AnimationController swipeController;

  @override
  void initState() {
    super.initState();
    swipeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    swipeController.dispose();
    super.dispose();
  }

  double get rotationAngle => position.dx / widget.screenWidth * 0.3;

  void resetPosition() => setState(() => position = Offset.zero);

  void handleDragEnd(DragEndDetails details) {
    const double dismissThreshold = 100.0;

    if (position.dx.abs() > dismissThreshold ||
        details.primaryVelocity!.abs() > 800) {
      final double endX =
      position.dx > 0 ? widget.screenWidth : -widget.screenWidth;

      swipeController.addListener(() {
        setState(() {
          position = Offset.lerp(
              position, Offset(endX, position.dy), swipeController.value)!;
        });
      });

      swipeController.forward().then((_) {
        widget.onDismissed();
        position = Offset.zero;
      });
    } else {
      resetPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double piVal = 3.14159;

    return GestureDetector(
      onPanStart: (_) => swipeController.reset(),
      onPanUpdate: (details) => setState(() => position += details.delta),
      onPanEnd: handleDragEnd,
      onTap: widget.flipCard,
      child: Transform.translate(
        offset: position,
        child: Transform.rotate(
          angle: rotationAngle,
          child: AnimatedBuilder(
            animation: widget.flipAnimation,
            builder: (context, child) {
              final angle = widget.isFlipped ? piVal : 0.0;
              final currentAngle = widget.flipAnimation.value * angle;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(currentAngle),
                alignment: Alignment.center,
                child: Container(
                  width: widget.screenWidth - 48,
                  height: 500,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: currentAngle < piVal / 2
                        ? widget.buildFront(widget.tip)
                        : Transform(
                      transform: Matrix4.rotationY(piVal),
                      alignment: Alignment.center,
                      child: widget.buildBack(widget.tip),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// STATIC STACKED CARD (Not draggable)
// -----------------------------------------------------------

class _StackedCard extends StatelessWidget {
  final TipCard tip;
  final Widget Function(TipCard) buildFront;

  const _StackedCard({
    required this.tip,
    required this.buildFront,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth - 48,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: buildFront(tip),
      ),
    );
  }
}