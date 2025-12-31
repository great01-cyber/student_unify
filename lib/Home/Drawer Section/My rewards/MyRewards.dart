import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

import 'BadgeService.dart';
// Import the service

class StudentBadgesScreen extends StatefulWidget {
  const StudentBadgesScreen({Key? key}) : super(key: key);

  @override
  State<StudentBadgesScreen> createState() => _StudentBadgesScreenState();
}

class _StudentBadgesScreenState extends State<StudentBadgesScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final BadgeService _badgeService = BadgeService();
  String? userId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Get current user ID from Firebase Auth
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    // Check if user is logged in
    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Please log in to view badges',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DonationStats>(
        stream: _badgeService.watchUserStats(userId!),
        builder: (context, statsSnapshot) {
          return StreamBuilder<List<BadgeModel>>(
            stream: _badgeService.watchUserBadges(userId!),
            builder: (context, badgesSnapshot) {
              if (badgesSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (badgesSnapshot.hasError) {
                return Center(
                  child: Text('Error loading badges: ${badgesSnapshot.error}'),
                );
              }

              final badges = badgesSnapshot.data ?? [];
              final stats = statsSnapshot.data ??
                  DonationStats(
                    totalDonations: 0,
                    uniqueStudentsHelped: 0,
                    currentStreak: 0,
                  );

              int unlockedCount = badges.where((b) => b.unlocked).length;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Student Badges',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '$unlockedCount / ${badges.length} Unlocked',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
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

                  // Stats section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your Impact',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'Donations',
                                  stats.totalDonations.toString(),
                                  Icons.favorite,
                                ),
                                _buildStatItem(
                                  'Students',
                                  stats.uniqueStudentsHelped.toString(),
                                  Icons.people,
                                ),
                                _buildStatItem(
                                  'Streak',
                                  '${stats.currentStreak}d',
                                  Icons.flash_on,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
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

                  SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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

class _BadgeCardState extends State<BadgeCard>
    with SingleTickerProviderStateMixin {
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
                    color:
                    widget.badge.gradientColors[0].withOpacity(0.3),
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
                                    0.3 +
                                        (widget.animation.value * 0.2),
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

                          // Lock icon or progress for locked badges
                          if (!widget.badge.unlocked) ...[
                            SizedBox(height: 4),
                            if (widget.badge.maxProgress > 1)
                              Text(
                                '${widget.badge.progress}/${widget.badge.maxProgress}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
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
    double progressPercentage = badge.maxProgress > 0
        ? (badge.progress / badge.maxProgress).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
              color: badge.unlocked ? Colors.white : Color(0xFF9CA3AF),
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
                color:
                badge.unlocked ? Color(0xFF10B981) : Color(0xFFF59E0B),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  badge.unlocked ? Icons.check_circle : Icons.lock_outline,
                  size: 16,
                  color:
                  badge.unlocked ? Color(0xFF10B981) : Color(0xFFF59E0B),
                ),
                SizedBox(width: 6),
                Text(
                  badge.unlocked ? 'Unlocked' : 'Locked',
                  style: TextStyle(
                    color: badge.unlocked
                        ? Color(0xFF10B981)
                        : Color(0xFFF59E0B),
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

          // Progress bar for locked badges
          if (!badge.unlocked && badge.maxProgress > 1) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${badge.progress}/${badge.maxProgress}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE5E7EB),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],

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