import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SustainabilityPage extends StatelessWidget {
  const SustainabilityPage({super.key});

  static final Color _primaryColor = Color(0xFF14B8A6); // Teal
  static final Color _secondaryColor = Color(0xFF0D9488);
  static final Color _accentColor = Color(0xFFF59E0B); // Amber
  static final Color _greenColor = Color(0xFF10B981);
  static final Color _blueColor = Color(0xFF3B82F6);
  static final Color _purpleColor = Color(0xFF8B5CF6);
  static final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_GB', symbol: '£');

  Future<Map<String, dynamic>> _fetchSustainabilityData(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: userId)
        .get();

    int totalItemsShared = 0;
    double totalEstimatedValue = 0.0;
    double totalWasteDivertedKg = 0.0;
    Map<String, int> categoryBreakdown = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      totalItemsShared++;

      final price = data['price'];
      if (price is num) {
        totalEstimatedValue += price.toDouble();
      }

      final kg = data['kg'];
      if (kg is num) {
        totalWasteDivertedKg += kg.toDouble();
      }

      // Category breakdown
      final category = data['category'] as String? ?? 'Other';
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
    }

    return {
      'totalItems': totalItemsShared,
      'totalValue': totalEstimatedValue,
      'totalKg': totalWasteDivertedKg,
      'categoryBreakdown': categoryBreakdown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Sustainability Impact",
            style: TextStyle(fontFamily: 'Mont', fontWeight: FontWeight.bold),
          ),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[300]),
              SizedBox(height: 20),
              Text(
                "Please log in to see your impact",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSustainabilityData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  SizedBox(height: 16),
                  Text(
                    "Calculating your impact...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Mont',
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading data: ${snapshot.error}'),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final totalItems = data['totalItems'] as int? ?? 0;
          final totalValue = data['totalValue'] as double? ?? 0.0;
          final totalKg = data['totalKg'] as double? ?? 0.0;
          final categoryBreakdown = data['categoryBreakdown'] as Map<String, int>? ?? {};

          if (totalItems == 0) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(totalItems, totalValue, totalKg),
                      SizedBox(height: 24),
                      _buildMetricsGrid(totalItems, totalValue, totalKg),
                      SizedBox(height: 24),
                      _buildCategoryChart(categoryBreakdown),
                      SizedBox(height: 24),
                      _buildImpactComparison(totalKg),
                      SizedBox(height: 24),
                      _buildAchievementBadges(totalItems),
                      SizedBox(height: 24),
                      _buildInfoSection(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Your Impact',
          style: TextStyle(
            fontFamily: 'Mont',
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryColor, _secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.eco,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  Icons.recycling,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(int totalItems, double totalValue, double totalKg) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _secondaryColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 60,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Sustainability Champion!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Mont',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'You\'re making a real difference in our community',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Mont',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nature_people, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Keep up the great work!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Mont',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int totalItems, double totalValue, double totalKg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impact Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            fontFamily: 'Mont',
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            _buildMetricCard(
              title: "Items Shared",
              value: totalItems.toString(),
              icon: Icons.volunteer_activism,
              color: _primaryColor,
              subtitle: "donations made",
            ),
            _buildMetricCard(
              title: "Value Given",
              value: _currencyFormatter.format(totalValue),
              icon: Icons.savings,
              color: _accentColor,
              subtitle: "to community",
            ),
            _buildMetricCard(
              title: "Waste Diverted",
              value: "${totalKg.toStringAsFixed(1)} kg",
              icon: Icons.recycling,
              color: _greenColor,
              subtitle: "from landfill",
            ),
            _buildMetricCard(
              title: "CO₂ Saved",
              value: "${(totalKg * 1.5).toStringAsFixed(1)} kg",
              icon: Icons.co2,
              color: _blueColor,
              subtitle: "estimated",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, int> categoryBreakdown) {
    if (categoryBreakdown.isEmpty) return SizedBox.shrink();

    final colors = [
      _primaryColor,
      _accentColor,
      _greenColor,
      _blueColor,
      _purpleColor,
      Colors.pink,
      Colors.orange,
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    categoryBreakdown.forEach((category, count) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '$count',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Mont',
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categoryBreakdown.entries.map((entry) {
              final index = categoryBreakdown.keys.toList().indexOf(entry.key);
              return _buildLegendItem(
                entry.key,
                entry.value,
                colors[index % colors.length],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String category, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            '$category ($count)',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactComparison(double totalKg) {
    final treesEquivalent = (totalKg * 0.02).toInt();
    final waterBottles = (totalKg * 5).toInt();
    final plasticsRecycled = (totalKg * 0.3).toInt();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: _greenColor),
              SizedBox(width: 8),
              Text(
                'That\'s equivalent to...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Mont',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildComparisonItem(
            Icons.park,
            'Planting $treesEquivalent trees',
            _greenColor,
          ),
          SizedBox(height: 12),
          _buildComparisonItem(
            Icons.water_drop,
            'Saving $waterBottles plastic bottles',
            _blueColor,
          ),
          SizedBox(height: 12),
          _buildComparisonItem(
            Icons.recycling,
            'Recycling ${plasticsRecycled}kg of plastic',
            _purpleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadges(int totalItems) {
    List<Map<String, dynamic>> achievements = [];

    if (totalItems >= 1) achievements.add({'title': 'First Step', 'icon': Icons.celebration, 'color': Colors.amber});
    if (totalItems >= 5) achievements.add({'title': 'Generous Giver', 'icon': Icons.favorite, 'color': Colors.pink});
    if (totalItems >= 10) achievements.add({'title': 'Community Hero', 'icon': Icons.military_tech, 'color': Colors.orange});
    if (totalItems >= 25) achievements.add({'title': 'Impact Master', 'icon': Icons.emoji_events, 'color': Colors.purple});
    if (totalItems >= 50) achievements.add({'title': 'Legend', 'icon': Icons.auto_awesome, 'color': Colors.blue});

    if (achievements.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: _accentColor),
              SizedBox(width: 8),
              Text(
                'Achievements Unlocked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Mont',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      achievement['color'].withOpacity(0.8),
                      achievement['color'],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: achievement['color'].withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(achievement['icon'], color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'How we calculate your impact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoItem('Value Given: Based on the estimated price you listed for each item'),
          _buildInfoItem('Waste Diverted: Calculated from the weight (kg) you provided'),
          _buildInfoItem('CO₂ Saved: Estimated using industry averages for waste reduction'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco_outlined, size: 80, color: _primaryColor),
            ),
            SizedBox(height: 24),
            Text(
              "Start making an impact!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mont',
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "You haven't shared any items yet.\nEvery donation helps reduce waste and support your community.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Mont',
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text('Create First Donation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
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
      ),
    );
  }
}