import 'package:flutter/material.dart';
import 'dart:ui';

class StudentBadgesScreen extends StatefulWidget {
  const StudentBadgesScreen({Key? key}) : super(key: key);

  @override
  State<StudentBadgesScreen> createState() => _StudentBadgesScreenState();
}

class _StudentBadgesScreenState extends State<StudentBadgesScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<BadgeModel> badges = [
    BadgeModel(
      id: 1,
      name: 'Peer Helper',
      description: 'Complete your first donation to unlock this badge',
      requirement: 'Make 1 donation to a fellow student',
      icon: Icons.favorite,
      unlocked: false,
      gradientColors: [Color(0xFFFB7185), Color(0xFFDB2777)],
    ),
    BadgeModel(
      id: 2,
      name: 'Campus Champion',
      description: 'Help multiple students across campus',
      requirement: 'Support 15 different students',
      icon: Icons.emoji_events,
      unlocked: false,
      gradientColors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
    ),
    BadgeModel(
      id: 3,
      name: 'Student-to-Student',
      description: 'Build a stronger student community',
      requirement: 'Donate to 5 fellow students',
      icon: Icons.groups,
      unlocked: false,
      gradientColors: [Color(0xFF60A5FA), Color(0xFF4F46E5)],
    ),
    BadgeModel(
      id: 4,
      name: 'Pay It Forward',
      description: 'Give back after receiving help',
      requirement: 'Donate after receiving support',
      icon: Icons.card_giftcard,
      unlocked: false,
      gradientColors: [Color(0xFF34D399), Color(0xFF0D9488)],
    ),
    BadgeModel(
      id: 5,
      name: 'Streak Master',
      description: 'Keep your giving streak alive',
      requirement: 'Donate for 7 consecutive days',
      icon: Icons.flash_on,
      unlocked: false,
      gradientColors: [Color(0xFFFACC15), Color(0xFFF97316)],
    ),
    BadgeModel(
      id: 6,
      name: 'Early Supporter',
      description: 'Be among the first to help',
      requirement: 'Donate within 24 hours of campaign launch',
      icon: Icons.star,
      unlocked: false,
      gradientColors: [Color(0xFFC084FC), Color(0xFFDB2777)],
    ),
    BadgeModel(
      id: 7,
      name: 'Goal Crusher',
      description: 'Help complete a campaign',
      requirement: 'Make the donation that reaches 100%',
      icon: Icons.adjust,
      unlocked: false,
      gradientColors: [Color(0xFFF87171), Color(0xFFFB7185)],
    ),
    BadgeModel(
      id: 8,
      name: 'Consistent Helper',
      description: 'Small donations, big impact',
      requirement: 'Make 10 donations of any amount',
      icon: Icons.trending_up,
      unlocked: false,
      gradientColors: [Color(0xFF22D3EE), Color(0xFF2563EB)],
    ),
    BadgeModel(
      id: 9,
      name: 'Campus Guardian',
      description: 'A true pillar of support',
      requirement: 'Help 15 students reach their goals',
      icon: Icons.workspace_premium,
      unlocked: false,
      gradientColors: [Color(0xFFA78BFA), Color(0xFF9333EA)],
    ),
    BadgeModel(
      id: 10,
      name: 'Community Star',
      description: 'Inspire others with your generosity',
      requirement: 'Share campaigns that result in 5+ donations',
      icon: Icons.auto_awesome,
      unlocked: false,
      gradientColors: [Color(0xFFE879F9), Color(0xFFDB2777)],
    ),
    BadgeModel(
      id: 11,
      name: 'Full Circle',
      description: 'From receiver to giver',
      requirement: 'Donate within 30 days of receiving help',
      icon: Icons.check_circle,
      unlocked: false,
      gradientColors: [Color(0xFFA3E635), Color(0xFF16A34A)],
    ),
    BadgeModel(
      id: 12,
      name: 'Student Legend',
      description: 'The ultimate student supporter',
      requirement: 'Complete 100 donations to fellow students',
      icon: Icons.emoji_events,
      unlocked: false,
      gradientColors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
    ),
  ];

  void _showBadgeDetail(BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BadgeDetailModal(badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Student Badges',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Color(0xFF1F2937),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF9FAFB),
                      Color(0xFFFFFFFF),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 40,
                      right: -20,
                      child: Icon(
                        Icons.emoji_events,
                        size: 120,
                        color: Color(0xFF1F2937).withOpacity(0.03),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: -30,
                      child: Icon(
                        Icons.stars,
                        size: 100,
                        color: Color(0xFF1F2937).withOpacity(0.03),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return BadgeCard(
                    badge: badges[index],
                    onTap: () => _showBadgeDetail(badges[index]),
                    animation: _controller,
                  );
                },
                childCount: badges.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeCard extends StatefulWidget {
  final BadgeModel badge;
  final VoidCallback onTap;
  final AnimationController animation;

  const BadgeCard({
    Key? key,
    required this.badge,
    required this.onTap,
    required this.animation,
  }) : super(key: key);

  @override
  State<BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<BadgeCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: widget.badge.unlocked
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.badge.gradientColors,
                )
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE5E7EB),
                    Color(0xFFD1D5DB),
                  ],
                ),
                boxShadow: widget.badge.unlocked
                    ? [
                  BoxShadow(
                    color: widget.badge.gradientColors[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PatternPainter(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with glow effect
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                widget.badge.unlocked ? 0.25 : 0.15,
                              ),
                              boxShadow: widget.badge.unlocked
                                  ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                    0.3 + (widget.animation.value * 0.2),
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : null,
                            ),
                            child: Icon(
                              widget.badge.icon,
                              size: 28,
                              color: widget.badge.unlocked
                                  ? Colors.white
                                  : Color(0xFF6B7280),
                            ),
                          ),

                          SizedBox(height: 8),

                          // Badge name
                          Flexible(
                            child: Text(
                              widget.badge.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.badge.unlocked
                                    ? Colors.white
                                    : Color(0xFF9CA3AF),
                                height: 1.2,
                              ),
                            ),
                          ),

                          // Lock icon for locked badges
                          if (!widget.badge.unlocked) ...[
                            SizedBox(height: 4),
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Shimmer effect for locked badges
                    if (!widget.badge.unlocked)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                            child: Container(
                              color: Colors.black.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BadgeDetailModal extends StatelessWidget {
  final BadgeModel badge;

  const BadgeDetailModal({Key? key, required this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 30),

          // Badge icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: badge.unlocked
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: badge.gradientColors,
              )
                  : LinearGradient(
                colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
              ),
              boxShadow: badge.unlocked
                  ? [
                BoxShadow(
                  color: badge.gradientColors[0].withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              badge.icon,
              size: 64,
              color: badge.unlocked
                  ? Colors.white
                  : Color(0xFF9CA3AF),
            ),
          ),

          SizedBox(height: 24),

          // Badge name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
          ),

          SizedBox(height: 12),

          // Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? Color(0xFF10B981).withOpacity(0.1)
                  : Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: badge.unlocked
                    ? Color(0xFF10B981)
                    : Color(0xFFF59E0B),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  badge.unlocked ? Icons.check_circle : Icons.lock_outline,
                  size: 16,
                  color: badge.unlocked ? Color(0xFF10B981) : Color(0xFFF59E0B),
                ),
                SizedBox(width: 6),
                Text(
                  badge.unlocked ? 'Unlocked' : 'Locked',
                  style: TextStyle(
                    color: badge.unlocked ? Color(0xFF10B981) : Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Requirement
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Requirement',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  badge.requirement,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // Close button
          Padding(
            padding: EdgeInsets.all(30),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: badge.unlocked
                      ? badge.gradientColors[0]
                      : Color(0xFF6B7280),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: badge.unlocked
                      ? badge.gradientColors[0].withOpacity(0.3)
                      : Colors.transparent,
                ),
                child: Text(
                  badge.unlocked ? 'Awesome!' : 'Got it!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BadgeModel {
  final int id;
  final String name;
  final String description;
  final String requirement;
  final IconData icon;
  final bool unlocked;
  final List<Color> gradientColors;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.requirement,
    required this.icon,
    required this.unlocked,
    required this.gradientColors,
  });
}
