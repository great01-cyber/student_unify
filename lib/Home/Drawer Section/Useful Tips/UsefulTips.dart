import 'package:flutter/material.dart';
import 'dart:math';

// Helper class for tip data
class TipCard {
  final String front;
  final String back;
  final List<int> colors;
  final IconData icon;

  TipCard({
    required this.front,
    required this.back,
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
    TipCard(
      front: "Cook in Batches",
      back:
      "Meal prep on Sundays. Cook large portions and freeze meals. Save 200+ monthly versus eating out daily.",
      colors: [0xFF60A5FA, 0xFF2563EB],
      icon: Icons.restaurant,
    ),
    TipCard(
      front: "Student Discounts",
      back: "Always ask for student discounts! Use UNiDAYS or Student Beans.",
      colors: [0xFFA78BFA, 0xFF9333EA],
      icon: Icons.discount,
    ),
    TipCard(
      front: "Library Resources",
      back: "Borrow textbooks and tech from your library. Save 500+ yearly.",
      colors: [0xFF4ADE80, 0xFF16A34A],
      icon: Icons.local_library,
    ),
    TipCard(
      front: "Buy Used",
      back: "Get books, furniture, electronics secondhand. Check Marketplace.",
      colors: [0xFFFB923C, 0xFFEA580C],
      icon: Icons.shopping_bag,
    ),
    TipCard(
      front: "Free Entertainment",
      back: "Use free museum days, campus events, and nature parks.",
      colors: [0xFFF472B6, 0xFFDB2777],
      icon: Icons.celebration,
    ),
  ];

  @override
  void initState() {
    super.initState();
    flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    flipAnimation = Tween<double>(begin: 0, end: 1).animate(flipController);
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(tip.icon, size: 80, color: Colors.white),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            tip.front,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBack(TipCard tip) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          tip.back,
          style: const TextStyle(fontSize: 20, color: Colors.white, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDraggableCard(int index, double screenWidth) {
    final tip = tips[index];
    final bool isCurrentCard = index == currentIndex;
    final int stackDepth = index - currentIndex;

    final double scale = (stackDepth).clamp(0, 2) * -0.05 + 1.0;
    final double offset = (stackDepth).clamp(0, 2) * 15.0;

    return KeyedSubtree(
      key: ValueKey(tip.front),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Student Money Tips",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      extendBodyBehindAppBar: true,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3A8A), // navy blue
              Color(0xFF3B82F6), // light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'Tap to flip • Swipe to advance',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),

              const Spacer(),

              SizedBox(
                height: 450,
                child: currentIndex < tips.length
                    ? Stack(
                  alignment: Alignment.topCenter,
                  children: List.generate(
                    min(tips.length - currentIndex, 3),
                        (index) =>
                        _buildDraggableCard(currentIndex + index, screenWidth),
                  ).reversed.toList(),
                )
                    : const Center(
                  child: Text(
                    'You\'ve seen all the tips! 🎉',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),

              const Spacer(),

              FloatingActionButton(
                onPressed: currentIndex > 0 ? goBackCard : null,
                backgroundColor: Colors.white,
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
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
    swipeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    swipeController.dispose();
    super.dispose();
  }

  double get rotationAngle => position.dx / widget.screenWidth * 0.5;

  void resetPosition() => setState(() => position = Offset.zero);

  void handleDragEnd(DragEndDetails details) {
    const double dismissThreshold = 100.0;

    if (position.dx.abs() > dismissThreshold ||
        details.primaryVelocity!.abs() > 800) {
      final double endX =
      position.dx > 0 ? widget.screenWidth : -widget.screenWidth;

      swipeController.addListener(() {
        setState(() {
          position =
          Offset.lerp(position, Offset(endX, position.dy), swipeController.value)!;
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
                  height: 450,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(widget.tip.colors[0]),
                        Color(widget.tip.colors[1])
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: currentAngle < piVal / 2
                      ? widget.buildFront(widget.tip)
                      : Transform(
                    transform: Matrix4.rotationY(piVal),
                    alignment: Alignment.center,
                    child: widget.buildBack(widget.tip),
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
      height: 450,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(tip.colors[0]), Color(tip.colors[1])],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: buildFront(tip),
    );
  }
}
